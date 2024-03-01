import "dart:async";
import "dart:ui";

import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:fullscreen_window/fullscreen_window.dart";
import "package:just_audio/just_audio.dart";
import "package:provider/provider.dart";
import "package:responsive_builder/responsive_builder.dart";
import "package:scroll_to_index/scroll_to_index.dart";
import "package:styled_text/styled_text.dart";
import "package:visibility_detector/visibility_detector.dart";
import "package:wakelock_plus/wakelock_plus.dart";
import "package:window_manager/window_manager.dart";

import "../api/vk/api.dart";
import "../api/vk/audio/get_lyrics.dart";
import "../consts.dart";
import "../extensions.dart";
import "../intents.dart";
import "../main.dart";
import "../provider/color.dart";
import "../provider/user.dart";
import "../services/cache_manager.dart";
import "../services/logger.dart";
import "../utils.dart";
import "fullscreen_player/desktop.dart";
import "fullscreen_player/mobile.dart";

/// Указывает, открыт ли полноэкранный плеер.
///
/// Для открытия или закрытия полноэкранного плеера воспользуйтесь методом [openFullscreenPlayer] или [closeFullscreenPlayer].
bool isFullscreenPlayerOpen = false;

/// Указывает, открыт ли мини плеер.
///
/// Для открытия или закрытия мини плеера воспользуйтесь методом [openMiniPlayer] или [closeMiniPlayer].
bool isMiniplayerOpen = false;

/// Метод, который открывает музыкальный плеер на всё окно, либо на весь экран, если приложение запущено на Desktop-платформе. Если [fullscreenOnDesktop] правдив, и приложение запущено на Desktop ([isDesktop]), то тогда приложение перейдёт в полноэкранный режим.
///
/// Для закрытия воспользуйтесь методом [closeFullscreenPlayer].
Future<void> openFullscreenPlayer(
  BuildContext context, {
  bool fullscreenOnDesktop = true,
}) async {
  // Если плеер уже открыт, то ничего не делаем.
  if (isFullscreenPlayerOpen || isMiniplayerOpen) {
    return;
  }

  // Если приложение запущено на Desktop, то нужно отобразить окно на весь экран.
  if (isDesktop && fullscreenOnDesktop) {
    await FullScreenWindow.setFullScreen(true);
  }

  if (!context.mounted) return;

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const FullscreenPlayerRoute(),
    ),
  );

  isFullscreenPlayerOpen = true;

  // Делаем Wakelock, что бы экран не отключался во время открытого плеера.
  await WakelockPlus.enable();
}

/// Метод, закрывающий ранее открытый при помощи метода [openFullscreenPlayer] полноэкранный плеер.
Future<void> closeFullscreenPlayer(
  BuildContext context, {
  bool popRoute = true,
}) async {
  // Если плеер не открыт, то ничего не делаем.
  if (!isFullscreenPlayerOpen || isMiniplayerOpen) {
    return;
  }

  // Если приложение запущено на Desktop, то нужно закрыть полноэкранный режим.
  if (isDesktop) {
    await FullScreenWindow.setFullScreen(false);
  }

  if (!context.mounted) return;

  if (popRoute) Navigator.of(context).pop();

  isFullscreenPlayerOpen = false;

  // Убираем Wakelock для защиты от отключения экрана.
  await WakelockPlus.disable();
}

/// Вызывает [openFullscreenPlayer] или [closeFullscreenPlayer], в зависимости о того, открыт сейчас полноэкранный плеер или нет.
Future<void> toggleFullscreenPlayer(
  BuildContext context, {
  bool fullscreenOnDesktop = true,
  bool popRoute = true,
}) async {
  if (isFullscreenPlayerOpen) {
    await closeFullscreenPlayer(
      context,
      popRoute: popRoute,
    );

    return;
  }

  await openFullscreenPlayer(
    context,
    fullscreenOnDesktop: fullscreenOnDesktop,
  );
}

