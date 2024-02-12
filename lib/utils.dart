import "dart:io";
import "dart:math";
import "dart:ui";

import "package:diacritic/diacritic.dart";
import "package:flutter/material.dart";

/// Извлекает access-токен из строки.
String? extractAccessToken(String input) {
  // Если строка начинается на vk1, то считаем, что это готовый access-токен.
  if (input.startsWith("vk1")) {
    return input;
  }

  Match? tokenMatch = RegExp(
    r"access_token=([^&]+)",
  ).firstMatch(
    input,
  );

  // Если ничего не найдено, то возвращаем null.
  if (tokenMatch == null) return null;

  String token = tokenMatch.group(1).toString();

  // Если токен не начинается на `vk1`, то возвращаем null.
  if (!token.startsWith("vk1")) return null;

  return token;
}

/// Класс для отображения страницы с навигацией.
///
/// Используется для простого mapping'а страниц, их иконок и названий.
class NavigationPage {
  /// Текст, используемый в [BottomNavigationBar].
  final String label;

  /// Иконка, которая используется на [BottomNavigationBar].
  final IconData icon;

  /// Иконка, которая используется при выборе элемента в [BottomNavigationBar]. Если не указано, то будет использоваться [icon].
  final IconData? selectedIcon;

  /// Route (страница), которая будет отображена при выборе этого элемента в [BottomNavigationBar].
  final Widget route;

  /// Указывает, в какой части экрана должен находиться аудиоплеер (в desktop-режиме) при выборе данного элемента.
  final Alignment audioPlayerAlign;

  /// Если true, то аудиоплеер (в desktop-режиме) сможет быть "больших" размеров.
  final bool allowBigAudioPlayer;

  /// [GlobalKey] для [Navigator]'а, используемый для этого Route.
  final GlobalKey<NavigatorState> navigatorKey;

  NavigationPage({
    required this.label,
    required this.icon,
    this.selectedIcon,
    required this.route,
    this.audioPlayerAlign = Alignment.bottomCenter,
    this.allowBigAudioPlayer = true,
  }) : navigatorKey = GlobalKey<NavigatorState>(
          debugLabel: label,
        );
}

/// Понижает яркость цвета.
Color darkenColor(Color color, double factor) {
  factor = 1.0 - (factor / 100.0); // convert percentage to fraction

  int red = (color.red * factor).round();
  int green = (color.green * factor).round();
  int blue = (color.blue * factor).round();

  red = max(0, red);
  green = max(0, green);
  blue = max(0, blue);

  return Color.fromARGB(color.alpha, red, green, blue);
}

/// Повышает яркость цвета.
Color lightenColor(Color color, double factor) {
  factor = 1.0 + (factor / 100.0); // convert percentage to fraction

  int red = (color.red * factor).round();
  int green = (color.green * factor).round();
  int blue = (color.blue * factor).round();

  red = min(255, red);
  green = min(255, green);
  blue = min(255, blue);

  return Color.fromARGB(color.alpha, red, green, blue);
}

/// Преобразовывает передаваемое значение количества секунд в строку вида `MM:SS`
String secondsAsString(int seconds) {
  if (seconds <= 0) return "00:00";

  final Duration duration = Duration(seconds: seconds);
  final String hrs = (duration.inHours).toString().padLeft(2, "0");
  final String mins = (duration.inMinutes % 60).toString().padLeft(2, "0");
  final String scnds = (duration.inSeconds % 60).toString().padLeft(2, "0");

  if (seconds >= 3600) return "$hrs:$mins:$scnds";

  return "$mins:$scnds";
}

int clampInt(int x, int min, int max) {
  if (x < min) return min;
  if (x > max) return max;

  return x;
}

/// Минимизирует JavaScript-код.
String minimizeJS(String input) {
  // Удаляем комментарии.
  input = input.replaceAll(RegExp(r"\/\/[^\n]*"), "");

  // Удаляем пробелы а так же переходы строк.
  input = input.replaceAll(RegExp(r"\s+"), " ");

  // Удаляем лишние переходы строк.
  input = input.replaceAll(RegExp(r"\n+"), "\n");

  return input;
}

/// Превращает входное значение [value] типа [int] в [bool].
bool boolFromInt(int value) => value == 1;

/// Превращает входное значение [value] типа [bool] в [int].
int intFromBool(bool value) => value ? 1 : 0;

/// Превращает входную строку [value] типа [String] в [DateTime].
DateTime? datetimeFromString(String? value) {
  if (value == null) return null;

  return DateTime.tryParse(value);
}

/// Превращает входную строку [value] типа [DateTime] в [String].
String stringFromdatetime(DateTime value) => value.toIso8601String();

/// Класс, заставляющий любые Scrollable-виджеты скроллиться даже на Desktop-плафтормах.
class AlwaysScrollableScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

/// Указывает, что приложение запущено на Desktop-платформе.
bool get isDesktop =>
    Platform.isWindows || Platform.isLinux || Platform.isMacOS;

/// Указывает, что приложение запущено на мобильной платформе.
bool get isMobile => Platform.isAndroid || Platform.isIOS;

/// Небольшой класс для создания виджетов класса [Slider] без Padding'ов.
///
/// Пример использования:
/// ```dart
/// SliderTheme(
///   data: SliderThemeData(
///     trackShape: CustomTrackShape(),
///   ),
///   child: Slider(...),
/// ),
/// ```
class CustomTrackShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    Offset offset = Offset.zero,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight!;
    final double trackLeft = offset.dx;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;

    return Rect.fromLTWH(
      trackLeft,
      trackTop,
      trackWidth,
      trackHeight,
    );
  }
}

/// Делает входную строку [input] «чище», очищая лишние символы, делая строку lowercase, а так же заменяя диакритические символы.
String cleanString(String input) {
  const List<String> toRemove = [
    " ",
    "-",
    ",",
    ".",
    "`",
    "'",
    "(",
    ")",
    "[",
    "]",
    "_"
  ];

  input = input.toLowerCase();

  for (String char in toRemove) {
    input = input.replaceAll(char, "");
  }

  return removeDiacritics(input);
}

extension RandomListItem<T> on List<T> {
  /// Возвращает случайный элемент из данного [List].
  T randomItem() {
    return this[Random().nextInt(length)];
  }
}
