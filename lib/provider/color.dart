import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../services/cache_manager.dart";
import "../services/image_to_color_scheme.dart";
import "../services/logger.dart";
import "playlists.dart";
import "user.dart";

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
    );
    logger.d(
      "${watch.elapsedMilliseconds}ms to create ColorScheme (quazer: ${state!.quantizeDuration?.inMilliseconds}ms)",
    );

    return state!;
  }

  /// Обновляет [state] данного объекта по передаваемому [ImageSchemeExtractor].
  void fromExtractor(ImageSchemeExtractor extractor) => state = extractor;

  /// Обновляет [state] данного объекта по передаваемым цветам, ранее извлечённых при помощи метода [fromImageProvider].
  Future<ImageSchemeExtractor> fromColors({
    required Map<int, int?> colorInts,
    required List<int> scoredColorInts,
    required int frequentColorInt,
    required int colorCount,
  }) async {
    fromExtractor(
      ImageSchemeExtractor(
        colorInts: colorInts,
        scoredColorInts: scoredColorInts,
        frequentColorInt: frequentColorInt,
        colorCount: colorCount,
      ),
    );

    return state!;
  }
}

/// [Provider], извлекающий цвета из изображения плейлиста, а так же сохраняющий их.
///
/// Если таковые цвета уже есть, то вместо извлечения новых, возвращаются старые.
@riverpod
Future<ImageSchemeExtractor?> colorInfoFromPlaylist(
  Ref ref,
  int ownerID,
  int id,
) async {
  final AppLogger logger = getLogger("colorInfoFromPlaylistProvider");
  final playlistsNotifier = ref.read(playlistsProvider.notifier);

  ExtendedPlaylist playlist = playlistsNotifier.getPlaylist(ownerID, id)!;

  // Если у плейлиста уже извлечены цвета, то возвращаем их.
  if (playlist.colorCount != null) {
    logger.d("Color info already extracted for ${playlist.mediaKey} from DB");

    return ImageSchemeExtractor(
      colorInts: playlist.colorInts!,
      scoredColorInts: playlist.scoredColorInts!,
      frequentColorInt: playlist.frequentColorInt!,
      colorCount: playlist.colorCount!,
    );
  }

  // Если у плейлиста нет изображения, то возвращаем null.
  if (playlist.photo == null) {
    return null;
  }

  final Stopwatch watch = Stopwatch()..start();

  final result = await ImageSchemeExtractor.fromImageProvider(
    CachedNetworkImageProvider(
      playlist.photo!.photo600,
      cacheKey: "${playlist.mediaKey}600",
      cacheManager: CachedNetworkImagesManager.instance,
    ),
  );
  logger.d(
    "${watch.elapsedMilliseconds}ms to create ColorScheme for playlist (quazer: ${result.quantizeDuration?.inMilliseconds}ms)",
  );

  // Сохраняем в БД.
  await playlistsNotifier.updatePlaylist(
    playlist.basicCopyWith(
      colorInts: result.colorInts,
      scoredColorInts: result.scoredColorInts,
      frequentColorInt: result.frequentColor.value,
      colorCount: result.colorCount,
    ),
    saveInDB: true,
  );

  return result;
}
