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
              // Expanded to constrain horizontal size for listviews
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // song name, scrollable
                    SizedBox(
                      height: 30,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          Text(
                            player.song.name,
                            style: const TextStyle(fontSize: 25),
                          )
                        ],
                      ),
                    ),

                    // artists, scrollable
                    SizedBox(
                      height: 30,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (var artist in player.song.artists)
                            TextButton(
                              onPressed: () {
                                // TODO: redirect to artist page
                              },
                              child: Text(artist),
                            )
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // like button
              IconButton(
                onPressed: () {
                  // TODO: like button, `SongRepr.toggleLike()`
                },
                icon: const Icon(Icons.favorite_border_rounded),
              )
            ],
          ),
        );
      },
    );
  }
}
