/// {@category backend}
///
/// [MusicDatabase] is a wrapper over `sembast`'s [Database] class that integrates with [SongRepr]
/// thereby making it easier and simpler to use
///
/// ```dart
/// // create an database, initialize it
/// var mDatabase = MusicDatabase();
/// await mDatabase.initialize();
///
/// // add a song (Iron by Woodkid)
/// await mDatabase.addSong('./test/testSong.mp3');
///
/// // search for a song (returns a list of `SongRepr`)
///
/// // 1. all songs starting with the letters 'iro'
/// var song = (await mDatabase.findSongsByName(query: 'iro').first;
///
/// // 2. all songs belonging to albums starting with 'iro'
/// await mDatabase.findSongsByAlbum(query: 'Iro');
///
/// // 3. all songs by or featuring 'woodkid'
/// await mDatabase.findSongsByArtist(query: 'woodkid');
///
/// // delete a song (deletes Iron by woodkid, albumArt will not be removed)
/// await mDatabase.deleteSong(song);
///
/// // update cache and fix any discrepancies introduced from deleting songs
/// await mDatabase.refreshDatabase();
/// ```
///

// Dart imports:
import 'dart:convert';
import 'dart:io';
import 'dart:math';

// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:id3/id3.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

// Project imports:
import 'package:swaram/model/song.model.dart';
import 'package:swaram/util/path.util.dart';

/// Store and access song details to quickly update UI
///
class MusicDatabase {
  /// sembast Database, access via `_store`
  ///
  late final Database _database;

  /// sembast StoreRef, used to manipulate `_database`
  ///
  final _store = StoreRef<String, Map<String, dynamic>>('songs');

  /// generate random numbers
  ///
  final _randomEngine = Random();

  /// completely initialize the this object
  ///
  /// ### Note:
  /// - the setup of this object requires some async operations, those
  ///   cannot be done in a normal class, hence they're being done here
  ///
  Future<void> initialize() async {
    await setupAppDocsFolder();

    // setup database reference
    _database = await databaseFactoryIo.openDatabase(
      await getSwaramDatabasePath(),
    );
  }

  /// extract ID3 data from the MP3 file at the given path and add it
  /// to the database
  ///
  /// ### Note:
  /// - returns `true` if song is added, `false` is song is skipped
  ///
  Future<bool> addSong({required String mp3FilePath}) async {
    // read the ID3 tags
    var mp3Bytes = await File(mp3FilePath).readAsBytes();
    var mp3Data = MP3Instance(mp3Bytes)..parseTagsSync();
    var id3Data = mp3Data.metaTags;

    // search for similar albums
    var searchResults = await _store.find(
      _database,
      finder: Finder(
        filter: Filter.matches(
          'album',
          id3Data['Album'].replaceAll('(', '\\(').replaceAll(')', '\\)'),
        ),
      ),
    );

    // save albumArt to cache
    var songArtists = (id3Data['Artist'] as String).split('/');

    late int albumArtFileNumber;
    bool albumArtCached = false;

    for (var result in searchResults) {
      var songJSON = result.value;

      if (listEquals([for (var artist in songJSON['artists']) artist as String], songArtists)) {
        albumArtCached = true;
        albumArtFileNumber = songJSON['albumArtFileNumber'];

        break;
      }
    }

    while (!albumArtCached && id3Data.containsKey('APIC')) {
      albumArtFileNumber = _randomEngine.nextInt(1000000);

      var albumArtFile = File(await getAlbumArtJpg(albumArtFileNumber));

      if (!albumArtFile.existsSync()) {
        await albumArtFile.writeAsBytes(
          base64.decode(id3Data['APIC']['base64']),
        );

        break;
      }
    }

    // check if song is in database
    var song = SongRepr(
      filePath: mp3FilePath,
      name: id3Data['Title'],
      album: id3Data['Album'],
      trackPos: int.parse(id3Data['TPOS']),
      albumArtFileNumber: albumArtFileNumber,
      artists: songArtists,
      genre: id3Data.containsKey('Genre') ? id3Data['Genre'] : 'Unknown',
      lyrics: id3Data.containsKey('USLT') ? id3Data['USLT']['lyrics'] : 'No lyrics available',
    );

    if (!await _containsSong(song)) {
      // get and modify songMap
      var songMap = song.toMap();
      songMap['searchName'] = songMap['name'].toString().toLowerCase();
      songMap['searchAlbum'] = songMap['album'].toString().toLowerCase();
      songMap['searchArtists'] = [for (var a in songMap['artists']) a.toString().toLowerCase()];

      // database update
      await _store.add(_database, songMap);

      // action status
      return true;
    }

    return false;
  }

