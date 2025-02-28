import "dart:ui";

import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:gap/gap.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../../../consts.dart";
import "../../../provider/l18n.dart";
import "../../../provider/player.dart";
import "../../../widgets/audio_track.dart";
import "../../../widgets/fading_list_view.dart";
import "../shared.dart";

/// Отображает список из треков, находящихся в очереди.
class _Items extends HookConsumerWidget {
  // /// Максимальное количество треков, отображаемых в очереди.
  // ///
  // /// Желательно, чтобы это число было не кратным, чтобы текущий трек был по середине.
  // static const int maxTracksCount = 31;

  /// Длительность анимации скроллинга до текущего трека.
  static const Duration scrollDuration = Duration(seconds: 1);

  /// Curve для анимации скроллинга до текущего трека.
  static const Curve scrollCurve = Curves.ease;

  const _Items();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(playerProvider);
    ref.watch(playerQueueProvider);
    ref.watch(playerAudioProvider);
    ref.watch(playerIsPlayingProvider);
    ref.watch(playerIsBufferingProvider);

    // final queue = useMemoized(
    //   () {
    //     return List.generate(
    //       maxTracksCount,
    //       (int index) {
    //         final relativeIndex = index - (maxTracksCount ~/ 2);

    //         return player.audioAtRelativeIndex(relativeIndex);
    //       },
    //     ).whereType<ExtendedAudio>().toList();
    //   },
    //   [player.index, player.queue],
    // );
    // TODO
    final queue = player.queue;

    final controller = useScrollController();

    double currentTrackScrollPosition() {
      final int index = queue!.indexWhere(
        (audio) => audio.id == player.audio?.id,
      );
      if (index == -1) return 0;

      const itemHeight = 50 + trackTileSpacing;

      return index * itemHeight -
          (controller.position.viewportDimension / 2) +
          (itemHeight / 2);
    }

    void scrollToCurrent(bool jump) {
      final offset = currentTrackScrollPosition();

      if (jump) {
        controller.jumpTo(offset);

        return;
      }

      controller.animateTo(
        duration: scrollDuration,
        curve: scrollCurve,
        offset,
      );
    }

    final lastAudioIndex = useRef<int?>(null);
    useEffect(
      () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!controller.hasClients) return;

          // Изменение трека.
          if (lastAudioIndex.value != player.index) {
            scrollToCurrent(lastAudioIndex.value == null);
            lastAudioIndex.value = player.index;

            return;
          }

          // Изменение размера экрана.
          scrollToCurrent(true);
        });

        return null;
      },
      [player.index, MediaQuery.sizeOf(context).height],
    );

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        scrollbars: false,
        overscroll: false,
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
        },
      ),
      child: ListView.separated(
        controller: controller,
        itemCount: queue!.length,
        separatorBuilder: (BuildContext context, int index) {
          return const Gap(trackTileSpacing);
        },
        itemBuilder: (BuildContext context, int index) {
          final audio = queue[index];
          final isPlaying = player.isPlaying;
          final isBuffering = player.isBuffering;
          final isSelected = audio.id == player.audio?.id;

          return AudioTrackTile(
            audio: audio,
            isSelected: isSelected,
            isPlaying: isPlaying,
            isLoading: isSelected && isBuffering,
            glowIfSelected: true,
            showDuration: false,
            showStatusIcons: false,
            onPlayToggle: () {
              if (isSelected) {
                player.togglePlay();

                return;
              }

              player.jumpToAudio(audio);
            },
          );
        },
      ),
    );
  }
}

/// Отображает строчку "Воспроизведение плейлиста", "название плейлиста".
class _Label extends ConsumerWidget {
  const _Label();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(playerProvider);
    final l18n = ref.watch(l18nProvider);
    ref.watch(playerPlaylistProvider);

    final playlist = player.playlist;

    return CategoryTextWidget(
      header: "Воспроизведение плейлиста", // TODO: INTL
      text: playlist!.title ?? l18n.general_favorites_playlist,
      icon: Icons.queue_music,
      isLeft: true,
    );
  }
}

/// Отображает блок с информацией по очереди воспроизведения.
class QueueInfoBlock extends HookConsumerWidget {
  /// Размер этого блока.
  final Size size;

  const QueueInfoBlock({
    super.key,
    required this.size,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: size.width,
      height: size.height,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 50,
        children: [
          _Label(),
          Expanded(
            child: FadingListView(
              strength: 0.05,
              child: _Items(),
            ),
          ),
        ],
      ),
    );
  }
}
