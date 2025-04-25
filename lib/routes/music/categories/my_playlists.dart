import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:gap/gap.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:skeletonizer/skeletonizer.dart";

import "../../../consts.dart";
import "../../../provider/l18n.dart";
import "../../../provider/player.dart";
import "../../../provider/playlists.dart";
import "../../../provider/preferences.dart";
import "../../../provider/user.dart";
import "../../../services/logger.dart";
import "../../../utils.dart";
import "../../../widgets/music_category.dart";
import "../../../widgets/playlist.dart";
import "../playlist.dart";

/// Виджет с разделом "Ваши плейлисты".
class MyPlaylistsBlock extends HookConsumerWidget {
  static final AppLogger logger = getLogger("MyPlaylistsBlock");

  const MyPlaylistsBlock({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);
    final player = ref.read(playerProvider);
    final playlists = ref.watch(playlistsProvider);
    final userPlaylists = ref.watch(userPlaylistsProvider);
    ref.watch(playerIsPlayingProvider);
    ref.watch(playerIsLoadedProvider);

    final int? playlistsCount = playlists.value?.playlistsCount;

    return MusicCategory(
      title: l18n.my_playlists_chip,
      count: playlistsCount,
      onDismiss: () {
        final preferences = ref.read(preferencesProvider.notifier);

        HapticFeedback.selectionClick();
        preferences.setPlaylistsChipEnabled(false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l18n.category_closed(
                category: l18n.my_playlists_chip,
              ),
            ),
            duration: const Duration(
              seconds: 5,
            ),
            action: SnackBarAction(
              label: l18n.general_restore,
              onPressed: () => preferences.setPlaylistsChipEnabled(true),
            ),
          ),
        );
      },
      children: [
        ScrollConfiguration(
          behavior: AlwaysScrollableScrollBehavior(),
          child: SizedBox(
            height: 310,
            child: ListView.separated(
              padding: EdgeInsets.zero,
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              physics: userPlaylists == null
                  ? const NeverScrollableScrollPhysics()
                  : null,
              itemCount: userPlaylists?.length ?? 10,
              separatorBuilder: (BuildContext context, int index) {
                return const Gap(8);
              },
              itemBuilder: (BuildContext context, int index) {
                // Skeleton loader.
                if (userPlaylists == null) {
                  return Skeletonizer(
                    child: PlaylistWidget(
                      name: fakePlaylistNames[index % fakePlaylistNames.length],
                    ),
                  );
                }

                // Настоящие данные.
                final ExtendedPlaylist playlist = userPlaylists[index];

                return PlaylistWidget(
                  backgroundUrl: playlist.photo?.photo600,
                  cacheKey: "${playlist.mediaKey}600",
                  name: playlist.title!,
                  description: playlist.description,
                  selected: player.playlist?.mediaKey == playlist.mediaKey,
                  currentlyPlaying: player.isPlaying,
                  onOpen: () {
                    HapticFeedback.lightImpact();

                    context.push(
                      "/music/playlist/${playlist.ownerID}/${playlist.id}",
                    );
                  },
                  onPlayToggle: (bool playing) {
                    HapticFeedback.mediumImpact();

                    return onPlaylistPlayToggle(
                      ref,
                      context,
                      playlist,
                      playing,
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
