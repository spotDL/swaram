// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';

// Project imports:
import 'package:swaram/model/player.model.dart';

class SongTitleDisplay extends StatelessWidget {
  const SongTitleDisplay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Song title and artists display, with linking to artists page
    return Consumer<Player>(
      builder: (context, player, child) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(25, 0, 25, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.song.name,
                    style: const TextStyle(fontSize: 25),
                  ),
                  Text(player.song.artists.join(', ')),
                ],
              ),
              IconButton(
                  onPressed: () {
                    // TODO: like button, `SongRepr.toggleLike()`
                  },
                  icon: const Icon(Icons.favorite_border_rounded))
            ],
          ),
        );
      },
    );
  }
}
