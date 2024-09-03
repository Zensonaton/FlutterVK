import "package:flutter/material.dart";
import "package:gap/gap.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:skeletonizer/skeletonizer.dart";

import "../../../../consts.dart";
import "../../../../main.dart";
import "../../../../provider/l18n.dart";
import "../../../../provider/player_events.dart";
import "../../../../provider/playlists.dart";
import "../../../../provider/user.dart";
import "../../../../services/logger.dart";
import "../../../../utils.dart";
import "../../music.dart";
import "../playlist.dart";

/// Виджет, показывающий раздел "Плейлисты для Вас".
class RecommendedPlaylistsBlock extends HookConsumerWidget {
  static final AppLogger logger = getLogger("RecommendedPlaylistsBlock");

  const RecommendedPlaylistsBlock({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(recommendedPlaylistsProvider);
    final l18n = ref.watch(l18nProvider);
    ref.watch(playerStateProvider);
    ref.watch(playerLoadedStateProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "Плейлисты для Вас".
        Text(
          l18n.music_recommendedPlaylistsChip,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Gap(14),

        // Содержимое.
        ScrollConfiguration(
          behavior: AlwaysScrollableScrollBehavior(),
          child: SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              physics: playlists == null
                  ? const NeverScrollableScrollPhysics()
                  : null,
              itemCount: playlists?.length,
              itemBuilder: (BuildContext context, int index) {
                // Skeleton loader.
                if (playlists == null) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      right: 8,
                    ),
                    child: Skeletonizer(
                      child: AudioPlaylistWidget(
                        name:
                            fakePlaylistNames[index % fakePlaylistNames.length],
                        description: "Playlist description here",
                        useTextOnImageLayout: true,
                      ),
                    ),
                  );
                }

                // Настоящие данные.
                final ExtendedPlaylist playlist = playlists[index];

                // Очень, блять, смешно, ВКонтакте.
                //
                // Спасибо вам за то что вам, сука, приспичило вставлять названия плейлистов
                // в само их изображение, из-за чего название в моём интерфейсе дублировалось дважды. Пфф...

                return Padding(
                  padding: const EdgeInsets.only(
                    right: 8,
                  ),
                  child: AudioPlaylistWidget(
                    backgroundUrl: playlist.photo?.photo600,
                    cacheKey: "${playlist.mediaKey}600",
                    name: playlist.title!,
                    description: playlist.subtitle,
                    selected:
                        player.currentPlaylist?.mediaKey == playlist.mediaKey,
                    currentlyPlaying: player.playing && player.loaded,
                    onOpen: () => context.push(
                      "/music/playlist/${playlist.ownerID}/${playlist.id}",
                    ),
                    onPlayToggle: (bool playing) => onPlaylistPlayToggle(
                      ref,
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
