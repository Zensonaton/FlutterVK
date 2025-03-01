import "dart:async";

import "package:hooks_riverpod/hooks_riverpod.dart";

import "../../enums.dart";
import "../../provider/preferences.dart";
import "../../provider/user.dart";
import "../../utils.dart";
import "../logger.dart";
import "backend.dart";
import "backends/media_kit.dart";
import "server.dart";
import "subscriber.dart";
import "subscribers/audio_mix.dart";
import "subscribers/audio_service.dart";
import "subscribers/audio_session.dart";
import "subscribers/debug_logging.dart";
import "subscribers/discord_rpc.dart"
    if (dart.library.js_interop) "subscribers/discord_rpc_stub.dart";
import "subscribers/errors_handler.dart";
import "subscribers/pause_on_mute.dart";
import "subscribers/persistent_state.dart";
import "subscribers/playlist_modifications.dart";
import "subscribers/recomms_notifier.dart";
import "subscribers/smtc.dart"
    if (dart.library.js_interop) "subscribers/smtc_stub.dart";
import "subscribers/stop_on_long_pause.dart";
import "subscribers/track_info.dart";
import "subscribers/window_bar_title.dart";
import "subscribers/windows_taskbar.dart";

/// Уровень лога плеера.
enum PlayerLogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
}

/// Класс, репрезентирующий отдельный лог плеера.
class PlayerLog {
  /// Уровень лога.
  final PlayerLogLevel level;

  /// Текст сообщения.
  final String text;

  /// Источник этого лога.
  final String? sender;

  const PlayerLog({
    required this.level,
    required this.text,
    this.sender,
  });

  @override
  String toString() => "PlayerLog($level: $text)";
}

/// Класс, предоставляющий доступ к музыкальному плееру, воспроизводящий музыку.
///
/// Внутри данного плеера есть несколько [PlayerBackend]'ов, руководящих воспроизведением.
class Player {
  static final AppLogger logger = getLogger("Player");

  /// Длительность, после которой метод [Player.previous] даже при указанном аргументе [allowPrevious] не будет переметывать в начало трека:
  /// ```dart
  /// if (position < rewindThreshold) {
  ///   await jump(index! - 1);
  /// } else {
  ///   seek(Duration.zero)
  /// }
  /// ```
  static const Duration rewindThreshold = Duration(seconds: 5);

  final Ref ref;

  Player(this.ref);

  PlayerBackend? _activeBackend;
  final List<PlayerBackend> _registeredBackends = [];
  final List<StreamSubscription> _backendSubscriptions = [];
  final List<StreamSubscription> _eventSubscriptions = [];
  PlayerLocalServer? _localServer;
  bool _isLoaded = false;
  bool _discordRPCEnabled = false;
  bool _pauseOnMuteEnabled = false;
  bool _stopOnLongPauseEnabled = false;
  RewindBehavior _rewindBehavior = RewindBehavior.always;
  bool _keepPlayingOnCloseEnabled = false;
  bool _isDebugLoggingEnabled = false;
  bool _trackTitleInWindowBarEnabled = false;

  /// Инициализирует данный [Player].
  ///
  /// Данный метод делает две вещи:
  /// 1. Подписывается на события всех [PlayerSubscriber]'ов.
  /// 2. Вызывает [registerBackend] для всех доступных backend'ов.
  Future<void> initialize() async {
    final stopWatch = Stopwatch()..start();

    final List<PlayerSubscriber> subscribers = [
      // Базовые subscriber'ы, независимые от платформы.
      PersistentStatePlayerSubscriber(this),
      StopOnLongPausePlayerSubscriber(this),
      TrackInfoPlayerSubscriber(this),
      AudioMixPlayerSubscriber(this),
      RecommendationsNotifierPlayerSubscriber(this),
      DebugLoggerPlayerSubscriber(this),
      ErrorsHandlerPlayerSubscriber(this),
      PlaylistModificationsPlayerSubscriber(this),

      // Window Bar Title (Desktop).
      if (isDesktop) WindowBarTitlePlayerSubscriber(this),

      // SMTC (Windows).
      if (isWindows) SMTCPlayerSubscriber(this),

      // Taskbar (Windows).
      if (isWindows) WindowsTaskbarPlayerSubscriber(this),

      // Discord RPC (Windows, Linux).
      if (isWindows || isLinux) DiscordRPCPlayerSubscriber(this),

      // Audio service (Web, Android, iOS, macOS).
      if (isWeb || isAndroid || isiOS || isMacOS)
        AudioServicePlayerSubscriber(this),

      // Audio session (Android).
      if (isAndroid) AudioSessionPlayerSubscriber(this),

      // Pause on mute (Desktop).
      if (isDesktop) PauseOnMutePlayerSubscriber(this),
    ];
    final List<PlayerBackend> backends = [
      MediaKitPlayerBackend(),
    ];
    logger.d(
      "Initializing with ${backends.length} backends [${backends.map((e) => e.name).join(", ")}] and ${subscribers.length} subscribers [${subscribers.map((e) => e.name).join(", ")}]",
    );

    // Подключаем всех подписчиков.
    for (final subscriber in subscribers) {
      await subscriber.initialize();

      _eventSubscriptions.addAll(subscriber.subscribe(this));
    }

    // Регистрируем все доступные backend'ы.
    for (final backend in backends) {
      await registerBackend(backend);
    }

    logger.d(
      "Player initialized in ${stopWatch.elapsedMilliseconds}ms with ${_eventSubscriptions.length} player listeners",
    );
  }

