import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../../provider/preferences.dart";
import "desktop/info.dart";
import "desktop/lyrics.dart";
import "desktop/queue.dart";

/// Часть [PlayerRoute], отображающая полнооконный плеер для Desktop Layout'а.
class DesktopPlayerWidget extends HookConsumerWidget {
  /// Длительность для всех переходов между треками.
  static const Duration transitionDuration = Duration(milliseconds: 500);

  /// Длительность анимации появления иконки для выхода из полнооконного плеера.
  static const Duration closeIconDuration = Duration(milliseconds: 250);

  /// Длительность анимации появления/исчезновения блоков.
  static const Duration blockAnimationDuration = Duration(milliseconds: 800);

  /// Размер Padding'а.
  static const EdgeInsets paddingSize = EdgeInsets.all(50);

  /// Отношение блока по центру ([CurrentAudioBlock]) по отношению к боковым блокам ([QueueInfoBlock], [LyricsInfoBlock]).
  static const double middleBlockFlex = 1.6;

  /// Расстояние между блоками.
  static const double gapSize = 50;

  const DesktopPlayerWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsNotifier = ref.read(preferencesProvider.notifier);
    final queueEnabled =
        ref.watch(preferencesProvider.select((val) => val.playerQueueBlock));
    final lyricsEnabled =
        ref.watch(preferencesProvider.select((val) => val.playerLyricsBlock));

    final mqSize = MediaQuery.sizeOf(context);
    final mqPadding = MediaQuery.paddingOf(context);
    final availableWidth =
        mqSize.width - mqPadding.horizontal - paddingSize.horizontal;
    final availableHeight =
        mqSize.height - mqPadding.vertical - paddingSize.vertical;

    final blockWidth =
        (availableWidth - 2 * gapSize) / (middleBlockFlex + 2 * 1);

    final middleBlockSize = Size(blockWidth * middleBlockFlex, availableHeight);
    final blocksSize = Size(blockWidth, availableHeight);

    final closeIconAnimation = useAnimationController(
      duration: closeIconDuration,
    );
    useListenable(closeIconAnimation);

    final queueAnimation = useAnimationController(
      duration: blockAnimationDuration,
      initialValue: queueEnabled ? 1.0 : 0.0,
    );
    useValueListenable(queueAnimation);
    useEffect(
      () {
        queueAnimation.animateTo(
          queueEnabled ? 1.0 : 0.0,
          curve: queueEnabled
              ? Easing.emphasizedDecelerate
              : Easing.emphasizedAccelerate,
        );

        return null;
      },
      [queueEnabled],
    );
    final lyricsAnimation = useAnimationController(
      duration: blockAnimationDuration,
      initialValue: lyricsEnabled ? 1.0 : 0.0,
    );
    useValueListenable(lyricsAnimation);
    useEffect(
      () {
        lyricsAnimation.animateTo(
          lyricsEnabled ? 1.0 : 0.0,
          curve: lyricsEnabled
              ? Easing.emphasizedDecelerate
              : Easing.emphasizedAccelerate,
        );

        return null;
      },
      [lyricsEnabled],
    );

    void onQueueClose() {
      prefsNotifier.setPlayerQueueBlockEnabled(false);
    }

    void onLyricsClose() {
      prefsNotifier.setPlayerLyricsBlockEnabled(false);
    }

    return MouseRegion(
      onEnter: (_) => closeIconAnimation.forward(),
      onExit: (_) => closeIconAnimation.reverse(),
      child: SafeArea(
        child: Stack(
          children: [
            if (closeIconAnimation.value > 0)
              Opacity(
                opacity: closeIconAnimation.value,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: BackButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
            Padding(
              padding: paddingSize,
              child: SizedBox(
                width: availableWidth,
                height: availableHeight,
                child: Stack(
                  children: [
                    if (queueAnimation.value > 0)
                      FractionalTranslation(
                        translation: Offset(
                          queueAnimation.value - 1.0,
                          0.0,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: QueueInfoBlock(
                            size: blocksSize,
                            onClose: onQueueClose,
                          ),
                        ),
                      ),
                    Align(
                      child: CurrentAudioBlock(
                        size: middleBlockSize,
                      ),
                    ),
                    if (lyricsAnimation.value > 0)
                      FractionalTranslation(
                        translation: Offset(
                          1.0 - lyricsAnimation.value,
                          0.0,
                        ),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: LyricsInfoBlock(
                            size: blocksSize,
                            onClose: onLyricsClose,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
