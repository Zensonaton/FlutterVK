import "dart:convert";
import "dart:io";
import "dart:math";
import "dart:ui";

import "package:crypto/crypto.dart";
import "package:diacritic/diacritic.dart";
import "package:dynamic_color/dynamic_color.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:go_router/go_router.dart";
import "package:responsive_builder/responsive_builder.dart";
import "package:window_manager/window_manager.dart";

import "consts.dart";
import "enums.dart";
import "l10n/app_localizations.dart";
import "main.dart";
import "provider/user.dart";

/// Класс для отображения Route'ов в [BottomNavigationBar], вместе с их названиями, а так же иконками.
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

  /// Если true, то аудиоплеер (в Desktop Layout'е) сможет быть "больших" размеров.
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

/// Извлекает Access токен ВКонтакте из передаваемой строки [input].
String? extractAccessToken(String input) {
  // Если строка начинается на vk1, то считаем, что это готовый Access токен.
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

/// Преобразовывает передаваемое значение количества секунд в строку вида `MM:SS`.
///
/// Примеры:
/// - 0 -> `00:00`
/// - 5 -> `00:05`
/// - 61 -> `01:01`
String durationAsString(Duration duration) {
  final String mins = (duration.inMinutes % 60).toString().padLeft(2, "0");
  final String scnds = (duration.inSeconds % 60).toString().padLeft(2, "0");

  if (duration.inHours >= 1) {
    final String hrs = (duration.inHours).toString().padLeft(2, "0");

    return "$hrs:$mins:$scnds";
  }

  return "$mins:$scnds";
}

/// Ограничивает передавамое значение [value] в пределах от [min] до [max].
int clampInt(int value, int min, int max) {
  if (value < min) return min;
  if (value > max) return max;

  return value;
}

/// Минимизирует JavaScript-код.
///
/// Данный метод удаляет комментарии, символы пробелов и табуляции, а так же удаляет символы перехода строк.
String minimizeJS(String input) {
  // Удаляем комментарии.
  input = input.replaceAll(RegExp(r"\/\/[^\n]*"), "");

  // Удаляем табуляцию/пробелы.
  input = input.replaceAll(RegExp(r"\s+"), " ");

  // Удаляем лишние переходы строк.
  input = input.replaceAll(RegExp(r"\n+"), "\n");

  return input;
}

/// Превращает входное значение [value] типа [int] в [bool].
///
/// Значения типа null интерпритируются как false.
bool boolFromInt(int? value) {
  if (value == null) return false;

  return value != 0;
}

/// Превращает входное значение [value] типа [bool] в [int].
int intFromBool(bool value) => value ? 1 : 0;

/// Превращает входную строку [value] типа [String] в [DateTime].
DateTime? datetimeFromString(String? value) {
  if (value == null) return null;

  return DateTime.tryParse(value);
}

/// Превращает входную строку [value] типа [DateTime] в [String].
String stringFromdatetime(DateTime value) => value.toIso8601String();

/// Превращает входное значение [value] типа [Enum] в [int].
int intFromEnum(Enum value) => value.index;

/// Превращает пустую строку ([String.isEmpty]) в null, либо возвращает тот же объект строки.
String? emptyStringAsNull(String? value) {
  if (value == null || value.isEmpty) return null;

  return value;
}

/// Класс, заставляющий любые Scrollable-виджеты скроллиться даже на Desktop-плафтормах.
class AlwaysScrollableScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices {
    return {
      PointerDeviceKind.touch,
      PointerDeviceKind.mouse,
    };
  }
}

/// Указывает, что приложение запущено на Web.
bool get isWeb => kIsWeb;

/// Указывает, что приложение запущено на Windows.
bool get isWindows => !isWeb && Platform.isWindows;

/// Указывает, что приложение запущено на Linux.
bool get isLinux => !isWeb && Platform.isWindows;

/// Указывает, что приложение запущено на macOS.
bool get isMacOS => !isWeb && Platform.isMacOS;

/// Указывает, что приложение запущено на Android.
bool get isAndroid => !isWeb && Platform.isAndroid;

/// Указывает, что приложение запущено на iOS
bool get isiOS => !isWeb && Platform.isIOS;

