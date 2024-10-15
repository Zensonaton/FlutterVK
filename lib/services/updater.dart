import "dart:io";

import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:install_plugin/install_plugin.dart";
import "package:path/path.dart" as path;
import "package:path_provider/path_provider.dart";
import "package:permission_handler/permission_handler.dart";

import "../api/github/get_latest.dart";
import "../api/github/get_releases.dart";
import "../api/github/shared.dart";
import "../consts.dart";
import "../main.dart";
import "../provider/download_manager.dart";
import "../provider/l18n.dart";
import "../provider/updater.dart";
import "../widgets/dialogs.dart";
import "../widgets/loading_overlay.dart";
import "../widgets/update_dialog.dart";
import "download_manager.dart";
import "logger.dart";

/// Класс для обработки обновлений приложения.
///
/// Если Вам нужен данный класс, то воспользуйтесь [updaterProvider].
class Updater {
  static final AppLogger logger = getLogger("Updater");

  final UpdaterRef ref;

  Updater({
    required this.ref,
  });

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

  /// Возвращает информацию по Github Release текущей версии приложения. Может вернуть null, если по какой-то причине Release не был найден.
  ///
  /// Если Вы не получили список из объектов [Release], то воспользуйтесь методом [getReleases], либо воспользуйтесь методом [getCurrent].
  static Release? getCurrentFrom(List<Release> releases) =>
      releases.firstWhereOrNull(
        (release) => release.tagName == appVersion,
      );

  /// Возвращает информацию по Github Release текущей версии приложения. Может вернуть null, если по какой-то причине Release не был найден.
  ///
  /// Если у Вас уже есть объект [Release] то рекомендуется воспользоваться методом [getCurrentFrom], что бы избежать повторного API-запроса.
  static Future<Release?> getCurrent() async => getCurrentFrom(
        await getReleases(),
      );

  /// Проверяет, нужно ли обновиться с текущей версии приложения до той версии, которая передаётся в [releases]. Если обновиться можно, то вместо null возвращает объект [Release], олицетворяющий последнюю версию, до которой можно произвести обновление.
  ///
  /// Если Вы не получили список из объектов [Release], то воспользуйтесь методом [getReleases], либо воспользуйтесь методом [shouldUpdate].
  static Release? shouldUpdateFrom(
    List<Release> releases, {
    bool allowPre = false,
    required List<String> downloadFilenames,
    bool disableCurrentVersionCheck = false,
  }) {
    for (Release release in releases) {
      // Если мы нашли одинаковую запись, то значит, что мы уже находимся на новой версии.
      if (!disableCurrentVersionCheck && release.tagName == appVersion) break;

      // Если нам запрещено смотреть на pre-release версии, то пропускаем таковые.
      if (!allowPre && release.prerelease) continue;

      // Если нам дано название файла, то проверяем, есть ли он в списке.
      if (!release.assets
          .any((asset) => downloadFilenames.contains(asset.name))) continue;

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
    required List<String> downloadFilenames,
    bool disableCurrentVersionCheck = false,
  }) async =>
      shouldUpdateFrom(
        await getReleases(),
        allowPre: allowPre,
        downloadFilenames: downloadFilenames,
        disableCurrentVersionCheck: disableCurrentVersionCheck,
      );

  /// Возвращает список из названий файлов, которое должно быть загружено с Github в зависимости от текущей платформы, на которой запущено приложение.
  ///
  /// К примеру, на OS Windows возвращает список из единственного `.exe` файла, который не зависит от архитектуры процессора, а на Android возвращает список из двух `.apk`-файлов: один для конкретной архитектуры текущего устройства, а второй - универсальный.
  static Future<List<String>> getFilenameByPlatform() async {
    switch (Platform.operatingSystem) {
      case "android":
        final List<String> filenames = ["Flutter.VK.Android.apk"];

        // Создаём список из .apk-файлов, которые зависят от архитектуры устройства.
        final List<String> abiFilenames = androidDeviceInfo?.supportedAbis
                .map((abi) => "Flutter.VK.Android.$abi.apk")
                .toList() ??
            [];

        return [...abiFilenames, ...filenames];

      case "windows":
        return ["Flutter.VK.installer.exe"];
    }

    return [];
  }

