// ignore_for_file: non_constant_identifier_names

import "../../main.dart";
import "shared.dart";

/// Производит поиск текста песни по его [title], [artist], [album], возвращая список из объектов [LRCLIBTrack].
Future<List<LRCLIBTrack>> lrcLib_search(
  String title, {
  String? artist,
  String? album,
}) async {
  var response = await lrcLibDio.get(
    "search",
    queryParameters: {
      "track_name": title,
      "artist_name": artist,
      "album_name": album,
    },
  );

  return (response.data as List)
      .map(
        (item) => LRCLIBTrack.fromJson(item),
      )
      .toList();
}
