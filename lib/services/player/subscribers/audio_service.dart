import "dart:async";

import "package:audio_service/audio_service.dart";

import "../../../consts.dart";
import "../../../enums.dart";
import "../../../main.dart";
import "../../../provider/user.dart";
import "../../../routes/home/music.dart";
import "../../../utils.dart";
import "../../cache_manager.dart";
import "../../logger.dart";
import "../player.dart";
import "../subscriber.dart";

/// Класс подписчика на события [Player] для работы с [AudioService]. Это нужно, чтобы создать медиа-уведомление на OS Android/iOS/Web для отображения, а так же управлением музыкой.
class AudioServicePlayerSubscriber extends PlayerSubscriber {
  static final AppLogger logger = getLogger("AudioServicePlayerSubscriber");

  AudioServicePlayerSubscriber(Player player) : super("AudioService", player);

  /// Объект сервиса аудио.
  late final PlayerAudioService _audioService;

  @override
  Future<void> initialize() async {
    if (isAndroid || isiOS || isMacOS) {
      throw UnsupportedError(
        "Audio service is only supported on Web, Android, iOS and macOS.",
      );
    }

    _audioService = await AudioService.init(
      builder: () => PlayerAudioService(player),
      config: const AudioServiceConfig(
        androidNotificationChannelName: appName,
        androidNotificationChannelId: "com.zensonaton.fluttervk",
        androidNotificationIcon: "drawable/ic_music_note",
        androidStopForegroundOnPause: false,
        preloadArtwork: true,
      ),
      cacheManager: CachedAlbumImagesManager.instance,
      cacheKeyResolver: (MediaItem item) => "${item.extras!["mediaKey"]!}max",
    );
  }

  @override
  List<StreamSubscription> subscribe(Player player) {
    return [
      player.isLoadedStream.listen(onIsLoaded),
      player.isPlayingStream.listen(onIsPlaying),
      player.isBufferingStream.listen(onIsBuffering),
      player.audioStream.listen(onAudio),
      player.playlistStream.listen(onPlaylist),
      player.seekStream.listen(onSeek),

      // События AudioService.
      AudioService.notificationClicked.listen(onNotificationClicked),
    ];
  }

  /// Преобразовывает переданный [audio] типа [ExtendedAudio] в [MediaItem].
  static MediaItem audioToMediaItem(ExtendedAudio audio) {
    final id = audio.mediaKey;
    String title = audio.title;
    if (audio.subtitle != null) title += " (${audio.subtitle})";
    if (audio.isExplicit) title += " $explicitChar";
    final artist = audio.artist;
    final album = audio.album?.title;
    final mediaArtUri =
        audio.maxThumbnail != null ? Uri.parse(audio.maxThumbnail!) : null;
    final Duration mediaDuration = Duration(
      seconds: audio.duration,
    );
    final Map<String, dynamic> mediaExtras = {
      "albumID": audio.album?.id,
      "mediaKey": id,
    };
    final Rating rating = Rating.newHeartRating(audio.isLiked);

    return MediaItem(
      id: id,
      title: title,
      artist: artist,
      album: album,
      artUri: mediaArtUri,
      duration: mediaDuration,
      extras: mediaExtras,
      rating: rating,
    );
  }

  /// События запуска плеера.
  void onIsLoaded(bool isLoaded) async {
    updatePlaybackState();
  }

  /// События паузы/воспроизведения музыки.
  void onIsPlaying(bool isPlaying) async {
    updatePlaybackState();
  }

  /// События буфферизации музыки.
  void onIsBuffering(bool isBuffering) async {
    updatePlaybackState();
  }

  /// События изменения режима перемешивания треков.
  void onIsShuffling(bool isShuffling) async {
    updatePlaybackState();
  }

  /// События изменения режима повторения треков.
  void onIsRepeating(bool isRepeating) async {
    updatePlaybackState();
  }

  /// События изменения трека, играющий в данный момент.
  void onAudio(ExtendedAudio audio) async {
    updatePlaybackState();
    updateAudio();
  }

  /// События изменения плейлиста.
  void onPlaylist(ExtendedPlaylist playlist) async {
    // TODO: Использовать очередь из треков, нежели playlist.audios.

    _audioService.queue.add(
      playlist.audios!
          .map(
            (audio) => audioToMediaItem(audio),
          )
          .toList(),
    );
  }

  /// События резкого скачка позиции трека.
  void onSeek(Duration position) async {
    updatePlaybackState();
  }

  /// Обработчик нажатия на уведомление.
  void onNotificationClicked(tapped) {
    if (!tapped) return;

    // TODO: Открытие полноэкранного плеера.
  }

