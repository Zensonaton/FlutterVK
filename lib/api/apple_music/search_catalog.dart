// ignore_for_file: non_constant_identifier_names

import "../../main.dart";

/// Ищет трек [title], возвращая ID альбома.
Future<int?> am_search_catalog(String title) async {
  var response = await appleMusicDio.get(
    "catalog/us/search",
    queryParameters: {
      "term": title,
      "extend": "artistUrl",
      "relate[albums]": "songs",
      "format[resources]": "map",
      "include[albums]": "artists",
      "limit": 1,
      "types": "albums,songs",
      "with": "serverBubbles",
    },
  );

  final songs = response.data["results"]["song"]?["data"];
  if (songs == null || songs.isEmpty) return null;

  final audioID = songs.first["id"];
  final audioInfo = response.data["resources"]["songs"][audioID]["attributes"];
  final String albumID = audioInfo["url"].split("/").last.split("?").first;

  return int.tryParse(albumID);
}
