import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../../../provider/l18n.dart";
import "../../../provider/player.dart";

/// Виджет, отображаемый как [AppBar] для [MobilePlayerWidget].
class TopBarWidget extends ConsumerWidget {
  const TopBarWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(playerProvider);
    final l18n = ref.watch(l18nProvider);
    ref.watch(playerPlaylistProvider);

    final playlist = player.playlist;

    final scheme = Theme.of(context).colorScheme;
    final color = scheme.onSurface;

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        BackButton(
          color: color,
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l18n.player_queue_header,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color.withValues(
                  alpha: 0.9,
                ),
              ),
            ),
            Text(
              playlist!.title ?? l18n.general_favorites_playlist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
