import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:gap/gap.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../../provider/l18n.dart";
import "../../provider/player.dart";
import "../../provider/preferences.dart";
import "../../services/logger.dart";
import "../../utils.dart";
import "../../widgets/audio_player.dart";
import "../../widgets/dialogs.dart";
import "../profile.dart";

/// Route для отображения различного функционала и инструментария, предназначенных для отладки приложения.
/// Пользователь может попасть в этот раздел через [ProfileRoute], нажав на "Debugging options".
///
/// go_route: `/profile/settings/debug`
class SettingsDebugRoute extends HookConsumerWidget {
  const SettingsDebugRoute({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);
    final player = ref.read(playerProvider);
    ref.watch(playerIsLoadedProvider);

    final preferences = ref.watch(preferencesProvider);
    final prefsNotifier = ref.read(preferencesProvider.notifier);

    final mobileLayout = isMobileLayout(context);

    final logExists = useFuture(
      useMemoized(
        () async {
          if (isWeb) return false;

          return (await logFilePath()).existsSync();
        },
      ),
    );

    void onDBResetTap() async {
      final result = await showYesNoDialog(
        context,
        icon: Icons.delete,
        title: l18n.reset_db_dialog,
        description: l18n.reset_db_dialog_desc,
        yesText: l18n.general_reset,
      );
      if (result != true || !context.mounted) return;

      showWipDialog(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Отладка", // TODO: INTL
        ),
      ),
      body: ListView(
        children: [
          // Debug-логирование плеера.
          SwitchListTile(
            secondary: const Icon(
              Icons.build,
            ),
            title: Text(
              l18n.player_debug_logging,
            ),
            subtitle: Text(
              l18n.player_debug_logging_desc,
            ),
            value: preferences.debugPlayerLogging,
            onChanged: (bool? enabled) async {
              HapticFeedback.lightImpact();
              if (enabled == null) return;

              prefsNotifier.setDebugPlayerLogging(enabled);
              player.setDebugLoggingEnabled(enabled);

              // Отображаем уведомление о необходимости в перезагрузки приложения.
              final messenger = ScaffoldMessenger.of(context);
              if (enabled) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      l18n.app_restart_required,
                    ),
                  ),
                );
              } else {
                messenger.hideCurrentSnackBar();
              }
            },
          ),

          // Поделиться логами.
          if (!isWeb || kDebugMode)
            ListTile(
              leading: const Icon(
                Icons.bug_report,
              ),
              title: Text(
                l18n.share_logs,
              ),
              enabled: logExists.data ?? false,
              subtitle: Text(
                logExists.data ?? false
                    ? l18n.share_logs_desc
                    : l18n.share_logs_desc_no_logs,
              ),
              onTap: shareLogs,
            ),

          // Сбросить базу треков.
          if (!isWeb || kDebugMode)
            ListTile(
              leading: const Icon(
                Icons.delete,
              ),
              title: Text(
                l18n.reset_db,
              ),
              subtitle: Text(
                l18n.reset_db_desc,
              ),
              onTap: onDBResetTap,
            ),

          // Данный Gap нужен, что бы плеер снизу при Mobile Layout'е не закрывал ничего важного.
          if (player.isLoaded && mobileLayout)
            const Gap(MusicPlayerWidget.mobileHeightWithPadding),
        ],
      ),
    );
  }
}
