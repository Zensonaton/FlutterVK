import "dart:io";

import "package:awesome_dio_interceptor/awesome_dio_interceptor.dart";
import "package:catcher_2/core/catcher_2.dart";
import "package:catcher_2/handlers/console_handler.dart";
import "package:catcher_2/handlers/file_handler.dart";
import "package:catcher_2/mode/silent_report_mode.dart";
import "package:catcher_2/model/catcher_2_options.dart";
import "package:dio/dio.dart";
import "package:dio_http2_adapter/dio_http2_adapter.dart";
import "package:dio_smart_retry/dio_smart_retry.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:flutter_local_notifications/flutter_local_notifications.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:just_audio_media_kit/just_audio_media_kit.dart";
import "package:local_notifier/local_notifier.dart";
import "package:media_kit/media_kit.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:path/path.dart" as path;
import "package:path_provider/path_provider.dart";
import "package:responsive_builder/responsive_builder.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:system_tray/system_tray.dart";
import "package:window_manager/window_manager.dart";

import "api/vk/consts.dart";
import "app.dart";
import "consts.dart";
import "db/db.dart";
import "provider/l18n.dart";
import "provider/observer.dart";
import "provider/player.dart";
import "provider/preferences.dart";
import "provider/shared_prefs.dart";
import "services/audio_player.dart";
import "services/connectivity_manager.dart";
import "services/logger.dart";
import "services/updater.dart";
import "utils.dart";

/// [GlobalKey] для [Navigator], который позволяет переходить между экранами вне контекста виджета.
///
/// Пример использования:
/// ```dart
/// navigatorKey.currentContext?.go("/music");
/// ```
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Объект базы данных приложения.
late final AppStorage appStorage;

/// Объект аудиоплеера.
late final VKMusicPlayer player;

/// Менеджер интернет соедининия.
late final ConnectivityManager connectivityManager;

/// Плагин для создания уведомлений на OS Android.
late final FlutterLocalNotificationsPlugin notificationsPlugin;

/// Объект [Dio], позволяющий создавать HTTP-запросы.
///
/// Данный объект содержит в себе interceptor'ы, позволяющие:
/// - Повторять запрос в случае ошибки сети.
/// - Логировать запросы и их ответы.
///
/// Пример использования:
/// ```dart
/// await dio.get("https://example.com/")
/// ```
late final Dio dio;

/// Объект [Dio], позволяющий создавать HTTP-запросы, настроенный конкретно под работу с API ВКонтакте.
///
/// Данный объект содержит в себе interceptor'ы, позволяющие:
/// - Повторять запрос в случае ошибки сети.
/// - Логировать запросы и их ответы.
///
/// Пример использования:
/// ```dart
/// await dio.post("users.get")
/// ```
late final Dio vkDio;

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

/// Обработчик события нажатия на уведомление от [notificationsPlugin].
@pragma("vm:entry-point")
void notificationTap(NotificationResponse notificationResponse) {
  navigatorKey.currentContext?.go("/profile/downloadManager");
}

/// Возвращает объект [Dio] с зарегистрированными [Interceptor]'ами.
void initDioInterceptors(Dio dio, {String loggerName = "Dio"}) {
  final AppLogger logger = getLogger(loggerName);

  // Игнорируем плохие SSL-сертификаты.
  dio.httpClientAdapter = Http2Adapter(
    ConnectionManager(
      onClientCreate: (_, config) => config.onBadCertificate = (_) => true,
    ),
  );

  dio.interceptors.addAll([
    // Обработчик для повтора HTTP-запросов в случае ошибок сети.
    RetryInterceptor(
      dio: dio,
      retryDelays: const [
        Duration(
          seconds: 1,
        ),
      ],
    ),

    // Обработчик для логирования HTTP-запросов и их ответов в debug-режиме.
    if (kDebugMode)
      AwesomeDioInterceptor(
        logRequestTimeout: false,
        logRequestHeaders: false,
        logResponseHeaders: false,
        logger: (String log) {
          String newLog = log;

          // Если слишком длинное, то обрезаем.
          if (newLog.length > 300) {
            newLog = "${newLog.substring(0, 300)}...";
          }

          logger.d(newLog);
        },
      ),
  ]);
}

