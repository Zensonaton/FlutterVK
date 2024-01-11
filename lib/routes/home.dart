import "package:animations/animations.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/foundation.dart";
import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:media_kit/media_kit.dart";
import "package:provider/provider.dart";
import "package:responsive_builder/responsive_builder.dart";

import "../api/shared.dart";
import "../consts.dart";
import "../main.dart";
import "../provider/user.dart";
import "../services/audio_player.dart";
import "../services/logger.dart";
import "../utils.dart";
import "../widgets/error_dialog.dart";
import "../widgets/fallback_audio_photo.dart";
import "../widgets/swipe_detector.dart";
import "../widgets/wip_dialog.dart";
import "home/messages.dart";
import "home/music.dart";
import "home/profile.dart";

/// Виджет миниплеера, отображаемый внизу экрана.
class BottomMusicPlayer extends StatefulWidget {
  /// Объект [Audio], который играет в данный момент.
  final Audio? audio;

  /// Объект [Audio], олицетворяющий предыдущий трек в плейлисте, на который плеер сможет переключиться.
  final Audio? previousAudio;

  /// Объект [Audio], олицетворяющий следующий трек в плейлисте.
  ///
  /// Если данное поле оставить как null, то надпись, показывающая следующий трек перед завершением текущего (при [useBigLayout] = true) отображаться не будет.
  final Audio? nextAudio;

  /// Указывает, что в данный момент трек воспроизводится.
  final bool playbackState;

  /// Указывает, что трек в данный момент лайкнут.
  final bool favoriteState;

  /// Указывает прогресс прослушивания трека.
  ///
  /// В данном поле указано число от 0.0 до 1.0.
  final double progress;

  /// Указывает, что в данный момент происходит буферизация.
  final bool isBuffering;

  /// Указывает, что у плеера включён режим случайного перемешивания треков.
  final bool isShuffleEnabled;

  /// Указывает, что у плеера включён режим повтора текущего трека.
  final bool isRepeatEnabled;

  /// Указывает громкость у проигрывателя.
  ///
  /// В данном поле указано число от 0.0 до 1.0.
  final double volume;

  /// Метод, вызываемый при переключении состояния паузы.
  final ValueSetter<bool>? onPlayStateToggle;

  /// Метод, вызываемый при изменения состояния "лайка" трека.
  final ValueSetter<bool>? onFavoriteStateToggle;

  /// Метод, вызываемый при попытке запустить следующий трек (свайп влево).
  final VoidCallback? onNextTrack;

  /// Метод, вызываемый при попытке запустить предыдущий трек (свайп вправо).
  final VoidCallback? onPreviousTrack;

  /// Метод, вызываемый при переключении режима случайного выбора треков.
  final ValueSetter<bool>? onShuffleToggle;

  /// Метод, вызываемый при переключении повтора трека.
  final ValueSetter<bool>? onRepeatToggle;

  /// Метод, вызываемый при попытке открыть полноэкранный плеер свайпов вверх.
  final VoidCallback? onFullscreen;

  /// Метод, вызываемый при попытке закрыть плеер свайпом вниз.
  final VoidCallback? onDismiss;

  /// Метод, вызываемый при изменении громкости.
  ///
  /// Выводом данного Callback'а является число от 0.0 до 1.0.
  final Function(double)? onVolumeChange;

  /// Если [true], то тогда будет использоваться альтернативный вид плеера, который предназначен для desktop-интерфейса.
  final bool useBigLayout;

  const BottomMusicPlayer({
    super.key,
    this.audio,
    this.previousAudio,
    this.nextAudio,
    this.playbackState = false,
    this.favoriteState = false,
    this.isBuffering = false,
    this.isShuffleEnabled = false,
    this.isRepeatEnabled = false,
    this.volume = 1,
    this.progress = 0,
    this.onPlayStateToggle,
    this.onFavoriteStateToggle,
    this.onNextTrack,
    this.onPreviousTrack,
    this.onShuffleToggle,
    this.onRepeatToggle,
    this.onFullscreen,
    this.onDismiss,
    this.onVolumeChange,
    this.useBigLayout = false,
  });

  @override
  State<BottomMusicPlayer> createState() => _BottomMusicPlayerState();
}

class _BottomMusicPlayerState extends State<BottomMusicPlayer> {
  /// Последняя известная цветовая схема для данного плеера.
  ///
  /// Используется как fallback в тот момент, пока актуальный [ColorScheme] ещё не был создан.
  ColorScheme? previousColorScheme;

