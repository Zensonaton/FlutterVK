// ignore_for_file: non_constant_identifier_names

import "../../../main.dart";

/// {@template VKAPI.audio.edit}
/// Модифицирует параметры трека: его название [title], исполнителя [artist] или жанр [genreID].
/// {@endtemplate}
///
/// API: `audio.edit`.
Future<int> audio_edit(
  int id,
  int ownerID,
  String title,
  String artist,
  int genreID,
) async {
  var response = await vkDio.post(
    "audio.edit",
    data: {
      "artist": artist,
      "title": title,
      "audio_id": id,
      "owner_id": ownerID,
      "genre_id": genreID,

      // Demo response
      "_demo_": 1,
    },
  );

  return response.data as int;
}
