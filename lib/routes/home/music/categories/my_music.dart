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
import "../../../../provider/user.dart";
import "../../../../utils.dart";
import "../../../../widgets/audio_track.dart";

/// Виджет с разделом "Моя музыка"
class MyMusicBlock extends HookConsumerWidget {
  /// Указывает, что ряд из кнопок по типу "Перемешать", "Все треки" будет располагаться сверху.
  final bool useTopButtons;

  const MyMusicBlock({
    super.key,
    this.useTopButtons = false,
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
        player.currentPlaylist?.mediaKey == playlist?.mediaKey;
    final bool selectedAndPlaying = selected && player.playing;
    final int musicCount = playlist?.count ?? 0;
    final int clampedMusicCount = clampInt(
      musicCount,
      0,
      10,
    );
    final Widget controlButtonsRow = Wrap(
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
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Название блока.
            Text(
              l18n.music_myMusicChip,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Gap(8),

            // Надпись с количеством треков.
            if (musicCount > 0)
              Text(
                musicCount.toString(),
                style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.secondary.withOpacity(0.75),
                ),
              ),
          ],
        ),
        Gap(useTopButtons ? 10 : 14),

        // Кнопки для управления (сверху, если useTopButtons = true).
        if (useTopButtons)
          Padding(
            padding: const EdgeInsets.only(
              bottom: 10,
            ),
            child: controlButtonsRow,
          ),

        // Настоящие данные.
        if (playlist?.audios != null && clampedMusicCount > 0)
          for (int index = 0; index < clampedMusicCount; index++) ...[
            buildListTrackWidget(
              ref,
              context,
              playlist!.audios!.elementAt(index),
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
            const Gap(8),
          ],

        // Кнопки для управления (снизу, если useTopButtons = false).
        if (!useTopButtons) const Gap(4),
        if (!useTopButtons) controlButtonsRow,
      ],
    );
  }
}
