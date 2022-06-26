/// {@category backend}
///
/// The quantum of information exchange is the [Song] object, it contains nine properties:
///
/// - id (song id in the database)
///
/// - filePath
///
/// - title
///
/// - songArtists (note: 'artists', not 'artist')
///
/// - genres
///
/// - lyrics
///
/// - album
///
/// - albumArtists (note: 'artists', not 'artist')
///
/// - albumPos (position of the track in the album)
///
/// - cachedAlbumArtFilePath (path to the cached album art)
///
library song.model;

/// an easy way to access song details
///
class Song {
  /// `mp3` file path
  ///
  late final String filePath;

  /// title of the song
  ///
  late final String title;

  /// song artists
  ///
  late final List<String> songArtists;

  /// song genres
  ///
  late final List<String> genres;

  /// lyrics (can be an empty string)
  ///
  late final String lyrics;

  /// name of the album
  ///
  late final String album;

  /// album artists
  ///
  late final List<String> albumArtists;

  /// position of the song in album
  ///
  late final int albumPosition;

  /// album art cache code
  ///
  late final String cachedAlbumArtFilePath;

  /// song's primary key in the database
  ///
  late final String id;

  // TODO: Liked songs, how?

  /// construct a song representation with the given details
  ///
  /// ### Note:
  /// - Make sure to set the [id] attribute after object creation
  ///
  Song({
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

  /// construct a song representation from the [Map] returned form [toMap]
  ///
  Song.fromMap(Map<String, dynamic> map) {
    filePath = map['filePath'];
    title = map['title'];
    songArtists = [for (var artist in map['songArtists']) artist as String];
    genres = [for (var genre in map['genres']) genre as String];
    lyrics = map['lyrics'];
    album = map['album'];
    albumArtists = [for (var artist in map['albumArtists']) artist as String];
    albumPosition = map['albumPosition'];
    cachedAlbumArtFilePath = map['cachedAlbumArtFilePath'];
  }

  /// convert song representation to a [Map] to be stored in the database
  ///
  Map<String, dynamic> toMap() {
    return {
      'filePath': filePath,
      'title': title,
      'songArtists': songArtists,
      'genres': genres,
      'lyrics': lyrics,
      'album': album,
      'albumArtists': albumArtists,
      'albumPosition': albumPosition,
      'cachedAlbumArtFilePath': cachedAlbumArtFilePath
    };
  }
}
