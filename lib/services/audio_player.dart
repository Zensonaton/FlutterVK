import "dart:async";
import "dart:io";

import "package:audio_service/audio_service.dart";
import "package:audio_session/audio_session.dart";
import "package:collection/collection.dart";
import "package:discord_rpc/discord_rpc.dart";
import "package:flutter/foundation.dart";
import "package:flutter_cache_manager/flutter_cache_manager.dart";
import "package:http/http.dart";
import "package:media_kit/media_kit.dart";
import "package:smtc_windows/smtc_windows.dart";

import "../api/shared.dart";
import "../consts.dart";
import "../main.dart";
import "../provider/user.dart";
import "../utils.dart";
import "cache_manager.dart";
import "download_manager.dart";
import "logger.dart";

/// enum, хранящий в себе различные возможные состояния работы [MediaKitPlayerExtended].
enum AudioPlaybackState {
  /// Воспроизводится трек.
  playing,

  /// Трек находится на паузе.
  paused,

  /// Воспроизведение плейлиста завершено.
  completed,

  /// Буферизация трека.
  buffering,

  /// Воспроизведение полностью остановлено.
  stopped;
}

/// Расширяет функционал класса [Player] библиотеки `media_kit`, getter и setter-методы для получения таких значений состояния класса, которые по-умолчанию не предоставляются стандартным объектом [Player].
class MediaKitPlayerExtended extends Player {
  final AppLogger _logger = getLogger("MediaKitPlayerExtended");

  final NativePlayer _nativePlayer;

  late List<StreamSubscription> _subscriptions;
  final StreamController<AudioPlaybackState> _playerStateStream;
  final StreamController<Playlist> _playlistStream;
  final StreamController<bool> _normalizationStream;
  final StreamController<bool> _shuffleStream;
  final StreamController<PlaylistMode> _loopModeStream;

  bool _normalizationEnabled;
  bool _shuffleEnabled;
  PlaylistMode _loopMode;
  bool _isLoaded;

  Playlist? _playlist;
  List<Media>? _unshuffledPlaylist;

  final DownloadManager _downloadManager = DownloadManager();

  /// Максимальное количество треков, которые могут быть загружены заранее.
  int maxPreloadTracks = 5;

  /// Указывает 'время жизни' для треков в кэше.
  ///
  /// Если не указывать, то при сохранении треки будут храниться месяц (30 дней).
  Duration? cacheLifespanDuration = const Duration(
    days: 1,
  );

  /// Указывает включённость нормализации.
  ///
  /// Переключить состояние нормализации можно при помощи метода [setAudioNormalization].
  bool get normalizationEnabled => _normalizationEnabled;

  /// Состояние случайного перемешивания треков в плейлисте.
  ///
  /// Для управления данным полем можно воспользоваться методом [setShuffle].
  bool get shuffleEnabled => _shuffleEnabled;

  /// Указывает состояние повтора плейлиста.
  ///
  /// Переключить можно при помощи метода [setPlaylistMode].
  PlaylistMode get loopMode => _loopMode;

  /// Указывает, что данный плеер не находится в состоянии [AudioPlaybackState.stopped];
  bool get isLoaded => _isLoaded;

  /// Индекс трека из плейлиста [currentPlaylist], который играет в данный момент.
  int? get trackIndex => _playlist?.index;

  Stream<AudioPlaybackState> get playerStateStream => _playerStateStream.stream;
  Stream<bool> get shuffleStream => _shuffleStream.stream;
  Stream<PlaylistMode> get loopModeStream => _loopModeStream.stream;
  Stream<Playlist> get playlistStream => _playlistStream.stream;
  Stream<int> get indexChangeStream {
    int oldIndex = _playlist?.index ?? -1;

    return playlistStream.map((event) => event.index).where((newIndex) {
      if (newIndex != oldIndex) {
        oldIndex = newIndex;

        return true;
      }

      return false;
    });
  }

