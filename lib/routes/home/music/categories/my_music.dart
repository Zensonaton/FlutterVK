import "package:flutter/material.dart";
import "package:gap/gap.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:skeletonizer/skeletonizer.dart";

import "../../../../consts.dart";
import "../../../../extensions.dart";
import "../../../../main.dart";
import "../../../../provider/l18n.dart";
import "../../../../provider/player_events.dart";
import "../../../../provider/playlists.dart";
import "../../../../provider/preferences.dart";
import "../../../../provider/user.dart";
import "../../../../utils.dart";
import "../../../../widgets/audio_track.dart";
import "../../../../widgets/music_category.dart";

/// Виджет с разделом "Моя музыка"
class MyMusicBlock extends HookConsumerWidget {
  const MyMusicBlock({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlist = ref.watch(favoritesPlaylistProvider);
    final l18n = ref.watch(l18nProvider);
    ref.watch(playerStateProvider);
    ref.watch(playerCurrentIndexProvider);
    ref.watch(playerLoadedStateProvider);

    final bool mobileLayout = isMobileLayout(context);

    void onPlayPressed() async {
      // Если данный плейлист уже играет, то просто ставим на паузу/воспроизведение.
      if (player.currentPlaylist?.mediaKey == playlist?.mediaKey) {
        await player.togglePlay();

        return;
      }

      await player.setShuffle(
        true,
        disableAudioMixCheck: true,
      );
      await player.setPlaylist(
        playlist!,
        selectedTrack: playlist.audios!.randomItem(),
      );
    }

    final bool selected =
        player.currentPlaylist?.ownerID == playlist?.ownerID &&
            player.currentPlaylist?.id == playlist?.id;
    final bool selectedAndPlaying = selected && player.playing;
    final int? musicCount = playlist?.count;
    final int clampedMusicCount = clampInt(
      musicCount ?? 0,
      0,
      10,
    );

    return MusicCategory(
      title: l18n.music_myMusicChip,
      count: playlist?.count,
      onDismiss: () {
        final preferences = ref.read(preferencesProvider.notifier);

        preferences.setMyMusicChipEnabled(false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l18n.music_categoryClosedTitle(l18n.music_myMusicChip),
            ),
            duration: const Duration(
              seconds: 5,
            ),
            action: SnackBarAction(
              label: l18n.general_restore,
              onPressed: () => preferences.setMyMusicChipEnabled(true),
            ),
          ),
        );
      },
      children: [
        // Настоящие данные.
        if (playlist?.audios != null && clampedMusicCount > 0)
          for (int index = 0; index < clampedMusicCount; index++) ...[
            buildListTrackWidget(
              ref,
              context,
              playlist!.audios![index],
              playlist,
              showDuration: !mobileLayout,
            ),
            const Gap(trackTileSpacing),
          ],

        // Skeleton loader.
        if (playlist?.audios == null)
          for (int index = 0;
              index < (playlist?.count ?? 10).clamp(0, 10);
              index++) ...[
            Skeletonizer(
              child: AudioTrackTile(
                audio: ExtendedAudio(
                  id: -1,
                  ownerID: -1,
                  title: fakeTrackNames[index % fakeTrackNames.length],
                  artist: fakeTrackNames[(index + 1) % fakeTrackNames.length],
                  duration: 60 * 3,
                  accessKey: "",
                  date: 0,
                ),
              ),
            ),
            const Gap(trackTileSpacing),
          ],
        const Gap(trackTileSpacing - 4),

        // Кнопки для управления.
        Wrap(
          spacing: 8,
          children: [
            // "Перемешать".
            FilledButton.icon(
              icon: Icon(
                selectedAndPlaying ? Icons.pause : Icons.play_arrow,
              ),
              label: Text(
                selected
                    ? player.playing
                        ? l18n.music_shuffleAndPlayPause
                        : l18n.music_shuffleAndPlayResume
                    : l18n.music_shuffleAndPlay,
              ),
              onPressed: playlist?.audios != null ? onPlayPressed : null,
            ),

            // "Все треки".
            FilledButton.tonalIcon(
              onPressed: playlist?.audios != null
                  ? () => context.push(
                        "/music/playlist/${playlist!.ownerID}/${playlist.id}",
                      )
                  : null,
              icon: const Icon(
                Icons.queue_music,
              ),
              label: Text(
                l18n.music_showAllFavoriteTracks,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
