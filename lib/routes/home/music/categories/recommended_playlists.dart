import "package:flutter/material.dart";
import "package:gap/gap.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:skeletonizer/skeletonizer.dart";

import "../../../../consts.dart";
import "../../../../provider/l18n.dart";
import "../../../../provider/player.dart";
import "../../../../provider/playlists.dart";
import "../../../../provider/preferences.dart";
import "../../../../provider/user.dart";
import "../../../../services/logger.dart";
import "../../../../utils.dart";
import "../../../../widgets/music_category.dart";
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
    final player = ref.read(playerProvider);
    final playlists = ref.watch(recommendedPlaylistsProvider);
    final l18n = ref.watch(l18nProvider);
    ref.watch(playerIsPlayingProvider);
    ref.watch(playerIsLoadedProvider);

    return MusicCategory(
      title: l18n.recommended_playlists_chip,
      onDismiss: () {
        final preferences = ref.read(preferencesProvider.notifier);

        preferences.setRecommendedPlaylistsChipEnabled(false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l18n.category_closed(
                category: l18n.recommended_playlists_chip,
              ),
            ),
            duration: const Duration(
              seconds: 5,
            ),
            action: SnackBarAction(
              label: l18n.general_restore,
              onPressed: () =>
                  preferences.setRecommendedPlaylistsChipEnabled(true),
            ),
          ),
        );
      },
      children: [
        ScrollConfiguration(
          behavior: AlwaysScrollableScrollBehavior(),
          child: SizedBox(
            height: 280,
            child: ListView.separated(
              padding: EdgeInsets.zero,
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              physics: playlists == null
                  ? const NeverScrollableScrollPhysics()
                  : null,
              itemCount: playlists?.length ?? 8,
              separatorBuilder: (BuildContext context, int index) {
                return const Gap(8);
              },
              itemBuilder: (BuildContext context, int index) {
                // Skeleton loader.
                if (playlists == null) {
                  return Skeletonizer(
                    child: AudioPlaylistWidget(
                      name: fakePlaylistNames[index % fakePlaylistNames.length],
                      description: "Playlist description here",
                      useTextOnImageLayout: true,
                    ),
                  );
                }

                // Настоящие данные.
                final ExtendedPlaylist playlist = playlists[index];

                return AudioPlaylistWidget(
                  backgroundUrl: playlist.photo?.photo600,
                  cacheKey: "${playlist.mediaKey}600",
                  name: playlist.title!,
                  description: playlist.subtitle,
                  selected: player.playlist?.mediaKey == playlist.mediaKey,
                  currentlyPlaying: player.isPlaying && player.isLoaded,
                  onOpen: () => context.push(
                    "/music/playlist/${playlist.ownerID}/${playlist.id}",
                  ),
                  onPlayToggle: (bool playing) => onPlaylistPlayToggle(
                    ref,
                    context,
                    playlist,
                    playing,
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
