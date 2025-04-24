// ignore_for_file: non_constant_identifier_names

import "package:json_annotation/json_annotation.dart";

import "../../../main.dart";
import "../shared.dart";

part "get.g.dart";

/// Ответ для метода [audio_get].
@JsonSerializable()
class APIAudioGetResponse {
  /// Количество треков.
  final int count;

  /// Информация о треках.
  final List<Audio> items;

  APIAudioGetResponse({
    required this.count,
    required this.items,
  });

  factory APIAudioGetResponse.fromJson(Map<String, dynamic> json) =>
      _$APIAudioGetResponseFromJson(json);
}

/// {@template VKAPI.audio.get}
/// Возвращает информацию об аудиофайлах пользователя или сообщества.
/// {@endtemplate}
///
/// API: `audio.get`.
Future<APIAudioGetResponse> audio_get(int userID) async {
  var response = await vkDio.post(
    "audio.get",
    data: {
      "owner_id": userID,

      // Demo response
      "_demo_": {
        // TODO
        "count": 0,
        "items": [],
      },
    },
  );

  return APIAudioGetResponse.fromJson(response.data);
}
