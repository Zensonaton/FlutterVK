// ignore_for_file: non_constant_identifier_names

import "../../../main.dart";

/// {@template VKAPI.audio.add}
/// Копирует трек с указанным ID ([ExtendedAudio.id], [ExtendedAudio.ownerID]) к данному пользователю, передавая относительный для данного пользователя сохранённый ID трека.
///
/// После добавления трека, его можно удалить методом `delete`.
/// {@endtemplate}
///
/// API: `audio.add`.
Future<int> audio_add(int id, int ownerID) async {
  final response = await vkDio.post(
    "audio.add",
    data: {
      "audio_id": id,
      "owner_id": ownerID,
    },
  );

  return response.data as int;
}
