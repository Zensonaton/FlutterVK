import "dart:io";

import "package:cancellation_token/cancellation_token.dart";
import "package:file_picker/file_picker.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:gap/gap.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:styled_text/tags/styled_text_tag_action.dart";
import "package:styled_text/tags/styled_text_tag_icon.dart";
import "package:styled_text/widgets/styled_text.dart";

import "../../provider/l18n.dart";
import "../../provider/player.dart";
import "../../provider/playlists.dart";
import "../../provider/settings_exporter_importer.dart";
import "../../provider/user.dart";
import "../../services/logger.dart";
import "../../utils.dart";
import "../../widgets/audio_player.dart";
import "../../widgets/dialogs.dart";
import "../../widgets/tip_widget.dart";
import "settings_exporter.dart";

/// Route для импорта изменений, вызванных функцией "экспорт локальных изменений" в профиле.
///
/// go_route: `/profile/settings_importer`.
class SettingsImporterRoute extends HookConsumerWidget {
  static final AppLogger logger = getLogger("SettingsImporterRoute");

  /// Длительность анимации прогресса импорта.
  static const Duration progressAnimationDuration = Duration(milliseconds: 500);

  const SettingsImporterRoute({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);
    final player = ref.read(playerProvider);
    final user = ref.watch(userProvider);

    final mobileLayout = isMobileLayout(context);

    final cancellationToken = useMemoized(
      () => CancellationToken(),
    );
    useEffect(
      () {
        return () {
          logger.d("Cancelling import...");

          cancellationToken.cancel();
        };
      },
      [],
    );

    final exportedSettingsFile = useState<File?>(null);
    final loadedSectionsInfo = useState<ExportedAudiosInfoMetadata?>(null);

    final enabledSections = useState<Set<String>>({});
    final isImportInProgress = useState(false);

    final animatedImportProgress = useAnimationController();
    useValueListenable(animatedImportProgress);

    final animatedExportProgressOpacity = useAnimationController(
      duration: progressAnimationDuration,
    );
    useEffect(
      () {
        animatedExportProgressOpacity.animateTo(
          animatedImportProgress.value > 0.0 &&
                  animatedImportProgress.value < 1.0
              ? 1.0
              : 0.0,
          curve: Curves.ease,
        );

        return null;
      },
      [animatedImportProgress.value],
    );
    useValueListenable(animatedExportProgressOpacity);

    void onFileSelectTap() async {
      try {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          dialogTitle: l18n.settings_import_select_file_dialog_title,
          type: isWindows ? FileType.custom : FileType.any,
          allowedExtensions: isWindows ? ["fluttervk"] : null,
          lockParentWindow: true,
        );
        if (result == null) return;

        // Импортируем файл.
        final file = File(result.files.single.path!);
        final loadedSections =
            await ref.read(settingsExporterProvider).loadSectionsData(
                  userID: user.id,
                  exportedFile: file,
                );

        // Делаем предупреждение, если текущая версия Flutter VK новее, чем версия файла.
        if (!context.mounted) return;
        if (loadedSections.exporterVersion < SettingsExporter.exporterVersion) {
          final result = await showYesNoDialog(
            context,
            title: l18n.settings_import_version_missmatch,
            description: l18n.settings_import_version_missmatch_desc(
              version: loadedSections.appVersion,
            ),
          );

          if (!(result ?? false)) return;
        }

        loadedSectionsInfo.value = loadedSections;
        exportedSettingsFile.value = file;
        enabledSections.value = loadedSections.sections.toJson().keys.toSet();
      } catch (error, stackTrace) {
        showLogErrorDialog(
          "Error while selecting file for import",
          error,
          stackTrace,
          logger,
          // ignore: use_build_context_synchronously
          context,
        );
      }
    }

