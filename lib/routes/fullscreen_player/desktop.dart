import "dart:async";

import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:just_audio/just_audio.dart";
import "package:provider/provider.dart";
import "package:skeletonizer/skeletonizer.dart";
import "package:styled_text/tags/styled_text_tag.dart";
import "package:styled_text/tags/styled_text_tag_action.dart";
import "package:styled_text/widgets/styled_text.dart";

import "../../consts.dart";
import "../../main.dart";
import "../../provider/user.dart";
import "../../services/cache_manager.dart";
import "../../services/logger.dart";
import "../../utils.dart";
import "../../widgets/dialogs.dart";
import "../../widgets/fallback_audio_photo.dart";
import "../../widgets/responsive_slider.dart";
import "../../widgets/scrollable_slider.dart";
import "../fullscreen_player.dart";
import "../home.dart";

/// Размер Padding'а для полноэкранного плеера при Desktop Layout'е.
const double _playerPadding = 56;

/// Ширина блока текста песни для полноэкранного плеера при Desktop Layout'е.
const double _lyricsWidth = 500;

/// Виджет, отображающий информацию по плейлисту, который играет в данный момент в полноэкранном плеере Desktop Layout'а.
class PlaylistTitleWidget extends StatelessWidget {
  const PlaylistTitleWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Изображение с нотой, либо анимация.
        RepaintBoundary(
          child: StreamBuilder<bool>(
            stream: player.playingStream,
            builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
              return snapshot.data ?? false
                  ? Image.asset(
                      "assets/images/audioEqualizer.gif",
                      color: Theme.of(context).colorScheme.primary,
                      width: 32,
                      height: 32,
                      fit: BoxFit.fill,
                    )
                  : Icon(
                      Icons.music_note,
                      color: Theme.of(context).colorScheme.primary,
                      size: 32,
                    );
            },
          ),
        ),
        const SizedBox(
          width: 14,
        ),

        // Текст с названием плейлиста.
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "Воспроизведение музыки".
            Text(
              AppLocalizations.of(context)!.music_fullscreenPlaylistNameTitle,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onBackground
                    .withOpacity(0.75),
              ),
            ),

            // Название плейлиста.
            Text(
              player.currentPlaylist?.title ??
                  AppLocalizations.of(context)!
                      .music_fullscreenFavoritePlaylistName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Виджет, отображающий информацию по следующему треку Desktop Layout'а.
class NextTrackInfoWidget extends StatefulWidget {
  const NextTrackInfoWidget({
    super.key,
  });

  @override
  State<NextTrackInfoWidget> createState() => _NextTrackInfoWidgetState();
}

class _NextTrackInfoWidgetState extends State<NextTrackInfoWidget> {
  /// Подписки на изменения состояния воспроизведения трека.
  late final List<StreamSubscription> subscriptions;

  @override
  void initState() {
    super.initState();

    subscriptions = [
      // Изменения позиции плеера.
      player.positionStream.listen(
        (Duration? state) => setState(() {}),
      ),

      // Изменение текущего трека.
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
    /// Определяет по оставшейся длине трека то, стоит ли показывать надпись со следующим треком.
    final bool displayNextTrack =
        (player.smartCurrentAudio != null && player.smartNextAudio != null)
            ? (player.progress >= nextPlayingTextProgress)
            : false;

    return AnimatedOpacity(
      opacity: displayNextTrack ? 1.0 : 0.0,
      duration: const Duration(
        milliseconds: 500,
      ),
      curve: Curves.ease,
      child: AnimatedSlide(
        duration: const Duration(
          milliseconds: 500,
        ),
        curve: Curves.ease,
        offset: Offset(
          displayNextTrack ? 0.0 : -0.1,
          0.0,
        ),
        child: InkWell(
          onTap: () => player.next(),
          borderRadius: BorderRadius.circular(
            globalBorderRadius,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(
                  globalBorderRadius,
                ),
                child: player.smartNextAudio!.album?.thumbnails != null
                    ? CachedNetworkImage(
                        imageUrl: player
                            .smartNextAudio!.album!.thumbnails!.photo1200!,
                        cacheKey: "${player.nextAudio!.album!.id}1200",
                        width: 32,
                        height: 32,
                        memCacheWidth: 32,
                        memCacheHeight: 32,
                        placeholder: (BuildContext context, String url) =>
                            const FallbackAudioAvatar(),
                        cacheManager: CachedAlbumImagesManager.instance,
                      )
                    : const FallbackAudioAvatar(
                        width: 32,
                        height: 32,
                      ),
              ),
              const SizedBox(
                width: 14,
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context)!
                        .music_fullscreenNextTrackTitle,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.75),
                    ),
                  ),
                  Text(
                    "${player.smartNextAudio!.artist} • ${player.smartNextAudio!.title}",
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Блок, отображающий текст песни.
class LyricsBlockWidget extends StatefulWidget {
  const LyricsBlockWidget({
    super.key,
  });

  @override
  State<LyricsBlockWidget> createState() => _LyricsBlockWidgetState();
}

class _LyricsBlockWidgetState extends State<LyricsBlockWidget> {
  /// Подписки на изменения состояния воспроизведения трека.
  late final List<StreamSubscription> subscriptions;

  @override
  void initState() {
    super.initState();

    subscriptions = [
      player.positionStream.listen(
        (Duration? position) => setState(() {}),
      ),
      player.sequenceStateStream.listen(
        (SequenceState? sequence) => setState(() {}),
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

    return AnimatedOpacity(
      duration: const Duration(
        milliseconds: 500,
      ),
      curve: Curves.ease,
      opacity: user.settings.trackLyricsEnabled ? 1.0 : 0.0,
      child: Align(
        alignment: Alignment.topRight,
        child: SizedBox(
          width: _lyricsWidth,
          height: MediaQuery.of(context).size.height - _playerPadding * 2 - 100,
          child: AnimatedSwitcher(
            duration: const Duration(
              milliseconds: 500,
            ),
            child: (player.currentAudio!.hasLyrics ?? false)
                ? player.currentAudio!.lyrics != null
                    ? TrackLyricsBlock(
                        key: ValueKey(
                          player.currentAudio!.mediaKey,
                        ),
                        lyrics: player.currentAudio!.lyrics!,
                      )
                    : ListView.builder(
                        key: const ValueKey(
                          "skeleton",
                        ),
                        itemCount: 50,
                        itemBuilder: (BuildContext context, int index) {
                          return Skeletonizer(
                            child: TrackLyric(
                              line: fakeTrackLyrics[
                                  index % fakeTrackLyrics.length],
                              isActive: false,
                            ),
                          );
                        },
                      )
                : Column(
                    key: const ValueKey(
                      "nolyrics",
                    ),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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
                      StyledText(
                        text: AppLocalizations.of(context)!
                            .music_fullscreenTrackNoLyrics,
                        textAlign: TextAlign.center,
                        tags: {
                          "bold": StyledTextTag(
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          "toggle": StyledTextActionTag(
                            (String? text, Map<String?, String?> attrs) {
                              user.settings.trackLyricsEnabled =
                                  !user.settings.trackLyricsEnabled;

                              user.markUpdated();
                            },
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        },
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Блок для полноэкранного плеера Desktop Layout'а, отображаемый снизу, который показывает информацию по текущему треку, а так же кнопки для управления плеером.
class FullscreenMediaControls extends StatefulWidget {
  const FullscreenMediaControls({
    super.key,
  });

  @override
  State<FullscreenMediaControls> createState() =>
      _FullscreenMediaControlsState();
}

class _FullscreenMediaControlsState extends State<FullscreenMediaControls> {
  /// Подписки на изменения состояния воспроизведения трека.
  late final List<StreamSubscription> subscriptions;

  @override
  void initState() {
    super.initState();

    subscriptions = [
      player.sequenceStateStream.listen(
        (SequenceState? state) => setState(() {}),
      ),
      player.playerStateStream.listen(
        (PlayerState? state) => setState(() {}),
      ),
      player.playingStream.listen(
        (bool playing) => setState(() {}),
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

    /// Указывает, сохранён ли этот трек в лайкнутых.
    final bool isFavorite = player.currentAudio!.isLiked;

    /// Указывает, что используется более компактный интерфейс.
    final bool compactLayout = MediaQuery.of(context).size.width <= 900;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Информация по текущему треку.
        Container(
          constraints: const BoxConstraints(
            minWidth: 200,
          ),
          width: MediaQuery.of(context).size.width -
              _playerPadding * 2 -
              (((player.currentAudio!.hasLyrics ?? false) &&
                      user.settings.trackLyricsEnabled)
                  ? _lyricsWidth
                  : 0) -
              50,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.bottomLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Изображение трека.
                Hero(
                  tag: player.currentAudio!.mediaKey,
                  child: AnimatedSwitcher(
                    duration: const Duration(
                      milliseconds: 500,
                    ),
                    child: Container(
                      key: ValueKey(
                        player.currentAudio!.album?.id,
                      ),
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 22,
                            spreadRadius: -3,
                            color: Theme.of(context).colorScheme.tertiary,
                            blurStyle: BlurStyle.outer,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          globalBorderRadius,
                        ),
                        child: player.currentAudio!.album?.thumbnails != null
                            ? CachedNetworkImage(
                                imageUrl: player.currentAudio!.album!
                                    .thumbnails!.photo1200!,
                                cacheKey:
                                    "${player.currentAudio!.album!.id}1200",
                                width: 130,
                                height: 130,
                                memCacheWidth: 200,
                                memCacheHeight: 200,
                                fit: BoxFit.fill,
                                placeholder:
                                    (BuildContext context, String url) =>
                                        const FallbackAudioAvatar(),
                                cacheManager: CachedAlbumImagesManager.instance,
                              )
                            : const FallbackAudioAvatar(
                                width: 130,
                                height: 130,
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 24,
                ),

                // Информация по названию трека и его исполнителю.
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          player.currentAudio!.title,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 36,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                        if (player.currentAudio!.isExplicit)
                          const SizedBox(
                            width: 4,
                          ),
                        if (player.currentAudio!.isExplicit)
                          Icon(
                            Icons.explicit,
                            color: Theme.of(context)
                                .colorScheme
                                .onBackground
                                .withOpacity(0.5),
                          ),
                      ],
                    ),
                    Text(
                      player.currentAudio!.artist,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 24,
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer
                            .withOpacity(0.75),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(
          height: 18,
        ),

        // Индикатор буферизации.
        if (player.buffering)
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8,
            ),
            child: LinearProgressIndicator(
              borderRadius: BorderRadius.circular(
                globalBorderRadius,
              ),
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
          ),

        // Slider для отображения прогресса воспроизведения трека.
        if (!player.buffering)
          SliderTheme(
            data: SliderThemeData(
              trackShape: CustomTrackShape(),
              overlayShape: SliderComponentShape.noOverlay,
              inactiveTrackColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            child: RepaintBoundary(
              child: StreamBuilder(
                stream: player.positionStream,
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  return ResponsiveSlider(
                    value: player.progress,
                    onChangeEnd: (double newProgress) => player.seekNormalized(
                      newProgress,
                    ),
                  );
                },
              ),
            ),
          ),
        const SizedBox(
          height: 4,
        ),

        // Кнопки управления воспроизведением.
        Stack(
          children: [
            // Кнопка для лайка/дизлайка трека. Если места мало (compactLayout), то кнопка находится в панели управления плеера (ниже).
            if (!compactLayout)
              Align(
                alignment: Alignment.bottomLeft,
                child: SizedBox(
                  height: 70,
                  child: IconButton(
                    onPressed: () {
                      if (!networkRequiredDialog(context)) return;

                      toggleTrackLikeState(
                        context,
                        player.currentAudio!,
                        !isFavorite,
                      );
                    },
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),

            // Кнопки управления плеера по центру, либо слева, если места мало (compactLayout).
            RepaintBoundary(
              child: Align(
                alignment: compactLayout
                    ? Alignment.bottomLeft
                    : Alignment.bottomCenter,
                child: SizedBox(
                  height: 70,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Если места мало, то кнопка для лайка/дизлайка.
                      if (compactLayout)
                        IconButton(
                          onPressed: () => toggleTrackLikeState(
                            context,
                            player.currentAudio!,
                            !isFavorite,
                          ),
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      if (compactLayout)
                        const SizedBox(
                          width: 8,
                        ),

                      // Переключение shuffle.
                      StreamBuilder<bool>(
                        stream: player.shuffleModeEnabledStream,
                        builder: (
                          BuildContext context,
                          AsyncSnapshot<bool> snapshot,
                        ) {
                          final bool enabled = snapshot.data ?? false;

                          return IconButton(
                            onPressed: () async {
                              await player.setShuffle(!enabled);

                              user.settings.shuffleEnabled = !enabled;
                              user.markUpdated();
                            },
                            icon: Icon(
                              enabled
                                  ? Icons.shuffle_on_outlined
                                  : Icons.shuffle,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          );
                        },
                      ),
                      const SizedBox(
                        width: 8,
                      ),

                      // Предыдущий трек.
                      IconButton(
                        onPressed: () => player.previous(
                          allowSeekToBeginning: true,
                        ),
                        icon: Icon(
                          Icons.skip_previous,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(
                        width: 8,
                      ),

                      // Пауза/воспроизведение.
                      StreamBuilder<PlayerState>(
                        stream: player.playerStateStream,
                        builder: (
                          BuildContext context,
                          AsyncSnapshot<PlayerState> snapshot,
                        ) {
                          return IconButton(
                            onPressed: () => player.togglePlay(),
                            icon: Icon(
                              player.playing
                                  ? Icons.pause_circle
                                  : Icons.play_circle,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                            iconSize: 50,
                          );
                        },
                      ),
                      const SizedBox(
                        width: 8,
                      ),

                      // Следующий трек.
                      IconButton(
                        onPressed: () => player.next(),
                        icon: Icon(
                          Icons.skip_next,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(
                        width: 8,
                      ),

                      // Повтор трека.
                      StreamBuilder<LoopMode>(
                        stream: player.loopModeStream,
                        builder: (
                          BuildContext context,
                          AsyncSnapshot<LoopMode> snapshot,
                        ) {
                          final bool enabled =
                              (snapshot.data ?? LoopMode.all) == LoopMode.one;

                          return IconButton(
                            onPressed: () => player.setLoop(
                              enabled ? LoopMode.all : LoopMode.one,
                            ),
                            icon: Icon(
                              enabled ? Icons.repeat_on_outlined : Icons.repeat,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Остальные кнопки (выход из полноэкранного режима, ...) справа.
            Align(
              alignment: Alignment.bottomRight,
              child: SizedBox(
                height: 70,
                child: RepaintBoundary(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Управление громкостью.
                      if (isDesktop)
                        StreamBuilder<double>(
                          stream: player.volumeStream,
                          builder: (
                            BuildContext context,
                            AsyncSnapshot<double> snapshot,
                          ) {
                            return ScrollableSlider(
                              value: snapshot.data ?? 1.0,
                              activeColor:
                                  Theme.of(context).colorScheme.primary,
                              inactiveColor: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.5),
                              onChanged: (double newVolume) async {
                                await player.setVolume(newVolume);

                                // Если пользователь установил минимальную громкость, а так же настройка "Пауза при отключении громкости" включена, то ставим плеер на паузу.
                                if (newVolume == 0 &&
                                    user.settings.pauseOnMuteEnabled) {
                                  await player.pause();
                                }
                              },
                            );
                          },
                        ),
                      if (isDesktop)
                        const SizedBox(
                          width: 18,
                        ),

                      // Показ текста песни.
                      IconButton(
                        onPressed: player.currentAudio!.hasLyrics ?? false
                            ? () {
                                user.settings.trackLyricsEnabled =
                                    !user.settings.trackLyricsEnabled;

                                user.markUpdated();
                              }
                            : null,
                        icon: Icon(
                          user.settings.trackLyricsEnabled &&
                                  (player.currentAudio!.hasLyrics ?? false)
                              ? Icons.lyrics
                              : Icons.lyrics_outlined,
                          color:
                              Theme.of(context).colorScheme.primary.withOpacity(
                                    player.currentAudio!.hasLyrics ?? false
                                        ? 1.0
                                        : 0.5,
                                  ),
                        ),
                      ),
                      const SizedBox(
                        width: 8,
                      ),

                      // Выход из полноэкранного режима.
                      IconButton(
                        onPressed: () => closePlayer(context),
                        icon: Icon(
                          Icons.fullscreen_exit,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Desktop Layout для полноэкранного плеера.
///
/// [FullscreenPlayerRoute] автоматически определяет, должен отображаться Desktop или Mobile Layout.
class FullscreenPlayerDesktopRoute extends StatelessWidget {
  static AppLogger logger = getLogger("FullscreenPlayerDesktopRoute");

  const FullscreenPlayerDesktopRoute({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(
        _playerPadding,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Надпись "Воспроизведение музыки".
              const PlaylistTitleWidget(),

              // Надпись со следующим треком.
              if (player.smartNextAudio != null) const NextTrackInfoWidget(),

              // Информация по текущему треку и медиаплеер.
              const SizedBox(
                width: double.infinity,
                child: FullscreenMediaControls(),
              ),
            ],
          ),

          // Текст песни, либо заглушка на случай, если текста нет.
          const LyricsBlockWidget(),
        ],
      ),
    );
  }
}