  /// Предыдущий объект типа [Media] из очереди.
  ///
  /// Если ничего сейчас не играет, либо сейчас играет самый первый трек из очереди, то вернётся null.
  Media? get previousMedia {
    if (trackIndex == null || _playlist == null || trackIndex! - 1 < 0) {
      return null;
    }

    return _playlist!.medias[trackIndex! - 1];
  }

  /// Объект типа [Media], олицетворяющий трек, играющий в данный момент.
  ///
  /// Если ничего сейчас не играет, то вернётся null.
  Media? get currentMedia {
    if (trackIndex == null ||
        _playlist == null ||
        trackIndex! >= _playlist!.medias.length) {
      return null;
    }

    return trackIndex != null ? _playlist!.medias[trackIndex!] : null;
  }

  /// Следующий объект типа [Media] в очереди.
  ///
  /// Если ничего сейчас не играет, либо сейчас играет самый последний трек, то вернётся null.
  Media? get nextMedia {
    if (trackIndex == null ||
        _playlist == null ||
        trackIndex! + 1 >= _playlist!.medias.length) {
      return null;
    }

    return _playlist!.medias[trackIndex! + 1];
  }

  /// Предыдущий трек типа [Audio] из очереди.
  ///
  /// Если ничего сейчас не играет, либо сейчас играет самый первый трек из очереди, то вернётся null.
  Audio? get previousAudio {
    final Media? media = previousMedia;
    if (media == null) return null;

    assert(media.extras != null && media.extras!["audio"] is Audio,
        "Объект audio отсутствует в extras");

    return media.extras!["audio"];
  }

  /// Текущий [Audio] из очереди.
  ///
  /// Если ничего сейчас не играет, либо сейчас играет самый первый трек из очереди, то вернётся null.
  Audio? get currentAudio {
    final Media? media = currentMedia;
    if (media == null) return null;

    assert(media.extras != null && media.extras!["audio"] is Audio,
        "Объект audio отсутствует в extras");

    return media.extras!["audio"];
  }

  /// Следующий [Audio] из очереди.
  ///
  /// Если ничего сейчас не играет, либо сейчас играет самый первый трек из очереди, то вернётся null.
  Audio? get nextAudio {
    final Media? media = nextMedia;
    if (media == null) return null;

    assert(media.extras != null && media.extras!["audio"] is Audio,
        "Объект audio отсутствует в extras");

    return media.extras!["audio"];
  }

  /// Прогресс проигранности данного трека. Возвращает значение от 0.0 до 1.0.
  ///
  /// Возвращает 0.0 во время буферизации.
  double get progress => (state.buffering || state.duration == Duration.zero)
      ? 0
      : clampDouble(
          state.position.inMilliseconds / state.duration.inMilliseconds,
          0,
          1,
        );

  /// Инициализирует данный плеер.
  Future<void> _initPlayer() async {
    _logger.d("Called initPlayer");

    await _nativePlayer.setProperty(
      "network-timeout",
      "60",
    );
  }

  /// Возвращает копию плейлиста, в котором все треки расположены в случайном порядке, а переданный трек с индексом [index] находится в самом начале выходного плейлиста.
  List<Media> _getShuffledPlaylist(List<Media> medias, int index) {
    final Media currentAudio = medias[index];

    return medias.toList()
      ..shuffle()
      ..remove(currentAudio)
      ..insert(0, currentAudio);
  }

