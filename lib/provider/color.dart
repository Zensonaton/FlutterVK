import "package:flutter/material.dart";

/// Provider для хранения цветовой схемы приложения, зависящая от обложки текущего трека.
///
/// Использование:
/// ```dart
/// final PlayerSchemeProvider scheme = Provider.of<PlayerSchemeProvider>(context, listen: false);
/// print(user.id);
/// ```
///
/// Если Вы хотите получить цветовую схему в контексте интерфейса Flutter, и хотите, что бы интерфейс сам обновлялся при изменении полей, то используйте следующий код:
/// ```dart
/// final PlayerSchemeProvider scheme = Provider.of<PlayerSchemeProvider>(context);
/// ```
class PlayerSchemeProvider extends ChangeNotifier {
  ColorScheme? _colorScheme;

  String? _mediaKey;

  /// Выдаёт последний известный [ColorScheme].
  ColorScheme? get colorScheme => _colorScheme;

  /// Выдаёт [Audio.mediaKey], с которым ассоциирован последний [colorScheme].
  String? get mediaKey => _mediaKey;

  /// Изменяет передаваемый [scheme], посылая изменения всему интерфейсу приложения. [mediaKey] используется для защиты от повторного вызова [notifyListeners].
  void setScheme(
    ColorScheme? scheme, {
    String? mediaKey,
  }) {
    if (scheme != null) {
      assert(
        mediaKey != null,
        "setScheme() requires cacheMediaKey to be non-null when scheme is specified",
      );
    }

    _colorScheme = scheme;

    // Посылаем обновления лишь в том случае, если mediaKey изменился, т.е., изменилась обложка трека.
    if (_mediaKey != mediaKey || scheme == null) {
      notifyListeners();
    }
    _mediaKey = mediaKey;
  }
}
