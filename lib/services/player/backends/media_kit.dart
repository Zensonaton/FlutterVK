import "dart:async";
import "dart:math";

import "package:media_kit/media_kit.dart" as mk;

import "../../../consts.dart";
import "../../../provider/user.dart";
import "../../logger.dart";
import "../backend.dart";
import "../player.dart";
import "../server.dart";

/// Audio Backend для [Player], воспроизводящий музыку при помощи плеера из `media_kit`.
///
/// Ввиду необычных особенностей работы shuffle в `media_kit`, данная реализация полностью отказывается от использования встроенных в `media_kit` плейлистов:
/// вместо этого, данный [PlayerBackend] управляет воспроизведением самостоятельно, посылая в [mk.Player] лишь по одному треку.
/// Благодаря подобной реализации, этот [PlayerBackend] сам управляет воспроизведением треков.
class MediaKitPlayerBackend extends PlayerBackend {
  static final AppLogger logger = getLogger("MediaKitPlayerBackend");

  /// Модификатор громкости.
  static const double volumeModifier = 100;

  /// Размер буффера MPV для воспроизведения. По умолчанию 50 МБ.
  static const int bufferSize = 50 * 1024 * 1024;

  /// Количество треков для prefetching'а.
  static const int prefetchMaxCount = 3;

  mk.Player? _player;
  PlayerLocalServer? _server;
  List<StreamSubscription>? _subscriptions;

  Duration? _tempPosition;

  final StreamController<bool> _isLoadedController =
      StreamController.broadcast();
  final StreamController<bool> _isPlayingControler =
      StreamController.broadcast();
  final StreamController<ExtendedAudio> _audioController =
      StreamController.broadcast();
  final StreamController<Duration> _positionController =
      StreamController.broadcast();
  final StreamController<Duration> _seekController =
      StreamController.broadcast();
  final StreamController<double> _volumeController =
      StreamController.broadcast();
  final StreamController<bool> _isBufferingController =
      StreamController.broadcast();
  final StreamController<Duration> _bufferedPositionController =
      StreamController.broadcast();
  final StreamController<ExtendedPlaylist> _playlistController =
      StreamController.broadcast();
  final StreamController<List<ExtendedAudio>> _queueController =
      StreamController.broadcast();
  final StreamController<bool> _isShufflingController =
      StreamController.broadcast();
  final StreamController<bool> _isRepeatingController =
      StreamController.broadcast();
  final StreamController<PlayerLog> _logController =
      StreamController.broadcast();
  final StreamController<String> _errorController =
      StreamController.broadcast();

  /// Возвращает плеер, используемый для воспроизведения музыки.
  mk.Player get player => _player!;

  /// Возвращает [mk.NativePlayer] для установки свойств плеера.
  mk.NativePlayer get nativePlayer => _player!.platform as mk.NativePlayer;

  MediaKitPlayerBackend({
    super.name = "media_kit",
    super.isLocal = true,
    super.localServerRequired = true,
  });

  ExtendedPlaylist? _playlist;

  /// Оригинальная очередь из треков.
  List<ExtendedAudio>? _queue;

  /// Модифицированная версия плейлиста. К примеру, в ней может храниться shuffled-версия плейлиста, если включён shuffle **выключен**, или обычная версия плейлиста, если shuffle **включён**. Да, тут используется инверсия.
  ///
  /// Данный плейлист заменяет [_queue] своим значением при вызове [setShuffle].
  List<ExtendedAudio>? _modifiedQueue;
  int? _index;
  bool _isShuffling = false;
  bool _isRepeating = false;

  @override
  Future<void> initialize({PlayerLocalServer? server}) async {
    assert(
      server != null,
      "PlayerLocalServer must be provided",
    );

    mk.MediaKit.ensureInitialized();

    _player = mk.Player(
      configuration: const mk.PlayerConfiguration(
        title: appName,
        bufferSize: bufferSize,
        logLevel: mk.MPVLogLevel.v,
      ),
    );
    nativePlayer.setProperty("prefetch-playlist", "yes");

    _server = server!;

    _subscriptions = [
      player.stream.completed.listen((bool completed) async {
        await _playNext();
      }),
      player.stream.playing.listen((bool playing) {
        _isPlayingControler.add(playing);
      }),
      player.stream.position.listen((Duration position) {
        _positionController.add(_tempPosition ?? position);
      }),
      player.stream.volume.listen((double volume) {
        _volumeController.add(volume / volumeModifier);
      }),
      player.stream.buffering.listen((bool buffering) {
        _isBufferingController.add(buffering);
      }),
      player.stream.buffer.listen((Duration buffer) {
        _bufferedPositionController.add(buffer);
      }),
      player.stream.error.listen((String error) {
        _errorController.add(error);
      }),
      player.stream.log.listen((mk.PlayerLog log) {
        PlayerLogLevel level = {
              "debug": PlayerLogLevel.debug,
              "info": PlayerLogLevel.info,
              "warn": PlayerLogLevel.warning,
              "error": PlayerLogLevel.error,
              "fatal": PlayerLogLevel.error,
            }[log.level] ??
            PlayerLogLevel.verbose;

        _logController.add(
          PlayerLog(
            level: level,
            text: log.text,
            sender: log.prefix,
          ),
        );
      }),
    ];
  }

