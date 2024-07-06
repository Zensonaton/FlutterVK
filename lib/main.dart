import "dart:io";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:just_audio_media_kit/just_audio_media_kit.dart";
import "package:local_notifier/local_notifier.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:path/path.dart" as path;
import "package:path_provider/path_provider.dart";
import "package:responsive_builder/responsive_builder.dart";
import "package:system_tray/system_tray.dart";
import "package:window_manager/window_manager.dart";

import "app.dart";
import "db/db.dart";
import "services/audio_player.dart";
import "services/connectivity_manager.dart";
import "services/download_manager.dart";
import "services/logger.dart";
import "services/updater.dart";
import "utils.dart";

// TODO: Удалить это.
/// Глобальный объект [BuildContext].
///
/// За этот костыль меня могут отпиздить, и правильно сделают. Данный BuildContext нужен, что бы можно было извлекать ключи локализации там, где BuildContext отсутствует (внутри методов initState, к примеру).
///
/// Источник: https://christopher.khawand.dev/posts/flutter-internationalization-without-buildcontext
BuildContext? buildContext;

/// [GlobalKey] для [Navigator], который позволяет переходить между экранами вне контекста виджета.
///
/// Пример использования:
/// ```dart
/// navigatorKey.currentContext?.go("/grades");
/// ```
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Объект базы данных приложения.
late final AppStorage appStorage;

/// Объект аудиоплеера.
late final VKMusicPlayer player;

/// Менеджер загрузок плейлистов.
late final DownloadManager downloadManager;

/// Менеджер интернет соедининия.
late final ConnectivityManager connectivityManager;

/// [ColorScheme] яркости [Brightness.light], которая используется в случае, если по какой-то причине приложение не смогло получить цвета акцента, либо цвета музыкального плеера.
final fallbackLightColorScheme = ColorScheme.fromSeed(
  seedColor: Colors.blueAccent,
  dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
);

/// [ColorScheme] яркости [Brightness.dark], которая используется в случае, если по какой-то причине приложение не смогло получить цвета акцента, либо цвета музыкального плеера.
final fallbackDarkColorScheme = ColorScheme.fromSeed(
  seedColor: Colors.blueAccent,
  brightness: Brightness.dark,
  dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
);

/// Версия приложения.
late String appVersion;

/// Инициализирует запись в системном трее Windows.
Future<void> initSystemTray() async {
  assert(
    isDesktop,
    "initSystemTray() can only be called on Desktop platforms",
  );

  // Инициализируем меню в трее.
  final SystemTray systemTray = SystemTray();

  await systemTray.initSystemTray(
    title: "Flutter VK",
    iconPath: Platform.isWindows ? "assets/icon.ico" : "assets/icon.png",
  );

  // Создаём контекстное меню.
  final Menu menu = Menu()
    ..buildFrom(
      [
        // Показ/скрытие окна приложения.
        MenuItemLabel(
          label: AppLocalizations.of(buildContext!)!.general_trayShowHide,
          onClicked: (MenuItemBase menuItem) async {
            if (await windowManager.isVisible()) {
              await windowManager.hide();

              return;
            }

            await windowManager.show();
          },
        ),
        MenuSeparator(),

        // Закрытие.
        MenuItemLabel(
          label: AppLocalizations.of(buildContext!)!.general_appMinimizedClose,
          onClicked: (MenuItemBase menuItem) => exit(0),
        ),
      ],
    );

  // Устанавливаем контекстное меню.
  await systemTray.setContextMenu(menu);

  // Обрабатываем события нажатия по иконке.
  systemTray.registerSystemTrayEventHandler(
    (String eventName) {
      if (eventName == kSystemTrayEventClick) {
        Platform.isWindows
            ? windowManager.show()
            : systemTray.popUpContextMenu();
      } else if (eventName == kSystemTrayEventRightClick) {
        Platform.isWindows
            ? systemTray.popUpContextMenu()
            : windowManager.show();
      }
    },
  );
}

