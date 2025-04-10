import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../../../enums.dart";
import "../../../provider/auth.dart";
import "../../../provider/l18n.dart";
import "../../../provider/preferences.dart";
import "../../../services/logger.dart";
import "../../../utils.dart";
import "../../../widgets/dialogs.dart";
import "../../../widgets/profile_category.dart";
import "../../profile.dart";

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

/// Раздел настроек для страницы профиля ([ProfileRoute]), отвечающий за настройки приложения Flutter VK.
class ProfileAppSettingsCategory extends HookConsumerWidget {
  const ProfileAppSettingsCategory({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);
    final preferences = ref.watch(preferencesProvider);
    final isDemo = ref.watch(isDemoProvider);

    final mobileLayout = isMobileLayout(context);

    final logExists = useFuture(
      useMemoized(
        () async {
          if (isWeb) return false;

          return (await logFilePath()).existsSync();
        },
      ),
    );

    void onSettingsExportTap() {
      if (!demoModeDialog(ref, context)) return;

      context.go("/profile/settings_exporter");
    }

    void onSettingsImportTap() {
      if (!demoModeDialog(ref, context)) return;

      context.go("/profile/settings_importer");
    }

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

    return ProfileSettingCategory(
      icon: Icons.settings,
      title: l18n.app_settings,
      centerTitle: mobileLayout,
      padding: EdgeInsets.only(
        top: mobileLayout ? 0 : 8,
      ),
      children: [
        // Экспорт настроек.
        ListTile(
          leading: const Icon(
            Icons.file_upload_outlined,
          ),
          title: Text(
            l18n.export_settings,
          ),
          subtitle: Text(
            l18n.export_settings_desc,
          ),
          onTap: onSettingsExportTap,
        ),

        // Импорт настроек.
        ListTile(
          leading: const Icon(
            Icons.file_download_outlined,
          ),
          title: Text(
            l18n.import_settings,
          ),
          subtitle: Text(
            l18n.import_settings_desc,
          ),
          onTap: onSettingsImportTap,
        ),

        // Сбросить базу данных.
        if (!isWeb)
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
          enabled: !isDemo && preferences.updatePolicy != UpdatePolicy.disabled,
          settingText: {
            UpdateBranch.releasesOnly: l18n.updates_channel_releases,
            UpdateBranch.preReleases: l18n.updates_channel_prereleases,
          }[preferences.updateBranch]!,
        ),

        // Поделиться логами.
        if (!isWeb)
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

        // TODO: Проверить на наличие обновлений.
      ],
    );
  }
}
