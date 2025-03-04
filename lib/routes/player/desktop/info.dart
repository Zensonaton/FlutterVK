import "dart:async";
import "dart:math";
import "dart:ui";

import "package:animations/animations.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../../../extensions.dart";
import "../../../provider/player.dart";
import "../../../provider/preferences.dart";
import "../../../widgets/audio_player.dart";
import "../../../widgets/audio_track.dart";
import "../../../widgets/dialogs.dart";
import "../../../widgets/loading_button.dart";
import "../desktop.dart";
import "../shared.dart";

/// Отображает информацию по текущему треку, а так же кнопки "лайк" и "дизлайк".
class _Info extends ConsumerWidget {
  const _Info();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(playerProvider);
    ref.watch(playerAudioProvider);

    final scheme =
        Theme.of(context).colorScheme; // TODO: Использовать тему трека.

    final audio = player.audio;
    final playlist = player.playlist;

    Future<void> onLikeTap() async {
      HapticFeedback.lightImpact();
      if (!networkRequiredDialog(ref, context)) return;

      final preferences = ref.read(preferencesProvider);

      if (!audio!.isLiked && preferences.checkBeforeFavorite) {
        if (!await audio.checkForDuplicates(ref, context)) return;
      }
      if (!context.mounted) return;

      await audio.likeDislikeRestoreSafe(
        context,
        player.ref,
        sourcePlaylist: playlist,
      );
    }

    Future<void> onDislikeTap() async {
      HapticFeedback.lightImpact();
      if (!networkRequiredDialog(ref, context)) return;

      await player.audio!.dislike(player.ref);

      await player.next();
    }

    return Row(
      children: [
        LoadingIconButton(
          icon: Icon(
            audio?.isLiked == true ? Icons.favorite : Icons.favorite_outline,
            color: scheme.onPrimaryContainer,
          ),
          color: scheme.onPrimaryContainer,
          onPressed: onLikeTap,
        ),
        Expanded(
          child: PageTransitionSwitcher(
            duration: DesktopPlayerWidget.transitionDuration,
            transitionBuilder: (
              Widget child,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
            ) {
              return SharedAxisTransition(
                animation: animation,
                secondaryAnimation: secondaryAnimation,
                transitionType: SharedAxisTransitionType.horizontal,
                fillColor: Colors.transparent,
                child: child,
              );
            },
            child: Column(
              key: ValueKey(
                audio?.id,
              ),
              children: [
                TrackTitleWithSubtitle(
                  title: audio?.title ?? "Unknown",
                  subtitle: audio?.subtitle,
                  textColor: scheme.onPrimaryContainer,
                  isExplicit: audio?.isExplicit ?? false,
                  explicitColor:
                      scheme.onPrimaryContainer.withValues(alpha: 0.75),
                ),
                Text(
                  audio?.artist ?? "Unknown",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onPrimaryContainer.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
        LoadingIconButton(
          icon: Icon(
            Icons.thumb_down_outlined,
            color: scheme.onPrimaryContainer,
          ),
          color: scheme.onPrimaryContainer,
          onPressed: onDislikeTap,
        ),
      ],
    );
  }
}

/// Виджет, отображаемый изображение текущего трека.
class _Image extends HookConsumerWidget {
  /// Радиус скругления изображений.
  static const double borderRadius = 16;

  /// Длительность анимации перехода между изображениями.
  static const Duration animationDuration = Duration(seconds: 1);

  /// Размер изображения.
  final double size;

  const _Image({
    required this.size,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(playerProvider);
    ref.watch(playerAudioProvider);

    final audio = player.audio;

    final imageUrl = audio?.maxThumbnail;

    return AnimatedSwitcher(
      duration: animationDuration,
      child: Stack(
        key: ValueKey(
          imageUrl,
        ),
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          BackgroundGlowImageWidget(
            audio: audio!,
          ),
          AudioImageWidget(
            audio: audio,
            size: size,
            borderRadius: borderRadius,
          ),
          AudioAnimatedImageWidget(
            audio: audio,
            size: size,
            borderRadius: borderRadius,
          ),
        ],
      ),
    );
  }
}

/// Отображает блок с информацией по тому треку, который воспроизводится.
class CurrentAudioBlock extends StatelessWidget {
  /// Размер этого блока.
  final Size size;

  const CurrentAudioBlock({
    super.key,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final imageSize = clampDouble(
      min(
        size.width - 100,
        size.height - 200,
      ),
      100,
      800,
    );

    return SizedBox(
      width: size.width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 20,
        children: [
          SizedBox(
            width: imageSize,
            height: imageSize,
            child: _Image(
              size: imageSize,
            ),
          ),
          SizedBox(
            width: imageSize,
            child: const _Info(),
          ),
          SizedBox(
            width: imageSize,
            child: const SliderWithProgressWidget(),
          ),
          SizedBox(
            width: imageSize,
            child: const PlayerControlsWidget(),
          ),
        ],
      ),
    );
  }
}
