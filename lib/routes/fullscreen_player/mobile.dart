import "dart:async";

import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:just_audio/just_audio.dart";
import "package:provider/provider.dart";

import "../../consts.dart";
import "../../main.dart";
import "../../provider/user.dart";
import "../../services/cache_manager.dart";
import "../../utils.dart";
import "../../widgets/fallback_audio_photo.dart";
import "../../widgets/responsive_slider.dart";
import "../fullscreen_player.dart";
import "../home.dart";
import "../home/music.dart";

/// Размер Padding'а для полноэкранного плеера при Mobile Layout'е.
const double _playerPadding = 20;

/// Размер (ширина и высота) изображения по центру полноэкраннонного плеера при Mobile Layout'е.
const double _playerImageSize = 400;

/// Ряд из кнопок полноэкранного плеера Mobile Layout'а, отображаемого сверху.
class TopFullscreenControls extends StatelessWidget {
  const TopFullscreenControls({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Кнопка для выхода из полноэкранного плеера.
        IconButton(
          icon: const Icon(
            Icons.arrow_downward,
          ),
          onPressed: () => closeFullscreenPlayer(context),
        ),

        // Название плейлиста, из которого идёт воспроизведение.
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Виджет, отображающий текст песни, или изображениие трека по центру полноэкранного плеера Mobile Layout'а.
class ImageLyricsBlock extends StatefulWidget {
  const ImageLyricsBlock({
    super.key,
  });

  @override
  State<ImageLyricsBlock> createState() => _ImageLyricsBlockState();
}

class _ImageLyricsBlockState extends State<ImageLyricsBlock> {
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
        (SequenceState? sequenceState) => setState(() {}),
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

    /// Указывает, что пользователь включил показа текста песни, а так же текст существует и он загружен.
    final bool lyricsLoadedAndShown = user.settings.trackLyricsEnabled &&
        player.currentAudio!.hasLyrics &&
        player.currentAudio!.lyrics != null;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Изображение трека.
        HeroMode(
          enabled: !lyricsLoadedAndShown,
          child: Hero(
            tag: player.currentAudio!.mediaKey,
            child: FittedBox(
              child: Padding(
                padding: const EdgeInsets.all(
                  36,
                ),
                child: AnimatedOpacity(
                  opacity: lyricsLoadedAndShown ? 0.0 : 1.0,
                  duration: const Duration(
                    milliseconds: 500,
                  ),
                  child: Container(
                    width: _playerImageSize,
                    height: _playerImageSize,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 15,
                          spreadRadius: -3,
                          color: Theme.of(context).colorScheme.tertiary,
                          blurStyle: BlurStyle.outer,
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        globalBorderRadius,
                      ),
                      child: player.currentAudio!.album?.thumb != null
                          ? CachedNetworkImage(
                              imageUrl:
                                  player.currentAudio!.album!.thumb!.photo1200!,
                              cacheKey: "${player.currentAudio!.album!.id}1200",
                              width: _playerImageSize,
                              height: _playerImageSize,
                              fit: BoxFit.fill,
                              placeholder: (BuildContext context, String url) =>
                                  const FallbackAudioAvatar(),
                              cacheManager: CachedNetworkImagesManager.instance,
                              memCacheWidth: _playerImageSize.toInt(),
                              memCacheHeight: _playerImageSize.toInt(),
                            )
                          : const FallbackAudioAvatar(
                              width: _playerImageSize,
                              height: _playerImageSize,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Текст песни данного трека.
        if (player.currentAudio!.lyrics != null &&
            user.settings.trackLyricsEnabled)
          Align(
            alignment: Alignment.topCenter,
            child: AnimatedOpacity(
              opacity: lyricsLoadedAndShown ? 1.0 : 0.0,
              duration: const Duration(
                milliseconds: 500,
              ),
              curve: Curves.ease,
              child: TrackLyricsBlock(
                lyrics: player.currentAudio!.lyrics!,
              ),
            ),
          ),
      ],
    );
  }
}

/// Кнопки, а так же информация по текущему треку полноэкранного плеера Mobile Layout'а, отображаемого снизу плеера.
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

    return Column(
      children: [
        // Кнопки для лайка/дизлайка, а так же включения/отключения текста песни.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Кнопка для дизлайка/лайка трека.
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

            // Информация по текущему треку: его исполнителю и названию.
            Expanded(
              child: Column(
                children: [
                  // Название трека (и иконка explicit).
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                          size: 12,
                        ),
                    ],
                  ),

                  // Иссполнитель трека.
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

            // Кнопка для включения/отключения показа текста песни.
            IconButton(
              onPressed: player.currentAudio!.hasLyrics
                  ? () {
                      user.settings.trackLyricsEnabled =
                          !user.settings.trackLyricsEnabled;

                      user.markUpdated();
                    }
                  : null,
              icon: Icon(
                user.settings.trackLyricsEnabled &&
                        player.currentAudio!.hasLyrics
                    ? Icons.lyrics
                    : Icons.lyrics_outlined,
                color: Theme.of(context).colorScheme.primary.withOpacity(
                      player.currentAudio!.hasLyrics ? 1.0 : 0.5,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 10,
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
                    onChangeEnd: (double newProgress) => player.seekNormalized(
                      newProgress,
                    ),
                  );
                },
              ),
            ),
          ),

        // Кнопки управления воспроизведением.
        SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Shuffle.
              StreamBuilder<bool>(
                stream: player.shuffleModeEnabledStream,
                builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                  final enabled = snapshot.data ?? false;

                  return IconButton(
                    onPressed: () async {
                      await player.setShuffle(!enabled);

                      user.settings.shuffleEnabled = !enabled;
                      user.markUpdated();
                    },
                    icon: Icon(
                      enabled ? Icons.shuffle_on_outlined : Icons.shuffle,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  );
                },
              ),
              const SizedBox(
                width: 8,
              ),

              // Запуск предыдущего трека.
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

              // Кнопка паузы.
              StreamBuilder<bool>(
                stream: player.playingStream,
                builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                  final bool playing = snapshot.data ?? false;

                  return IconButton(
                    onPressed: () => player.playOrPause(
                      !playing,
                    ),
                    icon: Icon(
                      playing ? Icons.pause_circle : Icons.play_circle,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    iconSize: 50,
                  );
                },
              ),
              const SizedBox(
                width: 8,
              ),

              // Запуск следующего трека.
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
                builder:
                    (BuildContext context, AsyncSnapshot<LoopMode> snapshot) {
                  final LoopMode loopMode = snapshot.data ?? LoopMode.all;

                  return IconButton(
                    onPressed: () => player.setLoop(
                      loopMode == LoopMode.one ? LoopMode.all : LoopMode.one,
                    ),
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
class FullscreenPlayerMobileRoute extends StatefulWidget {
  const FullscreenPlayerMobileRoute({
    super.key,
  });

  @override
  State<FullscreenPlayerMobileRoute> createState() =>
      _FullscreenPlayerMobileRouteState();
}

class _FullscreenPlayerMobileRouteState
    extends State<FullscreenPlayerMobileRoute> {
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
    /// Высота блока с текстом песни.
    final double lyricsBlockHeight = MediaQuery.of(context).size.height -
        _playerPadding * 2 -
        200 -
        MediaQuery.of(context).systemGestureInsets.bottom -
        MediaQuery.of(context).systemGestureInsets.top;

    return Padding(
      padding: const EdgeInsets.all(
        _playerPadding,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Кнопки управления полноэкранным плеером сверху.
          const TopFullscreenControls(),

          // Изображение трека, либо текст песни поверх него.
          SizedBox(
            height: lyricsBlockHeight,
            child: const ImageLyricsBlock(),
          ),

          // Управление плеером, а так же информация по текущему треку.
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 22,
            ),
            child: FullscreenMediaControls(),
          ),
        ],
      ),
    );
  }
}
