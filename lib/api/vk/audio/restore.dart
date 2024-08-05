// ignore_for_file: non_constant_identifier_names

import "../../../main.dart";
import "../shared.dart";

/// {@template VKAPI.audio.restore}
/// Восстанавливает трек по его ID после удаления методом `delete`.
///
/// В случае успешного восстановления, возвращает объект [Audio].
/// {@endtemplate}
///
/// API: `audio.restore`.
Future<Audio> audio_restore(int id, int ownerID) async {
  var response = await vkDio.post(
    "audio.restore",
    data: {
      "audio_id": id,
      "owner_id": ownerID,
    },
  );

  return Audio.fromJson(response.data);
}