/// Указывает, что приложение запущено на Desktop-платформе.
///
/// ```dart
/// Platform.isWindows || Platform.isLinux || Platform.isMacOS
/// ```
bool get isDesktop =>
    !isWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

/// Указывает, что приложение запущено на мобильной платформе.
///
/// ```dart
/// Platform.isAndroid || Platform.isIOS
/// ```
bool get isMobile => !isWeb && (Platform.isAndroid || Platform.isIOS);

/// Указывает, что используется Mobile Layout.
bool isMobileLayout(BuildContext context) =>
    getDeviceType(MediaQuery.sizeOf(context)) == DeviceScreenType.mobile;

/// Указывает, что используется Desktop Layout.
bool isDesktopLayout(BuildContext context) =>
    getDeviceType(MediaQuery.sizeOf(context)) == DeviceScreenType.desktop;

/// Указывает, что используется светлая тема ([Brightness.light]).
bool isLightTheme(BuildContext context) =>
    Theme.of(context).brightness == Brightness.light;

/// Указывает, что используется тёмная тема ([Brightness.dark]).
bool isDarkTheme(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

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
///
/// Используется для поиска треков.
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
    "_",
  ];

  input = input.toLowerCase();

  for (String char in toRemove) {
    input = input.replaceAll(char, "");
  }

  return removeDiacritics(input);
}

/// Возвращает строку, описывающую тип плейлиста в зависимости от его [ExtendedPlaylist.type].
String getPlaylistTypeString(AppLocalizations l18n, ExtendedPlaylist playlist) {
  switch (playlist.type) {
    case PlaylistType.favorites:
      return l18n.general_owned_playlist;

    case PlaylistType.searchResults:
    case PlaylistType.mood:
    case PlaylistType.audioMix:
    case PlaylistType.recommendations:
    case PlaylistType.simillar:
    case PlaylistType.madeByVK:
      return l18n.general_recommended_playlist;

    case PlaylistType.regular:
      return l18n.general_saved_playlist;
  }
}

/// Возвращает SHA256 хэш из передаваемой строки.
String sha256String(String str) => sha256
    .convert(
      utf8.encode(str),
    )
    .toString();

/// Возвращает UNIX-timestamp, отображающий количество секунд, прошедших с 1 января 1970 года.
int getUnixTimestamp() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

/// Производит шифрование байтов [input] при помощи XOR-шифрования с ключом [key].
///
/// Дешифровка производится так же, как и шифровка, поскольку XOR-шифрование является симметричным.
Uint8List xorCrypt(Uint8List input, Uint8List key) {
  final List<int> output = List<int>.filled(input.length, 0);

  for (int i = 0; i < input.length; i++) {
    output[i] = input[i] ^ key[i % key.length];
  }

  return Uint8List.fromList(output);
}

/// Isolated-версия метода [xorCrypt].
Future<Uint8List> xorCryptIsolate(Uint8List input, Uint8List key) => compute(
      (input) => xorCrypt(input, key),
      input,
    );

/// Создаёт две [ColorScheme]: [Brightness.light] и [Brightness.dark] из передаваемых от [DynamicColorBuilder] цветов.
///
/// Данный метод нужен для "исправления" цветов, передаваемых [DynamicColorBuilder]'ом, поскольку [DynamicColorBuilder] не поддерживает новые [ColorScheme], ввиду чего итоговый [ColorScheme] имеет тёмные оттенки.
///
/// Код взят и адаптирован из комментария Github Issue:
/// https://github.com/material-foundation/flutter-packages/issues/582#issuecomment-2081174158
(ColorScheme light, ColorScheme dark) generateDynamicColorSchemes(
  ColorScheme lightDynamic,
  ColorScheme darkDynamic,
) {
  // FIXME: Проверить, нужен ли этот костыль?

  List<Color> extractAdditionalColors(
    ColorScheme scheme,
  ) =>
      [
        scheme.surface,
        scheme.surfaceDim,
        scheme.surfaceBright,
        scheme.surfaceContainerLowest,
        scheme.surfaceContainerLow,
        scheme.surfaceContainer,
        scheme.surfaceContainerHigh,
        scheme.surfaceContainerHighest,
      ];

  ColorScheme insertAdditionalColors(
    ColorScheme scheme,
    List<Color> additionalColors,
  ) =>
      scheme.copyWith(
        surface: additionalColors[0],
        surfaceDim: additionalColors[1],
        surfaceBright: additionalColors[2],
        surfaceContainerLowest: additionalColors[3],
        surfaceContainerLow: additionalColors[4],
        surfaceContainer: additionalColors[5],
        surfaceContainerHigh: additionalColors[6],
        surfaceContainerHighest: additionalColors[7],
      );

  var lightBase = ColorScheme.fromSeed(seedColor: lightDynamic.primary);
  var darkBase = ColorScheme.fromSeed(
    seedColor: darkDynamic.primary,
    brightness: Brightness.dark,
  );

  var lightAdditionalColors = extractAdditionalColors(lightBase);
  var darkAdditionalColours = extractAdditionalColors(darkBase);

  var lightScheme = insertAdditionalColors(lightBase, lightAdditionalColors);
  var darkScheme = insertAdditionalColors(darkBase, darkAdditionalColours);

  return (lightScheme.harmonized(), darkScheme.harmonized());
}

