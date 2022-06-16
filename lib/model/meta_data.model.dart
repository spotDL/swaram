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
class MusicDataBase extends ChangeNotifier {
  /// sembast Database, access via `_store`
  ///
  late final Database _database;

  /// sembast StoreRef, used to manipulate `_database`
  ///
  final _store = StoreRef<String, dynamic>.main();

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
  Future<bool> addSong(String mp3FilePath) async {
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

      var albumArtFile = File(await getAlbumArtPath(albumArtFileNumber));

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
      // database update
      await _store.add(_database, song.toMap());

      // action status
      return true;
    }

    return false;
  }

  /// delete a song's ID3 data and albumArtCache
  ///
  Future<void> deleteSong(SongRepr uSong) async {
    // search for songs
    var songResults = await findSongs(field: 'name', query: uSong.name);

    // delete a song only if it has the same album and artists
    for (var songEntry in songResults.entries) {
      var songId = songEntry.key;
      var song = songEntry.value;

      if (uSong.album == song.album && listEquals(uSong.artists, song.artists)) {
        await _store.record(songId).delete(_database);

        await File(await getAlbumArtPath(song.albumArtFileNumber)).delete();
      }
    }
  }

  /// search the given field in the database, and return all songs that start
  /// with the chosen query
  ///
  /// ### Note:
  /// - return Map is of the form {databasePrimaryKey: [Song]}
  ///
  Future<Map<String, SongRepr>> findSongs({
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
        filter: Filter.matches(field, '$query.*', anyInList: searchingByArtist),
      ),
    );

    // convert each result into a song object
    return {for (var songJSON in songs) songJSON.key: SongRepr.fromMap(songJSON.value)};
  }

  /// check if a song exists in the database
  ///
  /// ### Note:
  /// - only compares title, artists, and album
  ///
  Future<bool> _containsSong(SongRepr song) async {
    // are there songs with the same title?
    var titleMatchResults = await findSongs(field: 'name', query: song.name);

    // compare album and artists for each song with the same title
    for (var titleMatchRes in titleMatchResults.values) {
      if (titleMatchRes.album == song.album && listEquals(titleMatchRes.artists, song.artists)) {
        return true;
      }
    }

    return false;
  }
}
