import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../../../provider/auth.dart";
import "../../../provider/l18n.dart";
import "../../../provider/preferences.dart";

/// Route для управления внешним видом полнооконного плеера.
/// Пользователь может попасть в этот раздел через "Стиль и внешний вид", а потом перейдя в "Полнооконный плеер".
///
/// go_route: `/profile/settings/visual/player`
class SettingsVisualPlayerRoute extends ConsumerWidget {
  const SettingsVisualPlayerRoute({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);

    final preferences = ref.watch(preferencesProvider);
    final prefsNotifier = ref.read(preferencesProvider.notifier);

    final recommendationsConnected = ref.watch(secondaryTokenProvider) != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l18n.fullscreen_player,
        ),
      ),
      body: ListView(
        children: [
          // Изображения трека как фон полноэкранного плеера.
          SwitchListTile(
            secondary: const Icon(
              Icons.photo_filter,
            ),
            title: Text(
              l18n.use_track_thumb_as_player_background,
            ),
            value: preferences.playerThumbAsBackground,
            onChanged: recommendationsConnected
                ? (bool? enabled) async {
                    HapticFeedback.lightImpact();
                    if (enabled == null) return;

                    prefsNotifier.setPlayerThumbAsBackground(enabled);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
