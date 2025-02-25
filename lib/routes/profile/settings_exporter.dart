import "dart:io";

import "package:cancellation_token/cancellation_token.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:gap/gap.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:path/path.dart";
import "package:path_provider/path_provider.dart";
import "package:share_plus/share_plus.dart";
import "package:styled_text/styled_text.dart";

import "../../consts.dart";
import "../../provider/l18n.dart";
import "../../provider/player.dart";
import "../../provider/playlists.dart";
import "../../provider/preferences.dart";
import "../../provider/settings_exporter_importer.dart";
import "../../provider/user.dart";
import "../../services/logger.dart";
import "../../utils.dart";
import "../../widgets/audio_player.dart";
import "../../widgets/dialogs.dart";
import "../../widgets/tip_widget.dart";
import "../music/bottom_audio_options.dart";

/// Диалог, показывающий информацию после успешного экспорта настроек.
///
/// Пример использования:
/// ```dart
/// showDialog(
/// 	context: context,
/// 	builder: (context) => const SuccessSettingsExportDialog()
/// );
/// ```
class SuccessSettingsExportDialog extends HookConsumerWidget {
  static final AppLogger logger = getLogger("SuccessSettingsExportDialog");

  /// [File], репрезентирующий файл с экспортированными данными.
  final File file;

  const SuccessSettingsExportDialog({
    super.key,
    required this.file,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);

    final copyLoadingState = useState<bool?>(null);

    void onCancelTap() => Navigator.of(context).pop();

    void onShareTap() => Share.shareXFiles(
          [XFile(file.path)],
        );

    void onCopyToDownloadsTap() async {
      copyLoadingState.value = false;

      try {
        final downloadsDir = await getDownloadsDirectory();
        if (!context.mounted) return;

        // Проверка на случай, если директория загрузок не была найдена.
        if (downloadsDir == null) {
          throw Exception("Downloads directory not found");
        }

        // Копируем файл.
        final newFile = File(
          join(
            downloadsDir.path,
            basename(
              file.path,
            ),
          ),
        );
        await file.copy(newFile.path);

        if (!context.mounted) return;

        // Показываем сообщение об успешном копировании.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l18n.copy_to_downloads_success,
            ),
          ),
        );

        copyLoadingState.value = true;
      } catch (error, stackTrace) {
        showLogErrorDialog(
          "Error while copying exported file to download directory",
          error,
          stackTrace,
          logger,
          context,
        );

        if (context.mounted) {
          copyLoadingState.value = null;
        }
      }
    }

    void onOpenFolderTap() async {
      if (!isWindows) {
        throw UnsupportedError(
          "Opening folder is only supported on Windows OS.",
        );
      }

      await Process.run(
        "explorer.exe",
        ["/select,", file.path],
      );
    }

    return MaterialDialog(
      icon: Icons.file_upload_outlined,
      title: l18n.export_settings_success,
      text: l18n.export_settings_success_desc,
      contents: [
        // "Поделиться".
        ListTile(
          title: Text(
            l18n.general_share,
          ),
          leading: const Icon(
            Icons.share,
          ),
          onTap: onShareTap,
        ),

        // "Скопировать в загрузки".
        ListTile(
          title: Text(
            l18n.general_copy_to_downloads,
          ),
          leading: () {
            // Выполняется копирование.
            if (copyLoadingState.value == false) {
              return const ListTileLoadingProgressIndicator();
            }

            // Копирование завершено.
            if (copyLoadingState.value == true) {
              return const Icon(
                Icons.check,
              );
            }

            // Начальное состояние.
            return const Icon(
              Icons.download,
            );
          }(),
          subtitle: copyLoadingState.value == true
              ? Text(
                  l18n.copy_to_downloads_success,
                )
              : null,
          onTap: copyLoadingState.value == null ? onCopyToDownloadsTap : null,
        ),

        // Открыть папку с экспортированным файлом на OS Windows.
        if (isWindows)
          ListTile(
            title: Text(
              l18n.general_open_folder,
            ),
            leading: const Icon(
              Icons.folder_open,
            ),
            onTap: onOpenFolderTap,
          ),
      ],
      actions: [
        // Отмена.
        TextButton(
          onPressed: onCancelTap,
          child: Text(
            l18n.general_close,
          ),
        ),
      ],
    );
  }
}

/// Виджет, в котором отображены параметры, которые можно экспортировать либо импортировать.
class SettingsExporterSelector extends HookConsumerWidget {
  static final AppLogger logger = getLogger("SettingsExporterSelector");

  /// Список из включённых секций.
  final Set<String> enabledSections;

  /// Информация по экспортированным секциям.
  final ExportedSections sectionsInfo;

