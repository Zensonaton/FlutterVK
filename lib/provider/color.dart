import "package:flutter/material.dart";

/// Provider для хранения цветовой схемы приложения, зависящая от обложки текущего трека.
///
/// Использование:
/// ```dart
/// final PlayerSchemeProvider scheme = Provider.of<PlayerSchemeProvider>(context, listen: false);
/// ```
///
/// Если Вы хотите получить цветовую схему в контексте интерфейса Flutter, и хотите, что бы интерфейс сам обновлялся при изменении полей, то используйте следующий код:
/// ```dart
/// final PlayerSchemeProvider scheme = Provider.of<PlayerSchemeProvider>(context);
/// ```
class PlayerSchemeProvider extends ChangeNotifier {
  String? _mediaKey;

  ColorScheme? _lightColorScheme;
  ColorScheme? _darkColorScheme;

  /// Выдаёт последний известный [ColorScheme] яркости [Brightness.light].
  ColorScheme? get lightColorScheme => _lightColorScheme;

  /// Выдаёт последний известный [ColorScheme] яркости [Brightness.dark].
  ColorScheme? get darkColorScheme => _darkColorScheme;

  /// Возвращает [ColorScheme] в зависимости от параметра [brightness].
  ColorScheme? colorScheme(Brightness brightness) =>
      brightness == Brightness.light ? lightColorScheme : darkColorScheme;

  /// Выдаёт [Audio.mediaKey], с которым ассоциирован последний [lightColorScheme] или [darkColorScheme].
  String? get mediaKey => _mediaKey;

  /// Изменяет передаваемый [scheme], посылая изменения всему интерфейсу приложения. [mediaKey] используется для защиты от повторного вызова [notifyListeners].
  void setScheme(
    ColorScheme lightScheme,
    ColorScheme darkScheme,
    String mediaKey,
  ) {
    _lightColorScheme = lightScheme;
    _darkColorScheme = darkScheme;

    // Посылаем обновления лишь в том случае, если mediaKey изменился, т.е., изменилась обложка трека.
    if (_mediaKey != mediaKey) {
      notifyListeners();
    }
    _mediaKey = mediaKey;
  }
}
