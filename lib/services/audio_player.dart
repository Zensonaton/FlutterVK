import "dart:async";
import "dart:io";

import "package:audio_service/audio_service.dart";
import "package:audio_session/audio_session.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:discord_rpc/discord_rpc.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:just_audio/just_audio.dart";
import "package:palette_generator/palette_generator.dart";
import "package:provider/provider.dart";
import "package:smtc_windows/smtc_windows.dart";

import "../consts.dart";
import "../main.dart";
import "../provider/user.dart";
import "../routes/home.dart";
import "../utils.dart";
import "cache_manager.dart";
import "logger.dart";

/// Класс для работы с аудиоплеером.
class VKMusicPlayer {
  /// [AppLogger] для этого класса.
  static AppLogger logger = getLogger("VKMusicPlayer");

  final AudioPlayer _player = AudioPlayer(
    handleInterruptions: false,
  );
  late final List<StreamSubscription> _subscriptions;

  ExtendedVKPlaylist? _playlist;
  ConcatenatingAudioSource? _queue;
  List<ExtendedVKAudio>? _audiosQueue;

  VKMusicPlayer() {
    _subscriptions = [
      // Слушаем события запуска воспроизведения.
      _player.playerStateStream.listen(
        (PlayerState state) async {
          if (_player.playerState.playing && !_loaded) {
            await startMusicSession();
            _loaded = true;

            _loadedStateController.add(_loaded);
          }

          await updateMusicSession();
        },
      ),

      // // Обработчик изменения текущего трека.
      sequenceStateStream.listen(
        (SequenceState? state) async {
          if (state == null || currentAudio == null) return;

          _fakeCurrentTrackIndex = null;

          await updateMusicSessionTrack();
          await updateMusicSession();
        },
      ),
    ];

    _initPlayer();
  }

  /// Объект [SMTCWindows] для управления воспроизведения музыкой при помощи глобальных клавиш на Windows.
  ///
  /// Данный объект инициализируется при вызове [_initPlayer], если приложение запущено на Windows.
  SMTCWindows? smtc;

  /// Сессия объекта [AudioSession], который позволяет указать операционным системам то, что воспроизводит данное приложение, а так же даёт возможность обрабатывать события "затыкания" приложения в случае, к примеру, звонка.
  ///
  /// Данный объект инициализируется при вызове [_initPlayer].
  AudioSession? audioSession;

  /// Список из значений [Audio.mediaKey], по которым была запущена задача по созданию цветовой схемы в методе [getColorSchemeAsync].
  final List<String> _colorSchemeItemsQueue = [];

  /// Кэш для объектов типа [ColorScheme] разных изображений по их [Audio.mediaKey].
  Map<String, (ColorScheme, ColorScheme)> imageColorSchemeCache = {};

  /// Флаг для [audioSession], устанавливаемый на значение true в случае, если плеер поставился на паузу из-за внешнего звонка или другой причины.
  bool _pausedExternally = false;

  /// Объект [DiscordRPC], который позволяет транслировать Rich Presence (надпись "сейчас слушает ...") в Discord.
  ///
  /// Инициализируется при вызове метода [_initPlayer]. Устанавливается лишь в случае, если [isDesktop] = true.
  DiscordRPC? discordRPC;

  bool _discordRPCEnabled = false;

  /// Указывает, что Discord Rich Presence включён.
  ///
  /// Для включения/отключения Discord RPC воспользуйтесь методом [setDiscordRPCEnabled];
  bool get discordRPCEnabled => _discordRPCEnabled;

  bool _loaded = false;

  /// Фейковый индекс трека, который играет в данный момент. Используется, что бы изменение трека после вызовов типа [next] или [previous] происходило мгновенно.
  int? _fakeCurrentTrackIndex;

  /// Указывает, что аудио плеер загружен (т.е., был запущен хоть раз), и его стоит показать в интерфейсе.
  ///
  /// Данное поле всегда true после запуска воспроизведения любого трека, и false после вызова [stop].
  bool get loaded => _loaded;

  final StreamController<bool> _loadedStateController =
      StreamController.broadcast();

  /// Stream, указывающий то, загружен ли плеер или нет. Указывает состояние поля [loaded].
  Stream<bool> get loadedStateStream =>
      _loadedStateController.stream.asBroadcastStream();

