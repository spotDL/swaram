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

// add a song (Iron by Woodkid)
await mDatabase.addSong('./test/testSong.mp3');

// search for a song (returns a list of `SongRepr`)

// 1. all songs starting with the letters 'iro'
var song = (await mDatabase.findSongs(,
    field: 'name',
    query: 'iro',
    searchingByArtist: true,
    )).first;

// 2. all songs belonging to albums starting with 'iro'
await mDatabase.findSongs(field:'album', query: 'Iro');      

// 3. all songs by or featuring 'woodkid'
await mDatabase.findSongs(field:'artists', query: 'woodkid');

// delete a song (deletes Iron by woodkid, albumArt will not be removed)
await mDatabase.deleteSong(song);

// update cache and fix any discrepancies introduced from deleting songs
await mDatabase.refreshDatabase();
```

## The `SongRepr` Object

The quantum of information exchange is the `SongRepr` object, it contains nine properties:

- id (song id in the database)

- name

- filePath

- album

- artists (note: 'artists', not 'artist')

- genre

- trackPos (position of the track in the album)

- lyrics

- albumArtFileNumber

The albumArt for every song is cached on disk, and the album art is identified by a unique number
that is less than 1,000,000 - the `albumArtFileNumber`

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
    `./lib/ui`, the custom components used for those pages are under `./lib/ui/components`. These
    files will not be documented.

    - `.util.dart`: Generic helper/ease-of-life functions.