  /// delete a song's ID3 data and albumArtCache
  ///
  Future<void> deleteSong({required SongRepr song}) async {
    await _store.record(song.id).delete(_database);
  }

  /// remove remnants of deleted data (if any) from the database and albumArtCache
  ///
  /// ### Note:
  /// - avoid using often, it is a costly operation
  ///
  Future<void> refreshDatabase() async {
    // empty album art cache
    Directory(
      await getAlbumArtCachePath(),
    ).listSync().forEach((element) {
      if (element is File) element.deleteSync();
    });

    // get all songs
    var allSongs = await _findSongs(field: 'name', query: '');

    // empty database, re-update cache and database
    var filePaths = <String>[];

    for (var song in allSongs) {
      filePaths.add(song.filePath);

      await _store.record(song.id).delete(_database);

      var albumArtFile = File(await getAlbumArtJpg(song.albumArtFileNumber));

      if (await albumArtFile.exists()) {
        await albumArtFile.delete();
      }
    }

    for (var path in filePaths) {
      addSong(mp3FilePath: path);
    }
  }

  /// search the given field in the database, and return all songs that start
  /// with the chosen query
  ///
  /// ### Note:
  /// - return Map is of the form {databasePrimaryKey: [SongRepr]}
  ///
  Future<List<SongRepr>> _findSongs({
    required String field,
    required String query,
    bool searchingByArtist = false,
  }) async {
    // filter db using RegX

    // unescaped parenthesis is interpreted as part of RegX and causes errors
    query = query.replaceAll('(', '\\(');
    query = query.replaceAll(')', '\\)');

    // note: artist field is a list, so we need to use anyInList, using
    // anyInList on non list fields always returns empty results
    var songs = await _store.find(
      _database,
      finder: Finder(
        filter: Filter.matches(field, '^$query.*', anyInList: searchingByArtist),
      ),
    );

    // convert each result into a song object
    return [for (var songJSON in songs) SongRepr.fromMap(songJSON.value)..setId(songJSON.key)]
      ..sort(
        (a, b) => a.name.compareTo(b.name),
      );
  }

  /// returns all songs whose name starts with the given query
  ///
  Future<List<SongRepr>> findSongsByName({required String query}) async {
    return _findSongs(field: 'searchName', query: query.toLowerCase());
  }

  /// returns all songs whose album starts with the given query
  ///
  Future<List<SongRepr>> findSongsByAlbum({required String query}) async {
    return _findSongs(field: 'searchAlbum', query: query.toLowerCase());
  }

  /// returns all songs who have at least one artist whose name starts with the given query
  ///
  Future<List<SongRepr>> findSongsByArtist({required String query}) async {
    return _findSongs(field: 'searchArtists', query: query.toLowerCase(), searchingByArtist: true);
  }

  /// check if a song exists in the database
  ///
  /// ### Note:
  /// - only compares title, artists, and album
  ///
  Future<bool> _containsSong(SongRepr song) async {
    // are there songs with the same title?
    var titleMatchResults = await _findSongs(field: 'name', query: song.name);

    // compare album and artists for each song with the same title
    for (var titleMatchRes in titleMatchResults) {
      if (titleMatchRes.album == song.album && listEquals(titleMatchRes.artists, song.artists)) {
        return true;
      }
    }

    return false;
  }
}