  /// Информация о том, играет ли что-то сейчас у плеера или нет.
  ///
  /// Учтите, что это поле может быть true даже в том случае, если идёт буферизация (см. [buffering]).
  ///
  /// Если Вы желаете узнать, запущен или остановлен ли плеер (т.е., состоянеи stopped), то тогда обратитесь к полю [loaded], которое всегда true после запуска воспроизведения любого трека, и false после вызова [stop].
  bool get playing => _player.playing;

  /// Stream, указывающий текущее состояние воспроизведения плеера.
  Stream<bool> get playingStream => _player.playingStream.asBroadcastStream();

  /// Информация о том, идёт ли буферизация (или какая-либо другая загрузка, из-за которой воспроизведение может быть приостановлено).
  bool get buffering => const [
        ProcessingState.buffering,
        ProcessingState.loading,
      ].contains(
        player.playerState.processingState,
      );

  /// Информация о том, насколько был загружен буфер трека.
  Duration get bufferedPosition => _player.bufferedPosition;

  /// Stream, возвращающий информацию о том, насколько был загружен буфер трека.
  Stream<Duration> get bufferedPositionStream =>
      _player.bufferedPositionStream.asBroadcastStream();

  /// Состояние громкости плеера. Возвращает процент, где 0.0 указывает выключенную громкость, а 1.0 - самая высокая громкость.
  double get volume => _player.volume;

  /// Stream, возвращающий события изменения громкости плеера.
  Stream<double> get volumeStream => _player.volumeStream.asBroadcastStream();

  /// Возвращает прогресс воспроизведения текущего трека в виде процента, где 0.0 указывает начало трека, а 1.0 - его конец.
  ///
  /// Возвращает null, если сейчас ничего не играет.
  ///
  /// Если Вам необходим Stream для отслеживания изменения данного поля, то воспользуйтесь [positionStream].
  double get progress => _player.duration != null &&
          _player.duration != Duration.zero &&
          !buffering
      ? clampDouble(
          _player.position.inMilliseconds / _player.duration!.inMilliseconds,
          0.0,
          1.0,
        )
      : 0.0;

  /// Возвращает текущую позицию трека.
  ///
  /// Для полной длительности трека воспользуйтесь полем [duration]. Если Вам необходим процент (число от 0.0 до 1.0), отображающий прогресс прослушивания текущего трека, то для этого есть поле [progress].
  Duration get position => _player.position;

  /// Stream, возвращающий события о изменения текущей позиции воспроизведения.
  ///
  /// Если Вам необходим процент (число от 0.0 до 1.0), отображающий прогресс прослушивания текущего трека, то для этого есть поле [progress].
  Stream<Duration> get positionStream =>
      _player.positionStream.asBroadcastStream();

  /// Возвращает длительность трека.
  ///
  /// Для полной позиции трека воспользуйтесь полем [position]. Если Вам необходим процент (число от 0.0 до 1.0), отображающий прогресс прослушивания текущего трека, то для этого есть поле [progress].
  Duration? get duration => _player.duration;

  /// Stream, возвращающий события о изменения длительности данного трека.
  ///
  /// Если Вам необходим процент (число от 0.0 до 1.0), отображающий прогресс прослушивания текущего трека, то для этого есть поле [progress].
  Stream<Duration?> get durationStream =>
      _player.durationStream.asBroadcastStream();

  /// Возвращает текущее состояние плеера.
  PlayerState get playerState => _player.playerState;

  /// Stream, возвращающий события о изменении состояния плеера.
  Stream<PlayerState> get playerStateStream =>
      _player.playerStateStream.asBroadcastStream();

  /// Возвращет информацию о состоянии плейлиста.
  SequenceState? get sequenceState => _player.sequenceState;

  /// Stream, возвращающий события о изменении текущего плеера.
  Stream<SequenceState?> get sequenceStateStream =>
      _player.sequenceStateStream.asBroadcastStream();

  /// Возвращет информацию о состоянии shuffle.
  bool get shuffleModeEnabled => _player.shuffleModeEnabled;

  /// Stream, возвращающий события о изменении состояния shuffle.
  Stream<bool> get shuffleModeEnabledStream =>
      _player.shuffleModeEnabledStream.asBroadcastStream();

  /// Возвращет информацию о состоянии повтора плейлиста.
  LoopMode get loopMode => _player.loopMode;