/// Открывает мини плеер, создавая маленькое "окошко" приложения.
Future<void> openMiniPlayer(
  BuildContext context,
) async {
  // Если плеер уже открыт, то ничего не делаем.
  if (isMiniplayerOpen || isFullscreenPlayerOpen) {
    return;
  }

  if (!context.mounted) return;

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const FullscreenPlayerRoute(),
    ),
  );

  // Если приложение запущено на Desktop, то делаем окошко маленьким.
  if (isDesktop) {
    await windowManager.setMinimumSize(
      const Size(
        300,
        150,
      ),
    );
    await windowManager.setMaximumSize(
      const Size(
        300,
        350,
      ),
    );
    await windowManager.setSize(
      const Size(
        300,
        350,
      ),
    );
    await windowManager.restore();
    await windowManager.setMaximizable(false);
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setAlignment(Alignment.bottomRight);
  }

  isMiniplayerOpen = true;
}

/// Метод, закрывающий ранее открытый при помощи метода [openFullscreenPlayer] мини плеер.
Future<void> closeMiniPlayer(
  BuildContext context, {
  bool popRoute = true,
}) async {
  // Если плеер не открыт, то ничего не делаем.
  if (!isMiniplayerOpen || isFullscreenPlayerOpen) {
    return;
  }

  if (popRoute && context.mounted) Navigator.of(context).pop();

  // Если приложение запущено на Desktop, то делаем окошко маленьким.
  if (isDesktop) {
    await windowManager.setMinimumSize(
      const Size(
        400,
        300,
      ),
    );
    await windowManager.setMaximumSize(
      const Size(
        10000,
        10000,
      ),
    );
    await windowManager.setSize(
      const Size(
        1280,
        720,
      ),
    );
    await windowManager.setMaximizable(true);
    await windowManager.setAlwaysOnTop(false);
    await windowManager.setResizable(true);
    await windowManager.center();
  }

  isMiniplayerOpen = false;
}

/// Вызывает [openMiniPlayer] или [closeMiniPlayer], в зависимости о того, открыт сейчас мини плеер или нет.
Future<void> toggleMiniPlayer(
  BuildContext context, {
  bool popRoute = true,
}) async {
  if (isMiniplayerOpen) {
    await closeMiniPlayer(
      context,
      popRoute: popRoute,
    );

    return;
  }

  await openMiniPlayer(
    context,
  );
}

/// Определяет, открыт сейчас мини плеер или полноэкранный плеер, и если открыт какой-то из них, вызывает [closeMiniPlayer] либо [closeFullscreenPlayer].
Future<void> closePlayer(
  BuildContext context, {
  bool popRoute = true,
}) async {
  // Закрываем мини плеер.
  if (isMiniplayerOpen) {
    await closeMiniPlayer(
      context,
      popRoute: popRoute,
    );

    return;
  }

  // Закрываем полноэкранный плеер.
  if (isFullscreenPlayerOpen) {
    await closeFullscreenPlayer(
      context,
      popRoute: popRoute,
    );

    return;
  }

  // Ничего не открыто. Ничего не делаем.
}

/// Виджет, отображающий отдельную строчку линии в тексте трека. По нажатию по данной линии, плеер перемотается на начало данной линии.
class TrackLyric extends StatelessWidget {
  /// Текст данной строчки. Если данное поле равно null, то вместо текста будет использоваться виджет [Icon], с иконкой ноты.
  final String? line;

  /// Указывает, что данная строчка была проиграна ранее, и теперь она неактивна.
  final bool isOld;

  /// Указывает, что данная строчка сейчас активна.
  final bool isActive;

  /// Указывает, что текст должен находиться по центру.
  final bool centerText;

  /// Действие, вызываемое при нажатии на данную строчку.
  final VoidCallback? onTap;

  const TrackLyric({
    super.key,
    this.line,
    this.isOld = false,
    required this.isActive,
    this.centerText = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color color = Theme.of(context).colorScheme.primary.withOpacity(
          isActive && !isOld
              ? 1.0
              : isOld
                  ? 0.75
                  : 0.5,
        );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
        globalBorderRadius,
      ),
      child: AnimatedDefaultTextStyle(
        duration: const Duration(
          milliseconds: 300,
        ),
        style: TextStyle(
          fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
          color: color,
          fontSize: 24,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 4,
          ),
          child: line != null
              ? Text(
                  line!,
                  textAlign: centerText ? TextAlign.center : null,
                )
              : Icon(
                  Icons.music_note,
                  color: color,
                ),
        ),
      ),
    );
  }
}

/// Виджет, отображающий текст трека.
class TrackLyricsBlock extends StatefulWidget {
  static AppLogger logger = getLogger("TrackLyricsBlock");

