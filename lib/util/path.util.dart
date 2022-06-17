// Dart imports:
import 'dart:io';

// Package imports:
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// setup the docs structure for storing app data
///
Future<void> setupAppDocsFolder() async {
  await Directory(
    join(
      await getSwaramDocsPath(),
      'albumArtCache',
    ),
  ).create(recursive: true);
}

/// get path to the app's docs folder
///
Future<String> getSwaramDocsPath() async {
  var appDocsDir = await getApplicationDocumentsDirectory();

  return join(
    appDocsDir.path,
    'swaram',
  );
}

/// get path to the swaram database
///
Future<String> getSwaramDatabasePath() async {
  return join(
    await getSwaramDocsPath(),
    'swaram.db',
  );
}

/// get file part to the albumArtCache folder
///
Future<String> getAlbumArtCachePath() async {
  return join(
    await getSwaramDocsPath(),
    'albumArtCache',
  );
}

/// get file path to a specific album art cover
///
Future<String> getAlbumArtJpg(int albumArtId) async {
  return join(
    await getSwaramDocsPath(),
    'albumArtCache',
    '$albumArtId.jpg',
  );
}
