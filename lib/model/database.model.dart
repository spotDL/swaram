/// {@category backend}
///
/// This class is never used directly with exception of initialization, see
/// [Playlist] and [Song] for the actual data handling
///
/// ```dart
/// await SwaramDatabase().initialize();
/// ```

// Package imports:
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

// Project imports:
import 'package:swaram/model/playlist.model.dart';
import 'package:swaram/model/song.model.dart';
import 'package:swaram/util/path.util.dart';

/// Holds the major components that [Playlist] and [Song] use to manipulate and update the database
class SwaramDatabase {
  /// Internal sembast [Database]
  late final Database database;

  /// store for song data
  final songStore = stringMapStoreFactory.store('songStore');

  /// store for playlist data
  final playlistStore = stringMapStoreFactory.store('playlistStore');

  /// some initialization steps are asynchronous, they are done here
  Future<void> initialize() async {
    // (create if required and) open database
    database = await databaseFactoryIo.openDatabase(await getSwaramDatabasePath());

    // create album art cache folder
    await setupAppDocsFolder();

    // set playlist parentDB
    Playlist.parentDB = this;

    // set song parentDB
    Song.parentDB = this;

    // set liked songs playlist
    // find all playlists starting with the word 'likes'
    var likeQueryPlaylists = await Playlist.findByName(name: 'likes');

    Playlist? likedSongsPlaylist;

    for (var playlist in likeQueryPlaylists) {
      // set likes if exists
      if (await playlist.getName() == 'likes') likedSongsPlaylist = playlist;
    }

    // create likes playlist if not existing
    likedSongsPlaylist ??= await Playlist.create(name: 'likes');

    // set likedSongs
    Song.likedSongs = likedSongsPlaylist;
  }
}
