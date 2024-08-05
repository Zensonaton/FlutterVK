// ignore_for_file: non_constant_identifier_names

import "../../../main.dart";
import "../../../utils.dart";

/// {@template VKAPI.audio.delete}
/// Удаляет ранее лайкнутый трек (методом `add`). В течении ~15 минут после удаления трека можно его восстановить, вызвав `restore`.
///
/// Возвращает `true`, если трек был успешно удалён.
/// {@endtemplate}
///
/// API: `audio.delete`.
Future<bool> audio_delete(int id, int ownerID) async {
  var response = await vkDio.post(
    "audio.delete",
    data: {
      "audio_id": id,
      "owner_id": ownerID,
    },
  );

  return boolFromInt(response.data);
}
