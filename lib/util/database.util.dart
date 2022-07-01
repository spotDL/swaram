/// {@category utilities}
///
/// A few utilities to help with the [MusicDatabase] management
///

// Dart imports:
import 'dart:io';

// Package imports:
import 'package:sembast/sembast.dart';

// Project imports:
import 'package:swaram/model/database.model.dart';
import 'package:swaram/model/song.model.dart';

/// create a regular expression from a search term
///
Future<String> prepRegExp({required String query}) async {
  return '^${query.replaceAll('(', '\\(').replaceAll(')', '\\)').toLowerCase()}.*';
}

/// take a list of song records and convert them to [Song] objects
///
/// ### Note:
/// - returned list is sorted alphabetically
///
Future<List<Song>> convertRecordToRepr({
  required MusicDatabase database,
  required List<RecordSnapshot> records,
}) async {
  return [
    for (var record in records) Song.fromMap(database: database, map: record.value)..id = record.key
  ]..sort((a, b) => a.title.compareTo(b.title));
}

/// add all `mp3` files in the given directory to the database
///
Future<void> addAllSongs({required MusicDatabase database, required String folderPath}) async {
  var folder = Directory(folderPath);

  await for (var element in folder.list()) {
    if (element is File && element.path.toString().endsWith('mp3')) {
      await database.addSong(filePath: element.path);
    }
  }
}
