import "dart:async";

import "package:flutter/material.dart";

import "../../../main.dart";
import "../../../provider/l18n.dart";
import "../../logger.dart";
import "../player.dart";
import "../subscriber.dart";

/// Класс подписчика на события [Player] для обработки событий ошибок.
class ErrorsHandlerPlayerSubscriber extends PlayerSubscriber {
  /// Время, через которое может сброситься счётчик ошибок.
  static const Duration errorsResetTimerDuration = Duration(minutes: 5);

  /// Максимальное количество ошибок за [errorsResetTimerDuration].
  static const int maxErrorsCount = 5;

  static final AppLogger logger = getLogger("ErrorsHandlerPlayerSubscriber");

  ErrorsHandlerPlayerSubscriber(Player player)
      : super("Errors handler", player);

  @override
  List<StreamSubscription> subscribe(Player player) {
    return [
      player.isLoadedStream.listen(onIsLoaded),
      player.errorStream.listen(onError),
    ];
  }

  /// Количество ошибок за эту сессию воспроизведения.
  int _errorsCount = 0;

  /// Последнее время возникновения ошибки.
  DateTime? _lastErrorTime;

  /// Добавляет ошибку в счётчик ошибок.
  void _addError() {
    if (_lastErrorTime != null &&
        DateTime.now().difference(_lastErrorTime!) > errorsResetTimerDuration) {
      logger.d("Resetting errors count");

      _errorsCount = 0;
    }

    _errorsCount++;
    _lastErrorTime = DateTime.now();
  }

  /// События запуска плеера.
  void onIsLoaded(bool isLoaded) async {
    if (!isLoaded) return;

    _errorsCount = 0;
  }

  /// Обработка ошибок в плеере.
  void onError(String message) {
    final l18n = player.ref.read(l18nProvider);
    final messenger = navigatorKey.currentContext != null
        ? ScaffoldMessenger.maybeOf(navigatorKey.currentContext!)
        : null;

    logger.e(message);

    _addError();
    logger.d("Errors count: $_errorsCount/$maxErrorsCount");

    final snackBarContent = _errorsCount >= maxErrorsCount
        ? l18n.player_playback_error(error: message)
        : l18n.player_playback_error_stopped(error: message);

    if (_errorsCount >= maxErrorsCount) {
      player.stop();
    }

    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          snackBarContent,
        ),
      ),
    );
  }
}
