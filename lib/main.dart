// Project imports:
import 'package:swaram/model/database.model.dart';
import 'package:swaram/util/database.util.dart';

void main(List<String> args) async {
  var db = MusicDatabase();
  await db.initialize();

  await addAllSongs(database: db, folderPath: r'C:\Users\ShadyTi\Music\');

  print(await db.playlistWithNameExists(name: 'old Likes2'));

  var playlist = await db.createPlaylist(name: 'old Likes');
  var pl2 = await db.createPlaylist(name: 'old Likes2');

  for (var song in await db.searchByTitle(query: 'b')) {
    await playlist.addSong(song: song);
  }

  for (var song in await db.searchByTitle(query: 'a')) {
    await pl2.addSong(song: song);
  }

  var plm = await db.findPlaylists(query: 'oLd');

  for (var pl in plm) {
    print(pl.name);
    for (var song in pl.songs) {
      print('\t${song.title}');
    }
  }
}
