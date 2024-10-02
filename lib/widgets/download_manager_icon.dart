import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

/// Значение, используемое как ширина и высота для [DownloadManagerIconWidget] в обычном состоянии.
const double downloadManagerMinimizedSize = 50;

/// Значение, используемое как ширина для [DownloadManagerIconWidget] в расширенном (наведённый курсор) состоянии.
const double downloadManagerExpandedWidth = 200;

class ProgressIndicatorIcon extends StatelessWidget {
  /// Общий прогресс загрузки от `0.0` до `1.0`.
  ///
  /// При `1.0` (100%) переходит в другую анимацию, и показывает "галочку" вместо "загрузки".
  final double progress;

  /// Указывает, наведён ли курсор на данный виджет.
  final bool isHovered;

  const ProgressIndicatorIcon({
    super.key,
    required this.progress,
    this.isHovered = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final isStarted = progress > 0.0;
    final isCompleted = progress >= 1.0;
    final bool shouldAnimate = progress > 0.0 && progress < 1.0;

    // FIXME: После первого открытия, анимация ломается из-за проверки с shouldAnimate.

    return SizedBox(
      width: downloadManagerMinimizedSize,
      height: downloadManagerMinimizedSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Анимация загрузки.
          if (isStarted)
            CircularProgressIndicator(
              strokeWidth: 3,
              value: progress,
            ).animate(
              onComplete: (controller) {
                if (!shouldAnimate) return;

                controller.loop();
              },
            ).rotate(
              duration: const Duration(
                seconds: 2,
              ),
              begin: 0,
              end: 1,
            ),

          // Иконка загрузки, либо же галочка, если загрузка была завершена.
          AnimatedSwitcher(
            duration: const Duration(
              milliseconds: 250,
            ),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: () {
              // Наведение.
              if (isHovered) {
                return Icon(
                  key: const ValueKey(
                    "hover",
                  ),
                  Icons.open_in_new,
                  color: scheme.onSecondaryContainer,
                  size: 22,
                );
              }

              // Завершено.
              if (isCompleted) {
                return Icon(
                  key: const ValueKey(
                    "completed",
                  ),
                  Icons.check,
                  color: scheme.onSecondaryContainer,
                  size: 22,
                );
              }

              // Загрузка.
              return Icon(
                key: const ValueKey(
                  "loading",
                ),
                Icons.arrow_downward,
                color: scheme.onSecondaryContainer,
                size: 22,
              ).animate(
                onPlay: (controller) {
                  if (!shouldAnimate) return;

                  controller.repeat(
                    reverse: true,
                  );
                },
              ).moveY(
                duration: const Duration(
                  milliseconds: 1000,
                ),
                curve: Curves.ease,
                begin: -2,
                end: 2,
              );
            }(),
          ),
        ],
      ),
    );
  }
}

/// Виджет, отображающий иконку для менеджера загрузок. При наведении на иконку данный виджет расширяется.
class DownloadManagerIconWidget extends HookConsumerWidget {
  /// Общий прогресс загрузки от `0.0` до `1.0`.
  ///
  /// При `1.0` (100%) переходит в другую анимацию, и показывает "галочку" вместо "загрузки".
  final double progress;

  /// Название плейлиста, в котором в данный момент происходит загрузка.
  ///
  /// Обязан быть, если [progress] не null.
  final String title;

  /// Событие, вызываемое при нажатии на этот виджет.
  final VoidCallback? onTap;

  const DownloadManagerIconWidget({
    super.key,
    required this.progress,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHovered = useState(false);
    final valueAnimController = useAnimationController(
      initialValue: progress,
    );
    useValueChanged(progress, (_, __) {
      return valueAnimController.animateTo(
        progress,
        curve: Curves.decelerate,
        duration: const Duration(
          milliseconds: 500,
        ),
      );
    });
    useValueListenable(valueAnimController);

    final scheme = Theme.of(context).colorScheme;
    const double availableSpace =
        downloadManagerExpandedWidth - downloadManagerMinimizedSize - 8;

    return InkWell(
      onHover: (bool value) => isHovered.value = value,
      onTap: onTap ?? () {},
      child: AnimatedContainer(
        curve: Curves.ease,
        duration: const Duration(
          milliseconds: 300,
        ),
        height: downloadManagerMinimizedSize,
        width: isHovered.value
            ? downloadManagerExpandedWidth
            : downloadManagerMinimizedSize,
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(
            downloadManagerMinimizedSize / 2,
          ),
        ),
        child: ClipRRect(
          child: OverflowBox(
            maxWidth: double.infinity,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Анимация загрузки с иконкой.
                RepaintBoundary(
                  child: ProgressIndicatorIcon(
                    progress: valueAnimController.value,
                    isHovered: isHovered.value,
                  ),
                ),

                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Название плейлиста.
                    SizedBox(
                      width: availableSpace,
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: scheme.onSecondaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // Процент загрузки.
                    SizedBox(
                      width: availableSpace,
                      child: Text(
                        "${(valueAnimController.value * 100).round()}%",
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: scheme.onSecondaryContainer.withOpacity(0.75),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