/// Инициализирует запись в системном трее Windows.
Future<void> initSystemTray(AppLocalizations l18n) async {
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
          label: l18n.general_trayShowHide,
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
          label: l18n.general_appMinimizedClose,
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

Future main() async {
  final AppLogger logger = getLogger("main");

  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Загружаем SharedPreferences, а так же Preferences provider'ы.
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Контейнер для provider'ов от riverpod'а.
    final container = ProviderContainer(
      overrides: [
        sharedPrefsProvider.overrideWith((_) => prefs),
      ],
      observers: [
        FlutterVKProviderObserver(),
      ],
    );
    final preferences = container.read(preferencesProvider);
    final l18n = container.read(l18nProvider);

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
          await initSystemTray(l18n);

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

    // Инициализируем библиотеку для создания уведомлений на OS Windows.
    if (Platform.isWindows) {
      await localNotifier.setup(appName: "Flutter VK");
    } else if (Platform.isAndroid) {
      // Инициализируем уведомления на OS Android.

      notificationsPlugin = FlutterLocalNotificationsPlugin();
      await notificationsPlugin.initialize(
        onDidReceiveNotificationResponse: notificationTap,
        onDidReceiveBackgroundNotificationResponse: notificationTap,
        const InitializationSettings(
          android: AndroidInitializationSettings(
            "drawable/ic_music_note",
          ),
        ),
      );
    }

    // Создаём объекты Dio.
    dio = Dio(
      BaseOptions(
        headers: {
          "User-Agent": vkAPIKateMobileUA,
        },
      ),
    );
    vkDio = Dio(
      BaseOptions(
        baseUrl: vkAPIBaseURL,
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "User-Agent": vkAPIKateMobileUA,

          // TODO: QUIC support
          // "x-quic": "1",
          // "x-response-format": "msgpack",
          // "accept-encoding": "zstd",
        },
      ),
    );
    initDioInterceptors(dio);
    initDioInterceptors(
      vkDio,
      loggerName: "VKDio",
    );

    // Загружаем базу данных Isar.
    appStorage = AppStorage();

    // Создаём менеджер интернет соединения.
    connectivityManager = ConnectivityManager();
    await connectivityManager.initialize();

    // Инициализируем плеер.
    JustAudioMediaKit.title = "Flutter VK";
    if (preferences.debugPlayerLogging) {
      logger.i("Media kit debug logger is enabled");

      JustAudioMediaKit.mpvLogLevel = MPVLogLevel.debug;
    }
    JustAudioMediaKit.ensureInitialized();

    player = container.read(vkMusicPlayerProvider);

    // Восстанавливаем состояние shuffle у плеера.
    if (preferences.shuffleEnabled) {
      await player.setShuffle(true);
    }

    // Переключаем состояние Discord Rich Presence.
    if (preferences.discordRPCEnabled && isDesktop) {
      await player.setDiscordRPCEnabled(true);
    }

    // Восстанавливаем значение настройки "пауза при отключении громкости".
    if (preferences.pauseOnMuteEnabled) {
      player.setPauseOnMuteEnabled(true);
    }

    // Восстанавливаем значение настройки "остановка при неактивности".
    if (preferences.stopOnPauseEnabled) {
      player.setStopOnPauseEnabled(true);
    }

    // На Desktop-платформах, создаём README-файл в папке кэша треков.
    if (isDesktop) {
      final File readmeFile = File(
        path.join(
          await CachedStreamAudioSource.getTrackStorageDirectory(),
          tracksCacheReadmeFileName,
        ),
      );
      readmeFile.createSync(
        recursive: true,
      );
      readmeFile.writeAsStringSync(
        l18n.general_musicReadmeFileContents,
      );
    }

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

    // Запускаем само приложение, а так же делаем глобальный обработчик ошибок.
    Catcher2(
      debugConfig: Catcher2Options(
        SilentReportMode(),
        [
          ConsoleHandler(
            enableDeviceParameters: false,
            enableApplicationParameters: false,
          ),
        ],
        logger: CatcherLogger(),
      ),
      releaseConfig: Catcher2Options(
        SilentReportMode(),
        [
          ConsoleHandler(),
          if (!kIsWeb)
            FileHandler(
              await logFilePath(),
            ),
        ],
        logger: CatcherLogger(),
      ),
      runAppFunction: () {
        runApp(
          UncontrolledProviderScope(
            container: container,
            child: const EagerInitialization(
              app: FlutterVKApp(),
            ),
          ),
        );
      },
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
