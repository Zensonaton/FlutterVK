// ignore_for_file: non_constant_identifier_names

import "../../../main.dart";
import "../../../utils.dart";

/// {@template VKAPI.audio.addDislike}
/// Помечает список аудиозаписей ([ExtendedAudio.mediaKey]) как дизлайкнутые.
///
/// Возвращает true, если аудиозаписи были помечены как дизлайкнутые.
/// {@endtemplate}
///
/// API: `audio.addDislike`.
Future<bool> audio_add_dislike(List<String> mediaKeys) async {
  final response = await vkDio.post(
    "audio.addDislike",
    data: {
      "audio_ids": mediaKeys.join(","),

      // Demo response
      "_demo_": 1,
    },
  );

  return boolFromInt(response.data);
}
