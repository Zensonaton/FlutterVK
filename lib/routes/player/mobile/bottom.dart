import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

/// Виджет, отображаемый в нижней части [MobilePlayerWidget], отображающий различные действия над треком.
class BottomBarWidget extends ConsumerWidget {
  /// Указывает, что выбран блок с текстом песни.
  final bool isLyricsSelected;

  /// Указывает, что выбран блок с очередью воспроизведения.
  final bool isQueueSelected;

  /// Указывает, что включен таймер воспроизведения.
  final bool isTimerEnabled;

  /// Указывает, что включен режим передачи на устройство.
  final bool isCastingEnabled;

  /// Действие, вызываемое при нажатии на блок с текстом песни.
  final VoidCallback? onLyricsPressed;

  /// Действие, вызываемое при нажатии на блок с очередью воспроизведения.
  final VoidCallback? onQueuePressed;

  /// Действие, вызываемое при нажатии на блок с таймером воспроизведения.
  final VoidCallback? onTimerPressed;

  /// Действие, вызываемое при нажатии на блок с режимом передачи на устройство.
  final VoidCallback? onCastingPressed;

  /// Действие, вызываемое при нажатии на блок с дополнительными настройками.
  final VoidCallback? onMorePressed;

  const BottomBarWidget({
    super.key,
    this.isLyricsSelected = false,
    this.isQueueSelected = false,
    this.isTimerEnabled = false,
    this.isCastingEnabled = false,
    this.onLyricsPressed,
    this.onQueuePressed,
    this.onTimerPressed,
    this.onCastingPressed,
    this.onMorePressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final color = scheme.primary;
    final disabledColor = scheme.onSurface.withValues(
      alpha: 0.75,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Icon(
            isLyricsSelected ? Icons.lyrics : Icons.lyrics_outlined,
            color: isLyricsSelected ? color : disabledColor,
          ),
          onPressed: onLyricsPressed,
        ),
        IconButton(
          icon: Icon(
            isQueueSelected ? Icons.queue_music : Icons.queue_music_outlined,
            color: isQueueSelected ? color : disabledColor,
          ),
          onPressed: onQueuePressed,
        ),

        // TODO: Таймер воспроизведения.
        if (kDebugMode)
          IconButton(
            icon: Icon(
              isTimerEnabled ? Icons.timer : Icons.timer_outlined,
              color: isTimerEnabled ? color : disabledColor,
            ),
            onPressed: onTimerPressed,
          ),

        // TODO: Casting.
        if (kDebugMode)
          IconButton(
            icon: Icon(
              isCastingEnabled ? Icons.cast_connected : Icons.cast,
              color: isCastingEnabled ? color : disabledColor,
            ),
            onPressed: onCastingPressed,
          ),
        IconButton(
          icon: Icon(
            Icons.adaptive.more,
            color: disabledColor,
          ),
          onPressed: onMorePressed,
        ),
      ],
    );
  }
}
