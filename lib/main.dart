// Dart imports:
import 'dart:io';

// Project imports:
import 'package:swaram/model/music_database.model.dart';

void main(List<String> args) async {
  var md = MusicDatabase();
  await md.initialize();

  var musicDir = Directory("C:\\Users\\ShadyTi\\Music\\");
  var songs = musicDir.listSync().whereType<File>();

  int count = 1;

  for (var song in songs) {
    // print('$count\t\t${song.path}');

    if (song.path.endsWith('.mp3')) {
      var status = await md.addSong(song.path);
    }
    count += 1;
  }
}
