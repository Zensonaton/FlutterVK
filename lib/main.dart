import "dart:io";

import "package:dynamic_color/dynamic_color.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:just_audio_media_kit/just_audio_media_kit.dart";
import "package:local_notifier/local_notifier.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:path/path.dart" as path;
import "package:path_provider/path_provider.dart";
import "package:provider/provider.dart";
import "package:responsive_builder/responsive_builder.dart";
import "package:system_tray/system_tray.dart";
import "package:url_launcher/url_launcher.dart";
import "package:window_manager/window_manager.dart";

import "consts.dart";
import "db/db.dart";
import "enums.dart";
import "intents.dart";
import "provider/color.dart";
import "provider/user.dart";
import "routes/home.dart";
import "routes/home/profile.dart";
import "routes/welcome.dart";
import "services/audio_player.dart";
import "services/connectivity_manager.dart";
import "services/download_manager.dart";
import "services/logger.dart";
import "services/updater.dart";
import "utils.dart";
import "widgets/loading_overlay.dart";

/// Глобальный объект [BuildContext].
///
/// За этот костыль меня могут отпиздить, и правильно сделают. Данный BuildContext нужен, что бы можно было извлекать ключи локализации там, где BuildContext отсутствует (внутри методов initState, к примеру).
///
/// Источник: https://christopher.khawand.dev/posts/flutter-internationalization-without-buildcontext
BuildContext? buildContext;

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
);

