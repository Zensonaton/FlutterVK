import "package:flutter/material.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../services/image_to_color_scheme.dart";
import "../services/logger.dart";

part "color.g.dart";

/// [Provider], который извлекает цветовые схемы из передаваемого изображения трека.
@riverpod
class TrackSchemeInfo extends _$TrackSchemeInfo {
  static final AppLogger logger = getLogger("TrackImageInfo");

  @override
  ImageSchemeExtractor? build() => null;

  /// Создаёт цветовые схемы из передаваемого [provider], обновляя [state] данного объекта.
  Future<ImageSchemeExtractor> fromImageProvider(ImageProvider provider) async {
    final Stopwatch watch = Stopwatch()..start();

    state = await ImageSchemeExtractor.fromImageProvider(provider);
    logger.d(
      "Took ${watch.elapsedMilliseconds}ms to create ColorScheme from image (resize ${state!.resizeDuration?.inMilliseconds}ms, qzer (Isolated): ${state!.quantizeDuration?.inMilliseconds}ms)",
    );

    return state!;
  }

  /// Обновляет [state] данного объекта по передаваемым цветам, ранее извлечённых при помощи метода [fromImageProvider].
  Future<ImageSchemeExtractor> fromColors({
    required Map<int, int?> colorInts,
    required List<int> scoredColorInts,
    required int frequentColorInt,
    required int colorCount,
  }) async {
    state = ImageSchemeExtractor(
      colorInts: colorInts,
      scoredColorInts: scoredColorInts,
      frequentColorInt: frequentColorInt,
      colorCount: colorCount,
    );

    return state!;
  }
}
