import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:gap/gap.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../../provider/auth.dart";
import "../../provider/l18n.dart";
import "../../provider/player.dart";
import "../../provider/preferences.dart";
import "../../utils.dart";
import "../../widgets/audio_player.dart";
import "../../widgets/dialogs.dart";
import "../profile.dart";

/// Route для управления интеграциями приложения.
/// Пользователь может попасть в этот раздел через [ProfileRoute], нажав на "Интеграции".
///
/// go_route: `/profile/settings/integrations`
class SettingsIntegrationsRoute extends ConsumerWidget {
  const SettingsIntegrationsRoute({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);
    final player = ref.read(playerProvider);
    ref.watch(playerIsLoadedProvider);

    final mobileLayout = isMobileLayout(context);

    final preferences = ref.watch(preferencesProvider);
    final prefsNotifier = ref.read(preferencesProvider.notifier);

    final recommendationsConnected = ref.watch(secondaryTokenProvider) != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l18n.integrations,
        ),
      ),
      body: ListView(
        children: [
          // Трансляция в статус.
          SwitchListTile(
            secondary: const Icon(
              Icons.podcasts,
            ),
            title: Text(
              l18n.status_broadcast,
            ),
            subtitle: Text(
              l18n.status_broadcast_desc,
            ),
            value: preferences.statusBroadcastEnabled,
            onChanged: (bool? enabled) async {
              HapticFeedback.lightImpact();
              if (enabled == null) return;

              prefsNotifier.setStatusBroadcastEnabled(enabled);
              player.setStatusBroadcastEnabled(enabled);
            },
          ),

          // Discord Rich Presence (Desktop).
          if (isDesktop || kDebugMode)
            SwitchListTile(
              secondary: const Icon(
                Icons.discord,
              ),
              title: Text(
                l18n.discord_rpc,
              ),
              subtitle: Text(
                l18n.discord_rpc_desc,
              ),
              value: preferences.discordRPCEnabled,
              onChanged: (bool? enabled) async {
                HapticFeedback.lightImpact();
                if (enabled == null) return;

                prefsNotifier.setDiscordRPCEnabled(enabled);
                player.setDiscordRPCEnabled(enabled);
              },
            ),

          // Загрузка отсутсвующих обложек из Deezer.
          SwitchListTile(
            secondary: const Icon(
              Icons.image_search,
            ),
            title: Text(
              l18n.deezer_thumbnails,
            ),
            subtitle: Text(
              l18n.deezer_thumbnails_desc,
            ),
            value: preferences.deezerThumbnails,
            onChanged: recommendationsConnected
                ? (bool? enabled) async {
                    if (!demoModeDialog(ref, context)) return;

                    HapticFeedback.lightImpact();
                    if (enabled == null) return;

                    prefsNotifier.setDeezerThumbnails(enabled);
                  }
                : null,
          ),

          // Тексты песен через LRCLIB.
          SwitchListTile(
            secondary: const Icon(
              Icons.lyrics_outlined,
            ),
            title: Text(
              l18n.lrclib_lyrics,
            ),
            subtitle: Text(
              l18n.lrclib_lyrics_desc,
            ),
            value: preferences.lrcLibEnabled,
            onChanged: (bool? enabled) async {
              if (!demoModeDialog(ref, context)) return;

              HapticFeedback.lightImpact();
              if (enabled == null) return;

              prefsNotifier.setLRCLIBEnabled(enabled);
            },
          ),

          // Анимированные обложки Apple Music.
          SwitchListTile(
            secondary: const Icon(
              Icons.slow_motion_video,
            ),
            title: Text(
              l18n.apple_music_animated_covers,
            ),
            subtitle: Text(
              l18n.apple_music_animated_covers_desc,
            ),
            value: preferences.appleMusicAnimatedCovers,
            onChanged: recommendationsConnected
                ? (bool? enabled) async {
                    if (!demoModeDialog(ref, context)) return;

                    HapticFeedback.lightImpact();
                    if (enabled == null) return;

                    prefsNotifier.setAppleMusicAnimatedCovers(enabled);
                  }
                : null,
          ),

          // Данный Gap нужен, что бы плеер снизу при Mobile Layout'е не закрывал ничего важного.
          if (player.isLoaded && mobileLayout)
            const Gap(MusicPlayerWidget.mobileHeightWithPadding),
        ],
      ),
    );
  }
}
