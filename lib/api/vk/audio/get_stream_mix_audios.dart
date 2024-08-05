// ignore_for_file: non_constant_identifier_names

import "../../../main.dart";
import "../shared.dart";

/// {@template VKAPI.audio.getStreamMixAudios}
/// Возвращает список треков для аудио микса (VK Mix).
/// {@endtemplate}
///
/// API: `audio.getStreamMixAudios`.
Future<List<Audio>> audio_get_stream_mix_audios(String mixID, int count) async {
  var response = await vkDio.post(
    "audio.getStreamMixAudios",
    data: {
      "mix_id": mixID,
      "count": count,
    },
  );

  return response.data
      .map<Audio>(
        (item) => Audio.fromJson(item),
      )
      .toList();
}
