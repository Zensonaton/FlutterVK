import "dart:io";

import "package:dynamic_color/dynamic_color.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:just_audio_background/just_audio_background.dart";
import "package:media_kit/media_kit.dart";
import "package:provider/provider.dart";
import "package:responsive_builder/responsive_builder.dart";
import "package:window_manager/window_manager.dart";

import "provider/color.dart";
import "provider/user.dart";
import "routes/home.dart";
import "routes/welcome.dart";
import "services/audio_player.dart";
import "utils.dart";
import "widgets/loading_overlay.dart";

/// Глобальный объект [BuildContext].
///
/// За этот костыль меня могут отпиздить, и правильно сделают. Данный BuildContext нужен, что бы можно было извлекать ключи локализации там, где BuildContext отсутствует (внутри методов initState, к примеру).
///
/// Источник: https://christopher.khawand.dev/posts/flutter-internationalization-without-buildcontext
BuildContext? buildContext;

/// Объект аудиоплеера.
late final VKMusicPlayer player;

final fallbackLightColorScheme = ColorScheme.fromSeed(
  seedColor: Colors.blueAccent,
);

final fallbackDarkColorScheme = ColorScheme.fromSeed(
  seedColor: Colors.blueAccent,
  brightness: Brightness.dark,
);

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

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
        ), () async {
      await windowManager.show();

      // Делаем фокус окна не в debug-режиме.
      if (!kDebugMode) {
        await windowManager.focus();
      }
    });
  }

  // Инициализируем плеер.
  player = VKMusicPlayer();

  // Регистрируем AudioHandler для управления музыки при помощи уведомлений.
  await JustAudioBackground.init(
    androidNotificationChannelName: "Flutter VK",
    androidNotificationChannelId: "com.zensonaton.fluttervk",
    androidNotificationIcon: "drawable/notification_icon",
    androidNotificationOngoing: true,
    preloadArtwork: true,
  );

  ResponsiveSizingConfig.instance.setCustomBreakpoints(
    const ScreenBreakpoints(
      desktop: 900,
      tablet: 700,
      watch: 100,
    ),
  );

  // Делаем панель навигации прозрачной.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

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
}

class MainApp extends StatefulWidget {
  const MainApp({
    super.key,
  });

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WindowListener {
  ThemeData buildTheme(ColorScheme colorScheme) => ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
      );

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

    user.markUpdated(false);
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
  void onWindowClose() {
    // TODO: Сделать так, что бы приложение просто минимизировалось при закрытии, если это позволяет сделать настройка у пользователя.

    exit(-1);
  }

  @override
  Widget build(BuildContext context) {
    final UserProvider user = Provider.of<UserProvider>(context);
    final PlayerSchemeProvider colorScheme =
        Provider.of<PlayerSchemeProvider>(context);

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
        theme: buildTheme(
          playerLightColorScheme ??
              lightColorScheme ??
              fallbackLightColorScheme,
        ),
        darkTheme: buildTheme(
          playerDarkColorScheme ?? darkColorScheme ?? fallbackDarkColorScheme,
        ),
        themeMode: user.settings.theme,
        themeAnimationDuration: const Duration(
          milliseconds: 500,
        ),
        themeAnimationCurve: Curves.ease,
        builder: (BuildContext context, Widget? child) {
          return LoadingOverlay(
            child: child!,
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
          LogicalKeySet(LogicalKeyboardKey.space): const ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (ActivateIntent intent) => player.togglePlay(),
          )
        },
        supportedLocales: const [
          Locale("ru"),
          Locale("en"),
        ],
        home: home,
      );
    });
  }
}