  /// Заменяет текущий плейлист новым.
  Future<void> setPlaylist(
    Playlist playlist, {
    bool ignoreShuffle = true,
  }) async {
    _logger.d(
      "Called setPlaylist(..., $ignoreShuffle)",
    );

    int index = playlist.index;

    // Перемешиваем новый плейлист, если у нас до этого был включён shuffle.
    if (!ignoreShuffle) {
      if (shuffleEnabled) {
        // Случайно перемешиваем плейлист, сохраняя "оригинальную" версию плейлиста.
        _unshuffledPlaylist = List.from(playlist.medias);

        final List<Media> shuffledMedia = _getShuffledPlaylist(
          playlist.medias,
          playlist.index,
        );

        // Получаем новый индекс в плейлисте.
        index = shuffledMedia.indexOf(
          playlist.medias[index],
        );
        playlist = playlist.copyWith(
          medias: shuffledMedia,
          index: index,
        );
      } else if (!shuffleEnabled && _unshuffledPlaylist != null) {
        // Получаем новый индекс в плейлисте.
        index = _unshuffledPlaylist!.indexOf(
          playlist.medias[index],
        );

        // Восстанавливаем оригинальный плейлист до его перемешивания.
        playlist = playlist.copyWith(
          medias: _unshuffledPlaylist!,
          index: index,
        );

        _unshuffledPlaylist = null;
      }
    }

    // Загружаем, а также кэшируем треки.
    for (var i = index; i < index + 5 && i < playlist.medias.length; i++) {
      final Media media = playlist.medias[i];
      final Audio audio = media.extras?["audio"];

      // Если мы уже заменили кэшированной версией трека, то ничего не делаем.
      if (media.extras!["fromCache"] ?? false) continue;

      // Проверяем наличие трека в кэше.
      final FileInfo? cachedFile =
          await VKMusicCacheManager.instance.getFileFromCache(audio.mediaKey);

      // Трек есть в кэше, заменяем кэшированной версией.
      if (cachedFile != null) {
        playlist.medias[i] = Media(
          cachedFile.file.uri.toString(),
          extras: {
            ...media.extras!,
            "fromCache": true,
          },
        );

        continue;
      }

      // Трека нет в кэше, запускаем загрузку.
      cacheAudio(audio);
    }

    _playlist = playlist;
    _playlistStream.add(_playlist!);
  }

  /// Загружает, после чего помещает трек в кэш приложения.
  Future<void> cacheAudio(
    Audio audio,
  ) async {
    _logger.d(
      "Called cacheAudio for ${audio.title} (${audio.mediaKey})",
    );

    // Загружаем трек при помощи менеджера загрузок.
    final Response? response = await _downloadManager.download(
      audio.url,
      cacheKey: audio.mediaKey,
    );

    // Трек *возможно* загружен, обрабатываем его, помещая его в кэш.
    // Данный метод может быть преждевременно отменён в случае, если загрузка файла уже начата.
    if (response == null) return;

    // Проверяем status code.
    if (response.statusCode != 200) {
      _logger.w(
        "Bad status code for track ${audio.title}: ${response.statusCode}",
      );

      return;
    }

    _logger.d(
      "${audio.title} has been downloaded (${response.bodyBytes.length} bytes)",
    );

    // Сохраняем скачанный трек в кэш.
    await VKMusicCacheManager.instance.putFile(
      audio.url,
      response.bodyBytes,
      fileExtension: "mр3",
      key: audio.mediaKey,
      eTag: response.headers["etag"],
      maxAge: cacheLifespanDuration == null
          ? const Duration(
              days: 30,
            )
          : cacheLifespanDuration!,
    );
  }

  /// Устанавливает настройки для кэширования треков.
  ///
  /// [maxPreloadTracks] указывает количество треков, которые загружаются "наперёд". Слишком большие значения устанавливать не рекомендуется, поскольку у пользователя может быть лимитированное подключение к интернету. При указании null предзагрузка будет полностью отключена.
  /// [tracksLifespan] указывает, сколько треки будут храниться в хранилище у пользователя. Если использовать null, то при сохранении треки будут храниться месяц (30 дней).
  /// [parallelDownloads] указывает максимальное количество треков, которые могут загружаться паралельно.
  void setMediaCachingSettings({
    int maxPreloadTracks = 5,
    Duration? tracksLifespan = const Duration(
      days: 1,
    ),
    int parallelDownloads = 2,
  }) {
    _logger.d(
      "Called setMediaCachingSettings($maxPreloadTracks, $tracksLifespan, $parallelDownloads)",
    );

    this.maxPreloadTracks = maxPreloadTracks;
    cacheLifespanDuration = tracksLifespan;
    _downloadManager.parallelDownloads = parallelDownloads;
  }

