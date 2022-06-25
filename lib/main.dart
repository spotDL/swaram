// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';

// Project imports:
import 'package:swaram/model/database.model.dart';
import 'package:swaram/model/player.model.dart';
import 'package:swaram/ui/components/player_pane.ui.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  var mdb = MusicDatabase();
  await mdb.initialize();

  var song = (await mdb.findSongsByName(query: 'The ')).first;

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
    return MaterialApp(
      darkTheme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.lime,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.dark,
      home: const Scaffold(
        body: Center(child: PlayerPane()),
      ),
    );
  }
}
