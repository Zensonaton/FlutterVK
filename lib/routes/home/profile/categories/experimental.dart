import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../../../../provider/auth.dart";
import "../../../../provider/l18n.dart";
import "../../../../provider/preferences.dart";
import "../../../../utils.dart";
import "../../../../widgets/dialogs.dart";
import "../../../../widgets/profile_category.dart";
import "../../profile.dart";

/// Раздел настроек для страницы профиля ([HomeProfilePage]), отвечающий за экспериментальные настройки.
class ProfileExperimentalSettingsCategory extends ConsumerWidget {
  const ProfileExperimentalSettingsCategory({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);

    final mobileLayout = isMobileLayout(context);

    final preferences = ref.watch(preferencesProvider);
    final prefsNotifier = ref.read(preferencesProvider.notifier);

    final recommendationsConnected = ref.watch(secondaryTokenProvider) != null;

    return ProfileSettingCategory(
      icon: Icons.science,
      title: l18n.experimental_options,
      centerTitle: mobileLayout,
      padding: EdgeInsets.only(
        top: mobileLayout ? 0 : 8,
      ),
      children: [
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
      ],
    );
  }
}