  /// Stream, возвращающий события о изменении состояния повтора плейлиста.
  Stream<LoopMode> get loopModeStream =>
      _player.loopModeStream.asBroadcastStream();

  /// Указывает индекс предыдущего трека в очереди. Если очередь пуста, либо это самый первый трек в очереди, то возвращает null.
  ///
  /// Для получения объекта типа [Audio] можно воспользоваться getter'ом [previousAudio].
  int? get previousTrackIndex => _player.previousIndex;

  /// Указывает индекс текущего трека в очереди. Если очередь пуста, либо сейчас ничего не играет, то возвращает null.
  ///
  /// Для получения объекта типа [Audio] можно воспользоваться getter'ом [currentAudio].
  int? get trackIndex => _player.currentIndex;

  /// Указывает индекс следующего трека в очереди. Если очередь пуста, либо это самый последний трек в очереди, то возвращает null.
  ///
  /// Для получения объекта типа [Audio] можно воспользоваться getter'ом [nextAudio].
  int? get nextTrackIndex => _player.nextIndex;

  /// Указывает индекс предыдущего трека в очереди.
  ///
  /// В отличии от [previousTrackIndex], данный метод возвращает трек в зависимости от значений [LoopMode]: если включён повтор плейлиста ([LoopMode.all]), то данный метод будет возвращать последний трек из очереди, если текущий трек самый первый.
  ///
  /// Для получения объекта типа [Audio] можно воспользоваться getter'ом [smartPreviousAudio].
  int? get smartPreviousTrackIndex {
    if (loopMode == LoopMode.one) {
      return smartTrackIndex;
    }

    return previousTrackIndex ?? (_audiosQueue ?? []).length - 1;
  }

  /// Указывает индекс текущего трека в очереди.
  ///
  /// Для получения объекта типа [Audio] можно воспользоваться getter'ом [smartCurrentAudio].
  int? get smartTrackIndex {
    return _fakeCurrentTrackIndex ?? trackIndex;
  }

  /// Указывает индекс следующего трека в очереди.
  ///
  /// В отличии от [nextTrackIndex], данный метод возвращает трек в зависимости от значений [LoopMode]: если включён повтор плейлиста ([LoopMode.all]), то данный метод будет возвращать последний трек из очереди, если текущий трек самый первый.
  ///
  /// Для получения объекта типа [Audio] можно воспользоваться getter'ом [smartNextAudio].
  int? get smartNextTrackIndex {
    if (loopMode == LoopMode.one) {
      return smartTrackIndex;
    }

    return nextTrackIndex ?? 0;
  }

  /// Возвращает объект [ExtendedVKAudio] для трека, который находится предыдущим в очереди. Если очередь пуста, либо это самый первый трек в очереди, то возвращает null.
  ///
  /// Для получения индекса этого трека можно воспользоваться getter'ом [previousTrackIndex].
  ExtendedVKAudio? get previousAudio {
    if (previousTrackIndex == null) return null;

    return _audiosQueue?[previousTrackIndex!];
  }

  /// Возвращает объект [ExtendedVKAudio] для трека, который играет в данный момент. Если очередь пуста, то возвращает null.
  ///
  /// Для получения индекса этого трека можно воспользоваться getter'ом [trackIndex].
  ExtendedVKAudio? get currentAudio {
    if (trackIndex == null) return null;

    return _audiosQueue?[trackIndex!];
  }

  /// Возвращает объект [ExtendedVKAudio] для трека, который находится предыдущим в очереди. Если очередь пуста, либо это последний трек в очереди, то возвращает null.
  ///
  /// Для получения индекса этого трека можно воспользоваться getter'ом [nextTrackIndex].
  ExtendedVKAudio? get nextAudio {
    if (nextTrackIndex == null) return null;

    return _audiosQueue?[nextTrackIndex!];
  }

  /// Возвращает объект [ExtendedVKAudio] для трека, который находится предыдущим в очереди. Если очередь пуста, либо это самый первый трек в очереди, то возвращает null.
  ///
  /// Для получения индекса этого трека можно воспользоваться getter'ом [smartPreviousTrackIndex].
  ExtendedVKAudio? get smartPreviousAudio {
    if (smartPreviousTrackIndex == null) return null;

    return _audiosQueue?[smartPreviousTrackIndex!];
  }