  /// Возвращает список всех зарегистрированных backend'ов.
  List<PlayerBackend> get registeredBackends => _registeredBackends;

  /// Регистрирует новый backend.
  ///
  /// После регистрации, вызывается метод [PlayerBackend.initialize].
  Future<void> registerBackend(PlayerBackend backend) async {
    logger.d("Registering backend '${backend.name}'...");

    // Если backend требует наличие HTTP-сервера, то запускаем его.
    if (backend.localServerRequired && _localServer == null) {
      logger.d("Starting local HTTP server for ${backend.name} backend");

      _localServer = PlayerLocalServer(ref: ref);
      await _localServer!.start();
    }

    // Инициализируем backend.
    await backend.initialize(server: _localServer);

    _registeredBackends.add(backend);
    _setActiveBackend(backend);
  }

  /// Метод, вызываемый внутри [registerBackend], который регистрирует указанный [PlayerBackend] как активный backend, и к которому подключаются различные подписки.
  void _setActiveBackend(PlayerBackend backend) {
    _activeBackend = backend;

    // Отписываемся от старых подписок.
    for (final subcription in _backendSubscriptions) {
      subcription.cancel();
    }
    _backendSubscriptions.clear();

    // Добавляем базовые подписки.
    _backendSubscriptions.addAll(
      [
        backend.isLoadedStream.listen((isLoaded) {
          if (_isLoaded == isLoaded) return;

          logger.d("Backend '${backend.name}' is loaded: $isLoaded");

          _isLoaded = isLoaded;
          _isLoadedController.add(isLoaded);
        }),
        backend.isPlayingStream.listen(_isPlayingController.add),
        backend.audioStream.listen(_audioController.add),
        backend.positionStream.listen(_positionController.add),
        backend.seekStream.listen(_seekController.add),
        backend.volumeStream.listen(_volumeController.add),
        backend.isBufferingStream.listen(_isBufferingController.add),
        backend.bufferedPositionStream.listen(_bufferedPositionController.add),
        backend.playlistStream.listen(_playlistController.add),
        backend.queueStream.listen(_queueController.add),
        backend.isShufflingStream.listen(_isShufflingController.add),
        backend.isRepeatingStream.listen(_isRepeatingController.add),
        backend.logStream.listen(_logController.add),
        backend.errorStream.listen(_errorController.add),
        backend.volumeNormalizationStream
            .listen(_volumeNormalizationController.add),
        backend.silenceRemovalEnabledStream
            .listen(_silenceRemovalEnabledController.add),
      ],
    );
  }

  /// Возвращает активный backend, который воспроизводит музыку.
  PlayerBackend get backend {
    assert(
      _activeBackend != null,
      "No active backend is set. Loaded backends: ${_registeredBackends.map((e) => e.name).join(", ")}",
    );

    return _activeBackend!;
  }

  /// Возвращает true, если плеер был запущен хоть раз (т.е., после вызова [Player.setPlaylist], и до [Player.stop]), и его нужно показывать в интерфейсе приложения.
  bool get isLoaded => _isLoaded;

  final StreamController<bool> _isLoadedController =
      StreamController.broadcast();

  /// {@template Player.isLoadedStream}
  /// Stream, указывающий то, загружен ли плеер или нет. Указывает состояние поля [isLoaded].
  /// {@endtemplate}
  Stream<bool> get isLoadedStream {
    return _isLoadedController.stream.asBroadcastStream();
  }

  final StreamController<bool> _isPlayingController =
      StreamController.broadcast();

  /// {@template Player.isPlayingStream}
  /// Stream, указывающий то, играет ли плеер музыку в данный момент. Возвращает значение поля [isPlaying].
  /// {@endtemplate}
  Stream<bool> get isPlayingStream {
    return _isPlayingController.stream.asBroadcastStream();
  }

