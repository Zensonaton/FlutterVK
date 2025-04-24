// ignore_for_file: non_constant_identifier_names

import "../../../main.dart";

/// {@template VKAPI.audio.setBroadcast}
/// Транслирует аудиозапись с переданным ID ([ExtendedAudio.mediaKey]) в статус текущего пользователя.
///
/// Если ничего не передано, то статус будет сброшен.
/// {@endtemplate}
///
/// API: `audio.setBroadcast`.
Future<void> audio_set_broadcast(String? mediaKey) async {
  await vkDio.post(
    "audio.setBroadcast",
    data: {
      "audio": mediaKey,

      // Demo response
      "_demo_": 0,
    },
  );
}
