// ignore_for_file: non_constant_identifier_names

import "package:json_annotation/json_annotation.dart";

import "../../../utils.dart";
import "../api.dart";
import "../shared.dart";

part "delete.g.dart";

/// Ответ для метода [audio_delete].
@JsonSerializable()
class APIAudioDeleteResponse {
  /// Указывает, удачный ли запрос.
  @JsonKey(fromJson: boolFromInt, defaultValue: false)
  final bool response;

  /// Объект ошибки.
  final APIError? error;

  APIAudioDeleteResponse(
    this.response,
    this.error,
  );

  factory APIAudioDeleteResponse.fromJson(Map<String, dynamic> json) =>
      _$APIAudioDeleteResponseFromJson(json);
  Map<String, dynamic> toJson() => _$APIAudioDeleteResponseToJson(this);
}

/// {@template VKAPI.audio.delete}
/// Удаляет ранее лайкнутый трек (методом `add`).
///
/// В течении ~15 минут после удаления трека можно его восстановить, вызвав `restore`.
/// {@endtemplate}
///
/// API: `audio.delete`.
Future<APIAudioDeleteResponse> audio_delete(
  String token,
  int id,
  int ownerID,
) async {
  var response = await callVkAPI(
    "audio.delete",
    token,
    {
      "audio_id": id.toString(),
      "owner_id": ownerID.toString(),
    },
  );

  return APIAudioDeleteResponse.fromJson(response.data);
}
