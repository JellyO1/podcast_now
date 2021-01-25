import 'dart:async';

import 'package:listennotes_api/models/podcast_simple.dart';
import 'package:podcast_now/repository/podcast_repository_interface.dart';
import 'package:rxdart/rxdart.dart';

class PodcastBloc {
  final IPodcastRepository podcastRepository;
  final _podcast = BehaviorSubject<PodcastSimple>();
  Stream<PodcastSimple> get podcast => _podcast.stream;

  final _onNewPodcastRequest = StreamController<void>();

  PodcastBloc(this.podcastRepository) {
    _onNewPodcastRequest.stream
        .debounce((event) => TimerStream(true, Duration(milliseconds: 200)))
        .asyncMap(_fetchPodcast)
        .listen(_podcast.add);

    _onNewPodcastRequest.add(null);
  }

  Future<PodcastSimple> _fetchPodcast(void event) async {
    return await podcastRepository.getRandomPodcast();
  }

  void newPodcast() {
    _onNewPodcastRequest.add(null);
  }

  dispose() {
    _podcast.close();
    _onNewPodcastRequest.close();
  }
}