/// Возвращает самое большое значение горизонтального Padding'а (т.е.. [MediaQuery.paddingOf] left или right).
double getHorizontalPadding(BuildContext context) {
  return max(
    MediaQuery.paddingOf(context).left,
    MediaQuery.paddingOf(context).right,
  );
}

/// Возвращает самое большое значение вертикального Padding'а (т.е.. [MediaQuery.paddingOf] top или bottom).
double getVerticalPadding(BuildContext context) {
  return max(
    MediaQuery.paddingOf(context).top,
    MediaQuery.paddingOf(context).bottom,
  );
}

/// Возвращает EdgeInsets, который учитывает Padding'и ([MediaQuery.paddingOf]), а так же пользовательские значения.
EdgeInsets getPadding(
  BuildContext context, {
  bool useLeft = true,
  bool useRight = true,
  bool useTop = true,
  bool useBottom = true,
  EdgeInsets? custom,
}) {
  final EdgeInsets padding = MediaQuery.paddingOf(context);

  if (custom != null) {
    return EdgeInsets.only(
      left: useLeft ? max(padding.left, custom.left) : 0,
      right: useRight ? max(padding.right, custom.right) : 0,
      top: useTop ? max(padding.top, custom.top) : 0,
      bottom: useBottom ? max(padding.bottom, custom.bottom) : 0,
    );
  }

  return EdgeInsets.only(
    left: useLeft ? padding.left : 0,
    right: useRight ? padding.right : 0,
    top: useTop ? padding.top : 0,
    bottom: useBottom ? padding.bottom : 0,
  );
}

/// Устанавливает название для окна приложения на Desktop-платформах.
Future<void> setWindowTitle({String? title}) async {
  if (!isDesktop) {
    throw UnsupportedError(
      "This method is only supported on Desktop platforms.",
    );
  }

  if (title == null) {
    await windowManager.setTitle(
      kDebugMode ? "$appName (DEBUG)" : appName,
    );

    return;
  }

  await windowManager.setTitle(title);
}

/// Указывает, что текущий [AppLifecycleState] является активным, т.е., приложение не свёрнуто.
bool isLifecycleActive() => [
      AppLifecycleState.resumed,
      AppLifecycleState.inactive,
    ].contains(WidgetsBinding.instance.lifecycleState);

/// Перекидывает на route полноэкранного плеера (`/player`), если он не открыт.
void openPlayerRouteIfNotOpened(BuildContext context) {
  final path = GoRouter.of(context).state.fullPath;
  if (path == "/player") return;

  context.push("/player");
}

/// Возвращает версию приложения в виде строки вида:
/// - `v1.0.0 (Debug)`
/// - `v0.6.9 (бета)`
/// - `v1.0.0`
String getAppVersion(
  AppLocalizations l18n, {
  bool prefixWithV = true,
  bool addSuffix = true,
}) {
  String version = appVersion;
  if (prefixWithV) {
    version = "v$version";
  }

  if (addSuffix) {
    final List<String> suffixes = [];
    if (isPrerelease) {
      suffixes.add(l18n.app_version_prerelease);
    }
    if (kDebugMode) {
      suffixes.add("DEBUG");
    }

    if (suffixes.isNotEmpty) {
      version += " (${suffixes.join(", ")})";
    }
  }

  return version;
}
