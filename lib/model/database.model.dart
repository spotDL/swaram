/// {@category backend}
///
/// [MusicDatabase] is a wrapper over `sembast`'s [Database] class that integrates with [Song]
/// thereby making it easier and simpler to use
///
/// ```dart
/// // create an database, initialize it
/// var mDatabase = MusicDatabase();
/// await mDatabase.initialize();
///
/// // add a song (Iron by Woodkid)
/// await mDatabase.addSong(filePath: r'/songs/someSong.mp3');
///
/// // search for a song (returns a list of `SongRepr`)
/// // all searches are case-insensitive
///
/// // 1. all songs starting with the letters 'iro'
/// var song = (await mDatabase.findSongsByTitle(query: 'iRo')).first;
///
/// // 2. all songs belonging to albums starting with 'iro'
/// await mDatabase.findSongsByAlbum(query: 'IRo');
///
/// // 3. all songs by or featuring 'woodkid'
/// await mDatabase.findSongsByArtist(query: 'WoOdK');
///
/// // delete a song (deletes Iron by woodkid, albumArt will not be removed)
/// await mDatabase.removeSong(song: song);
///
/// // update cache and fix any discrepancies introduced from deleting songs
/// await mDatabase.refreshDatabase();
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
import 'package:sembast/sembast_io.dart';

// Project imports:
import 'package:swaram/model/playlist.model.dart';
import 'package:swaram/model/song.model.dart';
import 'package:swaram/util/database.util.dart';
import 'package:swaram/util/path.util.dart';

class MusicDatabase {
  /// sembast database, contains various "stores"
  ///
  late final Database _database;

  /// store for song details, all other stores cross-reference this
  ///
  final _songStore = StoreRef<String, Map<String, dynamic>>('songs');

  /// store containing names of all other playlist
  ///
  final _masterPlaylistStore = StoreRef<String, Map<String, dynamic>>('playlists');

  late final Playlist likes;

  /// completely initialize this object
  ///
  /// ### Note:
  /// - the setup contains some async operations, those cannot be done
  ///   in a normal Constructor, hence they're being done here
  Future<void> initialize() async {
    await setupAppDocsFolder();

    // setup database
    _database = await databaseFactoryIo.openDatabase(
      await getSwaramDatabasePath(),
    );

    // likes
    var likePlaylists = await findPlaylists(query: 'likes');

    for (var playlist in likePlaylists) {
      if (playlist.name == 'likes') {
        likes = playlist;
        return;
      }
    }

    likes = await createPlaylist(name: 'likes');
  }

  // song related

  /// add the song at the given path to the database
  ///
  Future<bool> addSong({required filePath}) async {
    // read the ID3 tags
    var fileBytes = await File(filePath).readAsBytes();
    var data = MP3Instance(fileBytes)..parseTagsSync();
    var id3Data = data.metaTags;

    // if an identical song exists, exit
    var matchSongs = await findSongsByTitle(query: id3Data['Title']);
    var songArtists = (id3Data['Artist'] as String).split('/');

    for (var song in matchSongs) {
      if (song.album == id3Data['Album'] || listEquals(song.songArtists, songArtists)) return false;
    }

    // if same album does not exist, cache the album art
    var matchAlbumSongs = await findSongsByAlbum(query: id3Data['Album']);
    var albumArtists = (id3Data['Accompaniment'] as String).split('/');

    String cachePath = '';

    for (var song in matchAlbumSongs) {
      if (listEquals(song.albumArtists, albumArtists)) cachePath = song.cachedAlbumArtFilePath;
    }

    if (cachePath == '') {
      do {
        var cacheCode = await _songStore.add(_database, {'TEMP': 'TEMP'});
        cachePath = await getAlbumArtJpg(albumArtCode: cacheCode);
        await _songStore.record(cacheCode).delete(_database);
      } while (await File(cachePath).exists());

      // cache album art
      await File(cachePath).writeAsBytes(base64.decode(id3Data['APIC']['base64']));
    }

    // add song to database
    var song = Song(
      database: this,
      filePath: filePath,
      title: id3Data['Title'],
      songArtists: songArtists,
      genres: id3Data.containsKey('Genre') ? id3Data['Genre'].toString().split('/') : ['Unknown'],
      lyrics: id3Data.containsKey('USLT') ? id3Data['USLT']['lyrics'] : 'No lyrics available',
      album: id3Data['Album'],
      albumArtists: albumArtists,
      albumPosition: int.parse(id3Data['TPOS']),
      cachedAlbumArtFilePath: cachePath,
      isLiked: false,
    );

    // add extra search fields
    var songJSON = song.toMap();

    songJSON['searchTitle'] = song.title.toLowerCase();
    songJSON['searchAlbum'] = song.album.toLowerCase();
    songJSON['searchArtists'] = [for (var artist in song.songArtists) artist.toLowerCase()];

    await _songStore.add(_database, songJSON);

    return true;
  }

