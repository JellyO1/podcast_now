import 'dart:convert';
import 'dart:math';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:listennotes_api/listennotes_api.dart';
import 'package:listennotes_api/models/podcast_page.dart';
import 'package:listennotes_api/models/podcast_simple.dart';
import 'package:podcast_now/data_provider/entity.dart';
import 'package:podcast_now/data_provider/genre_entity.dart';
import 'package:podcast_now/data_provider/podcast_entity.dart';
import 'package:podcast_now/repository/podcast_repository_interface.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class PodcastRepository implements IPodcastRepository {
  late ListenNotesAPI listenNotesAPI;
  late Database cache;

  final List<Genre> genres = [];
  final List<Podcast> podcasts = [];

  PodcastRepository();

  Future init() async {
    // Firebase remote config
    final remoteConfig = FirebaseRemoteConfig.instance;

    // Initialize listenNotesAPI
    listenNotesAPI = ListenNotesAPI(apiKey: remoteConfig.getString("listennotes_api_key"));

    var databasePath = await getDatabasesPath();
    String dbPath = join(databasePath, 'podcast.db');

    if (kDebugMode && true) await deleteDatabase(dbPath);

    cache = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async => await db.transaction((txn) async {
        txn.execute(
            "CREATE TABLE Podcasts (id TEXT PRIMARY KEY, genre_id INTEGER, json TEXT, is_new INTEGER, FOREIGN KEY(genre_id) REFERENCES Genres(id))");
        txn.execute("CREATE TABLE Genres (id INTEGER PRIMARY KEY, page INTEGER)");
      }),
    );

    genres.addAll((await cache.query("Genres")).map((e) => Genre(e["id"] as int,  e["page"] as int)));

    if (genres.isEmpty) {
      genres.addAll((await listenNotesAPI.getGenres()).map((e) => Genre(e.id, 1)));
    }

    // This avoids hitting the local db (disk) for every podcast at the cost of memory
    // The maximum amount of size should be ngenres (160) * N (podcasts per page) * sizeof(PodcastSimple)
    var podcastsQuery = await cache.rawQuery("SELECT id, json FROM Podcasts WHERE is_new = 1");

    if (podcastsQuery.isNotEmpty) {
      podcasts.addAll(podcastsQuery.map((e) => Podcast(e["id"] as String, e["genre_id"] as int, e["json"] as String, e["is_new"] as bool)));
    }
  }

  @override
  Future<PodcastSimple> getRandomPodcast() async {
    final Genre genre = genres[Random(DateTime.now().millisecondsSinceEpoch).nextInt(genres.length)];

    if (podcasts.isEmpty) {
      final PodcastPage podcastPage = await listenNotesAPI.getBestPodcasts(page: genre.page++, genre: genre.id);
      podcasts.addAll(podcastPage.podcasts.map<Podcast>((e) => Podcast(e.id, genre.id, jsonEncode(e.toJson()), true)));
    }

    var pod = podcasts.where((element) => element.isNew == true).first;
    pod.isNew = false;

    return PodcastSimple.fromJson(jsonDecode(pod.json));
  }

  @override
  Future save() async {
    final batch = cache.batch();

    for (var entity in podcasts) {
      switch (entity.state) {
        case EntityState.added:
          batch.insert(entity.name, entity.toJson());
          break;
        case EntityState.deleted:
          batch.delete(entity.name, where: "id = ?", whereArgs: [entity.id]);
          break;
        case EntityState.modified:
          batch.update(entity.name, entity.toJson(), where: "id = ?", whereArgs: [entity.id]);
          break;

        case EntityState.unchanged:
        default:
          break;
      }

      entity.state = EntityState.unchanged;
    }

    for (var entity in genres) {
      switch (entity.state) {
        case EntityState.added:
          batch.insert(entity.name, entity.toJson());
          break;
        case EntityState.deleted:
          batch.delete(entity.name, where: "id = ?", whereArgs: [entity.id]);
          break;
        case EntityState.modified:
          batch.update(entity.name, entity.toJson(), where: "id = ?", whereArgs: [entity.id]);
          break;
        case EntityState.unchanged:
        default:
          break;
      }

      entity.state = EntityState.unchanged;
    }

    await batch.commit(noResult: true);
  }
}
