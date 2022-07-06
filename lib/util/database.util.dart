/// {@category utilities}
///
/// A few utilities to help with the [SwaramDatabase] management
///

// Dart imports:
import 'dart:io';

// Project imports:
import 'package:swaram/model/song.model.dart';

/// create a regular expression from a search term
///
Future<String> prepRegExp({required String query}) async {
  return '^${query.replaceAll('(', '\\(').replaceAll(')', '\\)').toLowerCase().trim()}.*';
}

/// add all `mp3` files in the given directory to the database
///
Future<void> addAllSongs({required String folderPath}) async {
  var folder = Directory(folderPath);

  await for (var element in folder.list()) {
    if (element is File && element.path.toString().endsWith('mp3')) {
      await Song.addToDB(path: element.path);
    }
  }
}
