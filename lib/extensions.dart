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

    return Color.fromARGB(
      (a * 255).toInt(),
      max(
        0,
        (r * factor * 255).toInt(),
      ),
      max(
        0,
        (g * factor * 255).toInt(),
      ),
      max(
        0,
        (b * factor * 255).toInt(),
      ),
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

    return Color.fromARGB(
      (a * 255).toInt(),
      min(
        255,
        (r * factor * 255).toInt(),
      ),
      min(
        255,
        (g * factor * 255).toInt(),
      ),
      min(
        255,
        (b * factor * 255).toInt(),
      ),
    );
  }
}
