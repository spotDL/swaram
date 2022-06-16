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