  final StreamController<ExtendedAudio> _audioController =
      StreamController.broadcast();

  /// {@template Player.audioStream}
  /// Stream, указывающий то, какой [ExtendedAudio] играет в данный момент. Возвращает значение поля [audio].
  ///
  /// Учтите, что данный Stream возвращает лишь событие запуска воспроизведения нового трека. Если вам нужен Stream, возвращающий события по модификациям текущего трека, то вместо этого воспользуйтесь [playlistStream] либо [queueStream].
  /// {@endtemplate}
  Stream<ExtendedAudio> get audioStream {
    return _audioController.stream.asBroadcastStream();
  }

  final StreamController<Duration> _positionController =
      StreamController.broadcast();

  /// {@template Player.positionStream}
  /// Stream, указывающий позицию воспроизведения трека. Возвращает значение поля [position].
  /// {@endtemplate}
  Stream<Duration> get positionStream {
    return _positionController.stream.asBroadcastStream();
  }

  final StreamController<Duration> _seekController =
      StreamController.broadcast();

  /// {@template Player.seekStream}
  /// Stream, указывающий события резкого изменения [position] ввиду, к примеру, вызова метода [Player.seek]. Возвращает значение поля [position].
  /// {@endtemplate}
  Stream<Duration> get seekStream {
    return _seekController.stream.asBroadcastStream();
  }

  final StreamController<double> _volumeController =
      StreamController.broadcast();

  /// {@template Player.volumeStream}
  /// Stream, указывающий громкость плеера. Возвращает значение поля [volume].
  /// {@endtemplate}
  Stream<double> get volumeStream {
    return _volumeController.stream.asBroadcastStream();
  }

  final StreamController<bool> _isBufferingController =
      StreamController.broadcast();

  /// {@template Player.isBufferingStream}
  /// Stream, возвращающий состояние буферизации. Возвращает значение поля [isBuffering].
  /// {@endtemplate}
  Stream<bool> get isBufferingStream {
    return _isBufferingController.stream.asBroadcastStream();
  }

  final StreamController<Duration> _bufferedPositionController =
      StreamController.broadcast();

  /// {@template Player.bufferedPositionStream}
  /// Stream, возвращающий прогресс буферизации. Возвращает значение поля [bufferedPosition].
  /// {@endtemplate}
  Stream<Duration> get bufferedPositionStream {
    return _bufferedPositionController.stream.asBroadcastStream();
  }

  final StreamController<ExtendedPlaylist> _playlistController =
      StreamController.broadcast();

  /// {@template Player.playlistStream}
  /// Stream, указывающий то, какой [ExtendedPlaylist] играет в данный момент. Возвращает значение поля [playlist].
  ///
  /// Данный метод возвращает не только события изменения текущего плейлиста методом [Player.setPlaylist], но ещё и изменения плейлиста во время воспроизведения музыки (например, при получении метаданных трека во время воспроизведения того же плейлиста).
  /// {@endtemplate}
  Stream<ExtendedPlaylist> get playlistStream {
    return _playlistController.stream.asBroadcastStream();
  }

  final StreamController<List<ExtendedAudio>> _queueController =
      StreamController.broadcast();

  /// {@template Player.queueStream}
  /// Stream, указывающий очередь из воспроизводиой очереди. Возвращает значение поля [queue].
  ///
  /// Данный метод возвращает не только события изменения текущего плейлиста методом [Player.setPlaylist], но ещё и изменения текущей очереди.
  /// {@endtemplate}
  Stream<List<ExtendedAudio>> get queueStream {
    return _queueController.stream.asBroadcastStream();
  }

  final StreamController<bool> _isShufflingController =
      StreamController.broadcast();

  /// {@template Player.isShufflingStream}
  /// Stream, указывающий то, включена ли случайная перемешка треков или нет. Возвращает значение поля [isShuffling].
  /// {@endtemplate}
  Stream<bool> get isShufflingStream {
    return _isShufflingController.stream.asBroadcastStream();
  }

  final StreamController<bool> _isRepeatingController =
      StreamController.broadcast();

  /// {@template Player.isRepeatingStream}
  /// Stream, указывающий то, включён ли повтор текущего трека или нет. Возвращает значение поля [isRepeating].
  /// {@endtemplate}
  Stream<bool> get isRepeatingStream {
    return _isRepeatingController.stream.asBroadcastStream();
  }

  final StreamController<PlayerLog> _logController =
      StreamController.broadcast();

  /// {@template Player.logStream}
  /// Stream, возвращающий логи плеера.
  /// {@endtemplate}
  Stream<PlayerLog> get logStream {
    return _logController.stream.asBroadcastStream();
  }

