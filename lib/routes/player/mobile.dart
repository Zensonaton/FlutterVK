import "dart:math";
import "dart:ui";

import "package:animations/animations.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../../provider/player.dart";
import "../../provider/user.dart";
import "../../widgets/fading_list_view.dart";
import "../music/bottom_audio_options.dart";
import "mobile/bottom.dart";
import "mobile/image.dart";
import "mobile/info.dart";
import "mobile/top.dart";
import "shared.dart";

/// Виджет для [MobilePlayerWidget], отображающий блок с изображением трека и его названием.
class _AudioBlock extends StatelessWidget {
  /// Размер изображения.
  final double size;

  /// Ширина этого блока.
  final double fullWidth;

  /// Горизонтальный padding.
  final double padding;

  const _AudioBlock({
    required this.size,
    required this.fullWidth,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final useSmallLayout = size <= 300;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Align(
          child: TrackImageWidget(
            size: size,
            fullWidth: fullWidth,
            padding: padding,
          ),
        ),
        RepaintBoundary(
          child: InfoControlsWidget(
            smallLayout: useSmallLayout,
          ),
        ),
      ],
    );
  }
}

/// Виджет для [MobilePlayerWidget], отображающий блок с текущим текстом песни.
class _LyricsBlock extends ConsumerWidget {
  const _LyricsBlock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(playerProvider);
    ref.watch(playerAudioProvider);

    final audio = player.audio;
    final lyrics = audio?.lyrics;

    return AnimatedSwitcher(
      duration: MobilePlayerWidget.switchDuration,
      child: lyrics != null
          ? FadingListView(
              key: ValueKey(
                audio!.id,
              ),
              child: AudioLyricsListView(
                lyrics: audio.lyrics!,
              ),
            )
          : const SizedBox.shrink(
              key: ValueKey(null),
            ),
    );
  }
}

/// Виджет для [MobilePlayerWidget], отображающий блок с текущим текстом песни.
class _QueueBlock extends StatelessWidget {
  const _QueueBlock();

  @override
  Widget build(BuildContext context) {
    return const FadingListView(
      child: PlayerQueueListView(),
    );
  }
}

/// Часть [PlayerRoute], отображающая полнооконный плеер для Mobile Layout'а.
class MobilePlayerWidget extends HookConsumerWidget {
  /// Длительность для всех переходов между треками.
  static const Duration transitionDuration = Duration(milliseconds: 500);

  /// Длительность перехода между открытой страницей с текстом песни, очереди, либо ничего.
  static const Duration switchDuration = Duration(milliseconds: 500);

  /// Размер Padding'а.
  static const EdgeInsets padding = EdgeInsets.all(16);

  /// Расстояние между блоками [TopBarWidget] (сверху) и [BottomBarWidget] (снизу), а так же внутренним содержимым.
  static const double spacing = 16;

  /// Размер блоков [TopBarWidget] (сверху) и [BottomBarWidget] (снизу).
  static const double barHeight = 50;

  const MobilePlayerWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mqSize = MediaQuery.sizeOf(context);
    final mqPadding = MediaQuery.paddingOf(context);

    final fullAreaSize = Size(
      mqSize.width - padding.horizontal - mqPadding.horizontal,
      mqSize.height - padding.vertical - mqPadding.vertical,
    );
    final imageSize = clampDouble(
      min(
        fullAreaSize.width,
        fullAreaSize.height - 300,
      ),
      100,
      1500,
    );
    final innerBodySize = Size(
      fullAreaSize.width,
      fullAreaSize.height - barHeight * 2 - spacing * 2,
    );

    final isLyricsEnabled = useState(false);
    final isQueueEnabled = useState(false);

    final detailsAudio = useRef<ExtendedAudio?>(null);
    final detailPlaylist = useRef<ExtendedPlaylist?>(null);

    void onLyricsSelected() {
      HapticFeedback.selectionClick();

      isLyricsEnabled.value = !isLyricsEnabled.value;
      isQueueEnabled.value = false;
    }

    void onQueuePressed() {
      HapticFeedback.selectionClick();

      isQueueEnabled.value = !isQueueEnabled.value;
      isLyricsEnabled.value = false;
    }

    void onMorePressed() {
      HapticFeedback.selectionClick();

      final player = ref.read(playerProvider);
      detailsAudio.value = player.audio;
      detailPlaylist.value = player.playlist;

      showModalBottomSheet(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (BuildContext context) {
          return BottomAudioOptionsDialog(
            audio: detailsAudio.value!,
            playlist: detailPlaylist.value!,
          );
        },
      );
    }

    return SafeArea(
      child: Padding(
        padding: padding,
        child: SizedBox(
          width: fullAreaSize.width,
          height: fullAreaSize.height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(
                height: barHeight,
                child: TopBarWidget(),
              ),
              SizedBox(
                width: innerBodySize.width,
                height: innerBodySize.height,
                child: PageTransitionSwitcher(
                  duration: transitionDuration,
                  transitionBuilder: (
                    Widget child,
                    Animation<double> animation,
                    Animation<double> secondaryAnimation,
                  ) {
                    return SharedAxisTransition(
                      animation: animation,
                      secondaryAnimation: secondaryAnimation,
                      transitionType: SharedAxisTransitionType.vertical,
                      fillColor: Colors.transparent,
                      child: child,
                    );
                  },
                  child: () {
                    if (isLyricsEnabled.value) {
                      return const _LyricsBlock();
                    } else if (isQueueEnabled.value) {
                      return const _QueueBlock();
                    }

                    return SizedBox.expand(
                      key: const ValueKey(
                        null,
                      ),
                      child: _AudioBlock(
                        size: imageSize,
                        fullWidth: fullAreaSize.width,
                        padding: padding.horizontal,
                      ),
                    );
                  }(),
                ),
              ),
              SizedBox(
                height: barHeight,
                child: BottomBarWidget(
                  isLyricsSelected: isLyricsEnabled.value,
                  onLyricsPressed: onLyricsSelected,
                  isQueueSelected: isQueueEnabled.value,
                  onQueuePressed: onQueuePressed,
                  onMorePressed: onMorePressed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