  /// Сверяет текущую версию приложения с последней версией из Github Actions, показывая информацию о результате проверки в интерфейсе. Если версия отличается, то вызывает [showModalBottomSheet] с целью показа информации о новом обновлении, а так же различными действиями с новым обновлением.
  ///
  /// [showLoadingOverlay] указывает, будет ли вызываться [LoadingOverlay.show] во время получения информации, [showMessageOnNoUpdates] указывает, будет ли показываться [ScaffoldMessenger] с сообщением о том, что обновлений нету, [useSnackbarOnUpdate] указывает, что вместо [showModalBottomSheet] будет использоваться [SnackBar] для отображения информации о появлении нового обновления.
  Future<bool> checkForUpdates(
    BuildContext context, {
    Release? updateRelease,
    bool allowPre = false,
    bool showLoadingOverlay = false,
    bool showMessageOnNoUpdates = false,
    bool useSnackbarOnUpdate = false,
    bool disableCurrentVersionCheck = false,
  }) async {
    logger.d("Checking for app updates (current: $appVersion)");

    final l18n = ref.read(l18nProvider);

    if (showLoadingOverlay) LoadingOverlay.of(context).show();

    try {
      final Release? release = updateRelease ??
          await shouldUpdate(
            allowPre: allowPre,
            downloadFilenames: await getFilenameByPlatform(),
            disableCurrentVersionCheck: disableCurrentVersionCheck,
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
                l18n.updateAvailableSnackbarTitle("v${release.tagName}"),
              ),
              action: SnackBarAction(
                label: l18n.showUpdateDetails,
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
              l18n.noUpdatesAvailableTitle,
            ),
          ),
        );
      }

      return false;
    } catch (e, stackTrace) {
      logger.e(
        "Couldn't check for updates:",
        error: e,
        stackTrace: stackTrace,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l18n.updatesRetrieveError(e.toString()),
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

  /// Показывает диалог, в котором написана информация об изменениях в этой версии приложения Flutter VK.
  Future<void> showChangelog(
    BuildContext context, {
    bool showLoadingOverlay = false,
  }) async {
    logger.d("Getting changelog for version $appVersion");

    if (showLoadingOverlay) LoadingOverlay.of(context).show();

    try {
      final Release? release = await getCurrent();

      // Release был найден.
      if (release != null && context.mounted) {
        logger.d("Changelog found");

        showModalBottomSheet(
          context: context,
          useRootNavigator: true,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (BuildContext context) {
            return ChangelogDialog(
              release: release,
            );
          },
        );

        return;
      }
    } catch (e, stackTrace) {
      showLogErrorDialog(
        "Couldn't get changelog",
        e,
        stackTrace,
        logger,
        // ignore: use_build_context_synchronously
        context,
      );
    } finally {
      if (showLoadingOverlay && context.mounted) {
        LoadingOverlay.of(context).hide();
      }
    }
  }

  /// Загружает указанный Release во временную папку, возвращая путь к файлу в случае успеха.
  Future<File> downloadUpdate(Release release) async {
    final l18n = ref.read(l18nProvider);
    final downloadManager = ref.read(downloadManagerProvider.notifier);

    // Получаем список из названий файлов, которые должны быть загружены.
    final List<String> downloadFilenames = await getFilenameByPlatform();
    logger.d("Suitable for update filenames: $downloadFilenames");

    // Ищем подходящий Asset из Release'ов.
    ReleaseAsset? asset;
    for (String filename in downloadFilenames) {
      asset = release.assets.firstWhereOrNull(
        (asset) => asset.name == filename,
      );

      if (asset != null) break;
    }

    if (asset == null) {
      throw Exception(
        "No suitable assets found in release",
      );
    }
    logger.d("Found suitable asset: ${asset.name}, size: ${asset.size} bytes");

    final File file = File(
      path.join(
        (await getApplicationSupportDirectory()).path,
        asset.name,
      ),
    );

    // Если такой файл уже есть с таким же размером, то не загружаем его по-новой.
    if (!kDebugMode && file.existsSync() && file.lengthSync() == asset.size) {
      logger.d("File already downloaded, skipping download");

      return file;
    }

    logger.d(
      "Downloading update, size: ${asset.size} bytes, path: ${file.path}",
    );

    // Загружаем файл обновления.
    await downloadManager.newTask(
      AppUpdaterDownloadTask(
        id: "update-${asset.name}",
        smallTitle: "Flutter VK",
        longTitle: l18n.downloadManagerAppUpdateLongTitle(release.tagName),
        url: asset.browserDownloadUrl,
        ref: ref,
        file: file,
      ),
    );

    logger.d("Update downloaded");

    return file;
  }

  /// Устанавливает обновление приложения. [update] - установочный файл, с которого должно пойти обновление.
  static Future<void> installUpdate(File update) async {
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
      // TODO: Отображать ошибку пользователю, если он не дал разрешение.
      if (!(await Permission.requestInstallPackages.request()).isGranted) {
        throw Exception("Packages install permission is not given");
      }

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
  Future<File> downloadAndInstallUpdate(Release release) async {
    // На Android, запрашиваем права для установки .apk-файлов.
    if (Platform.isAndroid) {
      await Permission.requestInstallPackages.request();
    }

    final File file = await downloadUpdate(release);
    await installUpdate(file);

    return file;
  }
}
