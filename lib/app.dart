import "dart:io";

import "package:dynamic_color/dynamic_color.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:gap/gap.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:local_notifier/local_notifier.dart";
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
import "routes/home/profile.dart";
import "utils.dart";
import "widgets/loading_overlay.dart";

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
    assert(
      isDesktop,
      "onWindowClose() called on non-desktop platform",
    );

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
}

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
    // В данный момент, этот метод ничего не делает.

    return app;
  }
}

/// Основной виджет главного приложения, используемый методом [runApp] внутри [main].
///
/// В случае, если по какой-то причине произойдёт ошибка, вместо этого класса будет вызван [runApp], но для класса [ErroredApp], который символизирует ошибку запуска приложения.
class FlutterVKApp extends HookConsumerWidget {
  const FlutterVKApp({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(
      () {
        final manager = FlutterVKWindowManager(ref: ref);
        windowManager.addListener(manager);

        return () => windowManager.removeListener(manager);
      },
      [],
    );

    // Делаем панель навигации прозрачной.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    final router = ref.watch(routerProvider);
    final preferences = ref.watch(preferencesProvider);
    final schemeInfo = ref.watch(trackSchemeInfoProvider);

    final bool appwideColors = preferences.playerColorsAppWide;
    final playerLightColorScheme = appwideColors
        ? useMemoized(
            () => schemeInfo?.createScheme(
              Brightness.light,
              schemeVariant: preferences.dynamicSchemeType,
            ),
            [schemeInfo, preferences.dynamicSchemeType],
          )
        : null;
    final playerDarkColorScheme = appwideColors
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
