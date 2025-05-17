import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:gap/gap.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:share_plus/share_plus.dart";

import "../../provider/l18n.dart";
import "../../provider/player.dart";
import "../../provider/playlists.dart";
import "../../provider/user.dart";
import "../../utils.dart";
import "../../widgets/audio_player.dart";
import "../../widgets/dialogs.dart";
import "../profile.dart";

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
        .map(
          (ExtendedAudio audio) => audio.fullArtistTitle(divider: "•"),
        )
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
          onPressed: () => Navigator.of(context).pop(),
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

/// Route для работы над данными пользователя.
/// Пользователь может попасть в этот раздел через [ProfileRoute], нажав на "Другие настройки".
///
/// go_route: `/profile/settings/data_control`
class SettingsDataControlRoute extends HookConsumerWidget {
  const SettingsDataControlRoute({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);

    final player = ref.read(playerProvider);
    ref.watch(playerIsLoadedProvider);

    final mobileLayout = isMobileLayout(context);

    void onSettingsExportTap() {
      if (!demoModeDialog(ref, context)) return;

      context.go("/profile/settings_exporter");
    }

    void onSettingsImportTap() {
      if (!demoModeDialog(ref, context)) return;

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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l18n.data_control,
        ),
      ),
      body: ListView(
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