  @override
  Future<void> setShuffle(bool shuffle) async {
    _logger.d("Called setShuffle($shuffle)");
    if (_shuffleEnabled == shuffle) return;

    _shuffleEnabled = shuffle;

    // Вся логика для shuffle расположена внутри метода setPlaylist, если аргумент ignoreShuffle равен false.
    if (_playlist != null) {
      await setPlaylist(
        _playlist!,
        ignoreShuffle: false,
      );
    }

    await super.setShuffle(shuffle);
    _shuffleStream.add(shuffle);
  }

  @override
  Future<void> setPlaylistMode(PlaylistMode playlistMode) async {
    _logger.d("Called setPlaylistMode($playlistMode)");

    await super.setPlaylistMode(playlistMode);

    _loopMode = playlistMode;
    _loopModeStream.add(playlistMode);
  }

  @override
  Future<void> stop() async {
    _logger.d("Called stop");

    await super.stop();
    await pause();
    await seek(Duration.zero);

    _loopMode = PlaylistMode.none;
    _shuffleEnabled = false;
    _playlist = null;
    _unshuffledPlaylist = null;
    _isLoaded = false;

    _shuffleStream.add(false);
    _playerStateStream.add(AudioPlaybackState.stopped);
    _loopModeStream.add(PlaylistMode.none);
  }

  @override
  Future<void> dispose() async {
    _logger.d("Called dispose");

    for (StreamSubscription subscription in _subscriptions) {
      subscription.cancel();
    }

    return super.dispose();
  }

  @override
  Future<void> open(
    Playable playable, {
    bool play = true,
  }) async {
    _logger.d("Called open(..., $play)");

    if (playable is Playlist) {
      await setPlaylist(
        playable,
        ignoreShuffle: false,
      );

      await super.open(
        playable.medias[playable.index],
        play: play,
      );

      return;
    }

    await super.open(
      playable,
      play: play,
    );
  }

  @override
  Future<void> play() async {
    if (_playlist == null) return;

    super.play();
  }

  /// Управляет воспроизведением. Вызывает [Player.play] или [Player.pause] в зависимости от аргумента [play].
  Future<void> setPlaying(bool play) async {
    if (play) {
      await this.play();

      return;
    }

    await pause();
  }

  /// Переключает состояние воспроизведения.
  Future<void> togglePlay() async {
    await setPlaying(!state.playing);
  }

  /// Изменяет громкость плеера.
  ///
  /// Передаваемая громкость должна находиться в пределах от 0.0 до 1.0.
  @override
  Future<void> setVolume(double volume) async {
    assert(volume >= 0.0 && volume <= 1.0,
        "volume должен быть в пределах от 0.0 до 1.0");

    _logger.d("Called setVolume($volume)");

    if (state.volume == volume * 100) return;

    await super.setVolume(volume * 100);
  }

  @override
  Future<void> next() async {
    _logger.d("Called next");
    if (_playlist == null) return;

    // Если это последний трек в плейлисте, то нужно начать воспроизведение с начала.
    if (trackIndex == _playlist!.medias.length - 1) {
      _logger.d(
        "Last track in playlist, starting playback from the start of playlist",
      );

      await setPlaylist(
        _playlist!.copyWith(
          index: 0,
        ),
      );

      return super.open(
        currentMedia!,
      );
    }

    await setPlaylist(
      _playlist!.copyWith(
        index: trackIndex! + 1,
      ),
    );

    return super.open(
      currentMedia!,
    );
  }

  @override
  Future<void> previous() async {
    _logger.d("Called previous");

    if (_playlist == null) return;

    // Если это самый первый трек в плейлисте, то нужно начать воспроизведение с конца.
    if (_playlist!.index == 0) {
      _logger.d(
        "First track in playlist, starting playback from the end of playlist",
      );

      await setPlaylist(
        _playlist!.copyWith(
          index: _playlist!.medias.length - 1,
        ),
      );

      return super.open(
        currentMedia!,
      );
    }

    await setPlaylist(
      _playlist!.copyWith(
        index: trackIndex! - 1,
      ),
    );

    return super.open(
      currentMedia!,
    );
  }

