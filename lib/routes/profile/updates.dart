import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:gap/gap.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../../enums.dart";
import "../../provider/auth.dart";
import "../../provider/l18n.dart";
import "../../provider/player.dart";
import "../../provider/preferences.dart";
import "../../provider/updater.dart";
import "../../utils.dart";
import "../../widgets/audio_player.dart";
import "../../widgets/dialogs.dart";
import "../profile.dart";

/// Диалог, помогающий пользователю поменять настройку "Отображение новых обновлений".
///
/// Пример использования:
/// ```dart
/// showDialog(
/// 	context: context,
/// 	builder: (context) => const UpdatesDialogTypeActionDialog()
/// );
/// ```
class UpdatesDialogTypeActionDialog extends ConsumerWidget {
  const UpdatesDialogTypeActionDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsNotifier = ref.read(preferencesProvider.notifier);
    final preferences = ref.watch(preferencesProvider);
    final l18n = ref.watch(l18nProvider);

    void onValueChanged(UpdatePolicy? policy) async {
      HapticFeedback.lightImpact();
      if (policy == null) return;

      // Делаем небольшое предупреждение, если пользователь пытается отключить обновления.
      if (policy == UpdatePolicy.disabled) {
        final result = await showYesNoDialog(
          context,
          icon: Icons.update_disabled,
          title: l18n.disable_updates_warning,
          description: l18n.disable_updates_warning_desc,
          yesText: l18n.disable_updates_warning_disable,
        );

        // Пользователь нажал на "Отключить", тогда мы должны выключить обновления.
        if (result == true && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l18n.updates_are_disabled,
              ),
              duration: const Duration(
                seconds: 8,
              ),
            ),
          );
        }

        // Пользователь отказался отключать уведомления, тогда ничего не меняем.
        if (result != true) return;
      }

      prefsNotifier.setUpdatePolicy(policy);
    }

    return MaterialDialog(
      icon: Icons.update,
      title: l18n.app_updates_policy,
      contents: [
        RadioListTile.adaptive(
          title: Text(
            l18n.app_updates_policy_dialog,
          ),
          value: UpdatePolicy.dialog,
          groupValue: preferences.updatePolicy,
          onChanged: onValueChanged,
        ),
        RadioListTile.adaptive(
          title: Text(
            l18n.app_updates_policy_popup,
          ),
          value: UpdatePolicy.popup,
          groupValue: preferences.updatePolicy,
          onChanged: onValueChanged,
        ),
        RadioListTile.adaptive(
          title: Text(
            l18n.app_updates_policy_disabled,
          ),
          value: UpdatePolicy.disabled,
          groupValue: preferences.updatePolicy,
          onChanged: onValueChanged,
        ),
      ],
    );
  }
}

/// Диалог, помогающий пользователю поменять настройку "Канал обновлений".
///
/// Пример использования:
/// ```dart
/// showDialog(
/// 	context: context,
/// 	builder: (context) => const UpdatesChannelDialog()
/// );
/// ```
class UpdatesChannelDialog extends ConsumerWidget {
  const UpdatesChannelDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsNotifier = ref.read(preferencesProvider.notifier);
    final preferences = ref.watch(preferencesProvider);
    final l18n = ref.watch(l18nProvider);

    void onValueChanged(UpdateBranch? branch) {
      HapticFeedback.lightImpact();
      if (branch == null) return;

      prefsNotifier.setUpdateBranch(branch);
    }

    return MaterialDialog(
      icon: Icons.route,
      title: l18n.updates_channel,
      contents: [
        RadioListTile.adaptive(
          title: Text(
            l18n.updates_channel_releases,
          ),
          value: UpdateBranch.releasesOnly,
          groupValue: preferences.updateBranch,
          onChanged: onValueChanged,
        ),
        RadioListTile.adaptive(
          title: Text(
            l18n.updates_channel_prereleases,
          ),
          value: UpdateBranch.preReleases,
          groupValue: preferences.updateBranch,
          onChanged: onValueChanged,
        ),
      ],
    );
  }
}

/// Route для управления настройками обновления приложения.
/// Пользователь может попасть в этот раздел через [ProfileRoute], нажав на "Обновления".
///
/// go_route: `/profile/settings/updates`
class SettingsUpdatesRoute extends ConsumerWidget {
  const SettingsUpdatesRoute({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);
    final preferences = ref.watch(preferencesProvider);
    final isDemo = ref.watch(isDemoProvider);
    final player = ref.read(playerProvider);
    final mobileLayout = isMobileLayout(context);
    ref.watch(playerIsLoadedProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l18n.updates,
        ),
      ),
      body: ListView(
        children: [
          // Политика для обновлений.
          SettingWithDialog(
            icon: Icons.update,
            title: l18n.app_updates_policy,
            subtitle: l18n.app_updates_policy_desc,
            dialog: const UpdatesDialogTypeActionDialog(),
            enabled: !isDemo,
            settingText: {
              UpdatePolicy.dialog: l18n.app_updates_policy_dialog,
              UpdatePolicy.popup: l18n.app_updates_policy_popup,
              UpdatePolicy.disabled: l18n.app_updates_policy_disabled,
            }[preferences.updatePolicy]!,
          ),

          // Канал для автообновлений.
          SettingWithDialog(
            icon: Icons.route,
            title: l18n.updates_channel,
            subtitle: l18n.updates_channel_desc,
            dialog: const UpdatesChannelDialog(),
            enabled:
                !isDemo && preferences.updatePolicy != UpdatePolicy.disabled,
            settingText: {
              UpdateBranch.releasesOnly: l18n.updates_channel_releases,
              UpdateBranch.preReleases: l18n.updates_channel_prereleases,
            }[preferences.updateBranch]!,
          ),

          // Список изменений.
          if (!isDemo || kDebugMode)
            ListTile(
              leading: const Icon(
                Icons.history,
              ),
              title: Text(
                l18n.show_changelog,
              ),
              subtitle: Text(
                l18n.show_changelog_desc,
              ),
              onTap: () async {
                if (!networkRequiredDialog(ref, context)) return;

                await ref.read(updaterProvider).showChangelog(context);
              },
            ),

          // О приложении.
          ListTile(
            leading: const Icon(
              Icons.security_update_good,
            ),
            title: Text(
              l18n.force_update_check,
            ),
            subtitle: Text(
              l18n.force_update_check_desc(
                version: getAppVersion(l18n),
              ),
            ),
            onTap: () async {
              if (!demoModeDialog(ref, context)) return;
              if (!networkRequiredDialog(ref, context)) return;

              await ref.read(updaterProvider).checkForUpdates(
                    context,
                    allowPre:
                        preferences.updateBranch == UpdateBranch.preReleases,
                    showMessageOnNoUpdates: true,
                  );
            },
          ),

          // Данный Gap нужен, что бы плеер снизу при Mobile Layout'е не закрывал ничего важного.
          if (player.isLoaded && mobileLayout)
            const Gap(MusicPlayerWidget.mobileHeightWithPadding),
        ],
      ),
    );
  }
}
