import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:skeletonizer/skeletonizer.dart";

import "../../../../consts.dart";
import "../../../../main.dart";
import "../../../../provider/l18n.dart";
import "../../../../provider/player_events.dart";
import "../../../../provider/playlists.dart";
import "../../../../provider/preferences.dart";
import "../../../../provider/user.dart";
import "../../../../services/logger.dart";
import "../../../../utils.dart";
import "../../../../widgets/music_category.dart";
import "../../music.dart";
import "../playlist.dart";

/// Виджет с разделом "Ваши плейлисты".
class MyPlaylistsBlock extends HookConsumerWidget {
  static final AppLogger logger = getLogger("MyPlaylistsBlock");

  const MyPlaylistsBlock({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistsProvider);
    final userPlaylists = ref.watch(userPlaylistsProvider);
    final l18n = ref.watch(l18nProvider);
    ref.watch(playerStateProvider);
    ref.watch(playerLoadedStateProvider);

    final int playlistsCount = playlists.value?.playlistsCount ?? 0;

    return MusicCategory(
      title: l18n.music_myPlaylistsChip,
      count: playlistsCount,
      onDismiss: () {
        final preferences = ref.read(preferencesProvider.notifier);

        preferences.setPlaylistsChipEnabled(false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l18n.music_categoryClosedTitle(l18n.music_myPlaylistsChip),
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
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              physics: userPlaylists == null
                  ? const NeverScrollableScrollPhysics()
                  : null,
              itemCount: userPlaylists?.length,
              itemBuilder: (BuildContext context, int index) {
                // Skeleton loader.
                if (userPlaylists == null) {
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
                final ExtendedPlaylist playlist = userPlaylists[index];

                return Padding(
                  padding: const EdgeInsets.only(
                    right: 8,
                  ),
                  child: AudioPlaylistWidget(
                    backgroundUrl: playlist.photo?.photo600,
                    cacheKey: "${playlist.mediaKey}600",
                    name: playlist.title!,
                    description: playlist.description,
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
