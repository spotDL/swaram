// Dart imports:
import 'dart:convert';
import 'dart:typed_data';

// Flutter imports:
import 'package:flutter/material.dart';

class Song {
  late final String name;
  late final String album;
  late final List<String> artists;
  late final String genre;
  late final int trackPos;
  late final String lyrics;
  late final Uint8List albumArt;

  Song({
    required this.name,
    required this.album,
    required this.artists,
    this.genre = 'unknown',
    required this.trackPos,
    required this.albumArt,
    this.lyrics = '',
  });

  Song.fromMap(Map map) {
    name = map['name'];
    // we need this oddball notation to deal with ImmutableList<dynamic> that is passed occasionally
    artists = [for (var artist in map['artists']) artist as String];
    album = map['album'];
    trackPos = map['trackPos'];
    genre = map['genre'];
    lyrics = map['lyrics'];
    albumArt = base64.decode(map['albumArt']);
  }

  Map toMap() {
    return {
      'name': name,
      'album': album,
      'artists': artists,
      'genre': genre,
      'trackPos': trackPos,
      'albumArt': base64.encode(albumArt),
      'lyrics': lyrics,
    };
  }
}