  @override
  Widget build(BuildContext context) {
    // Если fallback-цветовая схема плеера не была сохранена, то нам нужно её сохранить.
    previousColorScheme ??= Theme.of(context).colorScheme;

    /// Url изображения данного трека.
    final String? imageUrl = widget.audio?.album?.thumb?.photo68;

    /// [ImageProvider] (если [imageUrl] не null) для отображения изображения трека.
    final ImageProvider? image = imageUrl != null
        ? CachedNetworkImageProvider(
            imageUrl,
            cacheKey: widget.audio!.mediaKey,
          )
        : null;

    /// Размеры блоков слева и справа (блок с названием и блок с управлением громкостью.)
    ///
    /// Данные блоки обязаны иметь одинаковый размер, поскольку в [Row] используется [MainAxisAlignment.spaceBetween].
    final double sideBlocksSize = clampDouble(
      MediaQuery.of(context).size.width / 2,
      150,
      1500,
    );

    /// Определяет по оставшейся длине трека то, стоит ли показывать надпись со следующим треком.
    final bool displayNextTrack =
        (widget.audio != null && widget.nextAudio != null)
            ? (widget.progress >= 0.9)
            : false;

    // TODO: Избавиться от этого FutureBuilder.
    return FutureBuilder(
      future: imageUrl != null
          ? generateColorSchemeFromImage(
              image!,
              MediaQuery.of(context).platformBrightness,
            )
          : null,
      builder: (BuildContext context, AsyncSnapshot<ColorScheme> snapshot) {
        // Если мы получили актуальную цветовую схему, то мы должны сохранить её.
        if (snapshot.connectionState == ConnectionState.done) {
          previousColorScheme = snapshot.data!;
        }

        final ColorScheme scheme = previousColorScheme!;

        final Widget favoriteButton = IconButton(
          onPressed: () =>
              widget.onFavoriteStateToggle ?? (!widget.favoriteState),
          icon: Icon(
            widget.favoriteState ? Icons.favorite : Icons.favorite_outline,
            color: scheme.primary,
          ),
        );
        final Widget playPauseButton = widget.useBigLayout
            ? IconButton.filled(
                onPressed: () =>
                    widget.onPlayStateToggle?.call(!widget.playbackState),
                icon: Icon(
                  widget.playbackState ? Icons.pause : Icons.play_arrow,
                  color: scheme.primary,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: scheme.primaryContainer,
                ),
              )
            : IconButton(
                onPressed: () =>
                    widget.onPlayStateToggle?.call(!widget.playbackState),
                icon: Icon(
                  widget.playbackState ? Icons.pause : Icons.play_arrow,
                  color: scheme.primary,
                ),
              );
        final Widget shuffleButton = IconButton(
          onPressed: () =>
              widget.onShuffleToggle?.call(!widget.isShuffleEnabled),
          icon: Icon(
            widget.isShuffleEnabled ? Icons.shuffle_on : Icons.shuffle,
            color: scheme.primary,
          ),
        );
        final Widget previousButton = IconButton(
          onPressed: widget.onPreviousTrack,
          icon: Icon(
            Icons.skip_previous,
            color: scheme.primary,
          ),
        );
        final Widget nextButton = IconButton(
          onPressed: widget.onNextTrack,
          icon: Icon(
            Icons.skip_next,
            color: scheme.primary,
          ),
        );
        final Widget repeatButton = IconButton(
          onPressed: () => widget.onRepeatToggle?.call(!widget.isRepeatEnabled),
          icon: Icon(
            widget.isRepeatEnabled ? Icons.repeat_on : Icons.repeat,
            color: scheme.primary,
          ),
        );

        final Widget volumeControl = Listener(
          onPointerSignal: (PointerSignalEvent event) {
            if (event is! PointerScrollEvent) return;

            // Flutter возвращает количество как числа, кратные 100.
            //
            // Поскольку мы храним громкость как число от 0.0 до 1.0, мы должны разделить "шаг скроллинга" на 1000.
            // Так же, нельзя забывать, что логика здесь немного инвертирована.
            final double scrollAmount = (-event.scrollDelta.dy) / 1000;

            widget.onVolumeChange?.call(
              clampDouble(
                widget.volume + scrollAmount,
                0,
                1,
              ),
            );
          },
          child: SliderTheme(
            data: SliderThemeData(
              overlayShape: SliderComponentShape.noThumb,
            ),
            child: Slider(
              value: widget.volume,
              onChanged: (double volume) => widget.onVolumeChange?.call(
                volume,
              ),
              thumbColor: scheme.primary,
              activeColor: scheme.primary,
              inactiveColor: scheme.primary,
            ),
          ),
        );
        final Widget fullscreenButton = FittedBox(
          child: IconButton(
            onPressed: () => showWipDialog(
              context,
              title: "Плеер на весь экран (F11)",
            ),
            icon: Icon(
              Icons.fullscreen,
              color: scheme.primary,
            ),
          ),
        );

        return AnimatedContainer(
          height: widget.useBigLayout ? 90 : 70,
          duration: const Duration(
            milliseconds: 250,
          ),
          decoration: BoxDecoration(
            color: darkenColor(
              scheme.primaryContainer,
              widget.playbackState ? 0 : 15,
            ),
            borderRadius: widget.useBigLayout
                ? null
                : BorderRadius.circular(globalBorderRadius),
            boxShadow: [
              BoxShadow(
                color: scheme.secondaryContainer,
                blurRadius: widget.playbackState ? 50 : 0,
                blurStyle: BlurStyle.outer,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Плеер.
              SizedBox(
                height: double.infinity,
                child: Padding(
                  padding: EdgeInsets.all(
                    widget.useBigLayout ? 12 : 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Блок с информацией о треке, его изображении, названия. Отображается в Desktop и Mobile layout'ах.
                      // Однако, кнопка для лайка добавляется именно в Desktop layout'е.
                      Flexible(
                        child: MouseRegion(
                          cursor: widget.useBigLayout
                              ? SystemMouseCursors.basic
                              : SystemMouseCursors.click,
                          child: SwipeDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: !widget.useBigLayout
                                ? () => showWipDialog(
                                      context,
                                      title: "Плеер на всё окно",
                                    )
                                : null,
                            onDoubleTap: !widget.useBigLayout
                                ? () => widget.onPlayStateToggle
                                    ?.call(!widget.playbackState)
                                : null,
                            onSwipeUp: !widget.useBigLayout
                                ? () => showWipDialog(
                                      context,
                                      title: "Плеер на всё окно",
                                    )
                                : null,
                            onSwipeDown:
                                !widget.useBigLayout ? widget.onDismiss : null,
                            onSwipeLeft: !widget.useBigLayout
                                ? widget.onNextTrack
                                : null,
                            onSwipeRight: !widget.useBigLayout
                                ? widget.onPreviousTrack
                                : null,
                            child: SizedBox(
                              width: widget.useBigLayout
                                  ? sideBlocksSize
                                  : double.infinity,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: SizedBox(
                                      width: widget.useBigLayout ? 60 : 50,
                                      height: widget.useBigLayout ? 60 : 50,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          globalBorderRadius,
                                        ),
                                        child: imageUrl != null
                                            ? Image(
                                                image: image!,
                                              )
                                            : const FallbackAudioAvatar(),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: widget.useBigLayout ? 14 : 8,
                                  ),
                                  Flexible(
                                    flex: 3,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            widget.audio?.title ?? "",
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: scheme.onBackground,
                                            ),
                                          ),
                                        ),
                                        Flexible(
                                          child: Text(
                                            widget.audio?.artist ?? "",
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: scheme.onBackground
                                                  .withOpacity(
                                                0.9,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (widget.useBigLayout)
                                    const Flexible(
                                      child: SizedBox(
                                        width: 12,
                                      ),
                                    ),
                                  if (widget.useBigLayout)
                                    Flexible(
                                      child: favoriteButton,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Кнопки управления по центру в desktop-layout'е.
                      if (widget.useBigLayout)
                        Flexible(
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              // Надпись "Играет следующим":
                              if (widget.useBigLayout &&
                                  widget.nextAudio != null)
                                AnimatedPositioned(
                                  duration: const Duration(
                                    milliseconds: 500,
                                  ),
                                  curve: Curves.ease,
                                  top: displayNextTrack
                                      ? -(70 / 2 + 25)
                                      : -(70 / 2),
                                  child: AnimatedOpacity(
                                    duration: const Duration(
                                      milliseconds: 200,
                                    ),
                                    curve: Curves.ease,
                                    opacity: displayNextTrack ? 1.0 : 0.0,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.music_note,
                                          color: scheme.primary,
                                        ),
                                        const SizedBox(
                                          width: 8,
                                        ),
                                        Text(
                                          "${widget.nextAudio!.artist} • ${widget.nextAudio!.title}",
                                          style: TextStyle(
                                            color: scheme.primary,
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),

                              // Ряд из кнопок управления.
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: shuffleButton,
                                  ),
                                  const SizedBox(
                                    width: 8,
                                  ),
                                  Flexible(
                                    child: previousButton,
                                  ),
                                  const SizedBox(
                                    width: 8,
                                  ),
                                  Flexible(
                                    child: playPauseButton,
                                  ),
                                  const SizedBox(
                                    width: 8,
                                  ),
                                  Flexible(
                                    child: nextButton,
                                  ),
                                  const SizedBox(
                                    width: 8,
                                  ),
                                  Flexible(
                                    child: repeatButton,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                      // Кнопки управления громкости и прочей мелочи справа в desktop-layout'е.
                      if (widget.useBigLayout)
                        Flexible(
                          child: SizedBox(
                            width: sideBlocksSize,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: SizedBox(
                                    width: 150,
                                    child: volumeControl,
                                  ),
                                ),
                                const SizedBox(
                                  width: 8,
                                ),
                                Flexible(
                                  child: fullscreenButton,
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Кнопки для установки лайка и паузы в мобильном layout'е.
                      if (!widget.useBigLayout)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            favoriteButton,
                            playPauseButton,
                          ],
                        )
                    ],
                  ),
                ),
              ),

              // Полоска внизу для отображения прогресса трека.
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.useBigLayout ? 0 : 16,
                  ),
                  child: widget.isBuffering
                      ? LinearProgressIndicator(
                          minHeight: 2,
                          color: scheme.primary.withOpacity(
                            widget.playbackState ? 1 : 0.5,
                          ),
                        )
                      : FractionallySizedBox(
                          widthFactor: widget.progress,
                          child: Container(
                            height: 2,
                            color: scheme.primary.withOpacity(
                              widget.playbackState ? 1 : 0.5,
                            ),
                          ),
                        ),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

/// Route, показываемый как "домашняя страница", где расположена навигация между разными частями приложения.
class HomeRoute extends StatefulWidget {
  const HomeRoute({
    super.key,
  });

  @override
  State<HomeRoute> createState() => _HomeRouteState();
}

class _HomeRouteState extends State<HomeRoute> {
  final AppLogger logger = getLogger("HomeRoute");

  /// Текущий индекс страницы для [BottomNavigationBar].
  int navigationScreenIndex = 0;

  /// Страницы навигации для [BottomNavigationBar].
  late List<NavigationPage> navigationPages;

  @override
  void initState() {
    super.initState();

    navigationPages = [
      NavigationPage(
        label: AppLocalizations.of(buildContext!)!.home_messagesPageLabel,
        icon: Icons.message_outlined,
        selectedIcon: Icons.message,
        route: const HomeMessagesPage(),
        audioPlayerAlign: Alignment.bottomLeft,
        allowBigAudioPlayer: false,
      ),
      NavigationPage(
        label: AppLocalizations.of(buildContext!)!.music_Label,
        icon: Icons.my_library_music_outlined,
        selectedIcon: Icons.my_library_music,
        route: const HomeMusicPage(),
      ),
      NavigationPage(
        label: AppLocalizations.of(buildContext!)!.home_profilePageLabel,
        icon: Icons.person_outlined,
        selectedIcon: Icons.person,
        route: const HomeProfilePage(),
      ),
    ];

    // Если поменялось время того, сколько было прослушано у трека.
    player.stream.position.listen((Duration? position) => setState(() {}));

    // Если поменялась громкость плеера.
    player.stream.volume.listen((double volume) => setState(() {}));

    // Если поменялся текущий трек.
    player.indexChangeStream.listen((int index) => setState(() {}));

    // Если произошло какое-то иное событие.
    player.playerStateStream.listen(
      (AudioPlaybackState state) => setState(() {}),
    );

    // Логи плеера.
    if (kDebugMode) {
      player.stream.log.listen((event) {
        logger.d(event.text);
      });
    }

    // TODO: Нормальный обработчик ошибок.
    player.stream.error.listen((event) {
      player.stop();

      showErrorDialog(
        context,
        title: "Ошибка воспроизведения",
        description: event.toString(),
      );
    });
  }

  /// Изменяет выбранную страницу для [BottomNavigationBar] по передаваемому индексу страницы.
  void setNavigationPage(int pageIndex) {
    assert(pageIndex >= 0 && pageIndex < navigationPages.length);

    setState(() => navigationScreenIndex = pageIndex);
  }

  @override
  Widget build(BuildContext context) {
    final UserProvider user = Provider.of<UserProvider>(context);

    if (!user.isAuthorized) {
      return const Center(
        child: Text(
          "Вы не авторизованы.",
        ),
      );
    }

    final NavigationPage navigationPage =
        navigationPages.elementAt(navigationScreenIndex);

    final bool isMobileLayout =
        getDeviceType(MediaQuery.of(context).size) == DeviceScreenType.mobile;

    final bool showMiniPlayer = player.isLoaded;

    return Scaffold(
      appBar: isMobileLayout
          ? AppBar(
              title: Text(
                navigationPage.label,
              ),
              centerTitle: true,
            )
          : null,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMobileLayout)
                NavigationRail(
                  selectedIndex: navigationScreenIndex,
                  onDestinationSelected: setNavigationPage,
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (NavigationPage page in navigationPages)
                      NavigationRailDestination(
                        icon: Icon(
                          page.icon,
                        ),
                        label: Text(page.label),
                        selectedIcon: Icon(
                          page.selectedIcon ?? page.icon,
                        ),
                      )
                  ],
                ),
              if (!isMobileLayout) const VerticalDivider(),
              Expanded(
                child: PageTransitionSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (Widget child, Animation<double> animation,
                      Animation<double> secondaryAnimation) {
                    return SharedAxisTransition(
                      transitionType: SharedAxisTransitionType.vertical,
                      animation: animation,
                      secondaryAnimation: secondaryAnimation,
                      child: child,
                    );
                  },
                  child: navigationPage.route,
                ),
              ),
            ],
          ),
          AnimatedAlign(
            duration: const Duration(milliseconds: 500),
            curve: Curves.ease,
            alignment: navigationPage.audioPlayerAlign,
            child: AnimatedOpacity(
              opacity: showMiniPlayer ? 1 : 0,
              curve: Curves.ease,
              duration: const Duration(
                milliseconds: 500,
              ),
              child: AnimatedSlide(
                offset: Offset(
                  0,
                  showMiniPlayer ? 0 : 1,
                ),
                duration: const Duration(
                  milliseconds: 500,
                ),
                curve: Curves.ease,
                child: AnimatedContainer(
                  duration: const Duration(
                    milliseconds: 500,
                  ),
                  padding: !isMobileLayout && navigationPage.allowBigAudioPlayer
                      ? null
                      : const EdgeInsets.all(8),
                  curve: Curves.ease,
                  width: isMobileLayout
                      ? null
                      : (navigationPage.allowBigAudioPlayer
                          ? clampDouble(
                              MediaQuery.of(context).size.width,
                              500,
                              double.infinity,
                            )
                          : 360),
                  child: BottomMusicPlayer(
                    audio: player.currentAudio,
                    previousAudio: player.previousAudio,
                    nextAudio: player.nextAudio,
                    favoriteState: true,
                    playbackState: player.state.playing,
                    progress: player.progress,
                    volume: player.state.volume / 100,
                    isBuffering: player.state.buffering,
                    isShuffleEnabled: player.shuffleEnabled,
                    isRepeatEnabled:
                        player.state.playlistMode == PlaylistMode.single,
                    useBigLayout:
                        !isMobileLayout && navigationPage.allowBigAudioPlayer,
                    onFavoriteStateToggle: (_) => showWipDialog(context),
                    onPlayStateToggle: (bool enabled) async {
                      await player.setPlaying(enabled);

                      setState(() {});
                    },
                    onVolumeChange: (double volume) async {
                      await player.setVolume(volume);

                      setState(() {});
                    },
                    onDismiss: () async {
                      await player.stop();

                      setState(() {});
                    },
                    onFullscreen: () => showWipDialog(
                      context,
                      title: "Полноэкранный плеер",
                    ),
                    onShuffleToggle: (bool enabled) async {
                      await player.setShuffle(enabled);
                      user.settings.shuffleEnabled = enabled;

                      user.markUpdated();
                      setState(() {});
                    },
                    onRepeatToggle: (bool enabled) async {
                      await player.setPlaylistMode(
                        enabled ? PlaylistMode.single : PlaylistMode.none,
                      );

                      setState(() {});
                    },
                    onNextTrack: () => player.next(),
                    onPreviousTrack: () => player.previous(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isMobileLayout
          ? NavigationBar(
              onDestinationSelected: setNavigationPage,
              selectedIndex: navigationScreenIndex,
              destinations: [
                for (NavigationPage page in navigationPages)
                  NavigationDestination(
                    icon: Icon(
                      page.icon,
                    ),
                    label: page.label,
                    selectedIcon: Icon(
                      page.selectedIcon ?? page.icon,
                    ),
                  )
              ],
            )
          : null,
    );
  }
}