  final StreamController<String> _errorController =
      StreamController.broadcast();

  /// {@template Player.errorStream}
  /// Stream, возвращающий ошибки плеера.
  /// {@endtemplate}
  Stream<String> get errorStream {
    return _errorController.stream.asBroadcastStream();
  }

  final StreamController<bool> _isDiscordRPCEnabledController =
      StreamController.broadcast();

  /// Stream, указывающий то, включён ли Discord RPC или нет. Возвращает значение поля [isDiscordRPCEnabled].
  Stream<bool> get isDiscordRPCEnabledStream {
    return _isDiscordRPCEnabledController.stream.asBroadcastStream();
  }

  final StreamController<bool> _isPauseOnMuteEnabledController =
      StreamController.broadcast();

  /// Stream, указывающий то, включена ли настройка "пауза при минимальной громкости". Возвращает значение поля [isPauseOnMuteEnabled].
  Stream<bool> get isPauseOnMuteEnabledStream {
    return _isPauseOnMuteEnabledController.stream.asBroadcastStream();
  }

  final StreamController<bool> _isStopOnLongPauseEnabledController =
      StreamController.broadcast();

  /// Stream, указывающий то, включена ли настройка "остановка при неактивности". Возвращает значение поля [isStopOnLongPauseEnabled].
  Stream<bool> get isStopOnLongPauseEnabledStream {
    return _isStopOnLongPauseEnabledController.stream.asBroadcastStream();
  }

  final StreamController<RewindBehavior> _rewindBehaviorController =
      StreamController.broadcast();

  /// Stream, указывающий то, какое поведение будет при перемотке в начало трека. Возвращает значение поля [rewindBehavior].
  Stream<RewindBehavior> get rewindBehaviorStream {
    return _rewindBehaviorController.stream.asBroadcastStream();
  }

  final StreamController<bool> _keepPlayingOnCloseEnabledController =
      StreamController.broadcast();

  /// Stream, указывающий то, остановится ли плеер после смахивания приложения в списке задач на OS Android. Возвращает значение поля [keepPlayingOnCloseEnabled].
  Stream<bool> get keepPlayingOnCloseEnabledStream {
    return _keepPlayingOnCloseEnabledController.stream.asBroadcastStream();
  }

  final StreamController<bool> _isDebugLoggingEnabledController =
      StreamController.broadcast();

  /// Stream, указывающий то, включено ли debug-логирование плеера. Возвращает значение поля [isDebugLoggingEnabled].
  Stream<bool> get isDebugLoggingEnabledStream {
    return _isDebugLoggingEnabledController.stream.asBroadcastStream();
  }

  final StreamController<bool> _trackTitleInWindowBarEnabledController =
      StreamController.broadcast();

  /// Stream, указывающий то, включено ли отображение название трека в названии окна. Возвращает значение поля [trackTitleInWindowBarEnabled].
  Stream<bool> get trackTitleInWindowBarEnabledStream {
    return _trackTitleInWindowBarEnabledController.stream.asBroadcastStream();
  }

  final StreamController<VolumeNormalization> _volumeNormalizationController =
      StreamController.broadcast();

  /// {@template Player.volumeNormalizationStream}
  /// Stream, указывающий значение настройки "нормализация громкости". Возвращает значение поля [volumeNormalization].
  /// {@endtemplate}
  Stream<VolumeNormalization> get volumeNormalizationStream {
    return _volumeNormalizationController.stream.asBroadcastStream();
  }

  final StreamController<bool> _silenceRemovalEnabledController =
      StreamController.broadcast();

  /// {@template Player.silenceRemovalEnabledStream}
  /// Stream, указывающий то, включено ли устранение тишины. Возвращает значение поля [silenceRemovalEnabled].
  /// {@endtemplate}
  Stream<bool> get silenceRemovalEnabledStream {
    return _silenceRemovalEnabledController.stream.asBroadcastStream();
  }

  /// {@template Player.isPlaying}
  /// Возвращает true, если плеер воспроизводит музыку.
  ///
  /// Данному методу соответствует метод [Player.play], и он не зависит от состояния [Player.isBuffering].
  /// {@endtemplate}
  bool get isPlaying => backend.isPlaying;

  /// {@template Player.position}
  /// Возвращает текущую позицию воспроизведения аудио.
  /// {@endtemplate}
  ///
  /// Для получения процентного значения прогресса воспроизведения (т.е., число от `0.0` до `1.0`), то воспользуйтесь [Player.progress].
  Duration get position => backend.position;

  /// {@template Player.duration}
  /// Возвращает общую длительность аудио.
  /// {@endtemplate}
  Duration get duration => backend.duration;

