import "dart:async";
import "dart:typed_data";
import "dart:ui" as ui;

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:material_color_utilities/material_color_utilities.dart";
import "package:material_color_utilities/scheme/scheme_fruit_salad.dart";
import "package:material_color_utilities/scheme/scheme_rainbow.dart";

import "logger.dart";

/// Процент того, сколько должен занимать единственный цвет ([ImageSchemeExtractor.shouldCastShadow]), что бы не позволить ему отбрасывать тень ("свечение").
const double shadowFrequentColorThreshold = 0.5;

/// Процент яркости ([Color.computeLuminance]), который проверяется с целью определения того, должна ли отбрасываться тень от обложки или нет.
const double shadowColorLiminanceThreshold = 0.25;

/// Класс, извлекающий цвета из обложек треков.
///
/// Главный метод здесь - [fromImageProvider].
class ImageSchemeExtractor {
  static final AppLogger logger = getLogger("ImageSchemeExtractor");

  /// [ColorScheme] типа [Brightness.light], созданный из цветов передаваемого изображения.
  final ColorScheme lightColorScheme;

  /// [ColorScheme] типа [Brightness.dark], созданный из цветов передаваемого изображения.
  final ColorScheme darkColorScheme;

  /// [Map] из извлечённых цветов обложки трека, где каждый цвет является типом [int], а так же количеством этого цвета.
  ///
  /// Не путай с [scoredColorInts] или [getScoredColors], здесь хранятся цвета до вызова метода [Score.score].
  ///
  /// Если Вам нужен список цветов типа [Color], то обратитесь к методу [getColors].
  final Map<int, int> colorInts;

  /// Отсортированный [List] из извлечённых цветов обложки трека.
  Map<Color, int> getColors() => colorInts.map(
        (int color, int count) => MapEntry<Color, int>(
          Color(
            color,
          ),
          count,
        ),
      );

  /// Отсортированный [List] из самых частых цветов в изображении, где каждый цвет является типом [int].
  ///
  /// Если Вам нужен список цветов типа [Color], то обратитесь к методу [getScoredColors].
  final List<int> scoredColorInts;

  /// Отсортированный [List] из самых частых цветов в изображении.
  List<Color> getScoredColors() =>
      scoredColorInts.map((int intColor) => Color(intColor)).toList();

  /// Самый частый цвет из всех цветов.
  final Color frequentColor;

  /// Количество повторений [frequentColor].
  final int frequentColorCount;

  /// Общее количество цветов (в том числе и дубликаты).
  final int colorCount;

  /// Вычисляет процент того, сколько занимает [frequentColor] от [colorCount].
  double get frequentColorPercentage => frequentColorCount / colorCount;

  // Указывает, должна ли эта обложка отбрасывать тень ("свечение").
  final bool shouldCastShadow;

  /// [Duration], которое было затрачено на преобразование [ImageProvider] в объект типа [ui.Image].
  final Duration resizeDuration;

  /// [Duration], которое было затрачено на получение цветов из изображения.
  final Duration quantizeDuration;

  /// Выдаёт [ColorScheme] в зависимости от передаваемого [Brightness].
  ColorScheme? colorScheme(Brightness brightness) {
    if (brightness == Brightness.dark) return darkColorScheme;

    return lightColorScheme;
  }

  ImageSchemeExtractor({
    required this.lightColorScheme,
    required this.darkColorScheme,
    required this.colorInts,
    required this.scoredColorInts,
    required this.frequentColor,
    required this.frequentColorCount,
    required this.colorCount,
    required this.shouldCastShadow,
    required this.resizeDuration,
    required this.quantizeDuration,
  });

