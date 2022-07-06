/// {@category backend}
///
/// The quantum of information exchange is the [Song] object. It also contains static methods
/// to search for songs in the database.
///
/// To add a song to the database:
/// ```dart
/// var song = await Song.addToDB(path: pathToYouMP3File);
/// ```
///
/// To find a song (search is case-insensitive):
/// ```dart
/// var songs = await Song.findSongsByTitle(title: 'HoUsE CaRpEnTeR');
/// var songs = await Song.findSongsByAlbum(album: 'FolKsAnGe');
/// var songs = await Song.findSongsByArtist(Artist: 'MyRKuR');
/// ```
///
/// To find/change weather a song is liked or not:
/// ```dart
/// if (song.isLiked) print('liked');
/// await song.toggleLike();
/// ```
///

// Dart imports:
import 'dart:convert';
import 'dart:io';

// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:id3/id3.dart';
import 'package:sembast/sembast.dart';

// Project imports:
import 'package:swaram/model/database.model.dart';
import 'package:swaram/model/playlist.model.dart';
import 'package:swaram/util/database.util.dart';
import 'package:swaram/util/path.util.dart';

/// wrapper around song details for easy access and UI updating
class Song extends ChangeNotifier {
  /// id of the playlist
  late final String id;

  /// `mp3` file path
  late final String filePath;

  /// title of the song
  late final String title;

  /// song artists
  late final List<String> songArtists;

  /// song genres
  late final List<String> genres;

  /// lyrics (can be an empty string)
  late final String lyrics;

  /// name of the album
  late final String album;

  /// album artists
  late final List<String> albumArtists;

  /// position of the song in album
  late final int albumPosition;

  /// path to album art cache file
  late final String cachedAlbumArtFilePath;

  /// parent database
  static late final SwaramDatabase parentDB;

  /// current like status
  bool _isLiked = false;

  /// liked songs playlist
  static late final Playlist likedSongs;

  // ======================================
  // ===== constructors / destructors =====
  // ======================================

  /// internal constructor for the song object
  Song._internal({
    required this.id,
    required this.filePath,
    required this.title,
    required this.songArtists,
    required this.genres,
    required this.lyrics,
    required this.album,
    required this.albumArtists,
    required this.albumPosition,
    required this.cachedAlbumArtFilePath,
  });

  /// create a song object
  static Future<Song> fromID({required String id}) async {
    // pull up song record
    var record = (await parentDB.songStore.record(id).get(parentDB.database))!;

    // return the song
    var song = Song._internal(
      id: id,
      filePath: record['filePath'] as String,
      title: record['title'] as String,
      songArtists: [for (var artist in (record['songArtists'] as List)) artist as String],
      genres: [for (var genre in (record['genres'] as List)) genre as String],
      lyrics: record['lyrics'] as String,
      album: record['album'] as String,
      albumArtists: [for (var artist in (record['albumArtists'] as List)) artist as String],
      albumPosition: record['albumPosition'] as int,
      cachedAlbumArtFilePath: record['cachedAlbumArtFilePath'] as String,
    );

    if ((await likedSongs.getSongs()).contains(song)) await song.toggleLike();

    return song;
  }

