import "dart:ui";

import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:gap/gap.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:just_audio/just_audio.dart";

import "../../consts.dart";
import "../../main.dart";
import "../../provider/color.dart";
import "../../provider/l18n.dart";
import "../../provider/player_events.dart";
import "../../provider/preferences.dart";
import "../../provider/user.dart";
import "../../services/cache_manager.dart";
import "../../utils.dart";
import "../../widgets/dialogs.dart";
import "../../widgets/fallback_audio_photo.dart";
import "../../widgets/loading_button.dart";
import "../../widgets/responsive_slider.dart";
import "../fullscreen_player.dart";
import "../home.dart";
import "../home/music/bottom_audio_options.dart";

/// Размер (ширина и высота) изображения по центру полноэкраннонного плеера при Mobile Layout'е.
const double _playerImageSize = 400;

/// Ряд из кнопок полноэкранного плеера Mobile Layout'а, отображаемого сверху.
class TopFullscreenControls extends ConsumerWidget {
  const TopFullscreenControls({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Кнопка для выхода из полноэкранного плеера.
        IconButton(
          icon: Icon(
            Icons.adaptive.arrow_back,
          ),
          onPressed: () => closeFullscreenPlayer(context),
        ),

        // Название плейлиста, из которого идёт воспроизведение.
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l18n.music_fullscreenPlaylistNameTitle,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
                ),
              ),
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
        ),

        // Дополнительные действия над треком.
        if (player.currentPlaylist != null)
          IconButton(
            icon: Icon(
              Icons.adaptive.more,
            ),
            onPressed: () => showModalBottomSheet(
              context: context,
              useRootNavigator: true,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (BuildContext context) {
                return BottomAudioOptionsDialog(
                  audio: player.currentAudio!,
                  playlist: player.currentPlaylist!,
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Виджет, используемый в [ImageLyricsBlock] для отображения иконки трека.
class _PlayerImageWidget extends ConsumerWidget {
  /// Трек, изображение которого будет показано.
  final ExtendedAudio audio;

  const _PlayerImageWidget({
    required this.audio,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schemeInfo = ref.watch(trackSchemeInfoProvider);

    return FittedBox(
      child: Padding(
        padding: const EdgeInsets.all(
          36,
        ),
        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 350,
          ),
          curve: Curves.bounceOut,
          width: _playerImageSize,
          height: _playerImageSize,
          decoration: BoxDecoration(
            boxShadow: [
              if (player.playing)
                BoxShadow(
                  blurRadius: 20,
                  spreadRadius: -3,
                  color: (audio.thumbnail != null
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
            child: audio.maxThumbnail != null
                ? CachedNetworkImage(
                    imageUrl: audio.maxThumbnail!,
                    cacheKey: "${audio.mediaKey}max",
                    width: _playerImageSize,
                    height: _playerImageSize,
                    fit: BoxFit.fill,
                    placeholder: (BuildContext context, String url) =>
                        const FallbackAudioAvatar(),
                    cacheManager: CachedAlbumImagesManager.instance,
                  )
                : const FallbackAudioAvatar(
                    width: _playerImageSize,
                    height: _playerImageSize,
                  ),
          ),
        ),
      ),
    );
  }
}

/// Виджет, отображающий текст песни, или изображениие трека по центру полноэкранного плеера Mobile Layout'а.
class ImageLyricsBlock extends HookConsumerWidget {
  const ImageLyricsBlock({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(preferencesProvider);
    ref.watch(playerCurrentIndexProvider);
    final dragProgress = useState(0.0);

    const scrollWidth = _playerImageSize + 50;
    final bool lyricsLoadedAndShown = preferences.trackLyricsEnabled &&
        (player.currentAudio!.hasLyrics ?? false) &&
        player.currentAudio!.lyrics != null;

    return AnimatedSwitcher(
      duration: const Duration(
        milliseconds: 500,
      ),
      reverseDuration: const Duration(
        milliseconds: 200,
      ),
      switchInCurve: Curves.ease,
      switchOutCurve: Curves.ease,
      child: !lyricsLoadedAndShown
          ? MouseRegion(
              key: ValueKey(
                player.smartCurrentAudio!.mediaKey,
              ),
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => player.togglePlay(),
                onHorizontalDragUpdate: (DragUpdateDetails details) =>
                    dragProgress.value = clampDouble(
                  dragProgress.value - details.primaryDelta! / scrollWidth,
                  -1.0,
                  1.0,
                ),
                onHorizontalDragEnd: (DragEndDetails details) {
                  if (dragProgress.value > 0.5) {
                    // Запуск следующего трека.

                    player.next();
                  } else if (dragProgress.value < -0.5) {
                    // Запуск предыдущего трека.

                    player.previous();
                  }

                  dragProgress.value = 0.0;
                },
                child: HeroMode(
                  enabled: !lyricsLoadedAndShown,
                  child: Hero(
                    tag: player.currentAudio!.mediaKey,
                    child: SizedBox(
                      width: double.infinity,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Текущий трек.
                          AnimatedScale(
                            scale: player.playing ? 1.0 : 0.9,
                            duration: const Duration(
                              milliseconds: 500,
                            ),
                            curve: Curves.bounceOut,
                            child: Transform.translate(
                              offset: Offset(
                                dragProgress.value * -scrollWidth,
                                0.0,
                              ),
                              child: Opacity(
                                opacity: 1.0 - dragProgress.value.abs(),
                                child: _PlayerImageWidget(
                                  audio: player.smartCurrentAudio!,
                                ),
                              ),
                            ),
                          ),

                          // Другой трек.
                          if (!lyricsLoadedAndShown &&
                              dragProgress.value != 0.0)
                            Transform.translate(
                              offset: Offset(
                                (dragProgress.value > 0.0
                                        ? scrollWidth
                                        : -scrollWidth) -
                                    dragProgress.value * scrollWidth,
                                0.0,
                              ),
                              child: Opacity(
                                opacity: dragProgress.value.abs(),
                                child: _PlayerImageWidget(
                                  audio: dragProgress.value > 0.0
                                      ? player.smartNextAudio!
                                      : player.smartPreviousAudio!,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
          : Align(
              key: ValueKey(
                "lyrics${player.currentAudio!.mediaKey}",
              ),
              alignment: Alignment.topCenter,
              child: AnimatedOpacity(
                opacity: lyricsLoadedAndShown ? 1.0 : 0.0,
                duration: const Duration(
                  milliseconds: 500,
                ),
                curve: Curves.ease,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                  ),
                  child: TrackLyricsBlock(
                    lyrics: player.currentAudio!.lyrics!,
                  ),
                ),
              ),
            ),
    );
  }
}

/// Кнопки, а так же информация по текущему треку полноэкранного плеера Mobile Layout'а, отображаемого снизу плеера.
class FullscreenMediaControls extends ConsumerWidget {
  const FullscreenMediaControls({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsNotifier = ref.read(preferencesProvider.notifier);
    final preferences = ref.watch(preferencesProvider);
    ref.watch(playerStateProvider);
    ref.watch(playerCurrentIndexProvider);

    final bool isFavorite = player.currentAudio!.isLiked;
    final bool smallerLayout = MediaQuery.sizeOf(context).width <= 300;
    final bool showLyricsBlock = MediaQuery.sizeOf(context).height > 150;
    final bool canToggleShuffle =
        !(player.currentPlaylist?.isAudioMixPlaylist ?? false);
    final bool isRecommendationTypePlaylist =
        player.currentPlaylist?.isRecommendationTypePlaylist ?? false;

    Future<void> onLikeTap() async {
      if (!networkRequiredDialog(ref, context)) return;

      await toggleTrackLike(
        ref,
        player.currentAudio!,
        !isFavorite,
      );
    }

    Future<void> onDislikeTap() async {
      if (!networkRequiredDialog(ref, context)) return;

      // Делаем трек дизлайкнутым.
      final bool result = await dislikeTrackState(
        context,
        player.currentAudio!,
      );
      if (!result) return;

      // Запускаем следующий трек в плейлисте.
      await player.next();
    }

    void onLyricsTap() =>
        prefsNotifier.setTrackLyricsEnabled(!preferences.trackLyricsEnabled);

    void onMiniplayerCloseTap() => closeMiniPlayer(context);

    void onShuffleTap() async {
      assert(
        canToggleShuffle,
        "Called onShuffleTap, but canToggleShuffle is false",
      );

      await player.toggleShuffle();

      prefsNotifier.setShuffleEnabled(player.shuffleModeEnabled);
    }

    onSliderUsed(double newProgress) => player.seekNormalized(newProgress);

    void onPreviousTap() => player.previous(allowSeekToBeginning: true);

    void onPauseTap() => player.togglePlay();

    void onNextTap() => player.next();

    void onLoopTap() => player
        .setLoop(player.loopMode == LoopMode.one ? LoopMode.all : LoopMode.one);

    return Column(
      children: [
        // Кнопки для лайка/дизлайка, а так же включения/отключения текста песни.
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: smallerLayout ? 0 : 20,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Кнопка для лайка трека.
              LoadingIconButton(
                onPressed: onLikeTap,
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),

              // Кнопка для дизлайка трека.
              if (isRecommendationTypePlaylist)
                LoadingIconButton(
                  onPressed: onDislikeTap,
                  icon: Icon(
                    Icons.thumb_down_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),

              // Информация по текущему треку: его исполнителю и названию.
              Expanded(
                child: Column(
                  children: [
                    // Название трека (и иконка explicit).
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Название трека.
                        Flexible(
                          child: Text(
                            player.currentAudio!.title,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                        ),

                        // Плашка "Explicit".
                        if (player.currentAudio!.isExplicit && !smallerLayout)
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
                              size: 12,
                            ),
                          ),

                        // Подпись трека.
                        if (player.currentAudio!.subtitle != null)
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 6,
                              ),
                              child: Text(
                                player.currentAudio!.subtitle!,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer
                                      .withOpacity(0.5),
                                ),
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
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer
                            .withOpacity(0.75),
                      ),
                    ),
                  ],
                ),
              ),

              // Пустое место для центрирования текста, смещённого ввиду кнопки дизлайка слева.
              if (isRecommendationTypePlaylist) const Gap(40),

              // Кнопка для включения/отключения показа текста песни.
              if (showLyricsBlock)
                IconButton(
                  onPressed: player.currentAudio!.hasLyrics ?? false
                      ? onLyricsTap
                      : null,
                  icon: Icon(
                    preferences.trackLyricsEnabled &&
                            (player.currentAudio!.hasLyrics ?? false)
                        ? Icons.lyrics
                        : Icons.lyrics_outlined,
                    color: Theme.of(context).colorScheme.primary.withOpacity(
                          player.currentAudio!.hasLyrics ?? false ? 1.0 : 0.5,
                        ),
                  ),
                ),

              // Кнопка для выхода из плеера.
              if (!showLyricsBlock)
                IconButton(
                  onPressed: onMiniplayerCloseTap,
                  icon: Icon(
                    Icons.picture_in_picture_alt,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
            ],
          ),
        ),
        const Gap(10),

        // Индикатор буферизации.
        if (!smallerLayout && player.buffering)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
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
        if (!smallerLayout && !player.buffering)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
            ),
            child: SliderTheme(
              data: SliderThemeData(
                trackShape: CustomTrackShape(),
                overlayShape: SliderComponentShape.noOverlay,
                activeTrackColor: Theme.of(context).colorScheme.primary,
                inactiveTrackColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
              child: RepaintBoundary(
                child: StreamBuilder<Duration>(
                  stream: player.positionStream,
                  builder:
                      (BuildContext context, AsyncSnapshot<Duration> snapshot) {
                    return ResponsiveSlider(
                      value: player.progress,
                      onChangeEnd: onSliderUsed,
                    );
                  },
                ),
              ),
            ),
          ),

        // Кнопки управления воспроизведением.
        SizedBox(
          height: smallerLayout ? null : 70,
          child: Row(
            mainAxisAlignment: smallerLayout
                ? MainAxisAlignment.spaceBetween
                : MainAxisAlignment.center,
            children: [
              // Shuffle.
              StreamBuilder<bool>(
                stream: player.shuffleModeEnabledStream,
                builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                  final enabled = snapshot.data ?? false;

                  return IconButton(
                    onPressed: canToggleShuffle ? onShuffleTap : null,
                    icon: Icon(
                      enabled ? Icons.shuffle_on_outlined : Icons.shuffle,
                      color: canToggleShuffle
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  );
                },
              ),
              const Flexible(
                child: Gap(8),
              ),

              // Запуск предыдущего трека.
              IconButton(
                onPressed: onPreviousTap,
                icon: Icon(
                  Icons.skip_previous,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const Flexible(
                child: Gap(8),
              ),

              // Кнопка паузы.
              StreamBuilder<bool>(
                stream: player.playingStream,
                builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                  final bool playing = snapshot.data ?? false;

                  return IconButton(
                    onPressed: onPauseTap,
                    icon: Icon(
                      smallerLayout
                          ? (playing ? Icons.pause : Icons.play_arrow)
                          : (playing ? Icons.pause_circle : Icons.play_circle),
                      color: smallerLayout
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    iconSize: smallerLayout ? null : 50,
                  );
                },
              ),
              const Flexible(
                child: Gap(8),
              ),

              // Запуск следующего трека.
              IconButton(
                onPressed: onNextTap,
                icon: Icon(
                  Icons.skip_next,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const Flexible(
                child: Gap(8),
              ),

              // Повтор трека.
              StreamBuilder<LoopMode>(
                stream: player.loopModeStream,
                builder:
                    (BuildContext context, AsyncSnapshot<LoopMode> snapshot) {
                  final LoopMode loopMode = snapshot.data ?? LoopMode.all;

                  return IconButton(
                    onPressed: onLoopTap,
                    icon: Icon(
                      loopMode == LoopMode.one
                          ? Icons.repeat_on_outlined
                          : Icons.repeat,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Mobile Layout для полноэкранного плеера.
///
/// [FullscreenPlayerRoute] автоматически определяет, должен отображаться Desktop или Mobile Layout.
class FullscreenPlayerMobileRoute extends StatelessWidget {
  const FullscreenPlayerMobileRoute({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    /// Указывает, что будет использоваться очень маленький размер интерфейса.
    final bool smallerLayout = MediaQuery.sizeOf(context).width <= 300;

    /// Размер Padding'а для полноэкранного плеера при Mobile Layout'е.
    final double playerPadding = smallerLayout ? 10 : 20;

    /// Высота блока с текстом песни.
    final double lyricsBlockHeight = MediaQuery.sizeOf(context).height -
        playerPadding * 2 -
        (smallerLayout ? 95 : 220) -
        MediaQuery.of(context).systemGestureInsets.bottom -
        MediaQuery.of(context).systemGestureInsets.top;

    /// Указывает, что блок с текстом песни будет показан.
    final bool showLyricsBlock = MediaQuery.sizeOf(context).height > 150;

    /// [Padding] для всех элементов на данном Route.
    final EdgeInsets padding = EdgeInsets.all(
      playerPadding,
    ).copyWith(
      top: smallerLayout ? 0 : null,
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Кнопки управления полноэкранным плеером сверху.
        if (!smallerLayout)
          Padding(
            padding: padding,
            child: const TopFullscreenControls(),
          ),

        // Изображение трека, либо текст песни поверх него.
        SizedBox(
          width: double.infinity,
          child: Stack(
            children: [
              // Текст песни/изображение.
              if (showLyricsBlock)
                Align(
                  child: SizedBox(
                    height: lyricsBlockHeight,
                    child: const ImageLyricsBlock(),
                  ),
                ),

              // Кнопка для выхода из плеера при очень маленьком интерфейсе.
              if (smallerLayout && showLyricsBlock)
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: playerPadding,
                      left: 2,
                    ),
                    child: IconButton.filledTonal(
                      icon: const Icon(
                        Icons.arrow_back,
                      ),
                      onPressed: () => closeMiniPlayer(context),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Управление плеером, а так же информация по текущему треку.
        Padding(
          padding: padding.copyWith(
            left: smallerLayout ? 2 : 22,
            right: smallerLayout ? 2 : 22,
          ),
          child: const FullscreenMediaControls(),
        ),
      ],
    );
  }
}
