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
      title: l18n.export_music_list,
      text: l18n.export_music_list_desc(
        count: playlist.count!,
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
            l18n.general_share,
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

    void onSettingsExportTap() {
      context.go("/profile/settings_exporter");
    }

    void onSettingsImportTap() {
      context.go("/profile/settings_importer");
    }

    void onAudiosListExportTap() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return const ExportTracksListDialog();
        },
      );
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

        // Экспорт списка треков.
        ListTile(
          leading: const Icon(
            Icons.my_library_music,
          ),
          title: Text(
            l18n.export_music_list,
          ),
          onTap: onAudiosListExportTap,
        ),

        // Сбросить базу данных.
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
      ],
    );
  }
}
