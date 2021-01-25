import 'dart:math';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:listennotes_api/models/podcast_simple.dart';
import 'package:podcast_now/bloc/podcasts_bloc.dart';
import 'package:podcast_now/repository/podcast_repository.dart';
import 'package:podcast_now/repository/podcast_repository_interface.dart';
import 'package:podcast_now/splash_screen.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'ad_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize firebase
  await Firebase.initializeApp();

  // Pass all uncaught errors from the framework to Crashlytics.
  FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

  // Lock to portrait
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(Provider<IPodcastRepository>(
    create: (context) => PodcastRepository(),
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  static FirebaseAnalytics analytics = FirebaseAnalytics();
  static FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(analytics: analytics);

  final Map<String, Route<dynamic> Function(RouteSettings settings)> pages = {
    '/': (settings) {
      analytics.setCurrentScreen(screenName: settings.name, screenClassOverride: '$SplashScreen');
      return MaterialPageRoute(builder: (context) => SplashScreen(), settings: settings);
    },
    RandomPodcastHome.routeName: (settings) {
      analytics.setCurrentScreen(screenName: settings.name, screenClassOverride: '$RandomPodcastHome');
      return MaterialPageRoute(
        builder: (context) => Provider<PodcastBloc>(
          create: (context) => PodcastBloc(Provider.of<IPodcastRepository>(context, listen: false)),
          dispose: (context, bloc) => bloc.dispose(),
          lazy: false,
          child: RandomPodcastHome(),
        ),
      );
    }
  };

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Podcast Now!',
      theme: ThemeData.dark(),
      onGenerateRoute: (settings) => pages[settings.name](settings),
      navigatorObservers: [observer],
      debugShowCheckedModeBanner: false,
    );
  }
}

class RandomPodcastHome extends StatefulWidget {
  static const routeName = '/home';
  static const MobileAdTargetingInfo targetingInfo = MobileAdTargetingInfo(
    contentUrl: "https://www.listennotes.com",
    keywords: ['podcast'],
    nonPersonalizedAds: true,
  );

  const RandomPodcastHome({Key key}) : super(key: key);

  @override
  _RandomPodcastHomeState createState() => _RandomPodcastHomeState();
}

class _RandomPodcastHomeState extends State<RandomPodcastHome> with WidgetsBindingObserver {
  InterstitialAd _interstitialAd;

  @override
  Widget build(BuildContext context) {
    return Consumer<PodcastBloc>(
      builder: (context, bloc, child) => Scaffold(
        body: SafeArea(
          child: StreamBuilder<PodcastSimple>(
            stream: bloc.podcast,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                if (snapshot.data == null) return NoMorePodcasts();
                return PodcastDetail(
                  podcast: snapshot.data,
                  onNewPodcastRequest: () async {
                    if (_interstitialAd != null && await _interstitialAd.isLoaded()) _interstitialAd.show();

                    bloc.newPodcast();
                  },
                );
              }
              if (snapshot.hasError) {
                return FourOFourWidget(
                  text: snapshot.error.toString(),
                );
              }

              return Container();
            },
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _createInterstitialAdAsync();
    WidgetsBinding.instance.addObserver(this);
  }

  Future _createInterstitialAdAsync() async {
    final rc = await RemoteConfig.instance;
    var adUnitId = rc.getString("interstitial_ad_unit_id");

    _interstitialAd = InterstitialAd(
        adUnitId: adUnitId,
        listener: (MobileAdEvent event) {
          if (event == MobileAdEvent.closed) _interstitialAd.load();
        });

    _interstitialAd.load();
  }

  @override
  void dispose() {
    _interstitialAd.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        Provider.of<IPodcastRepository>(context, listen: false).save();
        break;
      default:
        break;
    }
    super.didChangeAppLifecycleState(state);
  }
}

class PodcastDetail extends StatelessWidget {
  final PodcastSimple podcast;
  final Function onNewPodcastRequest;

  const PodcastDetail({Key key, @required this.podcast, this.onNewPodcastRequest}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Container(
              height: MediaQuery.of(context).size.height * .4,
              child: Image.network(
                podcast.image,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
          ),
          Text(
            podcast.title,
            style: Theme.of(context).textTheme.headline6,
            textAlign: TextAlign.center,
          ),
          Text(
            podcast.publisher,
            style: Theme.of(context).textTheme.subtitle2,
            textAlign: TextAlign.center,
          ),
          Flexible(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(8)),
              child: SingleChildScrollView(
                child: Html(
                  data: podcast.description,
                ),
              ),
            ),
          ),
          podcast.listennotesUrl.isNotEmpty
              ? RaisedButton(
                  onPressed: () async => await launch(podcast.listennotesUrl),
                  color: Colors.grey[900],
                  child: Text("Listen on ListenNotes"),
                )
              : Container(),
          IconButton(
            onPressed: onNewPodcastRequest,
            icon: Icon(Icons.autorenew),
          )
        ],
      ),
    );
  }
}

class NoMorePodcasts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Text(
          "Thanks for using the app!\n\n You've seen every podcast ListenNotes has to give.\n\n"
          "If you'd like to see something added leave a comment.",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class FourOFourWidget extends StatelessWidget {
  final String text;

  const FourOFourWidget({Key key, @required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    FirebaseCrashlytics.instance.log(text);
    return Stack(
      children: [
        Positioned(
          top: 100,
          left: -20,
          right: -20,
          child: Transform(
            transform: Matrix4.rotationZ(-.2),
            child: Image(
              image: AssetImage("images/keep_out_tape.png"),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          left: -20,
          right: -20,
          child: Transform(
            transform: Matrix4.rotationZ(.2),
            child: Image(
              image: AssetImage("images/keep_out_tape.png"),
            ),
          ),
        ),
        Center(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFFB00),
              border: Border(
                top: BorderSide(
                  color: const Color(0xFF000000),
                  width: 8,
                ),
                bottom: BorderSide(
                  color: const Color(0xFF000000),
                  width: 8,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  text.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                    color: const Color(0xFF000000),
                  ),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }
}
