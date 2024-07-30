import "dart:io";

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

  /// Проверяет, нужно ли обновиться с текущей версии приложения до той версии, которая передаётся в [releases]. Если обновиться можно, то вместо null возвращает объект [Release], олицетворяющий последнюю версию, до которой можно произвести обновление.
  ///
  /// Если Вы не получили объект [Release], то воспользуйтесь методом [getReleases], либо воспользуйтесь методом [shouldUpdate].
  static Release? shouldUpdateFrom(
    List<Release> releases, {
    bool allowPre = false,
    String? downloadFilename,
    bool disableCurrentVersionCheck = false,
  }) {
    for (Release release in releases) {
      // Если мы нашли одинаковую запись, то значит, что мы уже находимся на новой версии.
      if (!disableCurrentVersionCheck && release.tagName == appVersion) break;

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
    bool disableCurrentVersionCheck = false,
  }) async =>
      shouldUpdateFrom(
        await getReleases(),
        allowPre: allowPre,
        downloadFilename: downloadFilename,
        disableCurrentVersionCheck: disableCurrentVersionCheck,
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
            downloadFilename: getFilenameByPlatform(),
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

  /// Загружает указанный Release во временную папку, возвращая путь к файлу в случае успеха.
  Future<File> downloadUpdate(Release release) async {
    final l18n = ref.read(l18nProvider);
    final downloadManager = ref.read(downloadManagerProvider.notifier);

    // Ищем подходящий Asset из Release'ов.
    final ReleaseAsset asset = release.assets.firstWhere(
      (item) => item.name == Updater.getFilenameByPlatform(),
      orElse: () => throw Exception(
        "${Updater.getFilenameByPlatform()} file have not been found in release assets",
      ),
    );

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
