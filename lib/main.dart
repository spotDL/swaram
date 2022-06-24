// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:swaram/model/database.model.dart';
import 'package:swaram/model/player.model.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  var md = MusicDatabase();
  await md.initialize();

  var pl = Player();

  print('song');

  await pl.load((await md._findSongs(field: 'name', query: '')).first.filePath);
  await pl.play();

  print('seek');
  await Future.delayed(Duration(seconds: 10), () async {
    await pl.setPosition(73.9);
  });

  Future.delayed(
    Duration(seconds: 20),
    () async {
      await pl.done();
    },
  );

  // await Future.delayed(Duration(seconds: 5), () async {
  //   await pl.dispose();
  // });

  // await

  // var t1 = DateTime.now();

  // var musicDir = Directory("C:\\Users\\ShadyTi\\Music\\");
  // var songs = musicDir.listSync().whereType<File>();

  // for (var song in songs) {
  //   // print('$count\t\t${song.path}');

  //   if (song.path.endsWith('.mp3')) {
  //     var status = await md.addSong(mp3FilePath: song.path);
  //   }
  // }

  // var t2 = DateTime.now();

  // var allSongs = await md.findSongs(field: 'name', query: '');

  // int count = 0;

  // for (var songEntry in allSongs.entries) {
  //   print('$count\t${songEntry.value.name}');

  //   if (songEntry.value.name.startsWith('a') || songEntry.value.name.startsWith('A')) {
  //     await md.deleteSong(uSong: songEntry.value);
  //   }
  //   count++;
  // }

  // print('----------');

  // allSongs = await md.findSongs(field: 'name', query: '');
  // count = 0;

  // for (var songEntry in allSongs.entries) {
  //   print('$count\t${songEntry.value.name}');
  //   count++;
  // }

  // print('----------');

  // await Future.delayed(const Duration(seconds: 10));

  // var t3 = DateTime.now();

  // await md.refreshDatabase();

  // var t4 = DateTime.now();

  // print('adding songs: ${t1.difference(t2)}');
  // print('updating database: ${t3.difference(t4)}');
}
