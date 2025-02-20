import "package:media_kit/media_kit.dart" as mk;

/// Класс для получения доступа к нативным методам плеера.
class MediaKitNativePlayer {
  final mk.Player player;

  MediaKitNativePlayer({
    required this.player,
  });

  Future<void> setProperty(String property, String value) async {
    final mk.PlatformPlayer native = player.platform!;
    if (native is! mk.NativePlayer) {
      throw UnsupportedError(
        "This method is only supported by the native player.",
      );
    }

    await native.setProperty(property, value);
  }
}
