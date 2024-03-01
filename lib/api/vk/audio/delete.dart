// ignore_for_file: non_constant_identifier_names

import "dart:convert";

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

/// Удаляет ранее лайкнутый трек (методом [audio_add]). В течении 15 минут после удаления трека можно его восстановить, вызвав [audio_restore].
///
/// API: `audio.delete`.
Future<APIAudioDeleteResponse> audio_delete(
  String token,
  int audioID,
  int ownerID,
) async {
  var response = await vkAPIcall(
    "audio.delete",
    token,
    {
      "audio_id": audioID.toString(),
      "owner_id": ownerID.toString(),
    },
  );

  return APIAudioDeleteResponse.fromJson(jsonDecode(response.body));
}
