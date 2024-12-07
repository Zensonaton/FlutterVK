import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:share_plus/share_plus.dart";

import "../../../../provider/auth.dart";
import "../../../../provider/l18n.dart";
import "../../../../provider/playlists.dart";
import "../../../../provider/preferences.dart";
import "../../../../provider/user.dart";
import "../../../../utils.dart";
import "../../../../widgets/dialogs.dart";
import "../../../../widgets/profile_category.dart";
import "../../profile.dart";

/// Диалог, отображающий пользователю информацию об экспортированном списке треков.
///
/// Пример использования:
/// ```dart
/// showDialog(
/// 	context: context,
/// 	builder: (context) => const ExportTracksListDialog()
/// );
/// ```
class ExportTracksListDialog extends ConsumerWidget {
  const ExportTracksListDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);
    final playlist = ref.watch(favoritesPlaylistProvider);
    if (playlist?.audios == null) {
      throw Exception("Expected tracks list to be loaded");
    }

    final String exportContents = playlist!.audios!
        .map((ExtendedAudio audio) => "${audio.artist} • ${audio.title}")
        .join("\n\n");

    return MaterialDialog(
      icon: Icons.my_library_music,
      title: l18n.profile_exportMusicListTitle,
      text: l18n.profile_exportMusicListDescription(
        playlist.count!,
      ),
      contents: [
        SelectableText(
          exportContents,
        ),
      ],
      actions: [
        // Закрыть.
        TextButton(
          onPressed: () => context.pop(),
          child: Text(
            l18n.general_close,
          ),
        ),

        // Поделиться.
        FilledButton.icon(
          onPressed: () => Share.share(exportContents),
          icon: const Icon(
            Icons.share,
          ),
          label: Text(
            l18n.profile_exportMusicListShareTitle,
          ),
        ),
      ],
    );
  }
}

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
      title: l18n.profile_experimentalTitle,
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
            l18n.profile_deezerThumbnailsTitle,
          ),
          subtitle: Text(
            l18n.profile_deezerThumbnailsDescription,
          ),
          value: preferences.deezerThumbnails,
          onChanged: recommendationsConnected
              ? (bool? enabled) async {
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
            l18n.profile_LRCLibLyricsTitle,
          ),
          subtitle: Text(
            l18n.profile_LRCLibLyricsDescription,
          ),
          value: preferences.lrcLibEnabled,
          onChanged: (bool? enabled) async {
            HapticFeedback.lightImpact();
            if (enabled == null) return;

            prefsNotifier.setLRCLIBEnabled(enabled);
          },
        ),

        // Экспорт настроек.
        ListTile(
          leading: const Icon(
            Icons.file_upload_outlined,
          ),
          title: Text(
            l18n.profile_exportModificationsTitle,
          ),
          subtitle: Text(
            l18n.profile_exportModificationsDescription,
          ),
          onTap: () {
            context.go("/profile/settings_exporter");
          },
        ),

        // Импорт настроек.
        ListTile(
          leading: const Icon(
            Icons.file_download_outlined,
          ),
          title: Text(
            l18n.profile_importModificationsTitle,
          ),
          subtitle: Text(
            l18n.profile_importModificationsDescription,
          ),
          onTap: () => context.go("/profile/settings_importer"),
        ),

        // Экспорт списка треков.
        ListTile(
          leading: const Icon(
            Icons.my_library_music,
          ),
          title: Text(
            l18n.profile_exportMusicListTitle,
          ),
          onTap: () => showDialog(
            context: context,
            builder: (BuildContext context) {
              return const ExportTracksListDialog();
            },
          ),
        ),
      ],
    );
  }
}
