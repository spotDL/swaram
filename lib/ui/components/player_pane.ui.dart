// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';

// Project imports:
import 'package:swaram/model/player.model.dart';
import 'package:swaram/ui/components/song_title_display.ui.dart';

/// UI element for basic music player controls
///
class PlayerPane extends StatelessWidget {
  /// build a `PlayerPane`
  ///
  const PlayerPane({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<Player>(
      builder: (context, player, child) {
        return Column(
          children: [
            // song title & like button
            const SongTitleDisplay(),

            // playback controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () async {
                    // TODO: implement shuffle
                  },
                  icon: const Icon(Icons.shuffle_rounded),
                ),
                IconButton(
                  onPressed: () async {
                    await player.setPosition(playbackInMilliseconds: 0);
                  },
                  icon: const Icon(Icons.skip_previous_rounded),
                ),
                IconButton(
                  onPressed: () async {
                    player.paused || player.cProgress == 0
                        ? await player.play()
                        : await player.pause();
                  },
                  icon: Icon(
                    player.paused || player.cProgress == 0 ? Icons.play_arrow_rounded : Icons.pause,
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await player.setPosition(playbackInMilliseconds: player.cDuration);
                  },
                  icon: const Icon(Icons.skip_next_rounded),
                ),
                IconButton(
                  onPressed: () async {
                    // TODO: implement loop
                  },
                  icon: const Icon(Icons.repeat_rounded),
                )
              ],
            ),

            // playback progress slider
            Slider(
              min: 0,
              value: player.cProgress.toDouble(),
              max: player.cDuration.toDouble() + 1000,
              onChanged: (newPosition) {
                player.setPosition(playbackInMilliseconds: newPosition.toInt());
              },
            ),

            // playback duration display
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 0, 25, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(player.cProgressAsText),
                  Text(player.cDurationAsText),
                ],
              ),
            )
          ],
        );
      },
    );
  }
}
