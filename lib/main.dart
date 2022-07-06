// Project imports:
import 'package:swaram/model/database.model.dart';
import 'package:swaram/model/playlist.model.dart';
import 'package:swaram/model/song.model.dart';
import 'package:swaram/util/database.util.dart';

void main(List<String> args) async {
  await SwaramDatabase().initialize();

  await addAllSongs(folderPath: r'C:\Users\ShadyTi\Music\');

  var pl = await Playlist.create(name: 'test');

  for (var song in await Song.findSongsByTitle(title: 'A')) {
    await pl.addSong(song: song);
  }
}
