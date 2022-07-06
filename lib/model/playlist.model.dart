/// {@category backend}
///
/// The [Playlist] class represents a playlist (obviously). The search functions for playlists
/// are also bundled with it.
///
/// To create/delete a playlist:
/// ```dart
/// var playlist = await Playlist.create('enterYourNameHere');
/// await playlist.setName('newNameGoesHere'); // change playlist name
/// print(await playlist.getName());
/// await playlist.delete();
/// ```
///
/// To add/remove songs:
/// ```dart
/// await playlist.addSong(yourSongObjectGoesHere);
/// await playlist.removeSong(yourSongObjectGoesHere);
///
/// var songs = await playlist.getSongs(); // get all songs in playlist
/// ```
///

// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:sembast/sembast.dart';

// Project imports:
import 'package:swaram/model/database.model.dart';
import 'package:swaram/model/song.model.dart';
import 'package:swaram/util/database.util.dart';

/// wrapper around playlist details for easy access and UI updating
class Playlist extends ChangeNotifier {
  /// id of the playlist
  late final String id;

  /// parent database
  static late final SwaramDatabase parentDB;

  // ======================================
  // ===== constructors / destructors =====
  // ======================================

  /// create a playlist object to represent an existing playlist
  Playlist._internal({required this.id});

  /// create a playlist object to represent an existing playlist
  static Future<Playlist> fromID({required String id}) async {
    return Playlist._internal(id: id);
  }

  /// make a playlist from scratch, add it to the database
  static Future<Playlist> create({required String name}) async {
    var id = await parentDB.playlistStore
        .add(parentDB.database, {'name': name, 'searchName': name.toLowerCase(), 'songIDs': []});

    return Playlist._internal(id: id);
  }

  /// delete this playlist from the database
  Future<void> delete() async {
    await parentDB.playlistStore.record(id).delete(parentDB.database);
  }

  // ================================
  // ===== name related methods =====
  // ================================

  /// get name of the playlist
  Future<String> getName() async {
    // get name from database
    var record = await parentDB.playlistStore.record(id).get(parentDB.database);
    return record!['name']! as String;
  }

  /// set name of the playlist
  Future<void> setName({required String name}) async {
    // update database
    await parentDB.playlistStore
        .record(id)
        .update(parentDB.database, {'name': name, 'searchName': name.toLowerCase()});

    notifyListeners();
  }

  // ================================
  // ===== song related methods =====
  // ================================

  /// get all songs in the playlist
  Future<List<Song>> getSongs() async {
    // get songIDs
    var songIDs = await _getSongIDs();

    // convert to Songs
    return [for (var songID in songIDs) await Song.fromID(id: songID)];
  }

  /// add a song to the playlist
  Future<void> addSong({required Song song}) async {
    // get songIDs
    var songIDs = await _getSongIDs();

    // update list
    songIDs.contains(song.id) ? null : songIDs.add(song.id);
    await parentDB.playlistStore.record(id).update(parentDB.database, {'songIDs': songIDs});

    notifyListeners();
  }

  /// add a song to the playlist
  Future<void> removeSong({required Song song}) async {
    // get songIDs
    var songIDs = await _getSongIDs();

    // update list
    songIDs.remove(song.id);
    await parentDB.playlistStore.record(id).update(parentDB.database, {'songIDs': songIDs});

    notifyListeners();
  }

  /// get IDs of all songs in the playlist
  Future<List<String>> _getSongIDs() async {
    var record = await parentDB.playlistStore.record(id).get(parentDB.database);
    record!;

    return [for (var id in (record['songIDs'] as List)) id as String];
  }

  // ==========================
  // ===== static methods =====
  // ==========================

  /// find a playlist by name
  static Future<List<Playlist>> findByName({required String name}) async {
    var playlistRecords = await parentDB.playlistStore.find(
      parentDB.database,
      finder: Finder(
        filter: Filter.matches('searchName', await prepRegExp(query: name)),
      ),
    );

    return [for (var record in playlistRecords) await Playlist.fromID(id: record.key)];
  }
}