  /// Если true, то все секции будут disabled.
  final bool disabled;

  /// Метод, вызываемый при новом списке из [enabledSections].
  final void Function(Set<String> sections) onSectionsChanged;

  const SettingsExporterSelector({
    super.key,
    required this.enabledSections,
    required this.sectionsInfo,
    this.disabled = false,
    required this.onSectionsChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);

    final exportedInfoMap = useMemoized(
      () => sectionsInfo.toJson(),
      [sectionsInfo],
    );

    SwitchListTile buildSwitchTile({
      required String key,
      required IconData icon,
      required String title,
      String Function({required int count})? subtitle,
    }) {
      final count = exportedInfoMap[key]?.length ?? 0;

      return SwitchListTile(
        secondary: Icon(
          icon,
        ),
        title: Text(
          title,
        ),
        subtitle: () {
          if (subtitle == null) return null;

          if (count == 0) {
            return Text(
              l18n.general_nothing_found,
            );
          }

          return StyledText(
            text: subtitle(count: count),
            tags: {
              "colored": StyledTextTag(
                style: TextStyle(
                  color:
                      disabled ? null : Theme.of(context).colorScheme.primary,
                ),
              ),
              "icon": StyledTextIconTag(
                icon,
                size: 20,
              ),
            },
          );
        }(),
        value: enabledSections.contains(key),
        onChanged: (!disabled && count > 0)
            ? (bool? enabled) async {
                HapticFeedback.lightImpact();
                if (enabled == null) return;

                final newSections = {...enabledSections};
                if (enabled) {
                  newSections.add(key);
                } else {
                  newSections.remove(key);
                }

                onSectionsChanged(newSections);
              }
            : null,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(
        globalBorderRadius,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            // Настройки Flutter VK.
            buildSwitchTile(
              key: "settings",
              icon: Icons.settings,
              title: l18n.export_settings_modified_settings,
              subtitle: l18n.export_settings_modified_settings_desc,
            ),

            // Изменённые обложки треков.
            buildSwitchTile(
              key: "modifiedThumbnails",
              icon: Icons.image_search,
              title: l18n.export_settings_modified_thumbnails,
              subtitle: l18n.export_settings_modified_thumbnails_desc,
            ),

            // Изменённые тексты песен.
            buildSwitchTile(
              key: "modifiedLyrics",
              icon: Icons.lyrics,
              title: l18n.export_settings_modified_lyrics,
              subtitle: l18n.export_settings_modified_lyrics_desc,
            ),

            // Изменённые параметры треков.
            buildSwitchTile(
              key: "modifiedLocalMetadata",
              icon: Icons.edit,
              title: l18n.export_settings_modified_metadata,
              subtitle: l18n.export_settings_modified_metadata_desc,
            ),

            // Кэшированные ограниченные треки.
            buildSwitchTile(
              key: "cachedRestricted",
              icon: Icons.music_off,
              title: l18n.export_settings_cached_restricted,
              subtitle: l18n.export_settings_cached_restricted_desc,
            ),

            // Локально заменённые треки.
            buildSwitchTile(
              key: "locallyReplacedAudios",
              icon: Icons.sd_card,
              title: l18n.export_settings_locally_replaced,
              subtitle: l18n.export_settings_locally_replaced_desc,
            ),
          ],
        ),
      ),
    );
  }
}

/// Route для импорта изменений, вызванных функцией "экспорт локальных изменений" в профиле.
///
/// go_route: `/profile/settings_exporter`.
class SettingsExporterRoute extends HookConsumerWidget {
  static final AppLogger logger = getLogger("SettingsExporterRoute");

  /// Длительность анимации прогресса экспорта.
  static const Duration progressAnimationDuration = Duration(milliseconds: 500);

