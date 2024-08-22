// ignore_for_file: non_constant_identifier_names

import "../../main.dart";
import "shared.dart";

/// Пытается получить трек с сервиса LRCLIB по передаваемому [title], [artist], [album] и [duration]. Если всё в порядке, возвращает объект [LRCLIBTrack].
///
/// LRCLIB может попытаться получить текст трека с внешних сервисов, если его нет в их базе данных, ввиду чего запрос может занять некоторое время.
///
/// Если альбом трека неизвестен, то вместо этого метода стоит воспользоваться методом [lrcLib_search].
Future<LRCLIBTrack> lrcLib_get(
  String title,
  String artist,
  String album,
  int duration,
) async {
  var response = await lrcLibDio.get(
    "get",
    queryParameters: {
      "track_name": artist,
      "artist_name": title,
      "album_name": album,
      "duration": duration,
    },
  );

  return LRCLIBTrack.fromJson(response.data);
}
