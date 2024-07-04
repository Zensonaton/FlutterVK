import "dart:async";

import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:just_audio/just_audio.dart";
import "package:skeletonizer/skeletonizer.dart";

import "../../consts.dart";
import "../../main.dart";
import "../../provider/color.dart";
import "../../provider/l18n.dart";
import "../../provider/preferences.dart";
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
class PlaylistTitleWidget extends ConsumerWidget {
  const PlaylistTitleWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);

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
              l18n.music_fullscreenPlaylistNameTitle,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
              ),
            ),

            // Название плейлиста.
            Text(
              player.currentPlaylist?.title ??
                  l18n.music_fullscreenFavoritePlaylistName,
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
class NextTrackInfoWidget extends ConsumerStatefulWidget {
  const NextTrackInfoWidget({
    super.key,
  });

  @override
  ConsumerState<NextTrackInfoWidget> createState() =>
      _NextTrackInfoWidgetState();
}

class _NextTrackInfoWidgetState extends ConsumerState<NextTrackInfoWidget> {
  /// Подписки на изменения состояния воспроизведения трека.
  late final List<StreamSubscription> subscriptions;

  @override
  void initState() {
    super.initState();

    subscriptions = [
      // Изменения позиции плеера.
      player.positionStream.listen(
        (_) => setState(() {}),
      ),

      // Изменение текущего трека.
      player.currentIndexStream.listen(
        (_) => setState(() {}),
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
    assert(
      player.smartNextAudio != null,
      "Next audio is not known",
    );

    final l18n = ref.watch(l18nProvider);

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
              // Изображение следующего трека.
              Padding(
                padding: const EdgeInsets.only(
                  right: 12,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    globalBorderRadius,
                  ),
                  child: player.smartNextAudio!.smallestThumbnail != null
                      ? CachedNetworkImage(
                          imageUrl: player.smartNextAudio!.smallestThumbnail!,
                          cacheKey: "${player.smartNextAudio!.mediaKey}small",
                          width: 32,
                          height: 32,
                          placeholder: (BuildContext context, String url) =>
                              const FallbackAudioAvatar(),
                          cacheManager: CachedAlbumImagesManager.instance,
                        )
                      : const FallbackAudioAvatar(
                          width: 32,
                          height: 32,
                        ),
                ),
              ),

              // Его название и прочая информация.
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // "Следующим сыграет".
                  Text(
                    l18n.music_fullscreenNextTrackTitle,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.75),
                    ),
                  ),

                  // Исполнитель и название трека.
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
class LyricsBlockWidget extends ConsumerStatefulWidget {
  const LyricsBlockWidget({
    super.key,
  });

  @override
  ConsumerState<LyricsBlockWidget> createState() => _LyricsBlockWidgetState();
}

class _LyricsBlockWidgetState extends ConsumerState<LyricsBlockWidget> {
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
    final preferences = ref.watch(preferencesProvider);

    return AnimatedOpacity(
      duration: const Duration(
        milliseconds: 500,
      ),
      curve: Curves.ease,
      opacity: preferences.trackLyricsEnabled ? 1.0 : 0.0,
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
                : const SizedBox(
                    key: ValueKey(
                      null,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Блок для полноэкранного плеера Desktop Layout'а, отображаемый снизу, который показывает информацию по текущему треку, а так же кнопки для управления плеером.
class FullscreenMediaControls extends ConsumerStatefulWidget {
  const FullscreenMediaControls({
    super.key,
  });

  @override
  ConsumerState<FullscreenMediaControls> createState() =>
      _FullscreenMediaControlsState();
}

class _FullscreenMediaControlsState
    extends ConsumerState<FullscreenMediaControls> {
  /// Подписки на изменения состояния воспроизведения трека.
  late final List<StreamSubscription> subscriptions;

  @override
  void initState() {
    super.initState();

    subscriptions = [
      // Изменения состояния плеера.
      player.playerStateStream.listen(
        (_) => setState(() {}),
      ),

      // Изменения состояния паузы/воспроизведения.
      player.playingStream.listen(
        (_) => setState(() {}),
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

  /// Переключает состояние лайка у трека, играющий в данный момент.
  void _toggleLike() {
    assert(
      player.currentAudio != null,
      "Current audio is null",
    );
    if (!networkRequiredDialog(ref, context)) return;

    toggleTrackLikeState(
      context,
      player.currentAudio!,
      !player.currentAudio!.isLiked,
    );
  }

  /// Добавляет дизлайк для трека, который играет в данный момент.
  void _toggleDislike() async {
    assert(player.currentAudio != null, "Current audio is null");
    assert(
      player.currentPlaylist!.isRecommendationTypePlaylist,
      "Attempted to dislike non-recommendation track",
    );
    if (!networkRequiredDialog(ref, context)) return;

    // Делаем трек дизлайкнутым.
    final bool result = await dislikeTrackState(context, player.currentAudio!);
    if (!result) return;

    // Запускаем следующий трек в плейлисте.
    await player.next();
  }

  @override
  Widget build(BuildContext context) {
    final schemeInfo = ref.watch(trackSchemeInfoProvider);
    final prefsNotifier = ref.read(preferencesProvider.notifier);
    final preferences = ref.watch(preferencesProvider);

    /// Указывает, сохранён ли этот трек в лайкнутых.
    final bool isFavorite = player.currentAudio!.isLiked;

    /// Указывает, что используется более компактный интерфейс.
    final bool compactLayout = MediaQuery.of(context).size.width <= 1000;

    /// Указывает, что большое изображение трека должно использовать меньший максимальный размер.
    final bool compactBigFullscreenImage =
        MediaQuery.of(context).size.width <= 1200 ||
            MediaQuery.of(context).size.height <= 800;

    /// Указывает, что кнопки управления будут иметь меньшее расстояние при маленьком размере интерфейса.
    final bool smallerButtonSpacing = MediaQuery.of(context).size.width <= 800;

    /// Указывает, что кнопка для переключения shuffle работает.
    final bool canToggleShuffle =
        !(player.currentPlaylist?.isAudioMixPlaylist ?? false);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Информация по текущему треку.
        Container(
          constraints: const BoxConstraints(
            minWidth: 200,
          ),
          padding: const EdgeInsets.only(
            bottom: 18,
          ),
          width: MediaQuery.of(context).size.width -
              _playerPadding * 2 -
              (((player.currentAudio!.hasLyrics ?? false) &&
                      preferences.trackLyricsEnabled)
                  ? _lyricsWidth
                  : 0) -
              50,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.bottomLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Изображение трека.
                Padding(
                  padding: const EdgeInsets.only(
                    right: 24,
                  ),
                  child: Hero(
                    tag: player.currentAudio!.mediaKey,
                    child: AnimatedSwitcher(
                      duration: const Duration(
                        milliseconds: 500,
                      ),
                      child: AnimatedContainer(
                        key: ValueKey(
                          player.currentAudio!.mediaKey,
                        ),
                        duration: const Duration(
                          milliseconds: 500,
                        ),
                        curve: Curves.ease,
                        width: 130 *
                            ((preferences.fullscreenBigThumbnail &&
                                    MediaQuery.sizeOf(context).height > 600)
                                ? compactBigFullscreenImage
                                    ? 2
                                    : 3
                                : 1),
                        height: 130 *
                            ((preferences.fullscreenBigThumbnail &&
                                    MediaQuery.sizeOf(context).height > 600)
                                ? compactBigFullscreenImage
                                    ? 2
                                    : 3
                                : 1),
                        decoration: BoxDecoration(
                          boxShadow: [
                            if (player.playing)
                              BoxShadow(
                                blurRadius: 22,
                                spreadRadius: -3,
                                color: (player.currentAudio?.thumbnail != null
                                        ? schemeInfo?.frequentColor
                                        : null) ??
                                    Colors.blueGrey.withOpacity(0.25),
                                blurStyle: BlurStyle.outer,
                              ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            globalBorderRadius,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => prefsNotifier
                                  .setFullscreenBigThumbnailEnabled(
                                !preferences.fullscreenBigThumbnail,
                              ),
                              child: player.currentAudio!.maxThumbnail != null
                                  ? CachedNetworkImage(
                                      imageUrl:
                                          player.currentAudio!.maxThumbnail!,
                                      cacheKey:
                                          "${player.currentAudio!.mediaKey}max",
                                      fit: BoxFit.fill,
                                      placeholder:
                                          (BuildContext context, String url) =>
                                              const FallbackAudioAvatar(),
                                      cacheManager:
                                          CachedAlbumImagesManager.instance,
                                    )
                                  : const FallbackAudioAvatar(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Информация по названию трека и его исполнителю.
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Название трека.
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

                        // Иконка Explicit.
                        if (player.currentAudio!.isExplicit)
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 4,
                            ),
                            child: Icon(
                              Icons.explicit,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer
                                  .withOpacity(0.5),
                            ),
                          ),

                        // Подпись трека.
                        if (player.currentAudio!.subtitle != null)
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 10,
                            ),
                            child: Text(
                              player.currentAudio!.subtitle!,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 22,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                    .withOpacity(0.5),
                              ),
                            ),
                          ),
                      ],
                    ),

                    // Исполнитель трека.
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

        // Кнопки управления воспроизведением.
        Stack(
          children: [
            // Кнопки лайка, дизлайка.
            if (!compactLayout)
              Align(
                alignment: Alignment.bottomLeft,
                child: SizedBox(
                  height: 70,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Кнопка для добавления/удаления лайка.
                      Padding(
                        padding: const EdgeInsets.only(
                          right: 8,
                        ),
                        child: IconButton(
                          onPressed: _toggleLike,
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),

                      // Кнопка для дизлайка трека, если включён рекомендуемый плейлист.
                      if (player.currentPlaylist!.isRecommendationTypePlaylist)
                        IconButton(
                          onPressed: _toggleDislike,
                          icon: Icon(
                            Icons.thumb_down_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                    ],
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
                        Padding(
                          padding: EdgeInsets.only(
                            right: smallerButtonSpacing ? 0 : 8,
                          ),
                          child: IconButton(
                            onPressed: _toggleLike,
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),

                      // Кнопка для дизлайка трека, если включён рекомендуемый плейлист.
                      if (compactLayout &&
                          player.currentPlaylist!.isRecommendationTypePlaylist)
                        Padding(
                          padding: EdgeInsets.only(
                            right: smallerButtonSpacing ? 0 : 8,
                          ),
                          child: IconButton(
                            onPressed: _toggleDislike,
                            icon: Icon(
                              Icons.thumb_down_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),

                      // Переключение shuffle.
                      Padding(
                        padding: EdgeInsets.only(
                          right: smallerButtonSpacing ? 0 : 8,
                        ),
                        child: StreamBuilder<bool>(
                          stream: player.shuffleModeEnabledStream,
                          builder: (
                            BuildContext context,
                            AsyncSnapshot<bool> snapshot,
                          ) {
                            final bool enabled = snapshot.data ?? false;

                            return IconButton(
                              onPressed: canToggleShuffle
                                  ? () async {
                                      await player.setShuffle(!enabled);

                                      prefsNotifier.setShuffleEnabled(!enabled);
                                    }
                                  : null,
                              icon: Icon(
                                enabled
                                    ? Icons.shuffle_on_outlined
                                    : Icons.shuffle,
                                color: canToggleShuffle
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),

                      // Предыдущий трек.
                      Padding(
                        padding: EdgeInsets.only(
                          right: smallerButtonSpacing ? 0 : 8,
                        ),
                        child: IconButton(
                          onPressed: () => player.previous(
                            allowSeekToBeginning: true,
                          ),
                          icon: Icon(
                            Icons.skip_previous,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),

                      // Пауза/воспроизведение.
                      Padding(
                        padding: EdgeInsets.only(
                          right: smallerButtonSpacing ? 0 : 8,
                        ),
                        child: StreamBuilder<PlayerState>(
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
                      ),

                      // Следующий трек.
                      Padding(
                        padding: EdgeInsets.only(
                          right: smallerButtonSpacing ? 0 : 8,
                        ),
                        child: IconButton(
                          onPressed: () => player.next(),
                          icon: Icon(
                            Icons.skip_next,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
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
                        Padding(
                          padding: EdgeInsets.only(
                            right: smallerButtonSpacing ? 0 : 18,
                          ),
                          child: StreamBuilder<double>(
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
                                  if (isMobile) return;

                                  await player.setVolume(newVolume);
                                },
                              );
                            },
                          ),
                        ),

                      // Показ текста песни.
                      Padding(
                        padding: EdgeInsets.only(
                          right: smallerButtonSpacing ? 0 : 8,
                        ),
                        child: IconButton(
                          onPressed: player.currentAudio!.hasLyrics ?? false
                              ? () => prefsNotifier.setTrackLyricsEnabled(
                                    !preferences.trackLyricsEnabled,
                                  )
                              : null,
                          icon: Icon(
                            preferences.trackLyricsEnabled &&
                                    (player.currentAudio!.hasLyrics ?? false)
                                ? Icons.lyrics
                                : Icons.lyrics_outlined,
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(
                                  player.currentAudio!.hasLyrics ?? false
                                      ? 1.0
                                      : 0.5,
                                ),
                          ),
                        ),
                      ),

                      // Выход из полноэкранного режима.
                      IconButton(
                        onPressed: () => closeFullscreenPlayer(context),
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
    return GestureDetector(
      onTap: () => player.togglePlay(),
      behavior: HitTestBehavior.translucent,
      child: Padding(
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
      ),
    );
  }
}