  /// Обновляет состояние воспроизведения.
  void updatePlaybackState() {
    final audio = player.audio;
    final isLoaded = player.isLoaded;
    final playing = player.isPlaying;
    final position = player.position;
    final isBuffering = player.isBuffering;
    final bufferedPosition = player.bufferedPosition;
    final playlist = player.playlist;
    final isShuffling = player.isShuffling;
    final isRepeating = player.isRepeating;
    final index = player.index;
    final isLiked = audio?.isLiked == true;
    final isAudioMix = playlist?.type == PlaylistType.audioMix;
    final isRecommended = playlist?.isRecommendationTypePlaylist == true;

    final AudioServiceShuffleMode shuffleMode = isShuffling
        ? AudioServiceShuffleMode.all
        : AudioServiceShuffleMode.none;
    final AudioServiceRepeatMode repeatMode =
        isRepeating ? AudioServiceRepeatMode.one : AudioServiceRepeatMode.none;
    final AudioProcessingState processingState = isLoaded
        ? (isBuffering
            ? AudioProcessingState.loading
            : AudioProcessingState.ready)
        : AudioProcessingState.idle;

    _audioService.playbackState.add(
      PlaybackState(
        playing: playing,
        updatePosition: position,
        bufferedPosition: bufferedPosition,
        shuffleMode: shuffleMode,
        repeatMode: repeatMode,
        processingState: processingState,
        queueIndex: index,
        controls: [
          MediaControl.skipToPrevious,
          playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,

          // Кнопка для shuffle, если у нас не аудио микс.
          if (!isAudioMix && !isRecommended)
            MediaControl.custom(
              androidIcon: isShuffling
                  ? "drawable/ic_shuffle_enabled"
                  : "drawable/ic_shuffle",
              label: "Shuffle",
              name: MediaNotificationAction.shuffle.name,
            ),

          // Кнопка для дизлайка трека, если это рекомендуемый плейлист.
          if (isRecommended)
            MediaControl.custom(
              androidIcon: "drawable/ic_dislike",
              label: "Dislike",
              name: MediaNotificationAction.dislike.name,
            ),

          // Кнопка для сохранения трека как лайкнутый.
          MediaControl.custom(
            androidIcon: isLiked
                ? "drawable/ic_favorite"
                : "drawable/ic_favorite_outline",
            label: "Favorite",
            name: MediaNotificationAction.favorite.name,
          ),
        ],
        systemActions: {
          MediaAction.seek,
        },
        androidCompactActionIndices: const [0, 1, 2],
      ),
    );
  }

  /// Обновляет аудио, которое играет в данный момент.
  void updateAudio() {
    _audioService.mediaItem.add(
      player.audio != null ? audioToMediaItem(player.audio!) : null,
    );
  }
}

/// Расширение для класса [BaseAudioHandler], методы которого вызываются при взаимодействии с медиа-уведомлением.
class PlayerAudioService extends BaseAudioHandler with SeekHandler {
  static final AppLogger logger = getLogger("PlayerAudioService");

  final Player player;

  bool _canPause = true;
  Timer? _skipPauseTimer;

  PlayerAudioService(this.player);

  @override
  Future<void> play() => player.play();

  @override
  Future<void> pause() async {
    if (!_canPause) return;

    return player.pause();
  }

  @override
  Future<void> stop() => player.stop();

  @override
  Future<void> skipToNext() async {
    _startSkipPauseTimer();
    await player.next();
  }

  @override
  Future<void> skipToPrevious() async {
    _startSkipPauseTimer();
    await player.smartPrevious(
      viaNotification: true,
    );
  }

  @override
  Future<void> seek(Duration position) {
    return player.seek(position);
  }

  @override
  Future<void> onTaskRemoved() async {
    final keepPlayingOnClose =
        player.isPlaying && player.keepPlayingOnCloseEnabled;

    if (keepPlayingOnClose) {
      logger.d("User removed task, but I'm still alive, ha-ha!");

      return;
    }

    return await stop();
  }

  @override
  Future<void> onNotificationDeleted() {
    logger.w(
      "onNotificationDeleted is called, which should not supposed to happen",
    );

    return stop();
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    if (player.playlist?.type == PlaylistType.audioMix) return;

    final isShuffling = shuffleMode == AudioServiceShuffleMode.all;

    await player.setShuffle(isShuffling);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    final isRepeating = repeatMode == AudioServiceRepeatMode.one;

    await player.setRepeat(isRepeating);
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    final action = MediaNotificationAction.values.firstWhere(
      (action) => action.name == name,
    );

    switch (action) {
      case (MediaNotificationAction.shuffle):
        await setShuffleMode(
          player.isShuffling
              ? AudioServiceShuffleMode.group
              : AudioServiceShuffleMode.all,
        );

        break;

      case (MediaNotificationAction.favorite):
        if (!connectivityManager.hasConnection) return;

        await toggleTrackLike(player.ref, player.audio!);

        break;

      case (MediaNotificationAction.dislike):
        if (!connectivityManager.hasConnection) return;

        await dislikeTrack(player.ref, player.audio!);

        break;
    }
  }

  /// Запускает небольшой таймер, необходимый для включения возможности ставить плеер на паузу после вызовов [skipToNext] либо [skipToPrevious].
  void _startSkipPauseTimer() {
    // Данный код нужен, поскольку по неясной причине, плеер media_kit ломается, если перед вызовом [setPlaylist] вызвать [pause]:
    // audio_service вызывает метод [pause] при попытке переключить треки, если это действие было сделано через наушники.
    // Я не уверен, является ли это особенностью моих Google Pixel Buds Pro или нет.
    // https://forums.pocketcasts.com/forums/topic/pause-when-skipping-via-pixel-buds-pro/

    _canPause = false;
    _skipPauseTimer?.cancel();

    _skipPauseTimer = Timer(const Duration(milliseconds: 100), () {
      _canPause = true;
    });
  }
}
