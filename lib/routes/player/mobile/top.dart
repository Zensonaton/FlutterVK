import "package:flutter/material.dart";
import "package:gap/gap.dart";
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

    final scheme = ColorScheme.of(context);
    final color = scheme.onSurface;

    return Row(
      spacing: 8,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        BackButton(
          color: color,
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
        const Gap(40),
      ],
    );
  }
}
