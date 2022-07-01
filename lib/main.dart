// Project imports:
import 'package:swaram/model/database.model.dart';
import 'package:swaram/util/database.util.dart';

void main(List<String> args) async {
  var db = MusicDatabase();
  await db.initialize();

  await addAllSongs(database: db, folderPath: r'C:\Users\ShadyTi\Music\');

  var song = (await db.findSongsByArtist(query: 'wOoDkId')).first;

  print(song.isLiked);

  print((db.likes.songs));

  await song.toggleLiked();

  print(song.isLiked);

  print((db.likes.songs));
}