  @override
  Future<void> jump(int index) async {
    _logger.d("Called jump($index)");

    // Не позволяем перейти на тот трек, который находится за пределами плейлиста.
    if (_playlist == null || index < 0 || index >= _playlist!.medias.length) {
      return;
    }

    await setPlaylist(
      _playlist!.copyWith(index: index),
    );
    return super.open(
      currentMedia!,
    );
  }

  @override
  Future<void> move(int from, int to) async {
    _logger.d("Called move($from, $to)");

    if (_playlist == null ||
        from >= _playlist!.medias.length ||
        to >= _playlist!.medias.length) return;

    final Playlist newPlaylist = _playlist!.copyWith(
      medias: _playlist!.medias.mapIndexed((int index, Media element) {
        if (index == from) {
          return _playlist!.medias[to];
        } else if (index == to) {
          return _playlist!.medias[from];
        }
        return element;
      }).toList(),
    );

    await setPlaylist(
      _playlist!.copyWith(
        index: newPlaylist.medias.indexOf(
          currentMedia!,
        ),
        medias: newPlaylist.medias,
      ),
    );
  }

  /// Добавляет трек [media] в конец играющего в данный момент плейлиста.
  @override
  Future<void> add(Media media) async {
    _logger.d("Called add(...)");

    if (_playlist == null) return;

    await setPlaylist(
      _playlist!.copyWith(
        medias: [
          ..._playlist!.medias,
          media,
        ],
      ),
    );

    if (shuffleEnabled && _unshuffledPlaylist != null) {
      _unshuffledPlaylist!.add(media);
    }
  }

  /// Добавляет трек [media] как следующий трек в очереди.
  ///
  /// После окончания воспроизведения текущего трека, плеер перейдет к воспроизведению трека из этого метода.
  Future<void> playNext(Media media) async {
    _logger.d("Called playNext(...)");

    if (_playlist == null) return;

    await setPlaylist(
      _playlist!.copyWith(
        medias: [
          ..._playlist!.medias.slice(0, trackIndex! + 1),
          media,
          ..._playlist!.medias.slice(trackIndex! + 1)
        ],
      ),
    );

    if (shuffleEnabled && _unshuffledPlaylist != null) {
      _unshuffledPlaylist!.insert(trackIndex!, media);
    }
  }

  /// Включает или отключает нормализацию громкости треков.
  Future<void> setAudioNormalization(bool enabled) async {
    _logger.d("Called setAudioNormalization($enabled)");

    if (_normalizationEnabled == enabled) return;

    _normalizationEnabled = enabled;
    await _nativePlayer.setProperty(
      "af",
      enabled ? "dynaudnorm=g=5:f=250:r=0.9:p=0.5" : "",
    );

    _normalizationStream.add(enabled);
  }

  MediaKitPlayerExtended({
    super.configuration = const PlayerConfiguration(
      title: "Flutter VK",
      logLevel: MPVLogLevel.warn,
    ),
  })  : _nativePlayer = NativePlayer(configuration: configuration),
        _playerStateStream = StreamController.broadcast(),
        _normalizationStream = StreamController.broadcast(),
        _shuffleStream = StreamController.broadcast(),
        _loopModeStream = StreamController.broadcast(),
        _playlistStream = StreamController.broadcast(),
        _normalizationEnabled = false,
        _shuffleEnabled = false,
        _loopMode = PlaylistMode.none,
        _isLoaded = false {
    _subscriptions = [
      // Состояния проигрывания трека (пауза/воспроизведение).
      stream.playing.listen(
        (bool playing) {
          if (playing) _isLoaded = true;

          _playerStateStream.add(
            playing ? AudioPlaybackState.playing : AudioPlaybackState.paused,
          );
        },
      ),

      // Состояние буферизации.
      stream.buffering.listen(
        (bool isBuffering) {
          // К сожалению, событие о окончании буферизации отправляется позднее, чем состояние воспроизведения трека.
          // По этой причине, здесь может произойти отправка события о том, что идёт воспроизведение.

          if (isBuffering) {
            _playerStateStream.add(AudioPlaybackState.buffering);

            return;
          }

          _playerStateStream.add(
            state.playing
                ? AudioPlaybackState.playing
                : AudioPlaybackState.paused,
          );
        },
      ),

      // Состояние завершённости трека.
      stream.completed.listen((bool isCompleted) async {
        if (!isCompleted) return;

        _playerStateStream.add(AudioPlaybackState.completed);

        if (loopMode == PlaylistMode.single) {
          await super.open(
            currentMedia!,
          );

          return;
        }

        await next();

        await Future.delayed(
          const Duration(milliseconds: 250),
          play,
        );
      }),

      // Обработчик пустого плейлиста.
      stream.playlist.listen((event) {
        if (event.medias.isNotEmpty) return;

        _logger.d("Playlist is empty");

        _isLoaded = false;

        _playerStateStream.add(AudioPlaybackState.stopped);
      }),
    ];
  }
}

