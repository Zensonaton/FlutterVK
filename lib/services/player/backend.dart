import "dart:async";

import "../../enums.dart";
import "../../provider/user.dart";
import "player.dart";
import "server.dart";

/// Класс, предоставляющий отдельный backend для воспроизведения музыки.
///
/// Для руководства множеством [PlayerBackend]'ов используется [Player].
class PlayerBackend {
  /// Название данного backend'а.
  final String name;

  /// Указывает, что этот backend умеет воспроизводить музыку из динамиков (либо наушников) данного устройства.
  ///
  /// У удалённых backend'ов данное значение равно false, поскольку они удалены, и не могут воспроизводить музыку.
  final bool isLocal;

  /// Указывает, что этот backend требует наличие запущенного HTTP-сервера для воспроизведения музыки.
  final bool localServerRequired;

  PlayerBackend({
    required this.name,
    required this.isLocal,
    required this.localServerRequired,
  });

  @override
  String toString() {
    return "PlayerBackend($name ${isInitialized ? "initialized" : "non-initialized"} ${isLocal ? "local" : "remote"} ${localServerRequired ? "http server required" : "http server not required"})";
  }

  /// Возвращает ошибку [UnimplementedError].
  static _throw() => throw UnimplementedError();

  /// Инициализирует данный backend. [server] передаётся лишь в случае, если backend требует наличие HTTP-сервера ([localServerRequired]).
  Future<void> initialize({PlayerLocalServer? server}) async => _throw();

  /// Очищает память, занимаемую данным backend'ом.
  ///
  /// После вызова данного метода необходимо повторно вызвать [PlayerBackend.initialize], чтобы использовать данный backend.
  Future<void> dispose() async => _throw();

  /// {@macro Player.isLoadedStream}
  Stream<bool> get isLoadedStream => _throw();

  /// {@macro Player.isPlayingStream}
  Stream<bool> get isPlayingStream => _throw();

  /// {@macro Player.audioStream}
  Stream<ExtendedAudio> get audioStream => _throw();

  /// {@macro Player.positionStream}
  Stream<Duration> get positionStream => _throw();

  /// {@macro Player.seekStream}
  Stream<Duration> get seekStream => _throw();

  /// {@macro Player.volumeStream}
  Stream<double> get volumeStream => _throw();

  /// {@macro Player.isBufferingStream}
  Stream<bool> get isBufferingStream => _throw();

  /// {@macro Player.bufferedPositionStream}
  Stream<Duration> get bufferedPositionStream => _throw();

  /// {@macro Player.playlistStream}
  Stream<ExtendedPlaylist> get playlistStream => _throw();

  /// {@macro Player.queueStream}
  Stream<List<ExtendedAudio>> get queueStream => _throw();

  /// {@macro Player.isShufflingStream}
  Stream<bool> get isShufflingStream => _throw();

  /// {@macro Player.isRepeatingStream}
  Stream<bool> get isRepeatingStream => _throw();

  /// {@macro Player.logStream}
  Stream<PlayerLog> get logStream => _throw();

  /// {@macro Player.errorStream}
  Stream<String> get errorStream => _throw();

  /// {@macro Player.volumeNormalizationStream}
  Stream<VolumeNormalization> get volumeNormalizationStream => _throw();

  /// {@macro Player.silenceRemovalEnabledStream}
  Stream<bool> get silenceRemovalEnabledStream => _throw();

  /// Указывает, инициализирован ли данный backend при помощи метода [PlayerBackend.initialize].
  ///
  /// Если backend не инициализирован, то нельзя использовать методы, связанные с воспроизведением музыки.
  bool get isInitialized => _throw();

  /// {@macro Player.isPlaying}
  bool get isPlaying => _throw();

  /// {@macro Player.position}
  Duration get position => _throw();

  /// {@macro Player.duration}
  Duration get duration => _throw();

  /// {@macro Player.volume}
  double get volume => _throw();

  /// {@macro Player.isBuffering}
  bool get isBuffering => _throw();

  /// {@macro Player.bufferedPosition}
  Duration get bufferedPosition => _throw();

  /// {@macro Player.index}
  int? get index => _throw();

  /// {@macro Player.playlist}
  ExtendedPlaylist? get playlist => _throw();

  /// {@macro Player.queue}
  List<ExtendedAudio>? get queue => _throw();

  /// {@macro Player.isShuffling}
  bool get isShuffling => _throw();

  /// {@macro Player.isRepeating}
  bool get isRepeating => _throw();

  /// {@macro Player.volumeNormalization}
  VolumeNormalization get volumeNormalization => _throw();

  /// {@macro Player.silenceRemovalEnabled}
  bool get silenceRemovalEnabled => _throw();

  /// {@macro Player.setVolumeNormalization}
  Future<void> setVolumeNormalization(
    VolumeNormalization normalization,
  ) async =>
      _throw();

  /// {@macro Player.setSilenceRemovalEnabled}
  Future<void> setSilenceRemovalEnabled(bool enabled) async => _throw();

  /// {@macro Player.play}
  Future<void> play() async => _throw();

  /// {@macro Player.pause}
  Future<void> pause() async => _throw();

  /// {@macro Player.stop}
  Future<void> stop() async => _throw();

  /// {@macro Player.seek}
  Future<void> seek(
    Duration position, {
    bool play = false,
  }) async =>
      _throw();

  /// {@macro Player.setVolume}
  Future<void> setVolume(double volume) async => _throw();

  /// {@macro Player.setShuffle}
  Future<void> setShuffle(bool shuffle) async => _throw();

  /// {@macro Player.setRepeat}
  Future<void> setRepeat(bool repeat) async => _throw();

  /// {@macro Player.next}
  Future<void> next() async => _throw();

  /// {@macro Player.previous}
  Future<void> previous({bool allowPrevious = false}) async => _throw();

  /// {@macro Player.jump}
  Future<void> jump(int index) async => _throw();

  /// {@macro Player.audioAtIndex}
  ExtendedAudio? audioAtIndex(int index, {bool wrapIndex = false}) => _throw();

  /// {@macro Player.setPlaylist}
  Future<void> setPlaylist(
    ExtendedPlaylist playlist, {
    bool play = true,
    ExtendedAudio? initialAudio,
    bool randomAudio = false,
  }) async =>
      throw UnimplementedError();

  /// {@macro Player.updateCurrentPlaylist}
  Future<void> updateCurrentPlaylist(ExtendedPlaylist playlist) async =>
      _throw();

  /// {@macro Player.insertToQueue}
  Future<void> insertToQueue(ExtendedAudio audio, {int? index}) async =>
      _throw();
}