  /// Отображаемый текст песни.
  final Lyrics lyrics;

  const TrackLyricsBlock({
    super.key,
    required this.lyrics,
  });

  @override
  State<TrackLyricsBlock> createState() => _TrackLyricsBlockState();
}

class _TrackLyricsBlockState extends State<TrackLyricsBlock> {
  /// [AutoScrollController] для [ListView.builder], необходимый для автоматического перемещения до определённой строчки.
  final AutoScrollController controller = AutoScrollController();

  /// Текст песни.
  late List<LyricTimestamp> lyrics;

  /// Массив, содержащий в себе информацию о том, какие блоки текста песни видны/не видны на экране.
  late List<bool>? visibilityIndexes;

  /// Указывает текущую активную строчку в тексте песни.
  int? currentLyricIndex;

  /// Указывает, что виджет с текстом песни виден внутри ListView.
  bool get currentLyricIsVisible => visibilityIndexes != null
      ? visibilityIndexes![currentLyricIndex ?? 0]
      : false;

  /// Указывает, производится ли скроллинг пользователем в [ListView.builder] или нет.
  bool currentlyScrolling = false;

  /// Вызывается при изменении состояния скроллинга у [ListView.builder].
  void onScroll() =>
      currentlyScrolling = controller.position.isScrollingNotifier.value &&
          !controller.isAutoScrolling;