    void onImportTap() async {
      if (isImportInProgress.value) return;
      if (loadedSectionsInfo.value == null) return;

      final importer = ref.read(settingsExporterProvider);

      final sectionsList = enabledSections.value.toList();
      final settings = sectionsList.contains("settings");
      final modifiedThumbnails = sectionsList.contains("modifiedThumbnails");
      final modifiedLyrics = sectionsList.contains("modifiedLyrics");
      final modifiedLocalMetadata =
          sectionsList.contains("modifiedLocalMetadata");
      final cachedRestricted = sectionsList.contains("cachedRestricted");
      final locallyReplacedAudios =
          sectionsList.contains("locallyReplacedAudios");

      isImportInProgress.value = true;
      animatedImportProgress.value = 0.0;
      List<ExtendedPlaylist>? modifiedPlaylists;
      try {
        modifiedPlaylists = await importer.import(
          userID: user.id,
          exportedFile: exportedSettingsFile.value!,
          exportedMetadata: loadedSectionsInfo.value!,
          settings: settings,
          modifiedThumbnails: modifiedThumbnails,
          modifiedLyrics: modifiedLyrics,
          modifiedLocalMetadata: modifiedLocalMetadata,
          cachedRestricted: cachedRestricted,
          locallyReplacedAudios: locallyReplacedAudios,
          cancellationToken: cancellationToken,
          onProgress: (progress) {
            animatedImportProgress.animateTo(
              progress,
              duration: progressAnimationDuration,
              curve: Curves.ease,
            );
          },
        );
      } catch (error, stackTrace) {
        showLogErrorDialog(
          "Error while importing settings (selected sections: $sectionsList):",
          error,
          stackTrace,
          logger,
          // ignore: use_build_context_synchronously
          context,
        );

        if (context.mounted) {
          animatedImportProgress.value = 0.0;
        }

        return;
      } finally {
        if (context.mounted) {
          isImportInProgress.value = false;
        }
      }
      if (!context.mounted) return;

      // Если импорт завершился успешно, то запускаем кэширование изменённых плейлистов,
      // а потом показываем диалог об успешном импорте.
      for (ExtendedPlaylist playlist in modifiedPlaylists) {
        createPlaylistCacheTask(
          importer.ref,
          playlist,
        );
      }

      final exportedFile = exportedSettingsFile.value!;
      exportedSettingsFile.value = null;
      loadedSectionsInfo.value = null;

      final result = await showYesNoDialog(
        context,
        icon: Icons.file_download_outlined,
        title: l18n.settings_import_success,
        description: isAndroid
            ? l18n.settings_import_success_desc_no_delete
            : l18n.settings_import_success_desc_with_delete,
      );

      // Если мы на OS Android, то удаляем файл несмотря на ответ, поскольку он находится в кэше.
      if (isAndroid || result == true) {
        try {
          if (exportedFile.existsSync()) {
            await exportedFile.delete();
          }
        } catch (error, stackTrace) {
          logger.e(
            "Error while deleting exported file ${exportedSettingsFile.value!.path}:",
            error: error,
            stackTrace: stackTrace,
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l18n.settings_import,
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Содержимое.
          ListView(
            padding: EdgeInsets.all(
              mobileLayout ? 16 : 24,
            ),
            children: [
              // Подсказка.
              TipWidget(
                iconOnTop: true,
                title: l18n.settings_import_tip,
                descriptionWidget: StyledText(
                  text: l18n.settings_import_tip_desc,
                  tags: {
                    "exportSettingsIcon": StyledTextIconTag(
                      Icons.file_upload_outlined,
                      size: 20,
                    ),
                    "exportSettings": StyledTextActionTag(
                      (String? text, Map<String?, String?> attrs) {
                        context.push("/profile/settings_exporter");
                      },
                      style: TextStyle(
                        color: ColorScheme.of(context).primary,
                      ),
                    ),
                  },
                ),
              ),
              Gap(mobileLayout ? 16 : 24),

              // Поле для выбора файла, если он ещё не загружен.
              if (loadedSectionsInfo.value == null)
                TipWidget(
                  iconOnTop: true,
                  icon: Icons.file_download_off_outlined,
                  description: l18n.settings_import_select_file,
                  actions: [
                    FilledButton.icon(
                      icon: const Icon(
                        Icons.file_download_outlined,
                      ),
                      label: Text(
                        l18n.general_select,
                      ),
                      onPressed: onFileSelectTap,
                    ),
                  ],
                ),

              // Поле для выбора секций, если файл загружен, а так же кнопка для импорта.
              if (loadedSectionsInfo.value != null) ...[
                // Выбор для секций.
                SettingsExporterSelector(
                  enabledSections: enabledSections.value,
                  sectionsInfo: loadedSectionsInfo.value!.sections,
                  disabled: isImportInProgress.value,
                  onSectionsChanged: (value) => enabledSections.value = value,
                ),
                Gap(mobileLayout ? 16 : 24),

                // Кнопка импорта.
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    icon: isImportInProgress.value
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator.adaptive(
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Icon(
                            Icons.file_download_outlined,
                          ),
                    label: Text(
                      l18n.settings_import_import,
                    ),
                    onPressed: enabledSections.value.isNotEmpty &&
                            !isImportInProgress.value
                        ? onImportTap
                        : null,
                  ),
                ),
              ],

              // Данный Gap нужен, что бы плеер снизу при Mobile Layout'е не закрывал ничего важного.
              if (player.isLoaded && mobileLayout)
                const Gap(MusicPlayerWidget.mobileHeightWithPadding),
            ],
          ),

          // Прогресс экспорта.
          if (animatedExportProgressOpacity.value > 0.0)
            Opacity(
              opacity: animatedExportProgressOpacity.value,
              child: LinearProgressIndicator(
                value: animatedImportProgress.value,
                minHeight: 3,
              ),
            ),
        ],
      ),
    );
  }
}
