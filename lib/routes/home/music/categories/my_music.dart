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
    final preferences = ref.watch(preferencesProvider);
    final playlist = ref.watch(favoritesPlaylistProvider);
    final player = ref.read(playerProvider);
    final l18n = ref.watch(l18nProvider);
    ref.watch(playerIsLoadedProvider);
    ref.watch(playerIsPlayingProvider);
    ref.watch(playerAudioProvider);
    ref.watch(playerIsBufferingProvider);

    final bool mobileLayout = isMobileLayout(context);

    void onPlayPressed() async {
      // Если данный плейлист уже играет, то просто ставим на паузу/воспроизведение.
      if (player.playlist?.mediaKey == playlist?.mediaKey) {
        await player.togglePlay();

        return;
      }

      if (preferences.shuffleOnPlay) {
        await player.setShuffle(true);
      }
      await player.setPlaylist(
        playlist!,
        randomAudio: preferences.shuffleOnPlay,
      );
    }

    final bool selected = player.playlist?.ownerID == playlist?.ownerID &&
        player.playlist?.id == playlist?.id;
    final int musicCount = playlist?.audios?.length ?? 0;
    final int clampedMusicCount = clampInt(musicCount, 0, 10);

    return MusicCategory(
      title: l18n.my_music_chip,
      count: musicCount,
      onDismiss: () {
        final preferences = ref.read(preferencesProvider.notifier);

        preferences.setMyMusicChipEnabled(false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l18n.category_closed(
                category: l18n.my_music_chip,
              ),
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
              isAvailable: playlist.audios![index].canPlay &&
                  playlist.audios![index].isLiked,
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
                selected
                    ? player.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow
                    : preferences.shuffleOnPlay
                        ? Icons.shuffle
                        : Icons.play_arrow,
              ),
              label: Text(
                selected
                    ? player.isPlaying
                        ? l18n.general_pause
                        : l18n.general_resume
                    : preferences.shuffleOnPlay
                        ? l18n.general_shuffle
                        : l18n.general_play,
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
                l18n.all_tracks,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
