import "package:flutter/material.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../enums.dart";
import "../services/image_to_color_scheme.dart";
import "../services/logger.dart";
import "preferences.dart";

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

    state = await ImageSchemeExtractor.fromImageProvider(
      provider,
      schemeVariant: {
        DynamicSchemeType.tonalSpot: DynamicSchemeVariant.tonalSpot,
        DynamicSchemeType.neutral: DynamicSchemeVariant.neutral,
        DynamicSchemeType.content: DynamicSchemeVariant.content,
        DynamicSchemeType.monochrome: DynamicSchemeVariant.monochrome,
      }[ref.read(preferencesProvider).dynamicSchemeType]!,
    );
    logger.d(
      "Took ${watch.elapsedMilliseconds}ms to create ColorScheme from image (resize ${state!.resizeDuration.inMilliseconds}ms, qzer (Isolated): ${state!.quantizeDuration.inMilliseconds}ms)",
    );

    return state!;
  }
}
