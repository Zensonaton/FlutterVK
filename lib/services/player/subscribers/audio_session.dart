import "dart:async";

import "package:audio_session/audio_session.dart";

import "../../../utils.dart";
import "../../logger.dart";
import "../player.dart";
import "../subscriber.dart";

/// Класс подписчика на события [Player] для регистрации [AudioSession], который позволяет обрабатывать события системы, такие как отключение наушников, звонок на телефон и т.д.
class AudioSessionPlayerSubscriber extends PlayerSubscriber {
  static final AppLogger logger = getLogger("AudioSessionPlayerSubscriber");

  AudioSessionPlayerSubscriber(Player player) : super("Audio session", player);

  /// Объект [AudioSession] для регистрации событий.
  late final AudioSession _audioSession;

  @override
  Future<void> initialize() async {
    if (!isAndroid) {
      throw UnsupportedError("AudioSession is not supported on this platform");
    }

    _audioSession = await AudioSession.instance;
    await _audioSession.configure(
      const AudioSessionConfiguration.music(),
    );
  }

  @override
  List<StreamSubscription> subscribe(Player player) {
    return [
      player.isPlayingStream.listen(onIsPlaying),

      // События AudioSession.
      _audioSession.becomingNoisyEventStream.listen(onBecomingNoisy),
      _audioSession.interruptionEventStream.listen(onInterruption),
    ];
  }

  /// Указывает, что плеер был приостановлен этим subscriber'ом ввиду события системы.
  bool _pausedDueInterrupt = false;

  /// События паузы/воспроизведения музыки.
  void onIsPlaying(bool isPlaying) async {
    if (isPlaying) {
      _pausedDueInterrupt = false;
    }

    await _audioSession.setActive(isPlaying);
  }

  /// События отключения наушников.
  void onBecomingNoisy(_) {
    logger.d("Becoming noisy, calling pause");

    player.pause();
  }

  /// Другие события системы (переход фокуса на другое медиа-приложение, звонок, ...).
  void onInterruption(AudioInterruptionEvent event) async {
    logger.d("Interrupt ${event.type.name}, is beginning: ${event.begin}");

    if (event.begin) {
      switch (event.type) {
        case AudioInterruptionType.duck:
          await player.setVolume(0.5);

          break;
        case AudioInterruptionType.pause:
        case AudioInterruptionType.unknown:
          if (!player.isPlaying) return;

          _pausedDueInterrupt = true;
          await player.pause();

          break;
      }

      return;
    }

    // Восстанавливаем плеер после окончания события.
    switch (event.type) {
      case AudioInterruptionType.duck:
        await player.setVolume(1.0);

        break;
      case AudioInterruptionType.pause:
      case AudioInterruptionType.unknown:
        if (!_pausedDueInterrupt) return;

        _pausedDueInterrupt = false;
        await player.play();

        break;
    }
  }
}