/// Класс для работы с аудиоплеером.
///
/// Данный класс является расширением класса [MediaKitPlayerExtended], который в свою очередь расширяет [Player] от media_kit с целью добавления дополнительных Stream'ов и state-переменных.
class VKMusicPlayer extends MediaKitPlayerExtended {
  final AppLogger logger = getLogger("VKMusicPlayer");

  /// Объект SMTC для отображения плеера для Windows.
  ///
  /// Данный объект не null только в том случае, если используется Windows. Инициализируется при вызове [_initPlayer].
  SMTCWindows? _smtc;

  /// Сессия объекта [AudioSession], который позволяет указать операционным системам то, что воспроизводит данное приложение, а так же даёт возможность обрабатывать события "затыкания" приложения в случае, к примеру, звонка.
  ///
  /// Данный объект инициализируется при вызове [_initPlayer].
  AudioSession? _audioSession;

  /// Объект [AudioPlayerHandler], который создаёт плеер в уведомлениях Android, а так же передаёт события при взаимодействиях с этим уведомлением.
  AudioPlayerHandler? audioPlayerHandler;

  /// Объект [DiscordRPC], который позволяет транслировать Rich Presence (надпись "сейчас слушает ...") в Discord.
  ///
  /// Инициализируется при вызове метода [_initPlayer]. Устанавливается лишь в случае, если [isDesktop] = true.
  DiscordRPC? _discordRPC;

  bool _discordRPCEnabled = false;

  /// Указывает, что [DiscordRPC] должен быть показан пользователю.
  ///
  /// Зависит от настройки.
  bool get discordRPCEnabled => _discordRPCEnabled;

  /// Указывает, что данный плеер был поставлен на паузу потому что другое приложение начало воспроизводить музыку.
  bool _pausedExternally = false;

  VKMusicPlayer() {
    _initPlayer();

    // Слушаем события от SMTC, если приложение запущено на Windows.
    if (Platform.isWindows) {
      _smtc = SMTCWindows(
        config: const SMTCConfig(
          fastForwardEnabled: false,
          nextEnabled: true,
          pauseEnabled: true,
          playEnabled: true,
          rewindEnabled: false,
          prevEnabled: true,
          stopEnabled: true,
        ),
        enabled: true,
      );

      try {
        _smtc!.buttonPressStream.listen((PressedButton event) async {
          switch (event) {
            case PressedButton.play:
              await play();

              break;
            case PressedButton.pause:
              await pause();

              break;
            case PressedButton.next:
              await next();

              break;
            case PressedButton.previous:
              await previous();

              break;
            case PressedButton.stop:
              await stop();

              break;
            default:
              break;
          }
        });
      } catch (e, stackTrace) {
        logger.e(
          "Ошибка при обработке события от SMTC: ",
          error: e,
          stackTrace: stackTrace,
        );
      }
    }

    // Слушаем события плеера.
    _subscriptions = [
      ..._subscriptions,

      // Событие изменение состояния плеера (пауза, ...).
      playerStateStream.listen((AudioPlaybackState state) => _updateState()),

      // Обработчик изменения текущего трека.
      indexChangeStream.listen((int index) async {
        final Audio? audio = currentAudio;
        if (audio == null) return;

        await _sendTrackData(audio);
      }),
    ];
  }

