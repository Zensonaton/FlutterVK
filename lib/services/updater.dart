import "dart:io";

import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:flutter_markdown/flutter_markdown.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:http/http.dart";
import "package:install_plugin/install_plugin.dart";
import "package:intl/intl.dart";
import "package:path_provider/path_provider.dart";
import "package:permission_handler/permission_handler.dart";
import "package:url_launcher/url_launcher.dart";

import "../api/github/get_latest.dart";
import "../api/github/get_releases.dart";
import "../api/github/shared.dart";
import "../consts.dart";
import "../main.dart";
import "../provider/l18n.dart";
import "../utils.dart";
import "../widgets/dialogs.dart";
import "../widgets/loading_overlay.dart";
import "logger.dart";
import "package:path/path.dart" as path;

/// Диалог, появляющийся снизу экрана, показывающий информацию о том, что доступно новое обновление.
///
/// Пример использования:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   builder: (BuildContext context) => const UpdateAvailableDialog(...),
/// ),
/// ```
class UpdateAvailableDialog extends ConsumerWidget {
  static AppLogger logger = getLogger("UpdateAvailableDialog");

  /// Github Release с новым обновлением.
  final Release release;

  const UpdateAvailableDialog({
    super.key,
    required this.release,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);
    final String locale = l18n.localeName;

    return DraggableScrollableSheet(
      expand: false,
      builder: (BuildContext context, ScrollController controller) {
        return Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Stack(
            children: [
              ListView(
                controller: controller,
                children: [
                  // Текст "Доступно обновление".
                  Text(
                    l18n.updateAvailableTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),

                  // Информация о старой и новой версии.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Текущая версия.
                      Text(
                        "v$appVersion",
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.75),
                        ),
                      ),

                      // Стрелочка.
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                        ),
                        child: Icon(
                          Icons.arrow_right,
                          size: 18,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.75),
                        ),
                      ),

                      // Новая версия, а так же информация о дате релиза.
                      Text(
                        "v${release.tagName}, ${DateFormat.yMd(locale).format(release.createdAt!)} ${DateFormat.Hm(locale).format(release.createdAt!)} ${release.prerelease ? "(Pre-release)" : ""}",
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.75),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 6,
                  ),

                  const Divider(),
                  const SizedBox(
                    height: 6,
                  ),

                  // Описание обновления.
                  MarkdownBody(
                    data: release.body,
                  ),
                  const SizedBox(
                    height: 6,
                  ),

                  const Divider(),
                  const SizedBox(
                    height: 6,
                  ),

                  // Ряд из кнопок.
                  Wrap(
                    spacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      // Подробности.
                      FilledButton.tonalIcon(
                        icon: const Icon(
                          Icons.library_books,
                        ),
                        label: Text(
                          l18n.showUpdateDetails,
                        ),
                        onPressed: () {
                          launchUrl(
                            Uri.parse(
                              release.htmlUrl,
                            ),
                          );
                        },
                      ),

                      // Установить.
                      FilledButton.icon(
                        icon: Icon(
                          isMobile
                              ? Icons.install_mobile
                              : Icons.install_desktop,
                        ),
                        label: Text(
                          l18n.installUpdate,
                        ),
                        onPressed: () async {
                          context.pop();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              duration: const Duration(
                                seconds: 10,
                              ),
                              content: Text(
                                l18n.installPendingDescription,
                              ),
                            ),
                          );

                          try {
                            Updater.downloadAndInstallUpdate(
                              release.assets.firstWhere(
                                (asset) =>
                                    asset.name ==
                                    Updater.getFilenameByPlatform(),
                                orElse: () => throw Exception(
                                  "${Updater.getFilenameByPlatform()} file have not been found in release assets",
                                ),
                              ),
                            );
                          } catch (e, stackTrace) {
                            showLogErrorDialog(
                              "Ошибка при обновлении приложения:",
                              e,
                              stackTrace,
                              logger,
                              context,
                              title: l18n.updateErrorTitle,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Класс для обработки обновлений приложения.
class Updater {
  /// [AppLogger] для этого класса.
  static AppLogger logger = getLogger("Updater");

  /// Возвращает информацию по последнему Github Release репозитория данного приложения.
  ///
  /// Для получения списка из Release'ов воспользуйтесь методом [getReleases].
  static Future<Release> getLatestRelease() async => get_latest(
        repoOwner,
        repoName,
      );

  /// Возвращает информацию по последним Github Release'ам репозитория данного приложения.
  static Future<List<Release>> getReleases() async => get_releases(
        repoOwner,
        repoName,
      );

  /// Проверяет, нужно ли обновиться с текущей версии приложения до той версии, которая передаётся в [releases]. Если обновиться можно, то вместо null возвращает объект [Release], олицетворяющий последнюю версию, до которой можно произвести обновление.
  ///
  /// Если Вы не получили объект [Release], то воспользуйтесь методом [getReleases], либо воспользуйтесь методом [shouldUpdate].
  static Release? shouldUpdateFrom(
    List<Release> releases, {
    bool allowPre = false,
    String? downloadFilename,
  }) {
    // Проходимся по последним релизам, сверяем версии.
    for (Release release in releases) {
      // Если мы нашли одинаковую запись, то значит, что мы уже находимся на новой версии.
      if (release.tagName == appVersion) break;

      // Если нам запрещено смотреть на pre release-версии, то пропускаем таковые.
      if (!allowPre && release.prerelease) continue;

      // Если нам дано название файла, то проверяем, есть ли он в списке.
      if (downloadFilename != null &&
          !release.assets.any(
            (asset) => asset.name == downloadFilename,
          )) continue;

      // Мы нашли подходящую версию!
      return release;
    }

    return null;
  }

  /// Проверяет, нужно ли обновиться с текущей версии приложения до версии, которая передаётся в результате API запроса к Github Actions. Если обновиться можно, то вместо null возвращает объект [Release], олицетворяющий последнюю версию, до которой можно произвести обновление.
  ///
  /// Если у Вас уже есть объект [Release] то рекомендуется воспользоваться методом [shouldUpdateFrom], что бы избежать повторного API-запроса.
  static Future<Release?> shouldUpdate({
    bool allowPre = false,
    String? downloadFilename,
  }) async =>
      shouldUpdateFrom(
        await getReleases(),
        allowPre: allowPre,
        downloadFilename: downloadFilename,
      );

  /// Возвращает название файла, которое должно быть загружено с Github в зависимости от текущей платформы.
  static String? getFilenameByPlatform() {
    switch (Platform.operatingSystem) {
      case "android":
        return "Flutter.VK.Android.apk";

      case "windows":
        return "Flutter.VK.installer.exe";
    }

    return null;
  }

  /// Сверяет текущую версию приложения с последней версией из Github Actions, показывая информацию о результате проверки в интерфейсе. Если версия отличается, то вызывает [showModalBottomSheet] с целью показа информации о новом обновлении, а так же различными действиями с новым обновлением.
  ///
  /// [showLoadingOverlay] указывает, будет ли вызываться [LoadingOverlay.show] во время получения информации, [showMessageOnNoUpdates] указывает, будет ли показываться [ScaffoldMessenger] с сообщением о том, что обновлений нету, [useSnackbarOnUpdate] указывает, что вместо [showModalBottomSheet] будет использоваться [SnackBar] для отображения информации о появлении нового обновления.
  static Future<bool> checkForUpdates(
    BuildContext context, {
    Release? updateRelease,
    bool allowPre = false,
    bool showLoadingOverlay = false,
    bool showMessageOnNoUpdates = false,
    bool useSnackbarOnUpdate = false,
  }) async {
    logger.d("Checking for app updates (current: $appVersion)");

    if (showLoadingOverlay) LoadingOverlay.of(context).show();

    try {
      final Release? release = updateRelease ??
          await shouldUpdate(
            allowPre: allowPre,
            downloadFilename: getFilenameByPlatform(),
          );

      // Если мы можем обновиться, то показываем ModalBottomSheet либо SnackBar.
      if (release != null) {
        logger.d(
          "Latest release: ${release.tagName}, pre: ${release.prerelease}",
        );

        if (useSnackbarOnUpdate && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!
                    .updateAvailableSnackbarTitle("v${release.tagName}"),
              ),
              action: SnackBarAction(
                label: AppLocalizations.of(context)!.showUpdateDetails,
                onPressed: () => checkForUpdates(
                  context,
                  updateRelease: release,
                  allowPre: allowPre,
                  showLoadingOverlay: true,
                  showMessageOnNoUpdates: showMessageOnNoUpdates,
                ),
              ),
            ),
          );
        } else if (context.mounted) {
          showModalBottomSheet(
            context: context,
            useRootNavigator: true,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (BuildContext context) {
              return UpdateAvailableDialog(
                release: release,
              );
            },
          );
        }

        return true;
      }

      // Обновлений не найдено.
      if (showMessageOnNoUpdates && context.mounted) {
        logger.d("No updates found");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.noUpdatesAvailableTitle,
            ),
          ),
        );
      }

      return false;
    } catch (e, stackTrace) {
      logger.e(
        "Не удалось проверить на наличие обновлений:",
        error: e,
        stackTrace: stackTrace,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.updatesRetrieveError(e.toString()),
            ),
          ),
        );
      }

      return false;
    } finally {
      // ignore: use_build_context_synchronously
      if (showLoadingOverlay) LoadingOverlay.of(context).hide();
    }
  }

  /// Загружает указанный Release во временную папку, возвращая путь к файлу в случае успеха.
  static Future<File> downloadUpdate(
    ReleaseAsset asset,
  ) async {
    final File file = File(
      path.join(
        (await getApplicationSupportDirectory()).path,
        asset.name,
      ),
    );

    // Если такой файл уже есть с таким же размером, то не загружаем его по-новой.
    if (file.existsSync() && await file.length() == asset.size) {
      logger.d("File already downloaded, skipping download");

      return file;
    }

    logger.d(
      "Downloading update, size: ${asset.size} bytes, path: ${file.path}",
    );

    final Response response = await get(
      Uri.parse(
        asset.browserDownloadUrl,
      ),
    );

    logger.d(
      "Response: ${response.statusCode}, ${response.bodyBytes.length} bytes",
    );

    assert(
      response.statusCode == 200,
      "Received wrong status code: ${response.statusCode}",
    );
    assert(
      response.bodyBytes.length == asset.size,
      "File size mismatch: ${response.bodyBytes.length} received, expected ${asset.size}",
    );

    await file.writeAsBytes(response.bodyBytes);

    logger.d("Update downloaded");

    return file;
  }

  /// Устанавливает обновление приложения. [update] - установочный файл, с которого должно пойти обновление.
  static Future<void> installUpdate(
    File update,
  ) async {
    logger.d("Installing update");

    if (Platform.isWindows) {
      // Запускаем процесс обновления через командную строку.
      final ProcessResult result = await Process.run(update.path, []);

      // Данный блок кода не должен выполняться, поскольку установщик сам по себе должен закрыть приложение.
      logger.d(
        "Updater exit code: ${result.exitCode}",
      );

      return;
    } else if (Platform.isAndroid) {
      // Запрашиваем разрешение на установку.
      assert(
        (await Permission.requestInstallPackages.request()).isGranted,
        "Packages install permission is not given",
      );

      // Запускаем установщик .apk-файла.
      final status = await InstallPlugin.installApk(
        update.path,
      );

      logger.d(
        "Update status: $status",
      );

      return;
    }

    throw Exception(
      "Unsupported platform: ${Platform.operatingSystem}",
    );
  }

  /// Загружает и устанавливает указанный Release во временную папку, возвращая путь к файлу в случае успешной установки.
  static Future<File> downloadAndInstallUpdate(
    ReleaseAsset asset,
  ) async {
    // На Android, запрашиваем права для установки .apk-файлов.
    if (Platform.isAndroid) {
      await Permission.requestInstallPackages.request();
    }

    final File file = await downloadUpdate(asset);
    await installUpdate(file);

    return file;
  }
}