  @override
  void initState() {
    super.initState();

    // Если у нас несинхронизированный текст песни, то тогда нам нужно преобразовать все [String] в [LyricTimestamp].
    lyrics = (widget.lyrics.timestamps ?? widget.lyrics.text!).map(
      (dynamic item) {
        if (item is LyricTimestamp) return item;

        return LyricTimestamp(
          line: item as String,
        );
      },
    ).toList();

    // Слушаем события скроллинга.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.position.isScrollingNotifier.addListener(onScroll);
    });

    // Пытаемся найти текущий момент в тексте песни, если мы уже что-то воспроизвели.
    currentLyricIndex = getCurrentLyricIndex();

    // Заполняем массив видимости строчек песни.
    visibilityIndexes = List.generate(
      lyrics.length,
      (index) => index == currentLyricIndex,
    );

    // Скроллим до этого момента в треке.
    if (currentLyricIndex != null) {
      scrollToIndex(
        currentLyricIndex!,
        checkVisibility: false,
      );
    }
  }

  @override
  void dispose() {
    super.dispose();

    if (controller.hasClients) {
      controller.position.isScrollingNotifier.removeListener(onScroll);
    }
  }

  /// Возвращает индекс текущей строчки в тексте песни.
  int? getCurrentLyricIndex() {
    final int playerPosition = player.position.inMilliseconds;

    // Узнаём индекс строчки в тексте песни.
    // Начинаем с конца, на случай, если по какой-то причине "поют" сразу две строчки песни.
    for (var i = lyrics.length - 1; i >= 0; i--) {
      LyricTimestamp lyric = lyrics[i];

      // Если нам не дано начало, то просто ничего не делаем.
      if (lyric.begin == null) return null;

      // Если у нас плеер находится в 'правильной' позиции, то тогда мы нашли активную строчку.
      if (playerPosition >= lyric.begin! && playerPosition <= lyric.end!) {
        return i;
      }
    }

    // Если ничего не найдено, то индекс должен отсутствовать.
    return currentLyricIndex;
  }

  /// Прокручивает [ListView] с текстом до указанного [index]. Если [checkVisibility] = true, то прокрутка произойдёт только в том случае, если виджет с текстом виден пользователю. [checkScroll] указывает, что скроллинг не будет происходить, если пользователь сам скроллит.
  Future<void> scrollToIndex(
    int index, {
    bool checkVisibility = true,
    bool checkScroll = true,
  }) async {
    // Проверяем на видимость.
    if (checkVisibility && !currentLyricIsVisible) return;

    // Проверяем на то, скроллит ли пользователь в данный момент или нет.
    if (checkScroll && currentlyScrolling) return;

    controller.scrollToIndex(
      currentLyricIndex!,
      preferPosition: AutoScrollPosition.middle,
    );
  }

  /// Метод, вызываемый при изменении строчки песни.
  void onLyricLineChanged() {
    // Если индекс неизвестен, то ничего не делаем.
    if (currentLyricIndex == null) return;

    scrollToIndex(currentLyricIndex!);
  }

  @override
  Widget build(BuildContext context) {
    // Пытаемся найти индекс текущего момента в тексте песни.
    final int? newLyricIndex = getCurrentLyricIndex();

    // Если поменялась строчка песни, то скроллим до этой строчки.
    if (newLyricIndex != currentLyricIndex) {
      currentLyricIndex = newLyricIndex;

      onLyricLineChanged();
    }

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        scrollbars: false,
      ),
      child: ListView.builder(
        controller: controller,
        itemCount: lyrics.length,
        itemBuilder: (BuildContext context, int index) {
          final LyricTimestamp lyric = lyrics[index];
          final bool isSyncedLyric = lyric.begin != null;

          bool isActive = isSyncedLyric && currentLyricIndex != null
              ? currentLyricIndex! == index
              : false;
          bool isOld = isSyncedLyric && currentLyricIndex != null
              ? currentLyricIndex! > index
              : true;

          return AutoScrollTag(
            key: ValueKey(index),
            controller: controller,
            index: index,
            child: VisibilityDetector(
              key: ValueKey(index),
              onVisibilityChanged: (VisibilityInfo info) {
                visibilityIndexes![index] = info.visibleFraction > 0;
              },
              child: TrackLyric(
                line: lyric.line,
                isActive: isActive,
                isOld: isOld,
                centerText: isSyncedLyric,
                onTap: isSyncedLyric
                    ? () => player.seek(
                          Duration(
                            milliseconds: lyric.begin!,
                          ),
                          play: true,
                        )
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Виджет, отображающий размытое фоновое изображение для полноэкранногоп плеера.
class BlurredBackgroundImage extends StatefulWidget {
  const BlurredBackgroundImage({
    super.key,
  });

  @override
  State<BlurredBackgroundImage> createState() => _BlurredBackgroundImageState();
}

class _BlurredBackgroundImageState extends State<BlurredBackgroundImage> {
  late final List<StreamSubscription> subscriptions;

  @override
  void initState() {
    super.initState();

    subscriptions = [
      player.sequenceStateStream.listen(
        (SequenceState? state) => setState(() {}),
      ),
    ];
  }

  @override
  void dispose() {
    super.dispose();

    for (StreamSubscription subscription in subscriptions) {
      subscription.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: 50,
          sigmaY: 50,
        ),
        child: CachedNetworkImage(
          imageUrl: player.currentAudio!.album!.thumbnails!.photo1200!,
          cacheKey: "${player.currentAudio!.album!.id}1200",
          fit: BoxFit.cover,
          cacheManager: CachedNetworkImagesManager.instance,
          color: Colors.black.withOpacity(0.55),
          colorBlendMode: BlendMode.darken,
          memCacheWidth: MediaQuery.of(context).size.width.toInt(),
          memCacheHeight: MediaQuery.of(context).size.height.toInt(),
        ),
      ),
    );
  }
}

/// Route, отображающий полноэкранный плеер.
class FullscreenPlayerRoute extends StatefulWidget {
  const FullscreenPlayerRoute({
    super.key,
  });

  @override
  State<FullscreenPlayerRoute> createState() => _FullscreenPlayerRouteState();
}

class _FullscreenPlayerRouteState extends State<FullscreenPlayerRoute> {
  static AppLogger logger = getLogger("FullscreenPlayerDesktopRoute");

  /// Список из [Audio.mediaKey] треков, текст песен которых пытается загрузиться в данный момент.
  ///
  /// Данное поле нужно, что бы при повторном вызове метода [build] не делалось множество HTTP-запросов.
  final List<String> lyricsQueue = [];

  /// Подписки на изменения состояния воспроизведения трека.
  late final List<StreamSubscription> subscriptions;

  @override
  void initState() {
    super.initState();

    subscriptions = [
      player.sequenceStateStream.listen(
        (SequenceState? state) => setState(() {}),
      ),
    ];
  }

  @override
  void dispose() {
    super.dispose();

    for (StreamSubscription subscription in subscriptions) {
      subscription.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final UserProvider user = Provider.of<UserProvider>(context);
    final PlayerSchemeProvider colorScheme =
        Provider.of<PlayerSchemeProvider>(context);

    // Проверка на случай, если запустился плеер без активного трека.
    if (player.currentAudio == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // GIF с собакой.
              RepaintBoundary(
                child: Image.asset(
                  "assets/images/dog.gif",
                  width: 25 * 5,
                  height: 12 * 5,
                  fit: BoxFit.fill,
                ),
              ),
              const SizedBox(
                height: 18,
              ),

              // Текст.
              StyledText(
                text: AppLocalizations.of(context)!.music_fullscreenNoAudio,
                textAlign: TextAlign.center,
                tags: {
                  "bold": StyledTextTag(
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  "exit": StyledTextActionTag(
                    (String? text, Map<String?, String?> attrs) {
                      closePlayer(context);
                    },
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                },
              ),
              const SizedBox(
                height: 24,
              ),

              // Кнопка для выхода.
              FilledButton.icon(
                onPressed: () => closePlayer(context),
                icon: const Icon(
                  Icons.fullscreen_exit,
                ),
                label: Text(
                  AppLocalizations.of(context)!.music_fullscreenNoAudioButton,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Запускаем задачу по получению цветовой схемы.
    player.getColorSchemeAsync().then(
      ((ColorScheme, ColorScheme)? schemes) {
        if (schemes == null) return;

        colorScheme.setScheme(
          schemes.$1,
          schemes.$2,
          player.currentAudio!.mediaKey,
        );
      },
    );

    // Если известно, что у трека есть текст песни, то пытаемся его загрузить.
    if (player.currentAudio!.hasLyrics &&
        player.currentAudio!.lyrics == null &&
        !lyricsQueue.contains(player.currentAudio!.mediaKey)) {
      lyricsQueue.add(player.currentAudio!.mediaKey);

      user.audioGetLyrics(player.currentAudio!.mediaKey).then(
        (APIAudioGetLyricsResponse response) {
          raiseOnAPIError(response);

          // Сохраняем текст песни.
          player.currentAudio!.lyrics = response.response!.lyrics;

          user.updatePlaylist(player.currentPlaylist!);
          user.markUpdated(false);
        },
      ).onError(
        (error, stackTrace) {
          logger.e(
            "Ошибка при попытке получить lyrics трека с ID ${player.currentAudio!.mediaKey}: ",
            error: error,
            stackTrace: stackTrace,
          );

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.musicFullscreenLyricsLoadError(
                    error.toString(),
                  ),
                ),
              ),
            );
          }
        },
      );
    }

    /// Указывает, что будет использоваться Mobile Layout.
    final bool useMobileLayout =
        getDeviceType(MediaQuery.of(context).size) == DeviceScreenType.mobile;

    return AnnotatedRegion(
      value: const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Theme(
        data: ThemeData(
          colorScheme: colorScheme.darkColorScheme ?? fallbackDarkColorScheme,
        ),
        child: Builder(
          builder: (
            BuildContext context,
          ) {
            return Scaffold(
              body: Actions(
                actions: {
                  FullscreenPlayerIntent: CallbackAction(
                    onInvoke: (intent) => closePlayer(context),
                  ),
                },
                child: CallbackShortcuts(
                  bindings: {
                    const SingleActivator(
                      LogicalKeyboardKey.escape,
                    ): () => closePlayer(context),
                  },
                  child: PopScope(
                    onPopInvoked: (_) {
                      closePlayer(
                        context,
                        popRoute: false,
                      );

                      return;
                    },
                    child: Focus(
                      autofocus: true,
                      canRequestFocus: true,
                      child: AnimatedContainer(
                        duration: const Duration(
                          milliseconds: 500,
                        ),
                        curve: Curves.ease,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Theme.of(context).colorScheme.primaryContainer,
                              Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .darken(0.5),
                            ],
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Размытое фоновое изображение.
                            if (player.currentAudio?.album?.thumbnails !=
                                    null &&
                                user.settings.playerThumbAsBackground)
                              SizedBox(
                                width: MediaQuery.of(context).size.width,
                                height: MediaQuery.of(context).size.height,
                                child: const BlurredBackgroundImage(),
                              ),

                            // Внутреннее содержимое, зависящее от типа Layout'а.
                            SafeArea(
                              child: useMobileLayout
                                  ? const FullscreenPlayerMobileRoute()
                                  : const FullscreenPlayerDesktopRoute(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
