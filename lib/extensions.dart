import "dart:math";
import "dart:ui";

extension RandomListItem<T> on List<T> {
  /// Возвращает случайный элемент из данного [List].
  T randomItem() {
    return this[Random().nextInt(length)];
  }
}

extension RandomSetItem<T> on Set<T> {
  /// Возвращает случайный элемент из данного [Set].
  T randomItem() {
    return elementAt(Random().nextInt(length));
  }
}

extension HexColor on Color {
  // Код взят со StackOverflow:
  // https://stackoverflow.com/a/50081214/15227244

  /// Возвращает объект [Color] из Hex-цвета вида `aabbcc` или `ffaabbcc`.
  static Color fromHex(
    String hexString,
  ) {
    final buffer = StringBuffer();

    if (hexString.length == 6 || hexString.length == 7) buffer.write("ff");
    buffer.write(hexString.replaceFirst("#", ""));

    return Color(
      int.parse(
        buffer.toString(),
        radix: 16,
      ),
    );
  }

  /// Конвертирует данный объект [Color] в строку Hex-цвета.
  ///
  /// Если [leadingHashSign] правдив, то данный метод добавит символ хэша (`#`).
  String toHex({
    bool leadingHashSign = true,
  }) {
    final String a = alpha.toRadixString(16).padLeft(2, "0");
    final String r = red.toRadixString(16).padLeft(2, "0");
    final String g = green.toRadixString(16).padLeft(2, "0");
    final String b = blue.toRadixString(16).padLeft(2, "0");

    if (leadingHashSign) {
      return "#$a$r$g$b";
    }

    return "$a$r$g$b";
  }
}

extension ColorBrightness on Color {
  /// Понижает яркость передаваемого цвета [color] на процент [factor], значение которого - число от `0.0` (т.е., никакого изменения) до `1.0` (т.е., максимальное затемнение цвета).
  Color darken(double factor) {
    assert(
      factor >= 0.0 && factor <= 1.0,
      "Expected factor to be in range of 0.0 to 1.0, but got $factor instead",
    );

    if (factor == 0.0) {
      return this;
    }

    factor = 1.0 - factor;

    final int r = max(
      0,
      (red * factor).round(),
    );
    final int g = max(
      0,
      (green * factor).round(),
    );
    final int b = max(
      0,
      (blue * factor).round(),
    );

    return Color.fromARGB(
      alpha,
      r,
      g,
      b,
    );
  }

  /// Повышает яркость передаваемого цвета [color] на процент [factor], значение которого - число от `0.0` (т.е., никакого изменения) до `1.0` (т.е., максимальное засветление цвета).
  Color lighten(double factor) {
    assert(
      factor >= 0.0 && factor <= 1.0,
      "Expected factor to be in range of 0.0 to 1.0, but got $factor instead",
    );

    if (factor == 0.0) {
      return this;
    }

    factor = 1.0 + factor;

    final int r = min(
      255,
      (red * factor).round(),
    );
    final int g = min(
      255,
      (green * factor).round(),
    );
    final int b = min(
      255,
      (blue * factor).round(),
    );

    return Color.fromARGB(
      alpha,
      r,
      g,
      b,
    );
  }
}
