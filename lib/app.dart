import "dart:io";

import "package:dynamic_color/dynamic_color.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:local_notifier/local_notifier.dart";
import "package:path/path.dart" as path;
import "package:provider/provider.dart";
import "package:url_launcher/url_launcher.dart";
import "package:window_manager/window_manager.dart";

import "consts.dart";
import "enums.dart";
import "intents.dart";
import "main.dart";
import "provider/color.dart";
import "provider/user.dart";
import "routes/home.dart";
import "routes/home/profile.dart";
import "routes/welcome.dart";
import "services/audio_player.dart";
import "services/logger.dart";
import "utils.dart";
import "widgets/loading_overlay.dart";

/// Основной виджет главного приложения, используемый методом [runApp] внутри [main].
///
/// В случае, если по какой-то причине произойдёт ошибка, вместо этого класса будет вызван [runApp], но для класса [ErroredApp], который символизирует ошибку запуска приложения.
class FlutterVKApp extends StatefulWidget {
  const FlutterVKApp({
    super.key,
  });

  @override
  State<FlutterVKApp> createState() => _FlutterVKAppState();
}

class _FlutterVKAppState extends State<FlutterVKApp> with WindowListener {
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

    // Восстанавливаем значение настройки "пауза при отключении громкости".
    if (user.settings.pauseOnMuteEnabled) {
      player.setPauseOnMuteEnabled(true);
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
      builder:
          (ColorScheme? lightDynamicScheme, ColorScheme? darkDynamicScheme) {
        final bool playerColorsAppwide = user.settings.playerColorsAppWide;
        final playerLightColorScheme =
            playerColorsAppwide ? colorScheme.lightColorScheme : null;
        final playerDarkColorScheme =
            playerColorsAppwide ? colorScheme.darkColorScheme : null;

        return MaterialApp(
          theme: ThemeData(
            colorScheme: playerLightColorScheme ?? fallbackLightColorScheme,
          ),
          darkTheme: ThemeData(
            colorScheme:
                (playerDarkColorScheme ?? fallbackDarkColorScheme).copyWith(
              surface: user.settings.oledTheme ? Colors.black : null,
              // Некоторые части интерфейса Flutter до сих пор используют background.
              // ignore: deprecated_member_use
              background: user.settings.oledTheme ? Colors.black : null,
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

/// Альтернативная версия класса [FlutterVKApp], вызываемая в случае, если при инициализации [FlutterVKApp] (или метода [runApp]/[main]) произошла ошибка. Данный класс отображает [MaterialApp], показывающий текст ошибки, а так же предлагающий пользователю опции для возможного решения проблемы.
///
/// Локализация при этом не используется, поскольку она может быть поломана в данном контексте.
class ErroredApp extends StatelessWidget {
  /// Ошибка, вызвавшая краш приложения.
  final String error;

  const ErroredApp({
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

                      // Открытие Github-репозитория.
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

                      // Кнопка для выхода.
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