  @override
  Future<void> dispose() async {
    await stop();

    if (_subscriptions != null) {
      for (final subscription in _subscriptions!) {
        await subscription.cancel();
      }
      _subscriptions!.clear();
    }

    await _player?.dispose();
  }

  @override
  Stream<bool> get isLoadedStream => _isLoadedController.stream;

  @override
  Stream<bool> get isPlayingStream => _isPlayingControler.stream;

  @override
  Stream<ExtendedAudio> get audioStream => _audioController.stream;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration> get seekStream => _seekController.stream;

  @override
  Stream<double> get volumeStream => _volumeController.stream;

  @override
  Stream<bool> get isBufferingStream => _isBufferingController.stream;

  @override
  Stream<Duration> get bufferedPositionStream =>
      _bufferedPositionController.stream;

  @override
  Stream<ExtendedPlaylist> get playlistStream => _playlistController.stream;

  @override
  Stream<List<ExtendedAudio>> get queueStream => _queueController.stream;

  @override
  Stream<bool> get isShufflingStream => _isShufflingController.stream;

  @override
  Stream<bool> get isRepeatingStream => _isRepeatingController.stream;

  @override
  Stream<PlayerLog> get logStream => _logController.stream;

  @override
  Stream<String> get errorStream => _errorController.stream;

  @override
  bool get isInitialized => _player != null;

  @override
  bool get isPlaying => player.state.playing;

  @override
  Duration get position => _tempPosition ?? player.state.position;

  @override
  Duration get duration => player.state.duration;

  @override
  double get volume => player.state.volume / volumeModifier;

  @override
  bool get isBuffering => player.state.buffering;

  @override
  Duration get bufferedPosition => player.state.buffer;

  @override
  int? get index => _index;

  @override
  ExtendedPlaylist? get playlist => _playlist;

  @override
  List<ExtendedAudio>? get queue => _queue;

  @override
  bool get isShuffling => _isShuffling;

  @override
  bool get isRepeating => _isRepeating;

  /// Возвращает копию переданного [index], но делает так, чтобы он не выходил за пределы допустимых значений.
  int _getValidIndex(int index) {
    if (index > _queue!.length - 1) {
      return 0;
    } else if (index < 0) {
      return _queue!.length - 1;
    }

    return index;
  }

  /// Отправляет в [mk.Player] список из [ExtendedAudio] для воспроизведения.
  Future<void> _sendAudios() async {
    if (_queue == null) return;

    // Если включён повтор, то отправляем лишь текущий трек.
    if (_isRepeating) {
      final audio = audioAtIndex(_index!)!;

      _audioController.add(audio);
      await player.open(
        mk.Media(
          _server!.fromAudio(audio, _playlist!),
        ),
      );

      return;
    }

    // Извлекаем список из [index:index + prefetchMaxCount] треков для работы prefetching'а.
    final List<mk.Media> audios = [];
    final maxIndex = _index! + prefetchMaxCount;
    for (int i = _index!; i < maxIndex; i++) {
      final audio = audioAtIndex(i, wrapIndex: true);

      audios.add(
        mk.Media(
          _server!.fromAudio(audio!, _playlist!),
        ),
      );
    }

    _audioController.add(audioAtIndex(_index!)!);
    await player.open(
      mk.Playlist(audios),
    );
  }

  /// Запускает воспроизведение следующего трека из плейлиста.
  Future<void> _playNext() async {
    if (_playlist == null || _queue == null) return;

    // Если включён повтор, то запускаем воспроизведение сначала.
    if (isRepeating) {
      await seek(Duration.zero);
    } else {
      _index = _getValidIndex(_index! + 1);
    }

    await _sendAudios();
  }

  @override
  Future<void> play() async => await player.play();

  @override
  Future<void> pause() async => await player.pause();

  @override
  Future<void> stop() async {
    _isLoadedController.add(false);
    _index = null;
    _playlist = null;
    _queue = [];
    _modifiedQueue = [];
    _server?.clear();

    await player.stop();
  }

