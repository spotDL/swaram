// Dart imports:
import 'dart:io';

// Project imports:
import 'package:swaram/model/music_database.model.dart';

void main(List<String> args) async {
  var md = MusicDatabase();
  await md.initialize();

  var t1 = DateTime.now();

  var musicDir = Directory("C:\\Users\\ShadyTi\\Music\\");
  var songs = musicDir.listSync().whereType<File>();

  for (var song in songs) {
    // print('$count\t\t${song.path}');

    if (song.path.endsWith('.mp3')) {
      var status = await md.addSong(mp3FilePath: song.path);
    }
  }

  var t2 = DateTime.now();

  var allSongs = await md.findSongs(field: 'name', query: '');

  int count = 0;

  for (var songEntry in allSongs.entries) {
    print('$count\t${songEntry.value.name}');

    if (songEntry.value.name.startsWith('a') || songEntry.value.name.startsWith('A')) {
      await md.deleteSong(uSong: songEntry.value);
    }
    count++;
  }

  print('----------');

  allSongs = await md.findSongs(field: 'name', query: '');
  count = 0;

  for (var songEntry in allSongs.entries) {
    print('$count\t${songEntry.value.name}');
    count++;
  }

  print('----------');

  await Future.delayed(const Duration(seconds: 10));

  var t3 = DateTime.now();

  await md.refreshDatabase();

  var t4 = DateTime.now();

  print('adding songs: ${t1.difference(t2)}');
  print('updating database: ${t3.difference(t4)}');
}
