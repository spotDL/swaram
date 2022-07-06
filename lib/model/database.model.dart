// Package imports:
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

// Project imports:
import 'package:swaram/model/playlist.model.dart';
import 'package:swaram/model/song.model.dart';
import 'package:swaram/util/path.util.dart';

// /// create a [StoreRef] with a [String] as a key and a [Map]`<String, List<String>>` as
// /// it's value
// StoreRef<String, Map<String, List<String>>> stringMapStoreFactory(name) =>
//     StoreRef<String, Map<String, List<String>>>(name);

/// The actual music database, not the wrapper, [SwaramDatabase]
class TrueDatabase {
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

    // set playlist parentDB
    Playlist.parentDB = this;

    // set song parentDB
    Song.parentDB = this;
  }
}
