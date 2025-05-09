import "dart:ui";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../../../provider/player.dart";
import "../../../provider/user.dart";
import "../../../utils.dart";
import "../../../widgets/scrollable_slider.dart";
import "../shared.dart";

/// Виджет для [MobilePlayerWidget], отображающий изображение трека, которое можно передвигать пальцем для переключения между треками.
class TrackImageWidget extends HookConsumerWidget {
  /// Длительность анимации переключения трека.
  static const Duration switchAnimationDuration = Duration(milliseconds: 400);

  /// Размер одной из сторон изображения.
  final double size;

  /// Ширина этого блока.
  final double fullWidth;

  /// Горизонтальный padding.
  final double padding;

  const TrackImageWidget({
    super.key,
    required this.size,
    required this.fullWidth,
    required this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(playerProvider);
    ref.watch(playerAudioProvider);

    final fullWithPadding = size + padding;

    final lastAudio = useState<ExtendedAudio?>(player.audio);
    final fromTransition = useState<ExtendedAudio?>(null);
    final toTransition = useState<ExtendedAudio?>(null);
    final switchAnimation = useAnimationController(
      duration: switchAnimationDuration,
      lowerBound: -1.0,
    );
    final switchingViaSwipe = useRef(false);
    final seekToPrevAudio = useRef(false);
    useValueListenable(switchAnimation);

    Future<void> audioSwitchTransition(
      ExtendedAudio from,
      ExtendedAudio to, {
      double progress = 0.0,
      bool forceFullDuration = false,
    }) async {
      if (progress < -1.0 || progress > 1.0) {
        throw ArgumentError(
          "Progress must be between -1.0 and 1.0, but got $progress instead",
        );
      }
      if (forceFullDuration && (progress != 1.0 && progress != -1.0)) {
        throw ArgumentError(
          "Progress must be 1.0 or -1.0 if forceFullDuration is set, but got $progress instead",
        );
      }

      switchAnimation.stop();

      // Запускаем анимацию лишь в том случае, если приложение активно.
      if ([AppLifecycleState.resumed, AppLifecycleState.inactive]
          .contains(WidgetsBinding.instance.lifecycleState)) {
        fromTransition.value = to;
        toTransition.value = from;

        final maxDurationMs = switchAnimationDuration.inMilliseconds;
        final left = forceFullDuration ? 1.0 : 1.0 - progress.abs();
        final leftReversed = -progress.sign * left;
        final durMs =
            (left * maxDurationMs).abs().clamp(0, maxDurationMs).toInt();

        switchAnimation.value = leftReversed;
        await switchAnimation.animateTo(
          0.0,
          duration: Duration(milliseconds: durMs),
        );
      }
      fromTransition.value = null;
      toTransition.value = null;
    }

    useEffect(
      () {
        final subscription = player.audioStream.listen((_) {
          // Запускаем анимацию перехода между треками, если предыдущий трек нам известны.
          if (player.audio != null && lastAudio.value?.id != player.audio?.id) {
            seekToPrevAudio.value = lastAudio.value == null ||
                lastAudio.value?.id == player.nextAudio?.id;
            final firedViaSwipe = switchingViaSwipe.value;
            final progress = firedViaSwipe
                ? switchAnimation.value
                : seekToPrevAudio.value
                    ? 1.0
                    : -1.0;

            final from = lastAudio.value ??
                (seekToPrevAudio.value
                    ? player.nextAudio
                    : player.previousAudio);
            final to = player.audio;

            if (from != null && to != null) {
              audioSwitchTransition(
                from,
                to,
                progress: progress,
                forceFullDuration: !firedViaSwipe,
              );
            }
          }

          if (player.audio != null) {
            lastAudio.value = player.audio;
          }
          switchingViaSwipe.value = false;
        });

        return subscription.cancel;
      },
      [],
    );

    final prevAudio = player.previousAudio;
    final audio = lastAudio.value;
    final nextAudio = player.nextAudio;

    void onVolumeScroll(double diff) async {
      if (isMobile) return null;

      return player.setVolume(
        clampDouble(
          player.volume + diff / 10,
          0.0,
          1.0,
        ),
      );
    }

    void onTap() {
      player.togglePlay();
    }

    void onHorizontalStart(DragStartDetails details) {
      switchAnimation.stop();
      switchingViaSwipe.value = true;
    }

    void onHorizontalUpdate(DragUpdateDetails details) {
      switchAnimation.value = clampDouble(
        switchAnimation.value + details.primaryDelta! / fullWithPadding,
        -1.0,
        1.0,
      );
    }

    void onHorizontalEnd(DragEndDetails details) async {
      final value = (switchAnimation.value +
              details.primaryVelocity! / fullWithPadding / 10)
          .clamp(-1.0, 1.0);

      // Если пользователь проскроллил слишком мало, то не считаем это как переключение трека.
      if (value.abs() < 0.5) {
        switchAnimation.animateTo(0.0);

        return;
      }

      final isNext = value < 0.0;
      if (isNext) {
        player.next();
      } else {
        player.previous();
      }
    }

    return ScrollableWidget(
      onChanged: onVolumeScroll,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: onTap,
          onHorizontalDragStart: onHorizontalStart,
          onHorizontalDragUpdate: onHorizontalUpdate,
          onHorizontalDragEnd: onHorizontalEnd,
          child: SizedBox(
            width: fullWidth,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Предыдущий трек.
                if (prevAudio != null)
                  Transform.translate(
                    offset: Offset(
                      (switchAnimation.value - 1.0) * fullWithPadding,
                      0.0,
                    ),
                    child: AudioImageWidget(
                      audio: prevAudio,
                      size: size,
                    ),
                  ),

                // Текущий трек.
                Transform.translate(
                  offset: Offset(
                    switchAnimation.value * fullWithPadding,
                    0.0,
                  ),
                  child: AudioImageWidget(
                    audio: audio!,
                    size: size,
                  ),
                ),

                // Следующий трек.
                if (nextAudio != null)
                  Transform.translate(
                    offset: Offset(
                      (switchAnimation.value + 1.0) * fullWithPadding,
                      0.0,
                    ),
                    child: AudioImageWidget(
                      audio: nextAudio,
                      size: size,
                    ),
                  ),

                // Анимированная обложка трека.
                if (switchAnimation.value == 0.0)
                  AudioAnimatedImageWidget(
                    audio: audio,
                    size: size,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