  const SettingsExporterRoute({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);
    final player = ref.read(playerProvider);
    ref.watch(playerIsLoadedProvider);

    final mobileLayout = isMobileLayout(context);

    final user = ref.watch(userProvider);
    final playlists = ref.watch(playlistsProvider).value!;
    final preferences = ref.watch(preferencesProvider);

    final sectionsInfo = useMemoized(
      () {
        final sections =
            ref.read(settingsExporterProvider).exportSectionsData();

        logger.d("Sections info: ${sections.toJson()}");

        return sections;
      },
      [preferences, playlists],
    );
    final cancellationToken = useMemoized(
      () => CancellationToken(),
    );
    useEffect(
      () {
        return () {
          logger.d("Cancelling export...");

          cancellationToken.cancel();
        };
      },
      [],
    );

    final enabledSections = useState<Set<String>>(
      preferences.exportedSections.toSet(),
    );
    final isExportInProgress = useState(false);

    final animatedExportProgress = useAnimationController();
    useValueListenable(animatedExportProgress);

    final animatedExportProgressOpacity = useAnimationController(
      duration: progressAnimationDuration,
    );
    useEffect(
      () {
        animatedExportProgressOpacity.animateTo(
          animatedExportProgress.value > 0.0 &&
                  animatedExportProgress.value < 1.0
              ? 1.0
              : 0.0,
          curve: Curves.ease,
        );

        return null;
      },
      [animatedExportProgress.value],
    );
    useValueListenable(animatedExportProgressOpacity);

    Future<void> onExportTap() async {
      final sectionsList = enabledSections.value.toList();
      final settings = sectionsList.contains("settings");
      final modifiedThumbnails = sectionsList.contains("modifiedThumbnails");
      final modifiedLyrics = sectionsList.contains("modifiedLyrics");
      final modifiedLocalMetadata =
          sectionsList.contains("modifiedLocalMetadata");
      final cachedRestricted = sectionsList.contains("cachedRestricted");
      final locallyReplacedAudios =
          sectionsList.contains("locallyReplacedAudios");

      // Сохраняем выбор пользователя.
      ref.read(preferencesProvider.notifier).setExportedSections(sectionsList);

      isExportInProgress.value = true;
      animatedExportProgress.value = 0.0;
      File? exportedFile;
      try {
        exportedFile = await ref.read(settingsExporterProvider).export(
              userID: user.id,
              sections: ExportedSections(
                settings: settings ? sectionsInfo.settings : null,
                modifiedThumbnails:
                    modifiedThumbnails ? sectionsInfo.modifiedThumbnails : null,
                modifiedLyrics:
                    modifiedLyrics ? sectionsInfo.modifiedLyrics : null,
                modifiedLocalMetadata: modifiedLocalMetadata
                    ? sectionsInfo.modifiedLocalMetadata
                    : null,
                cachedRestricted:
                    cachedRestricted ? sectionsInfo.cachedRestricted : null,
                locallyReplacedAudios: locallyReplacedAudios
                    ? sectionsInfo.locallyReplacedAudios
                    : null,
              ),
              cancellationToken: cancellationToken,
              onProgress: (progress) {
                animatedExportProgress.animateTo(
                  progress,
                  duration: progressAnimationDuration,
                  curve: Curves.ease,
                );
              },
            );
      } catch (error, stackTrace) {
        showLogErrorDialog(
          "Error while exporting settings (selected sections: $sectionsList):",
          error,
          stackTrace,
          logger,
          // ignore: use_build_context_synchronously
          context,
        );

        if (context.mounted) {
          animatedExportProgress.value = 0.0;
        }
      }

      if (context.mounted) {
        isExportInProgress.value = false;
      }

      // Если экспорт был неудачен, то ничего не делаем.
      if (exportedFile == null || !context.mounted) return;

      // Экспорт был успешен, отображаем диалог.
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return SuccessSettingsExportDialog(
            file: exportedFile!,
          );
        },
      );

      // Пытаемся удалить файл после закрытия диалога.
      try {
        if (exportedFile.existsSync()) {
          await exportedFile.delete();
        }
      } catch (error, stackTrace) {
        logger.e(
          "Error while deleting exported file ${exportedFile.path}:",
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l18n.export_settings_title,
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
                title: l18n.export_settings_tip,
                descriptionWidget: StyledText(
                  text: l18n.export_settings_tip_desc,
                  tags: {
                    "importSettingsIcon": StyledTextIconTag(
                      Icons.file_download_outlined,
                      size: 20,
                    ),
                    "importSettings": StyledTextActionTag(
                      (String? text, Map<String?, String?> attrs) {
                        context.push("/profile/settings_importer");
                      },
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  },
                ),
              ),
              Gap(mobileLayout ? 16 : 24),

              // Экспортируемые опции.
              SettingsExporterSelector(
                enabledSections: enabledSections.value,
                sectionsInfo: sectionsInfo,
                disabled: isExportInProgress.value,
                onSectionsChanged: (value) => enabledSections.value = value,
              ),
              Gap(mobileLayout ? 16 : 24),

              // Кнопка экспорта.
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  icon: isExportInProgress.value
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Icon(
                          Icons.file_upload_outlined,
                        ),
                  label: Text(
                    l18n.export_settings_export,
                  ),
                  onPressed: enabledSections.value.isNotEmpty &&
                          !isExportInProgress.value
                      ? onExportTap
                      : null,
                ),
              ),

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
                value: animatedExportProgress.value,
                minHeight: 3,
              ),
            ),
        ],
      ),
    );
  }
}