  @override
  Future<void> seek(
    Duration position, {
    bool play = false,
  }) async {
    _tempPosition = position;
    _seekController.add(position);
    await player.seek(position);
    await for (final _ in positionStream.take(1)) {}
    _tempPosition = null;

    if (play) await player.play();
  }

  @override
  Future<void> setVolume(double volume) async {
    await player.setVolume(volume * volumeModifier);
  }

  @override
  Future<void> setShuffle(bool shuffle) async {
    if (_isShuffling == shuffle) return;

    _isShuffling = shuffle;
    _isShufflingController.add(shuffle);

    if (queue == null || _index == null) return;

    final oldAudio = _queue![_index!];
    final oldQueue = List<ExtendedAudio>.from(_queue!);
    _queue = _modifiedQueue;
    _modifiedQueue = oldQueue;

    for (int i = 0; i < _queue!.length; i++) {
      if (_queue![i].id != oldAudio.id) continue;

      _index = i;
      break;
    }

    _queueController.add(_queue!);
  }

  @override
  Future<void> setRepeat(bool repeat) async {
    if (_isRepeating == repeat) return;

    _isRepeating = repeat;
    _isRepeatingController.add(repeat);
  }

  @override
  Future<void> next() async {
    await jump(_getValidIndex(_index! + 1));
  }

  @override
  Future<void> previous({bool allowPrevious = false}) async {
    if (allowPrevious && position > Player.rewindThreshold) {
      await seek(Duration.zero);

      return;
    }

    await jump(_getValidIndex(_index! - 1));
  }

  @override
  Future<void> jump(int index) async {
    _index = _getValidIndex(index);
    await _sendAudios();
  }

  @override
  ExtendedAudio? audioAtIndex(int index, {bool wrapIndex = false}) {
    if (wrapIndex) {
      return _queue?[_getValidIndex(index)];
    }

    if (index < 0) return null;
    return _queue?.elementAtOrNull(index);
  }

  @override
  Future<void> setPlaylist(
    ExtendedPlaylist playlist, {
    bool play = true,
    ExtendedAudio? initialAudio,
    bool randomAudio = false,
  }) async {
    if (playlist.audios == null) {
      throw ArgumentError("Playlist must have audios");
    }
    if (playlist.audios!.isEmpty) return;

    _playlist = playlist;
    _queue = playlist.audios!
        .where(
          (audio) => audio.canPlay,
        )
        .toList();
    _modifiedQueue = List<ExtendedAudio>.from(_queue!);
    if (isShuffling) {
      _queue!.shuffle();
    } else {
      _modifiedQueue!.shuffle();
    }

    _index = null;
    if (initialAudio != null) {
      for (int i = 0; i < _queue!.length; i++) {
        if (_queue![i].id != initialAudio.id) continue;

        _index = i;
        break;
      }
    } else if (randomAudio) {
      _index = Random().nextInt(_queue!.length);
    }
    _index ??= 0;

    _isLoadedController.add(true);
    _playlistController.add(playlist);
    _queueController.add(_queue!);
    await _sendAudios();
  }

  @override
  Future<void> updateCurrentPlaylist(ExtendedPlaylist playlist) async {
    if (playlist.audios == null) {
      throw ArgumentError("Playlist must have audios");
    }
    final isCurrent = this.playlist?.ownerID == playlist.ownerID &&
        this.playlist?.id == playlist.id;
    if (!isCurrent) {
      throw ArgumentError("Playlist must be current to update it");
    }

    final currentAudio = audioAtIndex(_index!);
    bool modifiedCurrentAudio = false;
    for (final audio in playlist.audios!) {
      final index = _queue!.indexWhere(
        (item) => item.id == audio.id,
      );

      if (index == -1) {
        _queue!.add(audio);
        _modifiedQueue!.add(audio);
      } else {
        // TODO: Вместо повторного поиска сделать другую систему.
        final mqIndex = _modifiedQueue!.indexWhere(
          (item) => item.id == audio.id,
        );

        _queue![index] = audio;
        _modifiedQueue![mqIndex] = audio;

        if (audio.id == currentAudio!.id && !audio.isEquals(currentAudio)) {
          modifiedCurrentAudio = true;
        }
      }
    }

    _queueController.add(_queue!);
    if (modifiedCurrentAudio) {
      _audioController.add(currentAudio!);
    }
  }

  @override
  Future<void> insertToQueue(ExtendedAudio audio, {int? index}) async {
    if (index == null) {
      _queue!.add(audio);
      _modifiedQueue!.add(audio);
    } else {
      _queue!.insert(index, audio);
      _modifiedQueue!.insert(index, audio);
    }

    _queueController.add(_queue!);
  }
}
