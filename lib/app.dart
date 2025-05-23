import "dart:io";

import "package:dynamic_color/dynamic_color.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:gap/gap.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:local_notifier/local_notifier.dart";
import "package:universal_back_gesture/back_gesture_page_transitions_builder.dart";
import "package:url_launcher/url_launcher.dart";
import "package:window_manager/window_manager.dart";

import "consts.dart";
import "enums.dart";
import "intents.dart";
import "l10n/app_localizations.dart";
import "main.dart";
import "provider/color.dart";
import "provider/l18n.dart";
import "provider/navigation_router.dart";
import "provider/player.dart";
import "provider/preferences.dart";
import "provider/user.dart";
import "route_transitions.dart";
import "routes/profile.dart";
import "services/logger.dart";
import "utils.dart";

/// Класс, расширяющий [WindowListener], позволяющий слушать события окна приложения.
///
/// В данном случае, данный класс заменяет метод [onWindowClose].
class FlutterVKWindowManager extends WindowListener {
  final WidgetRef ref;

  FlutterVKWindowManager({
    required this.ref,
  });

  /// Метод, вызываемый при попытке закрыть окно приложения.
  ///
  /// В этом методе обрабатывается закрытие окна в зависимости от настройки [UserPreferences.closeBehavior].
  @override
  void onWindowClose() async {
    if (!isDesktop) {
      throw Exception("onWindowClose() called on non-desktop platform");
    }

    final l18n = ref.read(l18nProvider);
    final player = ref.read(playerProvider);
    final preferences = ref.read(preferencesProvider);
    final behavior = preferences.closeBehavior;

    // В зависимости от настройки "Поведение при закрытии", приложение должно либо закрыться, либо просто минимизироваться.
    if (behavior == CloseBehavior.minimize ||
        (behavior == CloseBehavior.minimizeIfPlaying && player.isPlaying)) {
      final LocalNotification notification = LocalNotification(
        title: appName,
        body: l18n.app_minimized_message,
        silent: true,
        actions: [
          LocalNotificationAction(
            text: l18n.general_close,
          ),
          LocalNotificationAction(
            text: l18n.general_restore,
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
}

/// Основной виджет главного приложения, используемый методом [runApp] внутри [main].
///
/// В случае, если по какой-то причине произойдёт ошибка, вместо этого класса будет вызван [runApp], но для класса [ErroredApp], который символизирует ошибку запуска приложения.
class FlutterVKApp extends HookConsumerWidget {
  static final AppLogger logger = getLogger("FlutterVKApp");

  const FlutterVKApp({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = usePlatformBrightness();
    final appLifecycleState = useAppLifecycleState();
    useEffect(
      () {
        if (appLifecycleState != AppLifecycleState.resumed) return;

        // Меняем цвета статус-бара в зависимости от темы.
        // Понятия не имею почему, но без Future.microtask() это не работает.
        Future.microtask(
          () async {
            final uiStyle = brightness == Brightness.light
                ? SystemUiOverlayStyle.dark
                : SystemUiOverlayStyle.light;

            await SystemChrome.setEnabledSystemUIMode(
              SystemUiMode.edgeToEdge,
            );
            SystemChrome.setSystemUIOverlayStyle(
              uiStyle.copyWith(
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarDividerColor: Colors.transparent,
              ),
            );
          },
        );

        // Проверяем состояние интернет-соединения.
        connectivityManager.checkConnection();

        return null;
      },
      [appLifecycleState, brightness],
    );

    useEffect(
      () {
        // Обработчик событий окна приложения.
        final manager = FlutterVKWindowManager(ref: ref);
        if (isWindows) {
          windowManager.addListener(manager);
        }

        return () => windowManager.removeListener(manager);
      },
      [],
    );

    final player = ref.read(playerProvider);
    final router = ref.watch(routerProvider);
    final preferences = ref.watch(preferencesProvider);
    final schemeInfo = ref.watch(trackSchemeInfoProvider);

    final bool appWideColors = preferences.playerColorsAppWide;
    final playerLightColorScheme = appWideColors
        ? useMemoized(
            () => schemeInfo?.createScheme(
              Brightness.light,
              schemeVariant: preferences.dynamicSchemeType,
            ),
            [schemeInfo, preferences.dynamicSchemeType],
          )
        : null;
    final playerDarkColorScheme = appWideColors
        ? useMemoized(
            () => schemeInfo?.createScheme(
              Brightness.dark,
              schemeVariant: preferences.dynamicSchemeType,
            ),
            [schemeInfo, preferences.dynamicSchemeType],
          )
        : null;

    return DynamicColorBuilder(
      builder:
          (ColorScheme? dynamicLightScheme, ColorScheme? dynamicDarkScheme) {
        final (ColorScheme, ColorScheme)? dynamicSchemesFixed =
            dynamicLightScheme != null
                ? generateDynamicColorSchemes(
                    dynamicLightScheme,
                    dynamicDarkScheme!,
                  )
                : null;

        final lightScheme = playerLightColorScheme ??
            dynamicSchemesFixed?.$1 ??
            fallbackLightColorScheme;
        final darkScheme = playerDarkColorScheme ??
            dynamicSchemesFixed?.$2 ??
            fallbackDarkColorScheme;

        final pageTransitions = PageTransitionsTheme(
          builders: {
            for (final platform in TargetPlatform.values)
              platform: const BackGesturePageTransitionsBuilder(
                parentTransitionBuilder:
                    SharedAxisHorizontalPageTransitionsBuilder(),
              ),
          },
        );

        return ExcludeSemantics(
          child: MaterialApp.router(
            theme: ThemeData(
              colorScheme: lightScheme,
              pageTransitionsTheme: pageTransitions,
              appBarTheme: const AppBarTheme(
                centerTitle: true,
              ),
            ),
            darkTheme: ThemeData(
              colorScheme: darkScheme.copyWith(
                surface: preferences.oledTheme ? Colors.black : null,
              ),
              cardTheme: preferences.oledTheme
                  ? CardThemeData(color: darkScheme.surfaceContainerLowest)
                  : null,
              pageTransitionsTheme: pageTransitions,
              appBarTheme: const AppBarTheme(
                centerTitle: true,
              ),
            ),
            themeMode: preferences.theme,
            themeAnimationDuration: const Duration(
              milliseconds: 500,
            ),
            themeAnimationCurve: Curves.easeInOut,
            routerConfig: router,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            localeResolutionCallback: localeResolutionCallback,
            supportedLocales: AppLocalizations.supportedLocales,
            shortcuts: {
              const SingleActivator(
                LogicalKeyboardKey.keyF,
                control: true,
              ): const FavoriteTracksIntent(),
              const SingleActivator(
                LogicalKeyboardKey.f11,
              ): const FullscreenPlayerIntent(),
              const SingleActivator(
                LogicalKeyboardKey.space,
              ): const PlayPauseIntent(),
              const SingleActivator(
                LogicalKeyboardKey.arrowLeft,
                control: true,
              ): const PreviousTrackIntent(),
              const SingleActivator(
                LogicalKeyboardKey.arrowRight,
                control: true,
              ): const NextTrackIntent(),
              const SingleActivator(
                LogicalKeyboardKey.arrowLeft,
              ): const RewindIntent(),
              const SingleActivator(
                LogicalKeyboardKey.arrowRight,
              ): const FastForwardIntent(),
              const SingleActivator(
                LogicalKeyboardKey.arrowUp,
              ): const VolumeUpIntent(),
              const SingleActivator(
                LogicalKeyboardKey.arrowDown,
              ): const VolumeDownIntent(),
              const SingleActivator(
                LogicalKeyboardKey.keyS,
              ): const ShuffleIntent(),
              const SingleActivator(
                LogicalKeyboardKey.keyL,
              ): const LoopModeIntent(),
              const SingleActivator(
                LogicalKeyboardKey.keyQ,
                control: true,
              ): const CloseAppIntent(),
              const SingleActivator(
                LogicalKeyboardKey.escape,
              ): const CloseRouteIntent(),
            },
            actions: {
              FavoriteTracksIntent: CallbackAction(
                onInvoke: (intent) {
                  final ownerID = ref.read(userProvider).id;

                  return router.go("/music/playlist/$ownerID/0");
                },
              ),
              FullscreenPlayerIntent: CallbackAction(
                onInvoke: (intent) {
                  final path = router.state.fullPath;
                  if (path == "/player") {
                    router.pop();

                    return;
                  }

                  if (!player.isLoaded) return;

                  router.push("/player");

                  return null;
                },
              ),
              PlayPauseIntent: CallbackAction(
                onInvoke: (intent) => player.togglePlay(),
              ),
              PreviousTrackIntent: CallbackAction(
                onInvoke: (intent) => player.smartPrevious(),
              ),
              NextTrackIntent: CallbackAction(
                onInvoke: (intent) => player.next(),
              ),
              RewindIntent: CallbackAction(
                onInvoke: (intent) => player.seekBy(
                  const Duration(
                    seconds: -seekSeconds,
                  ),
                ),
              ),
              FastForwardIntent: CallbackAction(
                onInvoke: (intent) => player.seekBy(
                  const Duration(
                    seconds: seekSeconds,
                  ),
                ),
              ),
              VolumeUpIntent: CallbackAction(
                onInvoke: (intent) => player.setVolumeBy(0.1),
              ),
              VolumeDownIntent: CallbackAction(
                onInvoke: (intent) => player.setVolumeBy(-0.1),
              ),
              ShuffleIntent: CallbackAction(
                onInvoke: (intent) {
                  if (player.playlist?.type == PlaylistType.audioMix) {
                    return null;
                  }

                  return player.toggleShuffle();
                },
              ),
              LoopModeIntent: CallbackAction(
                onInvoke: (intent) => player.toggleRepeat(),
              ),
              CloseAppIntent: CallbackAction(
                onInvoke: (intent) => windowManager.close(),
              ),
              CloseRouteIntent: CallbackAction(
                onInvoke: (intent) {
                  if (!router.canPop()) return;

                  router.pop();

                  return null;
                },
              ),
            },
          ),
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
                    color: ColorScheme.of(context).error,
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