  /// Возвращает объект [ExtendedVKAudio] для трека, который играет в данный момент. Если очередь пуста, то возвращает null.
  ///
  /// Для получения индекса этого трека можно воспользоваться getter'ом [smartTrackIndex].
  ExtendedVKAudio? get smartCurrentAudio {
    if (smartTrackIndex == null) return null;

    return _audiosQueue?[smartTrackIndex!];
  }

  /// Возвращает объект [ExtendedVKAudio] для трека, который находится предыдущим в очереди. Если очередь пуста, либо это последний трек в очереди, то возвращает null.
  ///
  /// Для получения индекса этого трека можно воспользоваться getter'ом [smartNextTrackIndex].
  ExtendedVKAudio? get smartNextAudio {
    if (smartNextTrackIndex == null) return null;

    return _audiosQueue?[smartNextTrackIndex!];
  }

  /// Возвращает текущий плейлист.
  ///
  /// Учтите, что список треков в этом плейлисте не меняется в зависимости от shuffle или вызова метода [addNextToQueue].
  ExtendedVKPlaylist? get currentPlaylist => _playlist;

  /// Инициализирует некоторые компоненты данного плеера.
  ///
  /// Данный метод должен быть вызван лишь один раз, при инициализации плеера.
  Future<void> _initPlayer() async {
    // Устанавливаем значение для LoopMode по-умолчанию.
    await setLoop(LoopMode.all);

    // Слушаем события от SMTC, если приложение запущено на Windows.
    if (Platform.isWindows) {
      smtc = SMTCWindows(
        config: const SMTCConfig(
          fastForwardEnabled: true,
          nextEnabled: true,
          pauseEnabled: true,
          playEnabled: true,
          rewindEnabled: true,
          prevEnabled: true,
          stopEnabled: true,
        ),
        enabled: false,
      );

      try {
        smtc!.buttonPressStream.listen((PressedButton event) async {
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

    // Инициализируем объект AudioSession, что бы ставить плеер на паузу в случае звонка или другого события.
    if (audioSession == null) {
      audioSession = await AudioSession.instance;

      await audioSession!.configure(
        const AudioSessionConfiguration.music(),
      );

      // События отключения наушников.
      audioSession?.becomingNoisyEventStream.listen((_) {
        player.pause();
      });

      // Другие события системы.
      //
      // К примеру, здесь обрабатываются события звонка на телефон (громкость понижается на 50%), а так же события запуска других аудио-приложений.
      audioSession?.interruptionEventStream.listen((
        AudioInterruptionEvent event,
      ) async {
        if (event.begin) {
          switch (event.type) {
            case AudioInterruptionType.duck:
              await player.setVolume(0.5);

              break;
            case AudioInterruptionType.pause:
            case AudioInterruptionType.unknown:
              if (!playing) return;

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
              _pausedExternally = false;

              break;
          }
        }
      });
    }

    // Инициализируем Discord Rich Presence на Desktop-системах.
    if (isDesktop) {
      DiscordRPC.initialize();

      discordRPC = DiscordRPC(
        applicationId: discordAppID.toString(),
      );
      discordRPC!.start(
        autoRegister: true,
      );
      discordRPC!.clearPresence();
    }
  }

  /// Возобновляет воспроизведение музыки у плеера, ранее остановленной при помощи метода [pause].
  ///
  /// Если Вы хотите поставить музыку на паузу или начать воспроизведение в зависимости от значения переменной, то воспользуйтесь методом [playOrPause], который работает следующим образом:
  /// ```dart
  /// if (play) {
  ///   player.play();
  /// } else {
  ///   player.pause();
  /// }
  /// ```
  Future<void> play() async {
    // Если ничего не загружено, то мы не должны запускать воспроизведение.
    if (_queue == null) {
      return;
    }

    return await _player.play();
  }

  /// Приостанавливает воспроизведение музыки, которая ранее была запущена при помощи методов по типу [play].
  ///
  /// Если Вы хотите поставить музыку на паузу или начать воспроизведение в зависимости от значения переменной, то воспользуйтесь методом [playOrPause], который работает следующим образом:
  /// ```dart
  /// if (play) {
  ///   player.play();
  /// } else {
  ///   player.pause();
  /// }
  /// ```
  Future<void> pause() async {
    return await _player.pause();
  }

  /// Вызывает метод [play] или [pause], в зависимости от передаваемого аргумента [playing], указывающий, будет ли плеер играть.
  ///
  /// Данный метод работает следующим образом:
  /// ```dart
  /// if (play) {
  ///   player.play();
  /// } else {
  ///   player.pause();
  /// }
  /// ```
  Future<void> playOrPause(bool playing) async {
    if (playing) {
      return await play();
    }

    return await pause();
  }

  /// Переключает паузу у плеера.
  ///
  /// Данный метод рекомендуется вызывать только в тех случаях, где текущее состояние плеера может быть неизвестным, к примеру, в интерфейсе, где не вызывался метод [setState], или в уведомлениях, которые могут не обновить своё состояние "проигрывания" из-за какой-то ошибки.
  Future<void> togglePlay() async {
    return await playOrPause(!playing);
  }

  /// "Перепрыгивает" на указанный момент в треке.
  ///
  /// Если [play] = true, то при перемотке плеер будет автоматически запущен, если он до этого был приостановлен.
  Future<void> seek(
    Duration position, {
    bool play = false,
  }) async {
    await _player.seek(position);

    if (play && !playing) await _player.play();
  }

  /// "Перепрыгивает" на указанный момент в треке по значению от 0.0 до 1.0.
  ///
  /// Если Вы желаете перепрыгнуть на момент в треке по его времени то воспользуйтесь методом [seek].
  ///
  /// Если [play] = true, то при перемотке плеер будет автоматически запущен, если он до этого был приостановлен.
  Future<void> seekNormalized(
    double position, {
    bool play = false,
  }) async {
    assert(
      volume >= 0.0 && volume <= 1.0,
      "seekNormalized position $position is not in range from 0.0 to 1.0",
    );

    return await seek(
      Duration(
        milliseconds: (duration!.inMilliseconds * position).toInt(),
      ),
      play: play,
    );
  }

  /// Переключает на трек с указанным индексом.
  Future<void> jump(
    int index,
  ) async {
    _fakeCurrentTrackIndex = index;

    return await _player.seek(
      null,
      index: index,
    );
  }

  /// Указывает громкость плеера. Передаваемое значение громкости [volume] обязано быть в пределах от 0.0 до 1.0.
  Future<void> setVolume(double volume) async {
    assert(
      volume >= 0.0 && volume <= 1.0,
      "setVolume given volume $volume is not in range from 0.0 to 1.0",
    );

    return await _player.setVolume(volume);
  }

  /// Останавливает плеер, освобождая ресурсы.
  ///
  /// Данный метод стоит вызывать только в случае, когда пользователь остановил воспроизведение, к примеру, убив приложение или свернув уведомление. Для паузы стоит воспользоваться методом [pause].
  Future<void> stop() async {
    await _player.pause();
    await _player.stop();
    await updateMusicSession();
    await stopMusicSession();

    _playlist = null;
    _queue = null;
    _audiosQueue = null;
    _loaded = false;

    _loadedStateController.add(_loaded);
  }

  /// Полностью освобождает ресурсы, занятые данным плеером.
  Future<void> dispose() async {
    await stop();

    for (StreamSubscription subscription in _subscriptions) {
      subscription.cancel();
    }

    return await _player.dispose();
  }

  /// Заставляет плеер "перепрыгнуть" ([seek]) на самое начало воспроизведение текущего трека.
  Future<void> seekToBeginning() async {
    return await seek(Duration.zero);
  }

  /// Запускает воспроизведение следующего трека. Если это последний трек в плейлисте, то ничего не делает.
  Future<void> next() async {
    await jump(nextTrackIndex!);

    if (!playing) await play();
  }

  /// Запускает воспроизведение предыдущего трека в очереди. Если это первый трек в плейлисте, то ничего не делает.
  ///
  /// Если [allowSeekToBeginning] указан как true, то плеер, в случае, если прошло не более 5 секунд воспроизведения, запустит воспроизведение с самого начала трека, вместо перехода на предыдущий.
  Future<void> previous({
    bool allowSeekToBeginning = false,
  }) async {
    if (allowSeekToBeginning && _player.position.inSeconds >= 5) {
      await seekToBeginning();
    } else {
      await jump(previousTrackIndex!);
    }

    if (!playing) await play();
  }

  /// Включает или отключает случайное перемешивание треков в данном плейлисте, в зависимости от аргумента [shuffle].
  Future<void> setShuffle(bool shuffle) async {
    return await _player.setShuffleModeEnabled(shuffle);
  }

  /// Переключает состояние shuffle.
  Future<void> toggleShuffle() async {
    return await setShuffle(!shuffleModeEnabled);
  }

  /// Меняет режим повтора текущего плейлиста/трека.
  Future<void> setLoop(LoopMode loopMode) async {
    return await _player.setLoopMode(loopMode);
  }

  /// Устанавливает плейлист [playlist] для воспроизведения музыки, указывая при этом [index], начиная с которого будет запущено воспроизведение. Если [play] равен true, то при вызове данного метода плеер автоматически начнёт воспроизводить музыку.
  Future<void> setPlaylist(
    ExtendedVKPlaylist playlist, {
    bool play = true,
    ExtendedVKAudio? audio,
  }) async {
    assert(
      playlist.audios != null,
      "audios of ExtendedVKPlaylist is null",
    );

    // Создаём список из треков в плейлисте, которые можно воспроизвести.
    final List<ExtendedVKAudio> audios = playlist.audios!
        .where(
          (audio) => !audio.isRestricted,
        )
        .toList();

    // Обработка запуска пустого плейлиста.
    if (audios.isEmpty) return;

    _playlist = playlist;
    _audiosQueue = [...audios];
    _queue = ConcatenatingAudioSource(
      children: audios
          .map(
            (audio) => AudioSource.uri(
              Uri.parse(audio.url),
              tag: audio.asMediaItem,
            ),
          )
          .toList(),
    );

    await _player.setAudioSource(
      _queue!,
      initialIndex: audios.contains(audio) ? audios.indexOf(audio!) : 0,
    );

    if (play) {
      await this.play();
    }
  }

  /// Добавляет указанный трек как следующий для воспроизведения.
  Future<void> addNextToQueue(
    ExtendedVKAudio audio,
  ) async {
    // На случай, если очередь пустая.
    _queue ??= ConcatenatingAudioSource(
      children: [],
    );
    _audiosQueue ??= [];

    _queue!.insert(
      nextTrackIndex ?? 0,
      AudioSource.uri(
        Uri.parse(audio.url),
        tag: audio.asMediaItem,
      ),
    );
    _audiosQueue!.insert(
      nextTrackIndex ?? 0,
      audio,
    );
  }

  /// Включает или отключает Discord Rich Presence.
  Future<void> setDiscordRPCEnabled(bool enabled) async {
    logger.d("Called setDiscordRPCEnabled($enabled)");

    if (enabled) {
      assert(
        isDesktop,
        "Discord RPC can only be enabled on Desktop-platforms.",
      );
    }

    if (enabled == _discordRPCEnabled) return;
    _discordRPCEnabled = enabled;

    if (enabled) {
      await updateMusicSession();
    } else {
      discordRPC?.clearPresence();
    }
  }

  /// Запускает музыкальную сессию. При вызове данного метода, плеер активирует различные системы, по типу SMTC для Windows, Discord Rich Presence и прочие.
  ///
  /// Данный метод нужно вызвать после первого запуска плеера. После завершения музыкальной сессии, рекомендуется вызвать метод [stopMusicSession].
  Future<void> startMusicSession() async {
    logger.d("Called startMusicSession");

    // Указываем, что в данный момент идёт сессия музыки.
    await audioSession!.setActive(true);

    if (Platform.isWindows) {
      await smtc?.enableSmtc();
    }

    if (_loaded) return;
  }

  /// Метод, обновляющий данные о музыкальной сессии, отправляя новые данные по текущему треку после вызова метода [startMusicSession].
  ///
  /// Данный метод стоит вызывать после изменения текущего трека.
  Future<void> updateMusicSessionTrack() async {
    logger.d("Called updateMusicSessionTrack");

    if (currentAudio == null) return;

    // Если у пользователя Windows, то посылаем SMTC обновление.
    if (Platform.isWindows) {
      if (!smtc!.enabled) await smtc!.enableSmtc();

      await smtc?.updateMetadata(
        MusicMetadata(
          title: currentAudio!.title,
          artist: currentAudio!.artist,
          albumArtist: currentAudio!.artist,
          album: currentAudio!.album?.title,
          thumbnail: currentAudio!.album?.thumb?.photo,
        ),
      );
    }
  }

  /// Метод, обновляющий данные о музыкальной сессии после вызова метода [startMusicSession].
  ///
  /// Данный метод рекомендуется вызывать только при событиях изменения состояния плеера, например, начало буферизации, паузы/воспроизведения и/ли подобных.
  Future<void> updateMusicSession() async {
    logger.d("Called updateMusicSession");

    // Указываем, есть ли у нас в данный момент сессия музыки.
    await audioSession?.setActive(playing);

    // Если у пользователя Windows, то обновляем параметры SMTC.
    if (Platform.isWindows) {
      PlaybackStatus status = PlaybackStatus.Stopped;

      if (buffering) {
        status = PlaybackStatus.Changing;
      } else if (!loaded) {
        status = PlaybackStatus.Stopped;
      } else if (playing) {
        status = PlaybackStatus.Playing;
      } else if (!playing) {
        status = PlaybackStatus.Paused;
      }

      await smtc?.setPlaybackStatus(status);
    }

    // Обновляем Discord RPC, если это разрешено пользователем.
    if (discordRPCEnabled && currentAudio != null) {
      discordRPC?.updatePresence(
        DiscordPresence(
          state: currentAudio!.title,
          details: currentAudio!.artist,
          largeImageKey: "flutter-vk-logo",
          largeImageText: "Flutter VK",
          smallImageKey: playing ? "playing" : "paused",
          smallImageText: playing
              ? "${currentAudio!.artist} • ${currentAudio!.title}"
              : null,
          startTimeStamp: playing
              ? (DateTime.now().millisecondsSinceEpoch ~/ 1000) -
                  position.inSeconds
              : null,
        ),
      );
    }
  }

  /// Останавливает текущую музыкальную сессию, ранее начатую вызовом метода [startMusicSession].
  ///
  /// Данный метод стоит вызывать только после остановки музыкальной сессии, т.е., после вызова метода [stop].
  Future<void> stopMusicSession() async {
    logger.d("Called stopMusicSession");

    if (!loaded) return;

    if (Platform.isWindows) {
      await smtc?.disableSmtc();
    }

    await audioSession?.setActive(false);
    if (discordRPCEnabled) {
      discordRPC?.clearPresence();
    }
  }

  /// Создаёт две цветовых схемы из цветов плеера: [Brightness.light] и [Brightness.dark].
  ///
  /// Данный метод при повторном вызове (если уже идёт процесс создания цветовой схемы) возвращает null. Результаты данного метода кэшируются, поэтому можно повторно вызывать этот метод, если [Audio.mediaKey] одинаков.
  Future<(ColorScheme, ColorScheme)?> getColorSchemeAsync() async {
    final AppLogger logger = getLogger("getColorSchemeAsync");
    final Stopwatch watch = Stopwatch()..start();

    // Если у изображения трека нету фотографии, либо задача уже запущена, то возвращаем null.
    if (player.currentAudio?.album?.thumb == null ||
        _colorSchemeItemsQueue.contains(
          player.currentAudio!.mediaKey,
        )) return null;

    final String cacheKey = "${player.currentAudio!.mediaKey}68";

    // Задача по созданию цветовой схемы не находится в очереди, поэтому помещаем задачу в очередь.
    _colorSchemeItemsQueue.add(cacheKey);

    // Пытаемся извлечь значение цветовых схем из кэша.
    if (imageColorSchemeCache.containsKey(cacheKey)) {
      return imageColorSchemeCache[cacheKey];
    }

    logger.d("Creating ColorScheme for $cacheKey");

    // Извлекаем цвета из изображения, делая объект PaletteGenerator.
    final PaletteGenerator palette = await PaletteGenerator.fromImageProvider(
      CachedNetworkImageProvider(
        player.currentAudio!.album!.thumb!.photo68!,
        cacheKey: cacheKey,
        cacheManager: CachedNetworkImagesManager.instance,
      ),
    );

    // Превращаем наш PaletteGenerator в цветовые схемы.
    final ColorScheme lightScheme = palette.dominantColor != null
        ? ColorScheme.fromSeed(
            seedColor: palette.dominantColor!.color,
          )
        : fallbackLightColorScheme;
    final ColorScheme darkScheme = palette.dominantColor != null
        ? ColorScheme.fromSeed(
            seedColor: palette.dominantColor!.color,
            brightness: Brightness.dark,
          )
        : fallbackDarkColorScheme;

    imageColorSchemeCache[cacheKey] = (lightScheme, darkScheme);

    logger.d(
      "Done building ColorScheme for $cacheKey, took ${watch.elapsed}",
    );

    // Удаляем из очереди.
    _colorSchemeItemsQueue.remove(cacheKey);

    return imageColorSchemeCache[cacheKey];
  }
}

/// enum, перечисляющий действия в уведомлениях над треком.
enum MediaNotificationAction {
  /// Переключение состояния shuffle.
  shuffle,

  /// Переключение состояния "нравится" у трека.
  favorite,
}

/// Расширение для класса [BaseAudioHandler], методы которого вызываются при взаимодействии с медиа-уведомлением.
class AudioPlayerService extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final VKMusicPlayer _player;

  AudioPlayerService(
    this._player,
  ) {
    // События паузы/воспроизведения/...
    _player.playerStateStream.listen((PlayerState state) async {
      if (!player.playing) return;

      await _updateEvent();
    });

    // События изменения позиции плеера.
    _player.positionStream.listen((Duration position) async {
      await _updateEvent();
    });

    // События изменения плейлиста.
    _player.sequenceStateStream.listen((SequenceState? state) async {
      if (state == null) return;

      await _updateTrack();
    });

    // События остановки/первого запуска (загрузки) плеера.
    _player.loadedStateStream.listen((bool loaded) async {
      await _updateEvent();
    });

    // События изменения состояния shuffle.
    _player.shuffleModeEnabledStream.listen((bool enabled) async {
      await _updateEvent();
    });
  }

  /// Отправляет изменения состояния воспроизведения в `audio_service`, обновляя информацию, отображаемую в уведомлении.
  Future<void> _updateEvent() async {
    if (!_player.loaded) {
      if (playbackState.hasValue) await super.stop();

      return;
    }

    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          _player.playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.custom(
            androidIcon: _player.shuffleModeEnabled
                ? "drawable/ic_shuffle_enabled"
                : "drawable/ic_shuffle",
            label: "Shuffle",
            name: MediaNotificationAction.shuffle.name,
          ),
          MediaControl.custom(
            androidIcon: _player.currentAudio!.isLiked
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
        playing: _player.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        shuffleMode: player.shuffleModeEnabled == true
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
        repeatMode: _player.loopMode == LoopMode.one
            ? AudioServiceRepeatMode.one
            : AudioServiceRepeatMode.none,
        processingState: _player.buffering
            ? AudioProcessingState.loading
            : AudioProcessingState.ready,
      ),
    );
  }

  /// Отправляет новый трек в уведомление.
  Future<void> _updateTrack() async {
    mediaItem.add(_player.currentAudio?.asMediaItem);
  }

  @override
  Future<void> customAction(
    String name, [
    Map<String, dynamic>? extras,
  ]) async {
    final UserProvider user = Provider.of<UserProvider>(
      buildContext!,
      listen: false,
    );

    final MediaNotificationAction action =
        MediaNotificationAction.values.firstWhere(
      (action) => action.name == name,
    );

    switch (action) {
      case (MediaNotificationAction.shuffle):
        await _player.toggleShuffle();

        user.settings.shuffleEnabled = _player.shuffleModeEnabled;
        user.markUpdated(false);

        break;

      case (MediaNotificationAction.favorite):
        await toggleTrackLike(
          user,
          _player.currentAudio!,
          !_player.currentAudio!.isLiked,
        );

        await _updateEvent();
        user.markUpdated(false);

        break;
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> onTaskRemoved() => _player.stop();

  @override
  Future<void> onNotificationDeleted() => _player.stop();

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    await super.setShuffleMode(shuffleMode);

    await _player.setShuffle(
      shuffleMode == AudioServiceShuffleMode.all,
    );
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    await super.setRepeatMode(repeatMode);

    await _player.setLoop(
      repeatMode == AudioServiceRepeatMode.one ? LoopMode.one : LoopMode.all,
    );
  }

  @override
  Future<void> skipToNext() async {
    await _player.next();

    await super.skipToNext();
  }

  @override
  Future<void> skipToPrevious() async {
    await _player.previous(
      allowSeekToBeginning: true,
    );

    await super.skipToPrevious();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);
}
