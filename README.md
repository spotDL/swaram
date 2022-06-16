# Swaram (స్వరం)

A music manager to go along with spotDL. Still a work in progress.

# Developer QuickStart

The core of the music player are the `MusicDatabase` and `SongRepr` classes. Together they serve 
three primary functions:

- Storing song details

- Looking up songs

- Caching AlbumArt (so as not to have data duplication and file size ballooning)

All methods of the `MusicDatabase` class are asynchronous, please make sure to `await` them or you
will experience app-breaking bugs.

## `MusicDatabase` usage

```dart
// create an database, initialize it
var mDatabase = MusicDatabase();
await mDatabase.initialize();

// add a song
await mDatabase.addSong('./test/testSong.mp3');             // lets say that the song is Iron by Woodkid

// search for a song (returns a list of `SongRepr`)
var song = await mDatabase.findSongs('name', 'iro').first   // all songs starting with the letters 'iro'
await mDatabase.findSongs('album', 'Iro')                   // all songs belonging to albums starting with 'iro'
await mDatabase.findSongs('artists', 'woodkid')             // all songs by or featuring 'woodkid'

// delete a song
await mDatabase.deleteSong(song)                            // deletes Iron by woodkid
```

## The `SongRepr` Object

The quantum of information exchange is the `SongRepr` object, it contains eight properties:

- name

- filePath

- album

- artists (note: 'artists', not 'artist')

- genre

- trackPos (position of the track in the album)

- lyrics

- albumArtFileNumber

The albumArt for every song is cached on disk, and the album art is identified by a unique number
that is less than 1000000 - the `albumArtFileNumber`

```dart
// getting path to the albumArt JPG
var albumArtJpgPath = await getAlbumArtPath(song.albumArtFileNumber);
```

## Other notes

- You can look at more detailed API docs by generating the documentation using `dartdoc`. Further
developer notes in the source code.

- File naming conventions:

    - `.model.dart`: Files that compose the data model for the app.

    - `.ui.dart`: UI components. The main navigation routing pages are to be stored under
    `./lib/ui`, the custom components used for those pages are under `./lib/ui/components`.

    - `.util.dart`: Generic helper/ease-of-life functions.