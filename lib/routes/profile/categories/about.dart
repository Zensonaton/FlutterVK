import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:url_launcher/url_launcher.dart";

import "../../../consts.dart";
import "../../../enums.dart";
import "../../../main.dart";
import "../../../provider/auth.dart";
import "../../../provider/l18n.dart";
import "../../../provider/preferences.dart";
import "../../../provider/updater.dart";
import "../../../utils.dart";
import "../../../widgets/dialogs.dart";
import "../../../widgets/profile_category.dart";
import "../../profile.dart";

/// Раздел настроек для страницы профиля ([ProfileRoute]), отвечающий за раздел "О Flutter VK".
class ProfileAboutSettingsCategory extends HookConsumerWidget {
  const ProfileAboutSettingsCategory({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);
    final preferences = ref.watch(preferencesProvider);
    final isDemo = ref.watch(isDemoProvider);

    final mobileLayout = isMobileLayout(context);

    return ProfileSettingCategory(
      icon: Icons.info,
      title: l18n.about_flutter_vk,
      centerTitle: mobileLayout,
      padding: EdgeInsets.only(
        top: mobileLayout ? 0 : 8,
      ),
      children: [
        // Telegram.
        ListTile(
          leading: const Icon(
            Icons.telegram,
          ),
          title: Text(
            l18n.app_telegram,
          ),
          subtitle: Text(
            l18n.app_telegram_desc,
          ),
          onTap: () => launchUrl(
            Uri.parse(telegramURL),
          ),
        ),

        // Github.
        ListTile(
          leading: const Icon(
            Icons.source,
          ),
          title: Text(
            l18n.app_github,
          ),
          subtitle: Text(
            l18n.app_github_desc,
          ),
          onTap: () => launchUrl(
            Uri.parse(repoURL),
          ),
        ),

        // Список изменений этой версии.
        if (!isDemo)
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

        // Версия приложения (и проверка текущей версии).
        ListTile(
          leading: const Icon(
            Icons.info,
          ),
          title: Text(
            l18n.app_version,
          ),
          subtitle: Text(
            l18n.app_version_desc(
              version:
                  "v$appVersion${kDebugMode ? " (Debug)" : isPrerelease ? " (${l18n.app_version_prerelease})" : ""}",
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
      ],
    );
  }
}