/// Используется для исправления ошибки невалидных SSL-сертификатов.
///
/// Источник: https://github.com/dart-lang/http/issues/458#issuecomment-932652512.
class DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

Future main() async {
  final AppLogger logger = getLogger("main");

  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Инициализируем WindowManager на Desktop-платформах.
    if (isDesktop) {
      await windowManager.ensureInitialized();

      // Делаем так, что бы пользователь не смог закрыть приложение.
      // Обработка закрытия приложения находится в ином месте: [_MainAppState.onWindowClose].
      await windowManager.setPreventClose(true);

      // Устанавливаем размеры окна.
      windowManager.waitUntilReadyToShow(
        const WindowOptions(
          size: Size(
            1280,
            720,
          ),
          minimumSize: Size(
            400,
            500,
          ),
          center: true,
        ),
        () async {
          await windowManager.show();

          // Делаем фокус окна не в debug-режиме.
          if (!kDebugMode) {
            await windowManager.focus();
          }

          // Инициализируем иконку в трее.
          await initSystemTray();

          // Убираем полноэкранный режим.
          if (kDebugMode) {
            await windowManager.setFullScreen(false);
          }

          // Делаем название окна в debug-режиме.
          if (kDebugMode) {
            await windowManager.setTitle("Flutter VK (DEBUG)");
          }
        },
      );
    }

    // Удаляем файл обновления, если таковой существует.
    final File updaterInstaller = File(
      path.join(
        (await getApplicationSupportDirectory()).path,
        Updater.getFilenameByPlatform(),
      ),
    );
    try {
      if (updaterInstaller.existsSync()) {
        updaterInstaller.deleteSync();
      }
    } catch (e, stackTrace) {
      logger.w(
        "Error while deleting updater on path ${updaterInstaller.path}: ",
        error: e,
        stackTrace: stackTrace,
      );
    }

    // Удаляем папку со старым кэшем треков, если таковой существует.
    // Сейчас, для кэша треков используется папка audios, однако раньше использовалась папка tracks.
    final Directory oldCacheDirectory = Directory(
      path.join(
        (await getApplicationSupportDirectory()).path,
        "tracks",
      ),
    );
    if (oldCacheDirectory.existsSync()) {
      oldCacheDirectory.deleteSync(recursive: true);
    }

    // Инициализируем библиотеку для создания уведомлений.
    await localNotifier.setup(appName: "Flutter VK");

    // Загружаем базу данных Isar.
    appStorage = AppStorage();

    // Создаём менеджер загрузок.
    downloadManager = DownloadManager();

    // Создаём менеджер интернет соединения.
    connectivityManager = ConnectivityManager();
    await connectivityManager.initialize();

    // Инициализируем плеер.
    JustAudioMediaKit.title = "Flutter VK";
    JustAudioMediaKit.ensureInitialized();

    player = VKMusicPlayer();

    // Breakpoint'ы для разных размеров экранов.
    ResponsiveSizingConfig.instance.setCustomBreakpoints(
      const ScreenBreakpoints(
        desktop: 900,
        tablet: 700,
        watch: 100,
      ),
    );

    // Узнаём версию приложения.
    appVersion = (await PackageInfo.fromPlatform()).version;

    logger.i("Running Flutter VK v$appVersion");

    // Фикс сертификатов.
    HttpOverrides.global = DevHttpOverrides();

    // Запускаем само приложение.
    runApp(
      const ProviderScope(
        child: EagerInitialization(
          app: FlutterVKApp(),
        ),
      ),
    );
  } catch (e, stackTrace) {
    logger.f(
      "Exception while running FlutterVKApp (main): ",
      error: e,
      stackTrace: stackTrace,
    );

    // Пытаемся запустить errored-версию приложения.
    try {
      runApp(
        ProviderScope(
          child: ErroredApp(
            error: e.toString(),
          ),
        ),
      );
    } catch (e, stackTrace) {
      logger.f(
        "Couldn't run ErroredApp: ",
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
