/// {@category backend}
///
/// Playlists are just an ordered collection of songs, the [Playlist] class
/// reflects the same. It contains the following attributes
///
/// - id (playlist id in database)
///
/// - name
///
/// - songs (order is preserved, don't manually edit this)
///

// Project imports:
import 'package:swaram/model/database.model.dart';
import 'package:swaram/model/song.model.dart';

/// an easy way to access playlist details
///
class Playlist {
  /// name of the playlist
  ///
  late final String name;

  /// id/primary-key of the Playlist in the database
  ///
  late final String id;

  /// songs that the playlist contains (don't manually edit this unless to change song order)
  ///
  final songs = <Song>[];

  /// a reference to the parent database used to update the database
  ///
  late final MusicDatabase _dbReference;

  /// create a playlist
  ///
  Playlist({
    required this.name,
    required this.id,
    required MusicDatabase dbReference,
  }) : _dbReference = dbReference;

  /// add a song to the playlist
  ///
  Future<void> addSong({required Song song}) async {
    songs.add(song);
    await _dbReference.updatePlaylist(playlist: this);
  }

  /// remove a song from the playlist
  ///
  Future<void> removeSong({required Song song}) async {
    songs.remove(song);
    await _dbReference.updatePlaylist(playlist: this);
  }
}
