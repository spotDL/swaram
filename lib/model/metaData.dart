// Dart imports:
import 'dart:convert';
import 'dart:io';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:id3/id3.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

// Project imports:
import 'package:swaram/model/song.model.dart';

class MetaDataHandler extends ChangeNotifier {
  late final Database db;

  final _store = StoreRef<String, dynamic>.main();

  Future<void> init() async {
    // make application docs directory
    var docsDir = await getApplicationDocumentsDirectory();
    var appDocsDir = Directory(
      join(docsDir.path, 'swaram'),
    )..createSync();

    // open database
    db = await databaseFactoryIo.openDatabase(
      join(appDocsDir.path, 'swaram.db'),
    );
  }

  Future<void> addSong(String songFilePath) async {
    // read ID3 tags
    var mp3File = File(songFilePath).readAsBytesSync();
    var mp3Data = MP3Instance(mp3File)..parseTagsSync();
    var id3Data = mp3Data.metaTags;

    // create a song object form the ID3 tags
    var song = Song(
      name: id3Data['Title'],
      artists: (id3Data['Artist'] as String).split('/'),
      album: id3Data['Album'],
      trackPos: int.parse(id3Data['TPOS']),
      genre: id3Data['Genre'],
      lyrics: id3Data['USLT'] == null ? '' : id3Data['USLT']['lyrics'],
      albumArt: base64.decode(id3Data['APIC']['base64']),
    );

    // add the song to the database if it doesn't already exit in it
    if (!await _containsSong(song)) {
      await _store.add(db, song.toMap());
    }
  }

  Future<bool> _containsSong(Song song) async {
    // are there songs with the same title?
    var titleMatchResults = await findSongs(field: 'name', query: song.name);

    // compare album and artists for each song with the same title
    for (var titleMatchRes in titleMatchResults) {
      if (titleMatchRes.album == song.album && listEquals(titleMatchRes.artists, song.artists)) {
        return true;
      }
    }

    return false;
  }

  Future<List<Song>> findSongs({
    required String field,
    required String query,
    bool searchingByArtist = false,
  }) async {
    // filter db using RegX
    //
    // note: artist field is a list, so we need to use anyInList, using anyInList on non list
    // fields always returns empty results
    var songs = await _store.find(
      db,
      finder: Finder(filter: Filter.matches(field, '$query.*', anyInList: searchingByArtist)),
    );

    // convert each result into a song object
    return [for (var songJSON in songs) Song.fromMap(songJSON.value)];
  }
}
