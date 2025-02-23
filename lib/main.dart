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
import "package:local_notifier/local_notifier.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:path/path.dart" as path;
import "package:path_provider/path_provider.dart";
import "package:responsive_builder/responsive_builder.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:system_tray/system_tray.dart";
import "package:window_manager/window_manager.dart";

import "api/vk/shared.dart";
import "api/vk/users/get.dart";
import "app.dart";
import "consts.dart";
import "firebase_options.dart";
import "provider/auth.dart";
import "provider/db.dart";
import "provider/dio.dart";
import "provider/l18n.dart";
import "provider/observer.dart";
import "provider/player.dart";
import "provider/preferences.dart";
import "provider/shared_prefs.dart";
import "services/connectivity_manager.dart";
import "services/logger.dart";
import "services/player/server.dart";
import "services/updater.dart";
import "utils.dart";

/// [GlobalKey] для [Navigator], который позволяет переходить между экранами вне контекста виджета.
///
/// Пример использования:
/// ```dart
/// navigatorKey.currentContext?.go("/music");
/// ```
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
    title: appName,
    iconPath: isWindows ? "assets/icon.ico" : "assets/icon.png",
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
        isWindows ? windowManager.show() : systemTray.popUpContextMenu();
      } else if (eventName == kSystemTrayEventRightClick) {
        isWindows ? systemTray.popUpContextMenu() : windowManager.show();
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
    final appStorage = container.read(appStorageProvider);

    // Инициализируем Firebase (Analytics, Crashlytics), в release-режиме.
    // TODO: Реализовать логирование ошибок, даже если Firebase не используется (т.е., повторить функционал catcher_2).
    if (kReleaseMode && !isWeb) {
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

    // Узнаём версию приложения.
    appVersion = (await PackageInfo.fromPlatform()).version;

    if (!isWeb) {
      // Узнаём информацию об устройстве.
      androidDeviceInfo = isAndroid ? await deviceInfoPlugin.androidInfo : null;
      logger.d("Supported ABIs: ${androidDeviceInfo?.supportedAbis}");

      // Инициализируем WindowManager на Desktop-платформах.
      if (isDesktop) {
        await windowManager.ensureInitialized();
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
            if (!kDebugMode) await windowManager.focus();
            await initSystemTray(l18n);
            await setWindowTitle();
          },
        );
      }

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

      // Загружаем базу данных Isar, а так же запускаем миграцию.
      await appStorage.migrate();

      // Инициализируем библиотеку для создания уведомлений на OS Windows.
      if (isWindows) {
        await localNotifier.setup(appName: appName);
      } else if (isAndroid) {
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
    }

    // Объект авторизации.
    final auth = container.read(currentAuthStateProvider.notifier);

    // Создаём объекты Dio.
    dio = container.read(dioProvider);
    vkDio = container.read(vkDioProvider);
    lrcLibDio = container.read(lrcLibDioProvider);

    // Создаём менеджер интернет соединения.
    connectivityManager = ConnectivityManager();
    await connectivityManager.initialize();

    // Инициализируем плеер и его backend'ы.
    final player = container.read(playerProvider);
    await player.initialize();

    // Восстанавливаем настройки плеера.
    player.setShuffle(preferences.shuffleEnabled);
    player.setRepeat(preferences.loopModeEnabled);
    player.setDiscordRPCEnabled(preferences.discordRPCEnabled && isDesktop);
    player.setPauseOnMuteEnabled(preferences.pauseOnMuteEnabled && isDesktop);
    player.setStopOnLongPauseEnabled(preferences.stopOnPauseEnabled);
    player.setKeepPlayingOnCloseEnabled(preferences.androidKeepPlayingOnClose);
    player.setDebugLoggingEnabled(preferences.debugPlayerLogging);
    player.setTrackTitleInWindowBarEnabled(preferences.trackTitleInWindowBar);
    if (preferences.volume < 1.0 && isDesktop) {
      player.setVolume(preferences.volume);
    }

    // На Desktop-платформах, создаём README-файл в папке кэша треков.
    if (isDesktop) {
      final File readmeFile = File(
        path.join(
          await PlayerLocalServer.getTrackStorageDirectory(),
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

    // Если запущена Web-версия, то включаем демо-режим.
    if (isWeb) {
      logger.w("Running in demo mode");

      final List<APIUser> response = await users_get(token: "DEMO");
      auth.login(
        "DEMO",
        response.first,
        isDemo: true,
      );
    }

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
