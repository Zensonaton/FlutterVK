import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:url_launcher/url_launcher.dart";

import "../../../../consts.dart";
import "../../../../enums.dart";
import "../../../../main.dart";
import "../../../../provider/l18n.dart";
import "../../../../provider/preferences.dart";
import "../../../../provider/updater.dart";
import "../../../../services/logger.dart";
import "../../../../utils.dart";
import "../../../../widgets/dialogs.dart";
import "../../../../widgets/profile_category.dart";
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
          title: l18n.profile_disableUpdatesWarningTitle,
          description: l18n.profile_disableUpdatesWarningDescription,
          yesText: l18n.profile_disableUpdatesWarningDisable,
        );

        // Пользователь нажал на "Отключить", тогда мы должны выключить обновления.
        if (result == true && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l18n.profile_updatesDisabledText,
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
      title: l18n.profile_updatesPolicyTitle,
      contents: [
        RadioListTile.adaptive(
          title: Text(
            l18n.profile_updatesPolicyDialog,
          ),
          value: UpdatePolicy.dialog,
          groupValue: preferences.updatePolicy,
          onChanged: onValueChanged,
        ),
        RadioListTile.adaptive(
          title: Text(
            l18n.profile_updatesPolicyPopup,
          ),
          value: UpdatePolicy.popup,
          groupValue: preferences.updatePolicy,
          onChanged: onValueChanged,
        ),
        RadioListTile.adaptive(
          title: Text(
            l18n.profile_updatesPolicyDisabled,
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
      title: l18n.profile_updatesBranchTitle,
      contents: [
        RadioListTile.adaptive(
          title: Text(
            l18n.profile_updatesBranchReleases,
          ),
          value: UpdateBranch.releasesOnly,
          groupValue: preferences.updateBranch,
          onChanged: onValueChanged,
        ),
        RadioListTile.adaptive(
          title: Text(
            l18n.profile_updatesBranchPrereleases,
          ),
          value: UpdateBranch.preReleases,
          groupValue: preferences.updateBranch,
          onChanged: onValueChanged,
        ),
      ],
    );
  }
}

/// Раздел настроек для страницы профиля ([HomeProfilePage]), отвечающий за раздел "О Flutter VK".
class ProfileAboutSettingsCategory extends HookConsumerWidget {
  const ProfileAboutSettingsCategory({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);

    final mobileLayout = isMobileLayout(context);

    final logExists = useFuture(
      useMemoized(
        () async => (await logFilePath()).existsSync(),
      ),
    );

    final preferences = ref.watch(preferencesProvider);

    return ProfileSettingCategory(
      icon: Icons.info,
      title: l18n.profile_aboutTitle,
      centerTitle: mobileLayout,
      padding: EdgeInsets.only(
        top: mobileLayout ? 0 : 8,
      ),
      children: [
        // Поделиться логами.
        ListTile(
          leading: const Icon(
            Icons.bug_report,
          ),
          title: Text(
            l18n.profile_shareLogsTitle,
          ),
          enabled: logExists.data ?? false,
          subtitle: Text(
            logExists.data ?? false
                ? l18n.profile_shareLogsDescription
                : l18n.profile_shareLogsNoLogsDescription,
          ),
          onTap: shareLogs,
        ),

        // Github.
        ListTile(
          leading: const Icon(
            Icons.source,
          ),
          title: Text(
            l18n.profile_githubTitle,
          ),
          subtitle: Text(
            l18n.profile_githubDescription,
          ),
          onTap: () => launchUrl(
            Uri.parse(repoURL),
          ),
        ),

        // Политика для обновлений.
        SettingWithDialog(
          icon: Icons.update,
          title: l18n.profile_updatesPolicyTitle,
          subtitle: l18n.profile_updatesPolicyDescription,
          dialog: const UpdatesDialogTypeActionDialog(),
          settingText: {
            UpdatePolicy.dialog: l18n.profile_updatesPolicyDialog,
            UpdatePolicy.popup: l18n.profile_updatesPolicyPopup,
            UpdatePolicy.disabled: l18n.profile_updatesPolicyDisabled,
          }[preferences.updatePolicy]!,
        ),

        // Канал для автообновлений.
        SettingWithDialog(
          icon: Icons.route,
          title: l18n.profile_updatesBranchTitle,
          subtitle: l18n.profile_updatesBranchDescription,
          dialog: const UpdatesChannelDialog(),
          enabled: preferences.updatePolicy != UpdatePolicy.disabled,
          settingText: {
            UpdateBranch.releasesOnly: l18n.profile_updatesBranchReleases,
            UpdateBranch.preReleases: l18n.profile_updatesBranchPrereleases,
          }[preferences.updateBranch]!,
        ),

        // Список изменений этой версии.
        ListTile(
          leading: const Icon(
            Icons.article,
          ),
          title: Text(
            l18n.profile_showChangelogTitle,
          ),
          subtitle: Text(
            l18n.profile_showChangelogDescription,
          ),
          onTap: () async {
            if (!networkRequiredDialog(ref, context)) return;

            await ref.read(updaterProvider).showChangelog(context);
          },
        ),

        // Версия приложения (и проверка текущей версии).
        ListTile(
          leading: const Icon(
            Icons.info,
          ),
          title: Text(
            l18n.profile_appVersionTitle,
          ),
          subtitle: Text(
            l18n.profile_appVersionDescription(
              "v$appVersion${kDebugMode ? " (Debug)" : isPrerelease ? " (${l18n.profile_appVersionPreRelease})" : ""}",
            ),
          ),
          onTap: () async {
            if (!networkRequiredDialog(ref, context)) return;

            await ref.read(updaterProvider).checkForUpdates(
                  context,
                  allowPre:
                      preferences.updateBranch == UpdateBranch.preReleases,
                  showMessageOnNoUpdates: true,
                );
          },
        ),
      ],
    );
  }
}
