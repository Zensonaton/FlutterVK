import "dart:io";

import "package:dynamic_color/dynamic_color.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:gap/gap.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:local_notifier/local_notifier.dart";
import "package:path/path.dart" as path;
import "package:url_launcher/url_launcher.dart";
import "package:window_manager/window_manager.dart";

import "consts.dart";
import "enums.dart";
import "intents.dart";
import "main.dart";
import "provider/color.dart";
import "provider/l18n.dart";
import "provider/navigation_router.dart";
import "provider/preferences.dart";
import "provider/shared_prefs.dart";
import "routes/home/profile.dart";
import "services/audio_player.dart";
import "utils.dart";
import "widgets/loading_overlay.dart";

/// Wrapper для [FlutterVKApp], который загружает критически важные [Provider]'ы перед запуском основного приложения.
class EagerInitialization extends ConsumerWidget {
  /// Класс самого приложения.
  final FlutterVKApp app;

  const EagerInitialization({
    super.key,
    required this.app,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(sharedPrefsProvider);

    if (result.isLoading) {
      return const Center(
        child: CircularProgressIndicator.adaptive(),
      );
    } else if (result.hasError) {
      throw Exception(
        result.error!.toString(),
      );
    }

    return app;
  }
}

/// Основной виджет главного приложения, используемый методом [runApp] внутри [main].
///
/// В случае, если по какой-то причине произойдёт ошибка, вместо этого класса будет вызван [runApp], но для класса [ErroredApp], который символизирует ошибку запуска приложения.
class FlutterVKApp extends ConsumerStatefulWidget {
  const FlutterVKApp({
    super.key,
  });

  @override
  ConsumerState<FlutterVKApp> createState() => _FlutterVKAppState();
}

class _FlutterVKAppState extends ConsumerState<FlutterVKApp>
    with WindowListener {
  void init() async {
    final UserPreferences preferences = ref.read(preferencesProvider);

    // Загружаем обработчик событий окна.
    windowManager.addListener(this);

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
          await CachedStreamedAudio.getTrackStorageDirectory(),
          tracksCacheReadmeFileName,
        ),
      );
      readmeFile.createSync(
        recursive: true,
      );
      readmeFile.writeAsStringSync(
        ref.read(l18nProvider).general_musicReadmeFileContents,
      );
    }

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
    final AppLocalizations l18n = ref.read(l18nProvider);
    final UserPreferences preferences = ref.read(preferencesProvider);
    final CloseBehavior behavior = preferences.closeBehavior;

    // В зависимости от настройки "Поведение при закрытии", приложение должно либо закрыться, либо просто минимизироваться.
    if (behavior == CloseBehavior.minimize ||
        (behavior == CloseBehavior.minimizeIfPlaying && player.playing)) {
      final LocalNotification notification = LocalNotification(
        title: "Flutter VK",
        body: l18n.general_appMinimized,
        silent: true,
        actions: [
          LocalNotificationAction(
            text: l18n.general_appMinimizedClose,
          ),
          LocalNotificationAction(
            text: l18n.general_appMinimizedRestore,
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
    final router = ref.watch(routerProvider);
    final preferences = ref.watch(preferencesProvider);
    final trackImageInfo = ref.watch(trackSchemeInfoProvider);

    final bool appwideColors = preferences.playerColorsAppWide;
    final playerLightColorScheme =
        appwideColors ? trackImageInfo?.lightColorScheme : null;
    final playerDarkColorScheme =
        appwideColors ? trackImageInfo?.darkColorScheme : null;

    return DynamicColorBuilder(
      builder:
          (ColorScheme? lightDynamicScheme, ColorScheme? darkDynamicScheme) {
        final (ColorScheme, ColorScheme)? dynamicSchemesFixed =
            lightDynamicScheme != null
                ? generateDynamicColorSchemes(
                    lightDynamicScheme,
                    darkDynamicScheme!,
                  )
                : null;
        final ColorScheme? lightDynamicSchemeFixed = dynamicSchemesFixed?.$1;
        final ColorScheme? darkDynamicSchemeFixed = dynamicSchemesFixed?.$2;

        return MaterialApp.router(
          theme: ThemeData(
            colorScheme: playerLightColorScheme ??
                lightDynamicSchemeFixed ??
                fallbackLightColorScheme,
          ),
          darkTheme: ThemeData(
            colorScheme: (playerDarkColorScheme ??
                    darkDynamicSchemeFixed ??
                    fallbackDarkColorScheme)
                .copyWith(
              surface: preferences.oledTheme ? Colors.black : null,
              // Некоторые части интерфейса Flutter до сих пор используют background.
              // ignore: deprecated_member_use
              background: preferences.oledTheme ? Colors.black : null,
            ),
          ),
          themeMode: preferences.theme,
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
          routerConfig: router,
          onGenerateTitle: (BuildContext context) {
            // TODO: Избавиться от этого.
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
                  Icon(
                    Icons.warning,
                    color: Theme.of(context).colorScheme.error,
                    size: 36,
                  ),
                  const Gap(12),

                  // Текст про ошибку запуска.
                  SelectableText(
                    "Unfortunately, Flutter VK couldn't start up properly due to unhandled exception:\n$error\n\nPlease try to check for app updates, and/or create a Github Issue on Flutter VK Github.",
                    textAlign: TextAlign.center,
                  ),
                  const Gap(24),

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
