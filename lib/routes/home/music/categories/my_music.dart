import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:just_audio/just_audio.dart";
import "package:provider/provider.dart";
import "package:skeletonizer/skeletonizer.dart";

import "../../../../consts.dart";
import "../../../../extensions.dart";
import "../../../../main.dart";
import "../../../../provider/user.dart";
import "../../../../utils.dart";
import "../../../../widgets/page_route_builders.dart";
import "../../music.dart";
import "../playlist.dart";

/// Виджет с разделом "Моя музыка"
class MyMusicBlock extends StatefulWidget {
  /// Указывает, что ряд из кнопок по типу "Перемешать", "Все треки" будет располагаться сверху.
  final bool useTopButtons;

  const MyMusicBlock({
    super.key,
    this.useTopButtons = false,
  });

  @override
  State<MyMusicBlock> createState() => _MyMusicBlockState();
}

class _MyMusicBlockState extends State<MyMusicBlock> {
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

      // Изменения плейлиста.
      player.sequenceStateStream.listen(
        (SequenceState? state) => setState(() {}),
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

    final bool selected = player.currentPlaylist == user.favoritesPlaylist;
    final bool selectedAndPlaying = selected && player.playing;
    final int musicCount = user.favoritesPlaylist?.count ?? 0;
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
          onPressed: user.favoritesPlaylist?.audios != null
              ? () async {
                  // Если данный плейлист уже играет, то просто ставим на паузу/воспроизведение.
                  if (player.currentPlaylist == user.favoritesPlaylist) {
                    await player.togglePlay();

                    return;
                  }

                  await player.setShuffle(true);

                  await player.setPlaylist(
                    user.favoritesPlaylist!,
                    audio: user.favoritesPlaylist!.audios!.randomItem(),
                  );
                }
              : null,
          icon: Icon(
            selectedAndPlaying ? Icons.pause : Icons.play_arrow,
          ),
          label: Text(
            selected
                ? player.playing
                    ? AppLocalizations.of(context)!.music_shuffleAndPlayPause
                    : AppLocalizations.of(context)!.music_shuffleAndPlayResume
                : AppLocalizations.of(context)!.music_shuffleAndPlay,
          ),
        ),

        // "Все треки".
        FilledButton.tonalIcon(
          onPressed: user.favoritesPlaylist?.audios != null
              ? () => Navigator.push(
                    context,
                    Material3PageRoute(
                      builder: (context) => PlaylistInfoRoute(
                        playlist: user.favoritesPlaylist!,
                      ),
                    ),
                  )
              : null,
          icon: const Icon(
            Icons.queue_music,
          ),
          label: Text(
            AppLocalizations.of(context)!.music_showAllFavoriteTracks,
          ),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            bottom: widget.useTopButtons ? 10 : 14,
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  right: 8,
                ),
                child: Text(
                  AppLocalizations.of(context)!.music_myMusicChip,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (musicCount > 0)
                Text(
                  musicCount.toString(),
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

        // Кнопки для управления (сверху, если useTopButtons = true).
        if (widget.useTopButtons)
          Padding(
            padding: const EdgeInsets.only(
              bottom: 10,
            ),
            child: controlButtonsRow,
          ),

        // Настоящие данные.
        if (user.favoritesPlaylist?.audios != null)
          for (int index = 0; index < clampedMusicCount; index++)
            buildListTrackWidget(
              context,
              user.favoritesPlaylist!.audios!.elementAt(index),
              user.favoritesPlaylist!,
              addBottomPadding: index < clampedMusicCount - 1,
            ),

        // Skeleton loader.
        if (user.favoritesPlaylist?.audios == null)
          for (int index = 0; index < 10; index++)
            Skeletonizer(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: index + 1 != 10 ? 8 : 0,
                ),
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
            ),

        // Кнопки для управления (снизу, если useTopButtons = false).
        if (!widget.useTopButtons)
          const SizedBox(
            height: 12,
          ),

        if (!widget.useTopButtons) controlButtonsRow,
      ],
    );
  }
}
