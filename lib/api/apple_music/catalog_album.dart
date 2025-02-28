// ignore_for_file: non_constant_identifier_names

import "../../main.dart";

/// Возвращает ссылку на .m3u8-файл, используемый для отображения анимированной обложки альбома, по передаваемого [id] альбома.
Future<String?> am_catalog_album(int id) async {
  var response = await appleMusicDio.get(
    "catalog/us/albums/$id",
    queryParameters: {
      "fields": "editorialVideo",
    },
  );

  final List<dynamic> data = response.data["data"];
  if (data.isEmpty) return null;

  final video = data.first?["attributes"]?["editorialVideo"];
  if (video == null) return null;

  return (video["motionDetailSquare"] ??
      video["motionSquareVideo1x1"])?["video"];
}
