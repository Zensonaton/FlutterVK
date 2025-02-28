import "../../provider/user.dart";

/// Парсит содержимое файла `.m3u8` с анимированными обложками, возвращая список из [ExtendedAnimatedThumbnail].
List<ExtendedAnimatedThumbnail> parseM3U8Contents(String contents) {
  if (!contents.contains("#EXTM3U")) {
    throw Exception("Invalid M3U8 file");
  }

  final Map<int, ExtendedAnimatedThumbnail> thumbnails = {};

  final List<String> lines = contents.split("\n");
  for (var i = 0; i < lines.length; i++) {
    final String line = lines[i];
    final String? nextLine = lines.elementAtOrNull(i + 1);

    if (!line.startsWith("#EXT-X-STREAM-INF")) continue;

    final int resolution =
        int.parse(line.split("RESOLUTION=").last.split("x").first);
    final String codec = line.split("CODECS=\"").last.split(".").first;
    final String url = nextLine!;

    if (resolution < 1 || resolution > 4096 || resolution % 2 != 0) {
      throw Exception("Invalid resolution: $resolution");
    }
    if (!url.contains(".m3u8")) {
      throw Exception("Got non .m3u8 file in .m3u8 file");
    }
    if (!["avc1", "hvc1"].contains(codec)) {
      throw Exception("Unsupported codec: $codec");
    }

    if (codec == "avc1") continue;

    final realMP4Url = url.replaceFirst(".m3u8", "-.mp4");

    thumbnails[resolution] = ExtendedAnimatedThumbnail(
      resolution: resolution,
      url: realMP4Url,
    );
  }

  return thumbnails.values.toList();
}
