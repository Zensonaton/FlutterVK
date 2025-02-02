import "dart:io";

import "package:device_info_plus/device_info_plus.dart";
import "package:dio/dio.dart";
import "package:firebase_core/firebase_core.dart";
import "package:firebase_crashlytics/firebase_crashlytics.dart";
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

import "app.dart";
import "consts.dart";
import "firebase_options.dart";
import "provider/db_migrator.dart";
import "provider/dio.dart";
import "provider/l18n.dart";
import "provider/observer.dart";
import "provider/player.dart";
import "provider/preferences.dart";
import "provider/shared_prefs.dart";
import "services/audio_player.dart";
import "services/connectivity_manager.dart";
import "services/db.dart";
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

/// Плагин для API-вызовов, связанных с OS Android.
late final AndroidFlutterLocalNotificationsPlugin? androidNotificationsPlugin;

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
/// - Добавлять `access_token` и версию API в запросы.
///
/// Пример использования:
/// ```dart
/// await vkDio.post("users.get")
/// ```
late final Dio vkDio;

/// Объект [Dio], позволяющий создавать HTTP-запросы, настроенный конкретно под работу с API ВКонтакте.
///
/// Данный объект содержит в себе interceptor'ы, позволяющие:
/// - Повторять запрос в случае ошибки сети.
/// - Логировать запросы и их ответы.
///
/// Пример использования:
/// ```dart
/// await lrcLibDio.get("search?q=Never Gonna Give You Up")
/// ```
late final Dio lrcLibDio;

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
late final String appVersion;

/// Объект для получения информации об устройстве.
final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

/// Объект, хранящий информацию о текущем Android-устройстве. Может быть null, если устройство не является Android-устройством.
late final AndroidDeviceInfo? androidDeviceInfo;

/// Обработчик события нажатия на уведомление от [notificationsPlugin].
@pragma("vm:entry-point")
void notificationTap(NotificationResponse notificationResponse) {
  navigatorKey.currentContext?.go("/profile/download_manager");
}

/// Инициализирует запись в системном трее Windows.
Future<void> initSystemTray(AppLocalizations l18n) async {
  if (!isDesktop) {
    throw Exception("initSystemTray() can only be called on Desktop platforms");
  }

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
          label: l18n.tray_show_hide,
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
          label: l18n.general_close,
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
    final dbMigrator = container.read(dbMigratorProvider);

    // Инициализируем Firebase (Analytics, Crashlytics), в release-режиме.
    // TODO: Реализовать логирование ошибок, даже если Firebase не используется (т.е., повторить функционал catcher_2).
    if (kReleaseMode) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;

      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(
          error,
          stack,
          fatal: true,
        );

        return true;
      };
    }

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

          // Делаем название окна в debug-режиме.
          if (kDebugMode) {
            await windowManager.setTitle("Flutter VK (DEBUG)");
          }
        },
      );
    }

    // Узнаём версию приложения.
    appVersion = (await PackageInfo.fromPlatform()).version;

    // Узнаём информацию об устройстве.
    androidDeviceInfo =
        Platform.isAndroid ? await deviceInfoPlugin.androidInfo : null;
    logger.d("Supported ABIs: ${androidDeviceInfo?.supportedAbis}");

    // Удаляем файл обновления, если таковой существует.
    final supportDirectory = (await getApplicationSupportDirectory()).path;
    for (String filename in await Updater.getFilenameByPlatform()) {
      final File updaterInstaller = File(
        path.join(
          supportDirectory,
          filename,
        ),
      );

      try {
        if (!updaterInstaller.existsSync()) continue;

        await updaterInstaller.delete();
      } catch (error, stackTrace) {
        logger.w(
          "Error while deleting updater on path ${updaterInstaller.path}: ",
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    // Загружаем базу данных Isar.
    appStorage = AppStorage();

    // Запускаем миграцию базы данных.
    await dbMigrator.performMigration();

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
      androidNotificationsPlugin =
          notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      // Запрашиваем разрешения на отправку уведомлений.
      androidNotificationsPlugin?.requestNotificationsPermission();
    }

    // Создаём объекты Dio.
    dio = container.read(dioProvider);
    vkDio = container.read(vkDioProvider);
    lrcLibDio = container.read(lrcLibDioProvider);

    // Создаём менеджер интернет соединения.
    connectivityManager = ConnectivityManager();
    await connectivityManager.initialize();

    // Инициализируем плеер.
    JustAudioMediaKit.title = "Flutter VK";
    JustAudioMediaKit.prefetchPlaylist = !kDebugMode;
    if (preferences.debugPlayerLogging && isDesktop) {
      logger.i("Media kit debug logger is enabled");

      JustAudioMediaKit.mpvLogLevel = MPVLogLevel.debug;
    }
    JustAudioMediaKit.ensureInitialized();

    player = container.read(vkMusicPlayerProvider);

    // Восстанавливаем состояние shuffle у плеера.
    if (preferences.shuffleEnabled) {
      await player.setShuffle(true);
    }

    // Восстанавливаем состояние loop mode у плеера.
    if (preferences.loopModeEnabled) {
      await player.setLoopModeEnabled(true);
    }

    // Восстанавливаем громкость у плеера.
    if (preferences.volume < 1.0 && isDesktop) {
      await player.setVolume(preferences.volume);
    }

    // Переключаем состояние Discord Rich Presence.
    if (preferences.discordRPCEnabled && isDesktop) {
      await player.setDiscordRPCEnabled(true);
    }

    // Восстанавливаем значение настройки "пауза при отключении громкости".
    if (preferences.pauseOnMuteEnabled && isDesktop) {
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
        l18n.music_readme_contents,
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

    logger.i(
      "Running Flutter VK v$appVersion ${isPrerelease ? "(pre-release)" : ""}",
    );

    // Запускаем само приложение.
    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const FlutterVKApp(),
      ),
    );
  } catch (error, stackTrace) {
    logger.f(
      "Exception while running FlutterVKApp (main): ",
      error: error,
      stackTrace: stackTrace,
    );

    // Пытаемся запустить errored-версию приложения.
    try {
      runApp(
        ProviderScope(
          child: ErroredApp(
            error: error.toString(),
          ),
        ),
      );
    } catch (error, stackTrace) {
      logger.f(
        "Couldn't run ErroredApp: ",
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