  /// Преобразует [ImageProvider] в [ui.Image].
  static Future<ui.Image> _providerToImage(ImageProvider provider) async {
    final Completer<ui.Image> completer = Completer<ui.Image>();

    provider.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool synchronousCall) {
        if (completer.isCompleted) return;

        completer.complete(info.image);
      }),
    );

    return await completer.future;
  }

  static Future<ui.Image> _imageProviderToScaled(
    ImageProvider imageProvider,
  ) async {
    const double maxDimension = 112.0;
    final ImageStream stream = imageProvider.resolve(
      const ImageConfiguration(
        size: Size(
          maxDimension,
          maxDimension,
        ),
      ),
    );
    final Completer<ui.Image> imageCompleter = Completer<ui.Image>();
    late ImageStreamListener listener;
    late ui.Image scaledImage;
    Timer? loadFailureTimeout;

    listener = ImageStreamListener(
      (ImageInfo info, bool sync) async {
        loadFailureTimeout?.cancel();
        stream.removeListener(listener);
        final ui.Image image = info.image;
        final int width = image.width;
        final int height = image.height;
        double paintWidth = width.toDouble();
        double paintHeight = height.toDouble();
        assert(
          width > 0 && height > 0,
          "Both width and height must be positive",
        );

        final bool rescale = width > maxDimension || height > maxDimension;
        if (rescale) {
          paintWidth =
              (width > height) ? maxDimension : (maxDimension / height) * width;
          paintHeight =
              (height > width) ? maxDimension : (maxDimension / width) * height;
        }
        final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
        final Canvas canvas = Canvas(pictureRecorder);
        paintImage(
          canvas: canvas,
          rect: Rect.fromLTRB(0, 0, paintWidth, paintHeight),
          image: image,
          filterQuality: FilterQuality.none,
        );

        final ui.Picture picture = pictureRecorder.endRecording();
        scaledImage =
            await picture.toImage(paintWidth.toInt(), paintHeight.toInt());
        imageCompleter.complete(info.image);
      },
      onError: (Object exception, StackTrace? stackTrace) {
        stream.removeListener(listener);
        throw Exception("Failed to render image: $exception");
      },
    );

    loadFailureTimeout = Timer(
      const Duration(seconds: 5),
      () {
        stream.removeListener(listener);
        imageCompleter.completeError(
          TimeoutException("Timeout occurred trying to load image"),
        );
      },
    );

    stream.addListener(listener);
    await imageCompleter.future;
    return scaledImage;
  }

  static int _getArgbFromAbgr(int abgr) {
    const int exceptRMask = 0xFF00FFFF;
    const int onlyRMask = ~exceptRMask;
    const int exceptBMask = 0xFFFFFF00;
    const int onlyBMask = ~exceptBMask;
    final int r = (abgr & onlyRMask) >> 16;
    final int b = abgr & onlyBMask;

    return (abgr & exceptRMask & exceptBMask) | (b << 16) | r;
  }

  static DynamicScheme _buildDynamicScheme(
    Brightness brightness,
    Color seedColor,
    DynamicSchemeVariant schemeVariant,
  ) {
    final bool isDark = brightness == Brightness.dark;
    final Hct sourceColor = Hct.fromInt(seedColor.value);

    return switch (schemeVariant) {
      DynamicSchemeVariant.tonalSpot => SchemeTonalSpot(
          sourceColorHct: sourceColor,
          isDark: isDark,
          contrastLevel: 0.0,
        ),
      DynamicSchemeVariant.fidelity => SchemeFidelity(
          sourceColorHct: sourceColor,
          isDark: isDark,
          contrastLevel: 0.0,
        ),
      DynamicSchemeVariant.content => SchemeContent(
          sourceColorHct: sourceColor,
          isDark: isDark,
          contrastLevel: 0.0,
        ),
      DynamicSchemeVariant.monochrome => SchemeMonochrome(
          sourceColorHct: sourceColor,
          isDark: isDark,
          contrastLevel: 0.0,
        ),
      DynamicSchemeVariant.neutral => SchemeNeutral(
          sourceColorHct: sourceColor,
          isDark: isDark,
          contrastLevel: 0.0,
        ),
      DynamicSchemeVariant.vibrant => SchemeVibrant(
          sourceColorHct: sourceColor,
          isDark: isDark,
          contrastLevel: 0.0,
        ),
      DynamicSchemeVariant.expressive => SchemeExpressive(
          sourceColorHct: sourceColor,
          isDark: isDark,
          contrastLevel: 0.0,
        ),
      DynamicSchemeVariant.rainbow => SchemeRainbow(
          sourceColorHct: sourceColor,
          isDark: isDark,
          contrastLevel: 0.0,
        ),
      DynamicSchemeVariant.fruitSalad => SchemeFruitSalad(
          sourceColorHct: sourceColor,
          isDark: isDark,
          contrastLevel: 0.0,
        ),
    };
  }

  /// Создаёт [ColorScheme] по передаваемому [baseColor] и другим параметрам.
  ///
  /// Если у Вас нет [baseColor], то воспользуйтесь методом [fromImageProvider].
  static ColorScheme buildColorScheme(
    Color baseColor,
    Brightness brightness,
    DynamicSchemeVariant schemeVariant,
  ) {
    final DynamicScheme scheme = _buildDynamicScheme(
      brightness,
      baseColor,
      schemeVariant,
    );

    return ColorScheme(
      brightness: brightness,
      primary: Color(MaterialDynamicColors.primary.getArgb(scheme)),
      onPrimary: Color(MaterialDynamicColors.onPrimary.getArgb(scheme)),
      primaryContainer:
          Color(MaterialDynamicColors.primaryContainer.getArgb(scheme)),
      onPrimaryContainer:
          Color(MaterialDynamicColors.onPrimaryContainer.getArgb(scheme)),
      primaryFixed: Color(MaterialDynamicColors.primaryFixed.getArgb(scheme)),
      primaryFixedDim:
          Color(MaterialDynamicColors.primaryFixedDim.getArgb(scheme)),
      onPrimaryFixed:
          Color(MaterialDynamicColors.onPrimaryFixed.getArgb(scheme)),
      onPrimaryFixedVariant:
          Color(MaterialDynamicColors.onPrimaryFixedVariant.getArgb(scheme)),
      secondary: Color(MaterialDynamicColors.secondary.getArgb(scheme)),
      onSecondary: Color(MaterialDynamicColors.onSecondary.getArgb(scheme)),
      secondaryContainer:
          Color(MaterialDynamicColors.secondaryContainer.getArgb(scheme)),
      onSecondaryContainer:
          Color(MaterialDynamicColors.onSecondaryContainer.getArgb(scheme)),
      secondaryFixed:
          Color(MaterialDynamicColors.secondaryFixed.getArgb(scheme)),
      secondaryFixedDim:
          Color(MaterialDynamicColors.secondaryFixedDim.getArgb(scheme)),
      onSecondaryFixed:
          Color(MaterialDynamicColors.onSecondaryFixed.getArgb(scheme)),
      onSecondaryFixedVariant:
          Color(MaterialDynamicColors.onSecondaryFixedVariant.getArgb(scheme)),
      tertiary: Color(MaterialDynamicColors.tertiary.getArgb(scheme)),
      onTertiary: Color(MaterialDynamicColors.onTertiary.getArgb(scheme)),
      tertiaryContainer:
          Color(MaterialDynamicColors.tertiaryContainer.getArgb(scheme)),
      onTertiaryContainer:
          Color(MaterialDynamicColors.onTertiaryContainer.getArgb(scheme)),
      tertiaryFixed: Color(MaterialDynamicColors.tertiaryFixed.getArgb(scheme)),
      tertiaryFixedDim:
          Color(MaterialDynamicColors.tertiaryFixedDim.getArgb(scheme)),
      onTertiaryFixed:
          Color(MaterialDynamicColors.onTertiaryFixed.getArgb(scheme)),
      onTertiaryFixedVariant:
          Color(MaterialDynamicColors.onTertiaryFixedVariant.getArgb(scheme)),
      error: Color(MaterialDynamicColors.error.getArgb(scheme)),
      onError: Color(MaterialDynamicColors.onError.getArgb(scheme)),
      errorContainer:
          Color(MaterialDynamicColors.errorContainer.getArgb(scheme)),
      onErrorContainer:
          Color(MaterialDynamicColors.onErrorContainer.getArgb(scheme)),
      outline: Color(MaterialDynamicColors.outline.getArgb(scheme)),
      outlineVariant:
          Color(MaterialDynamicColors.outlineVariant.getArgb(scheme)),
      surface: Color(MaterialDynamicColors.surface.getArgb(scheme)),
      surfaceDim: Color(MaterialDynamicColors.surfaceDim.getArgb(scheme)),
      surfaceBright: Color(MaterialDynamicColors.surfaceBright.getArgb(scheme)),
      surfaceContainerLowest:
          Color(MaterialDynamicColors.surfaceContainerLowest.getArgb(scheme)),
      surfaceContainerLow:
          Color(MaterialDynamicColors.surfaceContainerLow.getArgb(scheme)),
      surfaceContainer:
          Color(MaterialDynamicColors.surfaceContainer.getArgb(scheme)),
      surfaceContainerHigh:
          Color(MaterialDynamicColors.surfaceContainerHigh.getArgb(scheme)),
      surfaceContainerHighest:
          Color(MaterialDynamicColors.surfaceContainerHighest.getArgb(scheme)),
      onSurface: Color(MaterialDynamicColors.onSurface.getArgb(scheme)),
      onSurfaceVariant:
          Color(MaterialDynamicColors.onSurfaceVariant.getArgb(scheme)),
      inverseSurface:
          Color(MaterialDynamicColors.inverseSurface.getArgb(scheme)),
      onInverseSurface:
          Color(MaterialDynamicColors.inverseOnSurface.getArgb(scheme)),
      inversePrimary:
          Color(MaterialDynamicColors.inversePrimary.getArgb(scheme)),
      shadow: Color(MaterialDynamicColors.shadow.getArgb(scheme)),
      scrim: Color(MaterialDynamicColors.scrim.getArgb(scheme)),
      surfaceTint: Color(MaterialDynamicColors.primary.getArgb(scheme)),
    );
  }

  /// Извлекает [ColorScheme], а так же цвета из передаваемого [ImageProvider].
  ///
  /// Является модифицированной версией метода [ColorScheme.fromImageProvider], которая выполняет некоторые части в отдельном Isolate для улучшенной производительности.
  static Future<ImageSchemeExtractor> fromImageProvider(
    ImageProvider provider, {
    DynamicSchemeVariant schemeVariant = DynamicSchemeVariant.tonalSpot,
    bool resizeImage = false,
  }) async {
    // Получаем объект типа [ui.Image], из которого уже можно извлекать цвета.
    final Stopwatch scaleWatch = Stopwatch()..start();
    final ui.Image scaledImage = await (resizeImage
        ? _imageProviderToScaled(provider)
        : _providerToImage(provider));

    // Получаем байты из объекта изображения.
    scaleWatch.stop();
    final Stopwatch quantizerTimer = Stopwatch()..start();
    final Uint32List imageBytes =
        (await scaledImage.toByteData())!.buffer.asUint32List();

    // Получаем объект, состоящий из:
    // - ColorScheme светлый,
    // - ColorScheme тёмный,
    // - Map<Color, количество цветов>,
    // - List<int> scored-цвета,
    // - Самый частый Color,
    // - Количество повторений этого частого Color,
    // - Общее количество цветов,
    // - bool, отображающий то, нужно ли отбрасывать тень ("свечение").
    final (
      ColorScheme,
      ColorScheme,
      Map<int, int>,
      List<int>,
      Color,
      int,
      int,
      bool,
    ) result = await compute(
      (Uint32List bytes) async {
        // Производим Quantizer.
        final QuantizerResult quantizerResult =
            await QuantizerCelebi().quantize(
          bytes,
          128,
          returnInputPixelToClusterPixel: true,
        );
        final Map<int, int> colorToCount = quantizerResult.colorToCount.map(
          (int key, int value) =>
              MapEntry<int, int>(_getArgbFromAbgr(key), value),
        );

        // Получаем список из самых "частых" цветов.
        final List<int> scoredResults = Score.score(
          colorToCount,
          desired: 12,
        );
        final ui.Color baseColor = Color(
          scoredResults.first,
        );

        // Создаём светлую и тёмную цветовые схемы.
        final ColorScheme lightColorScheme =
            buildColorScheme(baseColor, Brightness.light, schemeVariant);
        final ColorScheme darkColorScheme =
            buildColorScheme(baseColor, Brightness.dark, schemeVariant);

        // Ищем самый частый цвет из всех цветов, а так же общее количество цветов.
        int totalColors = 0;
        int largestColorCount = 0;
        int mostFrequentColor = 0;
        for (int color in colorToCount.keys) {
          final int count = colorToCount[color]!;

          totalColors += count;
          if (count > largestColorCount) {
            largestColorCount = count;
            mostFrequentColor = color;
          }
        }

        // Вычисляем то, нужно ли нам отображать тень ("свечение") от этой обложки в зависимости от цветов.
        final double frequentColorPercentage = largestColorCount / totalColors;
        final Color frequentColor = Color(mostFrequentColor);
        final bool shouldCastShadow = frequentColorPercentage <
                shadowFrequentColorThreshold ||
            frequentColor.computeLuminance() > shadowColorLiminanceThreshold;

        return (
          lightColorScheme,
          darkColorScheme,
          colorToCount,
          scoredResults,
          frequentColor,
          largestColorCount,
          totalColors,
          shouldCastShadow,
        );
      },
      imageBytes,
    );

    quantizerTimer.stop();
    return ImageSchemeExtractor(
      lightColorScheme: result.$1,
      darkColorScheme: result.$2,
      colorInts: result.$3,
      scoredColorInts: result.$4,
      frequentColor: result.$5,
      frequentColorCount: result.$6,
      colorCount: result.$7,
      shouldCastShadow: result.$8,
      resizeDuration: scaleWatch.elapsed,
      quantizeDuration: quantizerTimer.elapsed,
    );
  }
}
