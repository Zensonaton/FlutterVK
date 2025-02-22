// ignore_for_file: non_constant_identifier_names

import "../../../main.dart";
import "../fake.dart";
import "../shared.dart";

/// Возвращает фейковые данные для этого метода.
List<Map<String, dynamic>> _getFakeData(int count) {
  final audios = [...fakeAudios];
  audios.shuffle();

  return audios
      .take(count)
      .map(
        (audio) => audio.toJson(),
      )
      .toList();
}

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

      // Demo response
      "_demo_": _getFakeData(count),
    },
  );

  return response.data
      .map<Audio>(
        (item) => Audio.fromJson(item),
      )
      .toList();
}
