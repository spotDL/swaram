/// {@category backend}
///
/// The quantum of information exchange is the [SongRepr] object, it contains nine properties:
///
/// - id (song id in the database)
///
/// - name
///
/// - filePath
///
/// - album
///
/// - artists (note: 'artists', not 'artist')
///
/// - genre
///
/// - trackPos (position of the track in the album)
///
/// - lyrics
///
/// - albumArtFileNumber
///
/// The albumArt for every song is cached on disk, and the album art is identified by a unique number
/// that is less than 1,000,000 - the `albumArtFileNumber`
///
/// Consider looking at [getAlbumArtJpg] to get the path to the cached album art
///
/// ```dart
/// // getting path to the albumArt JPG
/// var albumArtJpgPath = await getAlbumArtJpg(song.albumArtFileNumber);
/// ```
///
library song.model;

// Project imports:
import 'package:swaram/util/path.util.dart';

///{@category backend}
///
/// a representation of a song stored in the database
///
class SongRepr {
  /// path to the file on disk
  ///
  late final String filePath;

  /// song's name
  ///
  late final String name;

  /// album name
  ///
  late final String album;

  /// the contributing artists (for this song)
  ///
  late final List<String> artists;

  /// genre of the song
  ///
  late final String genre;

  /// position of the track within the album
  ///
  late final int trackPos;

  /// lyrics of the song if available
  ///
  late final String lyrics;

  /// number of the albumArtFile
  ///
  late final int albumArtFileNumber;

  late final String _dbId;

  bool _idIsSet = false;

  /// construct a song representation with the given details
  ///
  SongRepr({
    required this.filePath,
    required this.name,
    required this.album,
    required this.artists,
    required this.trackPos,
    required this.albumArtFileNumber,
    required this.genre,
    required this.lyrics,
  });

  /// set the songs id
  void setId(String id) {
    if (!_idIsSet) {
      _dbId = id;
      _idIsSet = true;
    } else {
      throw Exception('databaseId can only be set once');
    }
  }

  /// id of the song in the database
  String get id => _dbId;

  /// construct a song representation from JSON returned form [toMap]
  ///
  SongRepr.fromMap(Map<String, dynamic> map) {
    name = map['name'];
    album = map['album'];
    genre = map['genre'];
    lyrics = map['lyrics'];
    filePath = map['filePath'];
    trackPos = map['trackPos'];
    albumArtFileNumber = map['albumArtFileNumber'];

    // we need this oddball notation to deal with ImmutableList<dynamic> that is passed occasionally
    artists = [for (var artist in map['artists']) artist as String];
  }

  /// convert song representation to a Map to be stored in the database
  ///
  Map toMap() {
    return {
      'name': name,
      'album': album,
      'genre': genre,
      'lyrics': lyrics,
      'artists': artists,
      'filePath': filePath,
      'trackPos': trackPos,
      'albumArtFileNumber': albumArtFileNumber,
    };
  }
}