  /// Включает или отключает трансляцию Discord Rich Presence.
  Future<void> setDiscordRPCEnabled(bool enabled) async {
    logger.d("called setDiscordRPCEnabled($enabled)");

    if (enabled == discordRPCEnabled) return;

    assert(
      isDesktop,
      "Discord RPC может быть включён только на Desktop-системах.",
    );

    _discordRPCEnabled = enabled;

    if (enabled) {
      if (currentAudio != null) await _sendTrackData(currentAudio!);

      return;
    }

    _discordRPC?.clearPresence();
  }

  @override
  Future<void> play() async {
    super.play();

    _pausedExternally = false;
  }

  @override
  Future<void> pause() async {
    super.pause();

    if (discordRPCEnabled) {
      _discordRPC?.clearPresence();
    }
  }

  @override
  Future<void> stop() async {
    await super.stop();

    if (Platform.isWindows) {
      _smtc?.disableSmtc();
    }

    await _audioSession?.setActive(false);
    audioPlayerHandler?.playbackState.add(PlaybackState());
    if (discordRPCEnabled) {
      _discordRPC?.clearPresence();
    }
  }

  /// Запускает воспроизведение указанного плейлиста.
  Future<void> openAudioList(
    ExtendedVKPlaylist playlist, {
    int index = 0,
  }) async {
    assert(
      playlist.audios != null,
      "Ожидалось, что ExtendedVKPlaylist будет иметь массив треков",
    );

    // Сохраняем настройки кэша.
    setMediaCachingSettings(
      maxPreloadTracks: playlist.isFavoritesPlaylist ? 5 : 2,
      tracksLifespan: playlist.isFavoritesPlaylist
          ? null
          : const Duration(
              days: 1,
            ),
    );

    // Добавляем все треки в очередь воспроизведения настоящего плеера.
    await open(
      Playlist(
        [
          for (Audio audio in playlist.audios!)
            Media(audio.url, extras: {
              "audio": audio,
              "fromCache": false,
            }),
        ],
        index: index,
      ),
    );
  }

  /// Добавляет трек [media] как следующий трек в очереди.
  ///
  /// После окончания воспроизведения текущего трека, плеер перейдет к воспроизведению трека из этого метода.
  Future<void> addNextToQueue(Audio audio) async {
    await super.playNext(
      Media(audio.url, extras: {
        "audio": audio,
      }),
    );
  }

  /// Инициализирует данный плеер, посылая уведомления и прочую информацию внешним системам.
  @override
  Future<void> _initPlayer() async {
    super._initPlayer();

    // Создаём объект AudioSession.
    if (_audioSession == null) {
      _audioSession = await AudioSession.instance;

      await _audioSession!.configure(
        const AudioSessionConfiguration.music(),
      );

      // События отключения наушников.
      _audioSession?.becomingNoisyEventStream.listen((_) {
        player.pause();
      });

      // Другие события системы.
      //
      // К примеру, здесь обрабатываются события звонка на телефон (громкость понижается на 50%), а так же события запуска других аудио-приложений.
      _audioSession?.interruptionEventStream.listen((
        AudioInterruptionEvent event,
      ) async {
        if (event.begin) {
          switch (event.type) {
            case AudioInterruptionType.duck:
              await player.setVolume(0.5);

              break;
            case AudioInterruptionType.pause:
            case AudioInterruptionType.unknown:
              if (!state.playing) return;

              await player.pause();

              // Здесь мы должны запомнить то, что пауза была установлена внешне.
              _pausedExternally = true;

              break;
          }
        } else {
          switch (event.type) {
            case AudioInterruptionType.duck:
              await player.setVolume(1.0);

              break;
            case AudioInterruptionType.pause:
            case AudioInterruptionType.unknown:
              // Мы имеем право на возобновление плеера только в том случае, если пауза была установлена внешне.
              if (!_pausedExternally) return;

              await player.play();

              break;
          }
        }
      });
    }

    // Инициализируем Discord Rich Presence на Desktop-системах.
    if (isDesktop) {
      DiscordRPC.initialize();

      _discordRPC = DiscordRPC(
        applicationId: discordAppID.toString(),
      );
      _discordRPC!.start(
        autoRegister: true,
      );
      _discordRPC!.clearPresence();
    }
  }

