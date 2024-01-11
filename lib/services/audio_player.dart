import "dart:async";
import "dart:io";
import "package:collection/collection.dart";

import "package:audio_service/audio_service.dart";
import "package:audio_session/audio_session.dart";
import "package:flutter/foundation.dart";
import "package:media_kit/media_kit.dart";
import "package:smtc_windows/smtc_windows.dart";

import "../api/shared.dart";
import "../main.dart";
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

  late final List<StreamSubscription> _subscriptions;
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
  void setPlaylist(Playlist playlist, {bool ignoreShuffle = true}) {
    _logger.d("Called setPlaylist(...)");

    // Перемешиваем новый плейлист, если у нас до этого был включён shuffle.
    //
    // Ввиду особенностей работы метода setShuffle у MediaKit'овского Player,
    //  нам необходимо самим сделать копию плейлиста со случайно разбросанными треками.
    if (!ignoreShuffle) {
      if (shuffleEnabled) {
        // Случайно перемешиваем плейлист.
        // Но для начала, нам нужно запомнить "оригинальную" версию плейлиста до его перемешивания.
        // Это необходимо, что бы при вызове этого метода с shuffleEnabled=false мы смогли вернуть оригинальную версию плейлиста.
        _unshuffledPlaylist = playlist.medias;

        // Узнаём какой трек играет сейчас, до перемешивания.
        final Media currentTrack = playlist.medias[playlist.index];

        // Случайно переставляем треки в плейлисте, устанавливая текущий трек в самое начало плейлиста.
        final List<Media> shuffledMedia = _getShuffledPlaylist(
          playlist.medias,
          playlist.index,
        );

        playlist = playlist.copyWith(
          medias: shuffledMedia,
          index: shuffledMedia.indexOf(currentTrack),
        );
      } else if (!shuffleEnabled && _unshuffledPlaylist != null) {
        // Восстанавливаем оригинальный плейлист до его перемешивания.
        playlist = playlist.copyWith(
          medias: _unshuffledPlaylist!,
          index: _unshuffledPlaylist!.indexOf(
            currentMedia!,
          ),
        );

        _unshuffledPlaylist = null;
      }
    }

    _playlist = playlist;
    _playlistStream.add(_playlist!);
  }

  @override
  Future<void> setShuffle(bool shuffle) async {
    _logger.d("Called setShuffle($shuffle)");
    if (_shuffleEnabled == shuffle) return;

    // Вся логика для shuffle расположена внутри метода setPlaylist, если аргумент ignoreShuffle равен false.
    if (_playlist != null) {
      setPlaylist(
        _playlist!,
        ignoreShuffle: false,
      );
    }

    await super.setShuffle(shuffle);

    _shuffleEnabled = shuffle;
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
      setPlaylist(playable);

      await super.open(
        playable.medias[playable.index],
        play: play,
      );
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
      this.play();

      return;
    }

    pause();
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

    final bool isLast = _playlist!.index == _playlist!.medias.length - 1;

    // Если это последний трек в плейлисте, то мы должны либо остановить воспроизведение, либо повторить его.
    if (isLast) {
      switch (loopMode) {
        case PlaylistMode.loop:
          setPlaylist(
            _playlist!.copyWith(
              index: 0,
            ),
          );

          super.open(
            currentMedia!,
          );

          break;
        case PlaylistMode.none:
          await super.stop();

          break;
        default:
      }

      return;
    }

    setPlaylist(
      _playlist!.copyWith(index: _playlist!.index + 1),
    );

    return super.open(
      currentMedia!,
    );
  }

  @override
  Future<void> previous() async {
    _logger.d("Called previous");

    if (_playlist == null || _playlist!.index - 1 < 0) return;

    // Если это самый первый трек в плейлисте, и у нас включён повтор плейлиста, то нужно начать воспроизведение с конца.
    if (loopMode == PlaylistMode.loop && _playlist!.index == 0) {
      setPlaylist(
        _playlist!.copyWith(index: _playlist!.medias.length - 1),
      );

      return super.open(
        currentMedia!,
      );
    }

    setPlaylist(
      _playlist!.copyWith(index: _playlist!.index - 1),
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

    setPlaylist(
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

    setPlaylist(
      _playlist!.copyWith(
        index: newPlaylist.medias.indexOf(
          currentMedia!,
        ),
        medias: newPlaylist.medias,
      ),
    );
  }

  @override
  Future<void> add(Media media) async {
    _logger.d("Called add($media)");

    if (_playlist == null) return;

    setPlaylist(
      _playlist!.copyWith(
        medias: [..._playlist!.medias, media],
      ),
    );

    if (shuffleEnabled && _unshuffledPlaylist != null) {
      _unshuffledPlaylist!.add(media);
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
      // Состояние буферизации.
      stream.buffering.listen(
        (bool isBuffering) {
          if (!isBuffering) return;

          _playerStateStream.add(AudioPlaybackState.buffering);
        },
      ),

      // Состояния проигрывания трека (пауза/воспроизведение).
      stream.playing.listen(
        (bool playing) {
          if (playing) _isLoaded = true;

          _playerStateStream.add(
            playing ? AudioPlaybackState.playing : AudioPlaybackState.paused,
          );
        },
      ),

      // Состояние завершённости трека.
      stream.completed.listen((bool isCompleted) async {
        if (!isCompleted) return;

        _playerStateStream.add(AudioPlaybackState.completed);

        if (loopMode == PlaylistMode.single) {
          await super.open(
            _playlist!.medias[_playlist!.index],
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
    // TODO: Сделать dispose() для этих Stream'ов.
    playerStateStream.listen((AudioPlaybackState state) => _updateState());
    stream.position.listen((Duration _) => _updateState());

    // Обработчик изменения текущего трека.
    indexChangeStream.listen((int index) {
      final Audio? audio = currentAudio;
      if (audio == null) return;

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
    });
  }

  @override
  Future<void> stop() async {
    super.stop();

    if (Platform.isWindows) {
      _smtc?.disableSmtc();
    }

    await _audioSession?.setActive(false);
  }

  /// Запускает воспроизведение указанного массива треков.
  ///
  /// При [maxPreloadTracks] > 0, приложение будет пытаться заранее загружать треки и помещать их в кэш.
  Future<void> openAudioList(
    List<Audio> audio, {
    int index = 0,
    bool readFromCache = true,
    int maxPreloadTracks = 5,
  }) async {
    // Добавляем все треки в очередь воспроизведения настоящего плеера.
    await open(
      Playlist(
        [
          for (Audio audio in audio)
            Media(audio.url, extras: {
              "audio": audio,
            }),
        ],
        index: index,
      ),
    );

    _sendTrackData(audio[0]);
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
              await player.pause();

              break;
          }
        } else {
          switch (event.type) {
            case AudioInterruptionType.duck:
              await player.setVolume(1.0);

              break;
            case AudioInterruptionType.pause:
            case AudioInterruptionType.unknown:
              await player.play();

              break;
          }
        }
      });
    }

    await _audioSession!.setActive(true);
  }

  /// Метод, отправляющий операционным системам информацию о том, что поменялся текущий трек.
  ///
  /// Данный метод должен вызываться при изменении трека.
  Future<void> _sendTrackData(Audio audio) async {
    // Если у пользователя Windows, то посылаем SMTC обновление.
    if (Platform.isWindows) {
      if (!_smtc!.enabled) _smtc!.enableSmtc();

      // TODO: Обновлять информацию о треке другим образом.
      _smtc!.updateMetadata(
        MusicMetadata(
          title: audio.title,
          albumArtist: audio.artist,
          album: audio.album?.title,
          thumbnail: audio.album?.thumb?.photo,
        ),
      );
    }
  }

  /// Посылает обновления состояния в уведомления Android и SMTC.
  void _updateState() async {
    // Если у пользователя Windows, то посылаем SMTC обновление.
    if (Platform.isWindows) {
      await _smtc!.setPlaybackStatus(
        state.playing ? PlaybackStatus.Playing : PlaybackStatus.Paused,
      );
    }

    // Обновляем состояние в уведомлении.
    audioPlayerHandler?.playbackState.add(
      PlaybackState(
        controls: [
          state.playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToPrevious,
          MediaControl.skipToNext,
          // TODO: Кнопки для лайка и shuffle.
          const MediaControl(
            androidIcon: "drawable/baseline_forward_30_24",
            label: "Shuffle",
            action: MediaAction.setShuffleMode,
          ),
          MediaControl.custom(
            androidIcon: "drawable/ic_baseline_favorite_24",
            label: "favorite",
            name: "favorite",
            extras: <String, dynamic>{"level": 1},
          ),
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekBackward,
          MediaAction.seekForward,
          MediaAction.skipToPrevious,
          MediaAction.skipToNext,
        },
        updatePosition: state.position,
        playing: state.playing,
        bufferedPosition: state.buffer,
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