  /// Возвращает процентное значение прогресса воспроизведения аудио (т.е., число от `0.0` до `1.0`).
  double get progress {
    if (duration == Duration.zero) return 0.0;

    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  /// {@template Player.volume}
  /// Возвращает текущую громкость воспроизведения аудио.
  /// {@endtemplate}
  double get volume => backend.volume;

  /// {@template Player.isBuffering}
  /// Возвращает true, если плеер находится в состоянии буферизации.
  /// {@endtemplate}
  bool get isBuffering => backend.isBuffering;

  /// {@template Player.bufferedPosition}
  /// Возвращает текущую позицию буферизации воспроизводимого аудио.
  /// {@endtemplate}
  Duration get bufferedPosition => backend.bufferedPosition;

  /// {@template Player.index}
  /// Индекс текущего воспроизводимого трека в очереди воспроизведения [Player.queue].
  ///
  /// Для удобного получения трека из плейлиста, который играет в данный момент, можно воспользоваться методом [Player.audioAtIndex].
  /// {@endtemplate}
  int? get index => backend.index;

  /// Возвращает текущий [ExtendedAudio], который воспроизводится.
  ///
  /// Если ничего не воспроизводится (можно проверить при помощи [Player.isLoaded]), то возвращает null.
  ExtendedAudio? get audio => audioAtIndex(index);

  /// Возвращает следующий [ExtendedAudio] в плейлисте.
  ///
  /// Если ничего не воспроизводится (можно проверить при помощи [Player.isLoaded]), то возвращает null.
  ExtendedAudio? get nextAudio => audioAtRelativeIndex(1, wrapIndex: true);

  /// Возвращает предыдущий [ExtendedAudio] в плейлисте.
  ///
  /// Если ничего не воспроизводится (можно проверить при помощи [Player.isLoaded]), то возвращает null.
  ExtendedAudio? get previousAudio => audioAtRelativeIndex(-1, wrapIndex: true);

  /// {@template Player.playlist}
  /// Плейлист типа [ExtendedPlaylist], который воспроизводится в данный момент.
  /// Если Вам нужна очередь из треков, то обратитесь к [Player.queue].
  ///
  /// Для установки плейлиста можно воспользоваться методом [Player.setPlaylist].
  /// {@endtemplate}
  ExtendedPlaylist? get playlist => backend.playlist;

  /// {@template Player.queue}
  /// Очередь воспроизведения треков, которая будет проигрываться плеером.
  ///
  /// Данный список будет меняться при вызовах метода [Player.setShuffle].
  ///
  /// Для удобного получения трека из плейлиста, который играет в данный момент, можно воспользоваться методом [Player.audioAtIndex].
  /// {@endtemplate}
  List<ExtendedAudio>? get queue => backend.queue;

  /// {@template Player.isShuffling}
  /// Возвращает true, если включён случайный порядок воспроизведения.
  /// {@endtemplate}
  bool get isShuffling => backend.isShuffling;

  /// {@template Player.isRepeating}
  /// Возвращает true, если включено повторение воспроизведения текущего трека.
  /// {@endtemplate}
  bool get isRepeating => backend.isRepeating;

  /// Возвращает true, если включён Discord RPC. Для переключения Discord RPC можно воспользоваться методом [Player.setDiscordRPCEnabled].
  bool get isDiscordRPCEnabled => _discordRPCEnabled;

  /// Возвращает true, если включена настройка "пауза при минимальной громкости". Для переключения данной настройки можно воспользоваться методом [Player.setPauseOnMuteEnabled].
  bool get isPauseOnMuteEnabled => _pauseOnMuteEnabled;

  /// Возвращает true, если включена настройка "остановка при неактивности". Для переключения данной настройки можно воспользоваться методом [Player.setStopOnLongPauseEnabled].
  bool get isStopOnLongPauseEnabled => _stopOnLongPauseEnabled;

  /// Возвращает значение настройки "перемотка при запуске предыдущего трека". Для переключения данной настройки можно воспользоваться методом [Player.setRewindBehavior].
  RewindBehavior get rewindBehavior => _rewindBehavior;

  /// Возвращает значение настройки "игра после смахивания приложения". Для переключения данной настройки можно воспользоваться методом [Player.setKeepPlayingOnCloseEnabled].
  bool get keepPlayingOnCloseEnabled => _keepPlayingOnCloseEnabled;

  /// Возвращает true, если включено debug-логирование плеера. Для переключения данной настройки можно воспользоваться методом [Player.setDebugLoggingEnabled].
  bool get isDebugLoggingEnabled => _isDebugLoggingEnabled;

  /// Возвращает true, если включена настройка "название трека в заголовке окна". Для переключения данной настройки можно воспользоваться методом [Player.setTrackTitleInWindowBarEnabled].
  bool get trackTitleInWindowBarEnabled => _trackTitleInWindowBarEnabled;

  /// {@template Player.volumeNormalization}
  /// Возвращает значение настройки "нормализация громкости". Для переключения данной настройки можно воспользоваться методом [Player.setVolumeNormalization].
  ///
  /// Вы так же можете проверить, включена ли нормализация громкости, при помощи [Player.isVolumeNormalizationEnabled].
  /// {@endtemplate}
  VolumeNormalization get volumeNormalization => backend.volumeNormalization;

  /// Указывает, включена ли нормализация громкости или нет. Если вам нужно узнать уровень нормализации, то воспользуйтесь [Player.volumeNormalization].
  bool get isVolumeNormalizationEnabled =>
      volumeNormalization != VolumeNormalization.disabled;

  /// {@template Player.silenceRemovalEnabled}
  /// Возвращает true, если включено удаление тишины. Для переключения данной настройки можно воспользоваться методом [Player.setSilenceRemovalEnabled].
  /// {@endtemplate}
  bool get silenceRemovalEnabled => backend.silenceRemovalEnabled;

  /// Управляет состоянием работы Discord RPC.
  void setDiscordRPCEnabled(bool enabled) {
    if (enabled == _discordRPCEnabled) return;

    _discordRPCEnabled = enabled;
    _isDiscordRPCEnabledController.add(enabled);
  }

  /// Управляет настройкой "пауза при минимальной громкости".
  void setPauseOnMuteEnabled(bool enabled) {
    if (enabled == _pauseOnMuteEnabled) return;

    _pauseOnMuteEnabled = enabled;
    _isPauseOnMuteEnabledController.add(enabled);
  }

  /// Управляет настройкой "остановка при неактивности".
  void setStopOnLongPauseEnabled(bool enabled) {
    if (enabled == _stopOnLongPauseEnabled) return;

    _stopOnLongPauseEnabled = enabled;
    _isStopOnLongPauseEnabledController.add(enabled);
  }

  /// Устанавливает поведение при перемотке в начало трека.
  void setRewindBehavior(RewindBehavior behavior) {
    if (behavior == _rewindBehavior) return;

    _rewindBehavior = behavior;
    _rewindBehaviorController.add(behavior);
  }

  /// Устанавливает значение настройки "игра после смахивания приложения".
  void setKeepPlayingOnCloseEnabled(bool enabled) {
    if (enabled == _keepPlayingOnCloseEnabled) return;

    _keepPlayingOnCloseEnabled = enabled;
    _keepPlayingOnCloseEnabledController.add(enabled);
  }

  /// Устанавливает значение настройки "debug-логирование".
  void setDebugLoggingEnabled(bool enabled) {
    if (enabled == _isDebugLoggingEnabled) return;

    _isDebugLoggingEnabled = enabled;
    _isDebugLoggingEnabledController.add(enabled);
  }

  /// Устанавливает значение настройки "название трека в заголовке окна".
  void setTrackTitleInWindowBarEnabled(bool enabled) {
    if (enabled == _trackTitleInWindowBarEnabled) return;

    _trackTitleInWindowBarEnabled = enabled;
    _trackTitleInWindowBarEnabledController.add(enabled);
  }

  /// {@template Player.setVolumeNormalization}
  /// Устанавливает значение настройки "нормализация громкости".
  /// {@endtemplate}
  Future<void> setVolumeNormalization(VolumeNormalization normalization) async {
    await backend.setVolumeNormalization(normalization);
  }

  /// {@template Player.setSilenceRemovalEnabled}
  /// Устанавливает значение настройки "удаление тишины".
  /// {@endtemplate}
  Future<void> setSilenceRemovalEnabled(bool enabled) async {
    await backend.setSilenceRemovalEnabled(enabled);
  }

  /// {@template Player.play}
  /// Запускает воспроизведение музыки, если оно было ранее приостановлено при помощи метода [Player.pause].
  /// {@endtemplate}
  Future<void> play() async => await backend.play();

  /// {@template Player.pause}
  /// Приостанавливает воспроизведение музыки. После, воспроизведение можно возобновить при помощи метода [Player.play].
  /// {@endtemplate}
  Future<void> pause() async => await backend.pause();

  /// Вызывает метод [Player.play] либо [Player.pause], в зависимости от аргумента [isPlaying].
  Future<void> setPlay({
    bool isPlaying = true,
  }) async {
    if (isPlaying) {
      return await backend.play();
    }

    return await backend.pause();
  }

  /// Вызывает метод [play] либо [pause] чтобы переключить воспроизведение музыки.
  Future<void> togglePlay() async {
    return await setPlay(
      isPlaying: !isPlaying,
    );
  }

  /// {@template Player.stop}
  /// Останавливает плеер, а так же закрывает (высвобождает) все ресурсы, связанные с ним.
  /// {@endtemplate}
  Future<void> stop() async => await backend.stop();

  /// {@template Player.seek}
  /// Устанавливает позицию воспроизведения аудио.
  ///
  /// [play] указывает, будет ли воспроизведение музыки возобновлено после установки позиции.
  /// {@endtemplate}
  Future<void> seek(
    Duration position, {
    bool play = false,
  }) async {
    return await backend.seek(
      position,
      play: play,
    );
  }

  /// Устанавливает позицию воспроизведения аудио относительно текущей позиции.
  ///
  /// [play] указывает, будет ли воспроизведение музыки возобновлено после установки позиции.
  Future<void> seekBy(
    Duration relativePosition, {
    bool play = false,
  }) async {
    return await seek(
      position + relativePosition,
      play: play,
    );
  }

  /// Устанавливает позицию воспроизведения аудио в процентном соотношении.
  ///
  /// [play] указывает, будет ли воспроизведение музыки возобновлено после установки позиции.
  Future<void> seekNormalized(
    double normalizedPosition, {
    bool play = false,
  }) async {
    return await seek(
      Duration(
        milliseconds: (duration.inMilliseconds * normalizedPosition).round(),
      ),
      play: play,
    );
  }

  /// {@template Player.setVolume}
  /// Устанавливает громкость воспроизведения музыки в процентном соотношении (от `0.0` до `1.0`).
  /// {@endtemplate}
  Future<void> setVolume(double volume) async {
    await backend.setVolume(volume.clamp(0.0, 1.0));
  }

  /// Устанавливает громкость воспроизведения музыки относительно текущей громкости.
  Future<void> setVolumeBy(double relativeVolume) async {
    return await setVolume(volume + relativeVolume);
  }

  /// {@template Player.setShuffle}
  /// Устанавливает случайный порядок воспроизведения.
  /// {@endtemplate}
  ///
  /// [disableAudioMixCheck] указывает, что проверка на включение случайной перемешки в плейлистах типа Audio Mix будет выключена.
  Future<void> setShuffle(
    bool shuffle, {
    bool disableAudioMixCheck = false,
  }) async {
    // TODO: Audio mix check.

    return await backend.setShuffle(shuffle);
  }

  /// Переключает случайный порядок воспроизведения.
  Future<void> toggleShuffle() async {
    return await setShuffle(!isShuffling);
  }

  /// {@template Player.setRepeat}
  /// Устанавливает повторение воспроизведения текущего трека.
  /// {@endtemplate}
  Future<void> setRepeat(bool repeat) async => await backend.setRepeat(repeat);

  /// Переключает повторение воспроизведения текущего трека.
  Future<void> toggleRepeat() async {
    return await setRepeat(!isRepeating);
  }

  /// {@template Player.next}
  /// Переключает воспроизведение на следующий трек в плейлисте.
  /// {@endtemplate}
  Future<void> next() async => await backend.next();

  /// {@template Player.previous}
  /// Переключает воспроизведение на предыдущий трек в плейлисте.
  ///
  /// Если [allowPrevious] правдив, то вместо запуска предыдущего трека будет запущен текущий трек с начала, если прошло не более 5 секунд с момента воспроизведения.
  /// {@endtemplate}
  ///
  /// Если вам нужно определить то, будет использоваться [allowPrevious] или нет в зависимости от источника (например, нажатие кнопки "назад" в UI, либо нажатие таковой кнопки в медиа-уведомлении), а так же в зависимости от той настройки, которую установил пользователь, то воспользуйтесь методом [smartPrevious].
  Future<void> previous({bool allowPrevious = false}) async {
    await backend.previous(allowPrevious: allowPrevious);
  }

  /// Запускает воспроизведение трека, который был воспроизведён перед текущим треком, либо же перематывает в начало текущего трека в зависимости от источника вызова этого метода (UI либо медиа-уведомление) и значения пользовательской настройки [UserPreferences.rewindOnPreviousBehavior].
  ///
  /// Если вам нужно проигнорировать текущее значение настройки [UserPreferences.rewindOnPreviousBehavior], то воспользуйтесь методом [Player.previous].
  ///
  /// [viaNotification] указывает, что данный метод был вызван через медиа-уведомление (SMTC, Android-уведомление, ...), нежели через UI приложения.
  Future<void> smartPrevious({
    bool viaNotification = false,
  }) async {
    final setting = rewindBehavior;
    final allowSeekToBeginning = setting == RewindBehavior.always ||
        (viaNotification && setting == RewindBehavior.onlyViaNotification) ||
        (!viaNotification && setting == RewindBehavior.onlyViaUI);

    logger.d(
      "smartPrevious(isNotification: $viaNotification, setting: ${setting.name}) -> can seek to beginning: $allowSeekToBeginning",
    );

    return await previous(
      allowPrevious: allowSeekToBeginning,
    );
  }

  /// {@template Player.jump}
  /// Переключает воспроизведение на индекс указанного трека в очереди воспроизведения [Player.queue].
  /// {@endtemplate}
  Future<void> jump(int index) async => await backend.jump(index);

  /// Переключает воспроизведение на указанный трек в очереди воспроизведения [Player.queue].
  ///
  /// Если такого трека нет, то ничего не произойдёт.
  Future<void> jumpToAudio(ExtendedAudio audio) async {
    final index = queue?.indexOf(audio);
    if (index == null || index == -1) return;

    return await jump(index);
  }

  /// {@template Player.audioAtIndex}
  /// Возвращает [ExtendedAudio] по индексу [index] в плейлисте. [wrapIndex] показывает, будет ли этот индекс циклироваться вокруг плейлиста, если он выходит за его пределы.
  /// {@endtemplate}
  ExtendedAudio? audioAtIndex(int? index, {bool wrapIndex = false}) {
    if (index == null) return null;

    return backend.audioAtIndex(index, wrapIndex: wrapIndex);
  }

  /// Возвращает [ExtendedAudio] по относительному (по отношению к текущему треку) индексу.
  ///
  /// К примеру, `-1` вернёт предыдущий трек, а `1` вернёт следующий трек.
  ExtendedAudio? audioAtRelativeIndex(
    int relativeIndex, {
    bool wrapIndex = false,
  }) {
    if (index == null) return null;

    return audioAtIndex(index! + relativeIndex, wrapIndex: wrapIndex);
  }

  /// {@template Player.setPlaylist}
  /// Устанавливает плейлист типа [ExtendedPlaylist], заменяющий текущий плейлист (если такой ранее был установлен), и запускает его воспроизведение, если [play] равен true.
  ///
  /// [initialAudio] указывает [ExtendedAudio], с которого начнётся воспроизведение после вызова данного метода. Однако, если [initialAudio] равен null, то воспроизведение начнётся с начала, либо со случайного трека, если [randomAudio] равен true.
  /// [randomAudio] включает воспроизведение случайного трека.
  /// {@endtemplate}
  Future<void> setPlaylist(
    ExtendedPlaylist playlist, {
    bool play = true,
    ExtendedAudio? initialAudio,
    bool randomAudio = false,
  }) async {
    return await backend.setPlaylist(
      playlist,
      play: play,
      initialAudio: initialAudio,
      randomAudio: randomAudio,
    );
  }

  /// {@template Player.updateCurrentPlaylist}
  /// Принимает новую версию плейлиста типа [ExtendedPlaylist], заменяя ту, которая воспроизводится в данный момент.
  /// Если [ExtendedPlaylist.id] будут отличаться, то будет выброшено исключение.
  ///
  /// Этот метод используется лишь при обновлении объекта плейлиста во время воспроизведения музыки.
  /// Если вам нужно установить новый плейлист, то воспользуйтесь методом [Player.setPlaylist].
  /// {@endtemplate}
  Future<void> updateCurrentPlaylist(ExtendedPlaylist playlist) async {
    return await backend.updateCurrentPlaylist(playlist);
  }

  /// {@template Player.insertToQueue}
  /// Добавляет [ExtendedAudio] в очередь воспроизведения. [index] указывает, в какое место в очереди будет добавлен трек. Если [index] не указан, то трек будет добавлен в конец очереди.
  /// ```dart
  /// final X = ExtendedAudio(...);
  /// await player.insertToQueue(X, 1);
  ///
  /// final oldQueue = [a, b, c];
  /// final newQueue = [a, X, b, c];
  /// ```
  /// {@endtemplate}
  Future<void> insertToQueue(ExtendedAudio audio, {int? index}) async {
    // TODO: Проверить, что будет, если нету загруженного плейлиста.

    return await backend.insertToQueue(
      audio,
      index: index,
    );
  }

  /// Добавляет [ExtendedAudio] в очередь воспроизведения после текущего трека.
  Future<void> addNextToQueue(ExtendedAudio audio) async {
    await insertToQueue(
      audio,
      index: index! + 1,
    );
  }

  /// Добавляет [ExtendedAudio] в конец очереди воспроизведения.
  Future<void> addToQueueEnd(ExtendedAudio audio) async {
    await insertToQueue(audio);
  }
}