  /// add a song to the database (ignored if song already exists in database)
  static Future<Song> addToDB({required String path}) async {
    // read the ID3 tags
    var fileBytes = await File(path).readAsBytes();
    var data = MP3Instance(fileBytes)..parseTagsSync();
    var id3Data = data.metaTags;

    // just some extractions for utility purpose
    var id3SongTitle = id3Data['Title'];
    var id3SongAlbum = id3Data['Album'];
    var id3SongArtists = (id3Data['Artist'] as String).split('/');
    var id3AlbumArtists = (id3Data['Accompaniment'] as String).split('/');

    // if an identical song exists, exit
    var matchSongs = await Song.findSongsByTitle(title: id3SongTitle);

    for (var song in matchSongs) {
      if (song.title == id3SongTitle &&
          song.album == id3SongAlbum &&
          listEquals(song.songArtists, id3SongArtists)) return song;
    }

    // search for other songs from the same album, if exist, set album art cache path
    var matchAlbumSongs = await Song.findSongsByAlbum(album: id3SongAlbum);

    String? cachePath;

    for (var song in matchAlbumSongs) {
      // set cache path (if exists)
      if (listEquals(song.albumArtists, id3AlbumArtists)) cachePath = song.cachedAlbumArtFilePath;
    }

    // cache album art if cached album art is not found
    cachePath ??= await getAlbumArtJpg(albumArtCode: '$id3SongAlbum@${id3AlbumArtists.join(', ')}');
    await File(cachePath).writeAsBytes(base64.decode(id3Data['APIC']['base64']));

    // add song to database
    var songID = await parentDB.songStore.add(parentDB.database, {});

    var song = Song._internal(
      id: songID,
      filePath: path,
      title: id3SongTitle,
      songArtists: id3SongArtists,
      genres: id3Data.containsKey('Genre') ? id3Data['Genre'].toString().split('/') : ['Unknown'],
      lyrics: id3Data.containsKey('USLT') ? id3Data['USLT']['lyrics'] : 'No lyrics available',
      album: id3SongAlbum,
      albumArtists: id3AlbumArtists,
      albumPosition: int.parse(id3Data['TPOS']),
      cachedAlbumArtFilePath: cachePath,
    );

    await parentDB.songStore.record(song.id).update(parentDB.database, song._toMap());

    return song;
  }

  // ==================
  // ===== search =====
  // ==================

  /// return all songs whose title starts with the given query
  static Future<List<Song>> findSongsByTitle({required String title}) async {
    // pull up song records
    var songRecords = await parentDB.songStore.find(
      parentDB.database,
      finder: Finder(filter: Filter.matches('searchTitle', await prepRegExp(query: title))),
    );

    // convert to song object, return list
    return [for (var record in songRecords) await Song.fromID(id: record.key)];
  }

  /// return all songs whose album starts with the given query
  static Future<List<Song>> findSongsByAlbum({required String album}) async {
    // pull up song records
    var songRecords = await parentDB.songStore.find(
      parentDB.database,
      finder: Finder(filter: Filter.matches('searchAlbum', await prepRegExp(query: album))),
    );

    // convert to song object, return list
    return [for (var record in songRecords) await Song.fromID(id: record.key)];
  }

  /// return all songs that have at least one artist whose name starts with the given query
  static Future<List<Song>> findSongsByArtist({required String artist}) async {
    // pull up song records
    var songRecords = await parentDB.songStore.find(
      parentDB.database,
      finder: Finder(
        filter: Filter.matches('searchArtists', await prepRegExp(query: artist), anyInList: true),
      ),
      // convert to song object, return list
    );

    return [for (var record in songRecords) await Song.fromID(id: record.key)];
  }

  // =================
  // ===== likes =====
  // =================

  /// weather the song is liked or not
  bool get isLiked => _isLiked;

  /// toggle the like status of the song
  Future<void> toggleLike() async {
    _isLiked = !_isLiked;

    if (_isLiked) {
      await likedSongs.addSong(song: this);
    } else {
      await likedSongs.removeSong(song: this);
    }

    notifyListeners();
  }

  // =================================
  // ===== utility / life-savers =====
  // =================================

  /// convert song representation to a [Map] to be stored in the database
  Map<String, dynamic> _toMap() {
    return {
      'filePath': filePath,
      'title': title,
      'searchTitle': title.toLowerCase(),
      'songArtists': songArtists,
      'searchArtists': [for (var artist in songArtists) artist.toLowerCase()],
      'genres': genres,
      'lyrics': lyrics,
      'album': album,
      'searchAlbum': album.toLowerCase(),
      'albumArtists': albumArtists,
      'albumPosition': albumPosition,
      'cachedAlbumArtFilePath': cachedAlbumArtFilePath,
    };
  }
}
