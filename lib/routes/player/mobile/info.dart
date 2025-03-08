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
import "../mobile.dart";
import "../shared.dart";

/// Часть для [InfoControlsWidget], отображающая информацию о треке, с кнопками для лайка и дизлайка.
class _Info extends ConsumerWidget {
  /// Указывает, что будет использоваться более сжатый layout.
  final bool smallLayout;

  const _Info({
    this.smallLayout = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(playerProvider);
    ref.watch(playerAudioProvider);

    final scheme = Theme.of(context).colorScheme;

    final audio = player.audio;

    return PageTransitionSwitcher(
      duration: MobilePlayerWidget.transitionDuration,
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
      layoutBuilder: (List<Widget> children) {
        return Stack(
          alignment: Alignment.centerLeft,
          children: children,
        );
      },
      child: Column(
        key: ValueKey(
          audio?.id,
        ),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TrackTitleWithSubtitle(
            title: audio?.title ?? "Unknown",
            subtitle: audio?.subtitle,
            fontSize: smallLayout ? null : 24,
            textColor: scheme.onPrimaryContainer,
            isExplicit: audio?.isExplicit ?? false,
            explicitColor: scheme.onPrimaryContainer.withValues(alpha: 0.75),
          ),
          Text(
            audio?.artist ?? "Unknown",
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: scheme.onPrimaryContainer.withValues(alpha: 0.9),
              fontSize: smallLayout ? null : 18,
            ),
          ),
        ],
      ),
    );
  }
}

/// Виджет, отображающий информацию о треке, а так же кнопки лайка и дизлайка.
class InfoControlsWidget extends ConsumerWidget {
  /// Указывает, что будет использоваться более сжатый layout.
  final bool smallLayout;

  const InfoControlsWidget({
    super.key,
    this.smallLayout = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(playerProvider);
    ref.watch(playerAudioProvider);
    ref.watch(playerPlaylistProvider);

    final scheme = Theme.of(context).colorScheme;

    final audio = player.audio;
    final playlist = player.playlist;
    final isRecommendation = playlist?.isRecommendationTypePlaylist == true;

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

    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: smallLayout ? 8 : 16,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: _Info(
                smallLayout: smallLayout,
              ),
            ),
            if (isRecommendation)
              LoadingIconButton(
                icon: Icon(
                  Icons.thumb_down_outlined,
                  color: scheme.onPrimaryContainer,
                ),
                color: scheme.onPrimaryContainer,
                iconSize: smallLayout ? null : 28,
                onPressed: onDislikeTap,
              ),
            LoadingIconButton(
              icon: Icon(
                audio?.isLiked == true
                    ? Icons.favorite
                    : Icons.favorite_outline,
                color: scheme.onPrimaryContainer,
              ),
              color: scheme.onPrimaryContainer,
              iconSize: smallLayout ? null : 28,
              onPressed: onLikeTap,
            ),
          ],
        ),
        const SliderWithProgressWidget(
          showTime: false,
        ),
        SizedBox(
          width: double.infinity,
          child: PlayerControlsWidget(
            large: !smallLayout,
          ),
        ),
      ],
    );
  }
}
