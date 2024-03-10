import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:just_audio/just_audio.dart";
import "package:provider/provider.dart";
import "package:skeletonizer/skeletonizer.dart";

import "../../../../consts.dart";
import "../../../../main.dart";
import "../../../../provider/user.dart";
import "../../../../services/logger.dart";
import "../../../../utils.dart";
import "../../../../widgets/page_route_builders.dart";
import "../../music.dart";
import "../playlist.dart";

/// Виджет с разделом "Ваши плейлисты"
class MyPlaylistsBlock extends StatefulWidget {
  static AppLogger logger = getLogger("MyPlaylistsBlock");

  const MyPlaylistsBlock({
    super.key,
  });

  @override
  State<MyPlaylistsBlock> createState() => _MyPlaylistsBlockState();
}

class _MyPlaylistsBlockState extends State<MyPlaylistsBlock> {
  /// Подписки на изменения состояния воспроизведения трека.
  late final List<StreamSubscription> subscriptions;

  @override
  void initState() {
    super.initState();

    subscriptions = [
      // Изменения состояния воспроизведения.
      player.playerStateStream.listen(
        (PlayerState state) => setState(() {}),
      ),

      // Изменения состояния остановки/запуска плеера.
      player.loadedStateStream.listen(
        (bool loaded) => setState(() {}),
      ),
    ];
  }

  @override
  void dispose() {
    super.dispose();

    for (StreamSubscription subscription in subscriptions) {
      subscription.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final UserProvider user = Provider.of<UserProvider>(context);

    final int playlistsCount = user.playlistsCount ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "Ваши плейлисты".
        Padding(
          padding: const EdgeInsets.only(
            bottom: 14,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  right: 8,
                ),
                child: Text(
                  AppLocalizations.of(context)!.music_myPlaylistsChip,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (playlistsCount > 0)
                Text(
                  playlistsCount.toString(),
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withOpacity(0.75),
                  ),
                ),
            ],
          ),
        ),

        // Содержимое.
        ScrollConfiguration(
          behavior: AlwaysScrollableScrollBehavior(),
          child: SizedBox(
            height: 310,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              physics: user.regularPlaylists.isEmpty
                  ? const NeverScrollableScrollPhysics()
                  : null,
              itemCount: user.regularPlaylists.isNotEmpty
                  ? user.regularPlaylists.length
                  : null,
              itemBuilder: (BuildContext context, int index) {
                // Skeleton loader.
                if (user.regularPlaylists.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      right: 8,
                    ),
                    child: Skeletonizer(
                      child: AudioPlaylistWidget(
                        name:
                            fakePlaylistNames[index % fakePlaylistNames.length],
                      ),
                    ),
                  );
                }

                // Настоящие данные.
                final ExtendedPlaylist playlist = user.regularPlaylists[index];

                return Padding(
                  padding: const EdgeInsets.only(
                    right: 8,
                  ),
                  child: AudioPlaylistWidget(
                    backgroundUrl: playlist.photo?.photo270,
                    cacheKey: "${playlist.mediaKey}270",
                    name: playlist.title!,
                    description: playlist.description,
                    selected: player.currentPlaylist == playlist,
                    currentlyPlaying: player.playing && player.loaded,
                    onOpen: () => Navigator.push(
                      context,
                      Material3PageRoute(
                        builder: (context) => PlaylistInfoRoute(
                          playlist: playlist,
                        ),
                      ),
                    ),
                    onPlayToggle: (bool playing) => onPlaylistPlayToggle(
                      context,
                      playlist,
                      playing,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
