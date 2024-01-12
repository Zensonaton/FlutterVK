import "package:audio_service/audio_service.dart";
import "package:dynamic_color/dynamic_color.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:media_kit/media_kit.dart";
import "package:provider/provider.dart";
import "package:responsive_builder/responsive_builder.dart";

import "provider/user.dart";
import "routes/home.dart";
import "routes/welcome.dart";
import "services/audio_player.dart";
import "widgets/loading_overlay.dart";

/// Глобальный объект [BuildContext].
///
/// За этот костыль меня могут отпиздить, и правильно сделают. Данный BuildContext нужен, что бы можно было извлекать ключи локализации там, где BuildContext отсутствует (внутри методов initState, к примеру).
///
/// Источник: https://christopher.khawand.dev/posts/flutter-internationalization-without-buildcontext
BuildContext? buildContext;

/// Объект аудиоплеера.
///
/// TODO: Каким-то образом, спрятать данный объект куда-то, вместо того, что бы использовать его как глобальную переменную.
late final VKMusicPlayer player;

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  // Инициализируем плеер.
  player = VKMusicPlayer();

  // Регистрируем AudioHandler для управления музыки при помощи уведомлений.
  player.audioPlayerHandler = await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelName: "Flutter VK",
      androidNotificationChannelId: "com.zensonaton.fluttervk",
      preloadArtwork: true,
    ),
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
    ChangeNotifierProvider(
      create: (context) => UserProvider(false),
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

class _MainAppState extends State<MainApp> {
  static final fallbackLightColorScheme = ColorScheme.fromSeed(
    seedColor: Colors.blueAccent,
  );

  static final fallbackDarkColorScheme = ColorScheme.fromSeed(
    seedColor: Colors.blueAccent,
    brightness: Brightness.dark,
  );

  ThemeData buildTheme(ColorScheme colorScheme) => ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
      );

  /// Виджет, который будет хранить в себе "главную" страницу, с которой и начнётся изначальная навигация пользователем.
  Widget? home;

  void init() async {
    // Загружаем объект пользователя с диска.
    final UserProvider user = Provider.of<UserProvider>(context, listen: false);

    // Узнаём, куда нужно перекинуть пользователя.
    home = await user.loadFromDisk() ? const HomeRoute() : const WelcomeRoute();

    // Восстанавливаем состояние shuffle у плеера.
    if (user.settings.shuffleEnabled) {
      player.setShuffle(true);
    }

    // Переключаем состояние Discord Rich Presence.
    if (user.settings.discordRPCEnabled) {
      await player.setDiscordRPCEnabled(true);
    }

    // Восстанавливаем состояние нормализации у плеера.
    if (user.settings.audioNormalizationEnabled) {
      await player.setAudioNormalization(true);
    }

    user.markUpdated(false);

    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    init();
  }

  @override
  Widget build(BuildContext context) {
    if (home == null) {
      return const Center(
        child: CircularProgressIndicator.adaptive(),
      );
    }

    return DynamicColorBuilder(builder: (lightColorScheme, darkColorScheme) {
      return MaterialApp(
        theme: buildTheme(lightColorScheme ?? fallbackLightColorScheme),
        darkTheme: buildTheme(darkColorScheme ?? fallbackDarkColorScheme),
        builder: ((BuildContext context, Widget? child) {
          return LoadingOverlay(
            child: child!,
          );
        }),
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
