import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:gap/gap.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:url_launcher/url_launcher.dart";

import "../../consts.dart";
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

/// Route для отображения информации о приложении.
/// Пользователь может попасть в этот раздел через [ProfileRoute], нажав на "О Flutter VK".
///
/// go_route: `/profile/settings/about`
class SettingsAboutRoute extends ConsumerWidget {
  const SettingsAboutRoute({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);
    final player = ref.read(playerProvider);
    ref.watch(playerIsLoadedProvider);
    final mobileLayout = isMobileLayout(context);
    final preferences = ref.watch(preferencesProvider);
    final isDemo = ref.watch(isDemoProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l18n.about_flutter_vk,
        ),
      ),
      body: ListView(
        children: [
          // Telegram-канал.
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

          // Исходный код проекта.
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
              Icons.info,
            ),
            title: Text(
              l18n.app_version,
            ),
            subtitle: Text(
              l18n.app_version_desc(
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
