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

/// Часть для [TrackInfoWidget], отображающая информацию о треке, с кнопками для лайка и дизлайка.
class _Info extends ConsumerWidget {
  const _Info();

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
            textColor: scheme.onPrimaryContainer,
            isExplicit: audio?.isExplicit ?? false,
            explicitColor: scheme.onPrimaryContainer.withValues(alpha: 0.75),
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
    );
  }
}

/// Виджет, отображающий информацию о треке, а так же кнопки лайка и дизлайка.
class TrackInfoWidget extends ConsumerWidget {
  const TrackInfoWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(playerProvider);
    ref.watch(playerAudioProvider);
    ref.watch(playerPlaylistProvider);

    final scheme = Theme.of(context).colorScheme;

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

    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 16,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Expanded(
              child: _Info(),
            ),
            LoadingIconButton(
              icon: Icon(
                Icons.thumb_down_outlined,
                color: scheme.onPrimaryContainer,
              ),
              color: scheme.onPrimaryContainer,
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
              onPressed: onLikeTap,
            ),
          ],
        ),
        const SliderWithProgressWidget(),
        const PlayerControlsWidget(),
      ],
    );
  }
}
