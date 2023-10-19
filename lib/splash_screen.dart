import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:podcast_now/main.dart';
import 'package:podcast_now/repository/podcast_repository_interface.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF212121),
      body: Center(
        child: Stack(
          children: [
            RotationTransition(
              turns: _controller,
              alignment: Alignment.center,
              child: Image(
                image: AssetImage("images/refresh_icon_216.png"),
              ),
            ),
            Image(image: AssetImage("images/podcast_icon_216.png")),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(seconds: 2))..repeat();
    _initializeDependencies();
  }

  Future<void> _initializeDependencies() async {
    // Firebase remote config
    await Firebase.initializeApp(
       options: DefaultFirebaseOptions.currentPlatform,
    );
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.fetchAndActivate();

    final podcastRepository = context.read<IPodcastRepository>();
    await podcastRepository.init();

    if (kDebugMode) await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);

    Navigator.of(context).pushReplacementNamed(RandomPodcastHome.routeName);
  }
}
