// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';

// Project imports:
import 'package:swaram/model/database.model.dart';
import 'package:swaram/model/player.model.dart';
import 'package:swaram/ui/components/player.ui.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  var mdb = MusicDatabase();
  await mdb.initialize();

  var song = (await mdb.findSongsByName(query: 'H')).first;

  var player = Player();
  await player.load(song: song);

  runApp(
    ChangeNotifierProvider(
      create: (_) => player,
      child: const Home(),
    ),
  );
}

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(child: PlayerPane()),
      ),
    );
  }
}
