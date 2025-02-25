// ignore_for_file: non_constant_identifier_names

import "package:collection/collection.dart";

import "../../../main.dart";
import "../fake.dart";
import "../shared.dart";

/// Возвращает фейковые данные для этого метода.
Map<String, dynamic>? _getFakeData(int id, int ownerID) {
  return fakeAudios
      .firstWhereOrNull(
        (audio) => audio.id == id,
      )
      ?.toJson();
}

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

      // Demo response
      "_demo_": _getFakeData(id, ownerID),
    },
  );

  return Audio.fromJson(response.data);
}
