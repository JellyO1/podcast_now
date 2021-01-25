import 'package:listennotes_api/models/podcast_simple.dart';

abstract class IPodcastRepository {
  Future init();
  Future<PodcastSimple> getRandomPodcast();
  Future save();
}