  /// delete a song's details from the database
  ///
  /// ### Note
  /// - does not modify album art cache as other songs might depend on the
  ///   album art.
  ///
  /// - use [refreshDatabase] to update album art cache and fix any
  ///   discrepancies in the database
  ///
  Future<void> removeSong({required Song song}) async {
    await _songStore.record(song.id).delete(_database);
  }

  // song search related

  /// return all songs whose title starts with the given query
  ///
  /// ### Note:
  /// - returned songs sorted in alphabetical order
  ///
  Future<List<Song>> findSongsByTitle({required String query}) async {
    var songRecords = await _songStore.find(
      _database,
      finder: Finder(filter: Filter.matches('searchTitle', await prepRegExp(query: query))),
    );

    return convertRecordToRepr(database: this, records: songRecords);
  }

  /// return all songs whose album starts with the given query
  ///
  /// ### Note:
  /// - returned songs sorted in alphabetical order
  ///
  Future<List<Song>> findSongsByAlbum({required String query}) async {
    var songRecords = await _songStore.find(
      _database,
      finder: Finder(filter: Filter.matches('searchAlbum', await prepRegExp(query: query))),
    );

    return convertRecordToRepr(database: this, records: songRecords);
  }

  /// return all songs that have at least one artist whose name starts with the given query
  ///
  /// ### Note:
  /// - returned songs sorted in alphabetical order
  ///
  Future<List<Song>> findSongsByArtist({required String query}) async {
    var songRecords = await _songStore.find(
      _database,
      finder: Finder(
        filter: Filter.matches('searchArtists', await prepRegExp(query: query), anyInList: true),
      ),
    );

    var songList = await convertRecordToRepr(database: this, records: songRecords);

    for (var song in songList) {
      if (likes.songs.contains(song)) await song.setLiked();
    }

    return songList;
  }

  // playlist related

  /// make a new playlist into which to add songs into
  ///
  Future<Playlist> createPlaylist({required String name}) async {
    var playlistId = await _masterPlaylistStore
        .add(_database, {'searchName': name.toLowerCase(), 'name': name, 'songs': []});

    return Playlist(name: name, id: playlistId, dbReference: this);
  }

  /// delete a playlist from the database
  ///
  Future<void> deletePlaylist({required Playlist playlist}) async {
    await _masterPlaylistStore.record(playlist.id).delete(_database);
  }

  /// update the songs in a playlist
  ///
  Future<void> updatePlaylist({required Playlist playlist}) async {
    await _masterPlaylistStore.record(playlist.id).update(_database, {
      'searchName': playlist.name.toLowerCase(),
      'name': playlist.name,
      'songs': [for (var song in playlist.songs) song.id]
    });
  }

  /// find all playlists whose name starts with the given query
  ///
  Future<List<Playlist>> findPlaylists({required String query}) async {
    var outPlaylists = <Playlist>[];

    // find all songs starting with the query
    var playlistRecords = await _masterPlaylistStore.find(
      _database,
      finder: Finder(filter: Filter.matches('searchName', await prepRegExp(query: query))),
    );

    // get the songId's and convert them to songs
    // create the playlist object
    for (var playlist in playlistRecords) {
      var playlistId = playlist.key;
      var playlistName = playlist.value['name'];

      var songs = <Song>[];

      for (var songId in playlist.value['songs']) {
        var songRecords = await _songStore.find(
          _database,
          finder: Finder(filter: Filter.custom((record) => record.key == songId)),
        );

        songs.add(Song.fromMap(database: this, map: songRecords.first.value)..id = songId);
      }

      outPlaylists.add(
        Playlist(name: playlistName, id: playlistId, dbReference: this)..songs.addAll(songs),
      );
    }

    return outPlaylists;
  }

  /// check if a playlist with the exact same name exists
  ///
  Future<bool> playlistWithNameExists({required String name}) async {
    var playlistRecords = await _masterPlaylistStore.find(
      _database,
      finder: Finder(filter: Filter.custom((record) => record.value['name'] == name.trim())),
    );

    return playlistRecords.isNotEmpty;
  }

  // misc

  /// remove remnants of deleted data (if any) from the database and albumArtCache
  ///
  /// ### Note:
  /// - avoid using often, it is a costly operation
  ///
  Future<void> refreshDatabase() async {
    // empty album art cache
    Directory(await getAlbumArtCachePath()).listSync().forEach((cacheElement) async {
      if (cacheElement is File) await cacheElement.delete();
    });

    // get all songs
    var allSongs = await findSongsByTitle(query: '');

    // TODO: playlist entries

    // take note of still existing files, delete all entries from the database
    var filePaths = <String>[];

    for (var song in allSongs) {
      if (await File(song.filePath).exists()) filePaths.add(song.filePath);

      await _songStore.record(song.id).delete(_database);
    }

    // re-update database
    for (var path in filePaths) {
      await addSong(filePath: path);
    }
  }
}