  /// Метод, отправляющий операционным системам информацию о том, что поменялся текущий трек.
  ///
  /// Данный метод должен вызываться при изменении трека.
  Future<void> _sendTrackData(Audio audio) async {
    // Указываем, что в данный момент идёт сессия музыки.
    await _audioSession!.setActive(true);

    // Обновляем трек в уведомлении Android.
    audioPlayerHandler?.mediaItem.add(
      MediaItem(
        id: audio.mediaKey,
        title: audio.title,
        album: audio.album?.title,
        artist: audio.artist,
        duration: Duration(
          seconds: audio.duration,
        ),
        artUri: audio.album?.thumb != null
            ? Uri.parse(
                audio.album!.thumb!.photo!,
              )
            : null,
      ),
    );

    // Если у пользователя Windows, то посылаем SMTC обновление.
    if (Platform.isWindows) {
      if (!_smtc!.enabled) await _smtc!.enableSmtc();

      await _smtc!.updateMetadata(
        MusicMetadata(
          title: audio.title,
          albumArtist: audio.artist,
          album: audio.album?.title,
          thumbnail: audio.album?.thumb?.photo,
        ),
      );
    }

    // Обновляем Discord RPC, если это разрешено пользователем.
    if (discordRPCEnabled) {
      _discordRPC?.updatePresence(
        DiscordPresence(
          state: audio.title,
          details: audio.artist,
          partySize: _playlist?.index,
          partySizeMax: _playlist?.medias.length,
          largeImageKey: "flutter-vk-logo",
          largeImageText: "Flutter VK",
        ),
      );
    }
  }

  /// Посылает обновления состояния в уведомления Android и Windows SMTC.
  void _updateState() async {
    // Если у пользователя Windows, то посылаем SMTC обновление.
    if (Platform.isWindows) {
      await _smtc!.setPlaybackStatus(
        state.playing ? PlaybackStatus.Playing : PlaybackStatus.Paused,
      );
    }

    // Обновляем состояние в уведомлении Android и других систем.
    audioPlayerHandler?.playbackState.add(
      PlaybackState(
        controls: [
          state.playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToPrevious,
          MediaControl.skipToNext,
          // TODO: Кнопки для лайка и shuffle.
          // const MediaControl(
          //   androidIcon: "drawable/baseline_forward_30_24",
          //   label: "Shuffle",
          //   action: MediaAction.setShuffleMode,
          // ),
          // MediaControl.custom(
          //   androidIcon: "drawable/ic_baseline_favorite_24",
          //   label: "favorite",
          //   name: "favorite",
          //   extras: <String, dynamic>{"level": 1},
          // ),
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekBackward,
          MediaAction.seekForward,
          MediaAction.skipToPrevious,
          MediaAction.skipToNext,
        },
        androidCompactActionIndices: [
          1,
          0,
          2,
        ],
        updatePosition: state.position,
        playing: state.playing,
        bufferedPosition: state.buffering ? state.buffer : Duration.zero,
        processingState: state.buffering
            ? AudioProcessingState.buffering
            : AudioProcessingState.ready,
      ),
    );
  }
}

/// Класс для управления аудиоплеера при помощи уведомлений.
class AudioPlayerHandler extends BaseAudioHandler
    with SeekHandler, QueueHandler {
  @override
  Future<void> play() async => player.play();

  @override
  Future<void> pause() async => player.pause();

  @override
  Future<void> skipToNext() async => player.next();

  @override
  Future<void> skipToPrevious() async => player.previous();

  @override
  Future<void> skipToQueueItem(int index) async => player.jump(index);

  @override
  Future<void> stop() async => player.stop();

  @override
  Future<void> seek(Duration position) async => player.seek(position);

  @override
  Future<void> onTaskRemoved() async => player.stop();

  @override
  Future<void> onNotificationDeleted() async => player.stop();
}