/// [ColorScheme] яркости [Brightness.dark], которая используется в случае, если по какой-то причине приложение не смогло получить цвета акцента, либо цвета музыкального плеера.
final fallbackDarkColorScheme = ColorScheme.fromSeed(
  seedColor: Colors.blueAccent,
  brightness: Brightness.dark,
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
      logger.w("Не удалось удалить существующий файл обновления по пули ${updaterInstaller.path}: ", error: e, stackTrace: stackTrace,);
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

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (BuildContext context) => UserProvider(false),
          ),
          ChangeNotifierProvider(
            create: (BuildContext context) => PlayerSchemeProvider(),
          ),
        ],
        child: const MainApp(),
      ),
    );
  } catch (e, stackTrace) {
    logger.f(
      "Ошибка при запуске приложения (main): ",
      error: e,
      stackTrace: stackTrace,
    );

    // Пытаемся запустить errored-версию приложения.
    try {
      runApp(
        ErroredMainApp(
          error: e.toString(),
        ),
      );
    } catch (e, stackTrace) {
      logger.w(
        "Запустить errored-версию приложения не вышло: ",
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}

/// Основной виджет главного приложения, используемый методом [runApp] внутри [main].
///
/// В случае, если по какой-то причине произойдёт ошибка, вместо этого класса будет вызван [runApp], но для класса [ErroredMainApp], который символизирует ошибку запуска приложения.
class MainApp extends StatefulWidget {
  const MainApp({
    super.key,
  });

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WindowListener {
  final AppLogger logger = getLogger("MainApp");

  /// Виджет, который будет хранить в себе "главную" страницу, с которой и начнётся изначальная навигация пользователем.
  Widget? home;

  void init() async {
    // Загружаем обработчик событий окна.
    windowManager.addListener(this);

    // Загружаем объект пользователя с диска.
    final UserProvider user = Provider.of<UserProvider>(context, listen: false);

    // Узнаём, куда нужно перекинуть пользователя.
    home = await user.loadFromDisk() ? const HomeRoute() : const WelcomeRoute();

    // Восстанавливаем состояние shuffle у плеера.
    if (user.settings.shuffleEnabled) {
      await player.setShuffle(true);
    }

    // Переключаем состояние Discord Rich Presence.
    if (user.settings.discordRPCEnabled && isDesktop) {
      await player.setDiscordRPCEnabled(true);
    }

    // Восстанавливаем значение настройки "остановка при неактивности".
    if (user.settings.stopOnPauseEnabled) {
      player.setStopOnPauseEnabled(true);
    }

    // На Desktop-платформах, создаём README-файл в папке кэша треков, если он не существует.
    if (isDesktop) {
      final File readmeFile = File(
        path.join(
          await CachedStreamedAudio.getTrackStorageDirectory(),
          tracksCacheReadmeFileName,
        ),
      );
      if (!readmeFile.existsSync()) {
        readmeFile.createSync(
          recursive: true,
        );
        readmeFile.writeAsStringSync(
          // ignore: use_build_context_synchronously
          AppLocalizations.of(buildContext!)!.general_musicReadmeFileContents,
        );
      }
    }

    user.markUpdated(false);

    // Делаем панель навигации прозрачной.
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
  }

  @override
  void initState() {
    super.initState();

    init();
  }

  @override
  void dispose() {
    super.dispose();

    windowManager.removeListener(this);
  }

  @override
  void onWindowClose() async {
    final UserProvider user = Provider.of<UserProvider>(context, listen: false);
    final AppCloseBehavior behavior = user.settings.closeBehavior;

    // В зависимости от настройки "Поведение при закрытии", приложение должно либо закрыться, либо просто минимизироваться.
    if (behavior == AppCloseBehavior.minimize ||
        (behavior == AppCloseBehavior.minimizeIfPlaying && player.playing)) {
      final LocalNotification notification = LocalNotification(
        title: "Flutter VK",
        body: AppLocalizations.of(buildContext!)!.general_appMinimized,
        silent: true,
        actions: [
          LocalNotificationAction(
            text: AppLocalizations.of(buildContext!)!.general_appMinimizedClose,
          ),
          LocalNotificationAction(
            text:
                AppLocalizations.of(buildContext!)!.general_appMinimizedRestore,
          ),
        ],
      );
      notification.onClick = windowManager.show;
      notification.onClickAction = (int index) async {
        if (index == 0) {
          exit(0);
        }

        await windowManager.show();
        await notification.close();
      };

      // Отображаем уведомление.
      await notification.show();

      // Сворачиваем приложение.
      await windowManager.hide();

      return;
    }

    exit(0);
  }

  @override
  Widget build(BuildContext context) {
    final UserProvider user = Provider.of<UserProvider>(context);
    final PlayerSchemeProvider colorScheme =
        Provider.of<PlayerSchemeProvider>(context);

    // Если мы ещё не загрузились, то показываем загрузку.
    if (home == null) {
      return const Center(
        child: CircularProgressIndicator.adaptive(),
      );
    }

    return DynamicColorBuilder(
      builder: (ColorScheme? lightColorScheme, ColorScheme? darkColorScheme) {
        final playerLightColorScheme = user.settings.playerColorsAppWide
            ? colorScheme.lightColorScheme
            : null;
        final playerDarkColorScheme = user.settings.playerColorsAppWide
            ? colorScheme.darkColorScheme
            : null;

        return MaterialApp(
          theme: ThemeData(
            colorScheme: playerLightColorScheme ??
                lightColorScheme ??
                fallbackLightColorScheme,
          ),
          darkTheme: ThemeData(
            colorScheme: (playerDarkColorScheme ??
                    darkColorScheme ??
                    fallbackDarkColorScheme)
                .copyWith(
              background: user.settings.oledTheme ? Colors.black : null,
              surface: user.settings.oledTheme ? Colors.black : null,
            ),
          ),
          themeMode: user.settings.theme,
          themeAnimationDuration: const Duration(
            milliseconds: 500,
          ),
          themeAnimationCurve: Curves.ease,
          builder: (BuildContext context, Widget? child) {
            return LoadingOverlay(
              child: AnnotatedRegion(
                value: const SystemUiOverlayStyle(
                  systemNavigationBarColor: Colors.transparent,
                  systemNavigationBarDividerColor: Colors.transparent,
                ),
                child: child!,
              ),
            );
          },
          onGenerateTitle: (BuildContext context) {
            buildContext = context;

            return "Flutter VK";
          },
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          shortcuts: {
            // Пауза.
            LogicalKeySet(
              LogicalKeyboardKey.space,
            ): const PlayPauseIntent(),

            // Полноэкранный плеер.
            LogicalKeySet(
              LogicalKeyboardKey.f11,
            ): const FullscreenPlayerIntent(),
          },
          actions: {
            PlayPauseIntent: CallbackAction(
              onInvoke: (intent) => player.togglePlay(),
            ),
          },
          supportedLocales: const [
            Locale("ru"),
            Locale("en"),
          ],
          home: home,
        );
      },
    );
  }
}

/// Альтернативная версия класса [MainApp], вызываемая в случае, если при инициализации [MainApp] (или метода [runApp]/[main]) произошла ошибка. Данный класс отображает [MaterialApp], показывающий текст ошибки, а так же предлагающий пользователю опции для возможного решения проблемы.
class ErroredMainApp extends StatelessWidget {
  /// Ошибка, вызвавшая краш приложения.
  final String error;

  const ErroredMainApp({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: fallbackLightColorScheme,
      ),
      darkTheme: ThemeData(
        colorScheme: fallbackDarkColorScheme,
        brightness: Brightness.dark,
      ),
      home: Scaffold(
        body: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(
                16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Иконка.
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: 12,
                    ),
                    child: Icon(
                      Icons.warning,
                      color: Theme.of(context).colorScheme.error,
                      size: 36,
                    ),
                  ),

                  // Текст про ошибку запуска.
                  // В данном классе мы не должны использовать локализацию, поскольку она может быть поломана.
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: 24,
                    ),
                    child: SelectableText(
                      "Unfortunately, Flutter VK couldn't start up properly due to unhandled exception:\n$error\n\nPlease try to check for app updates, and/or create a Github Issue on Flutter VK Github.",
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Кнопки снизу.
                  Wrap(
                    spacing: 8,
                    children: [
                      // Кнопка для возможности поделиться логами.
                      const FilledButton(
                        onPressed: shareLogs,
                        child: Text(
                          "Share logs",
                        ),
                      ),

                      // Кнопка для возможности поделиться логами.
                      FilledButton.tonal(
                        onPressed: () => launchUrl(
                          Uri.parse(
                            repoURL,
                          ),
                        ),
                        child: const Text(
                          "Open Github",
                        ),
                      ),

                      // Кнопка для возможности поделиться логами.
                      FilledButton.tonal(
                        onPressed: () => exit(0),
                        child: const Text(
                          "Exit",
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
