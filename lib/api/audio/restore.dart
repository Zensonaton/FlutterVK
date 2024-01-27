// ignore_for_file: non_constant_identifier_names

import "dart:convert";

import "package:json_annotation/json_annotation.dart";

import "../api.dart";
import "../shared.dart";

part "restore.g.dart";

/// Ответ для метода [audio_get].
@JsonSerializable()
class APIAudioRestoreResponse {
  /// Объект ответа.
  final Audio? response;

  /// Объект ошибки.
  final APIError? error;

  APIAudioRestoreResponse(
    this.response,
    this.error,
  );

  factory APIAudioRestoreResponse.fromJson(Map<String, dynamic> json) =>
      _$APIAudioRestoreResponseFromJson(json);
  Map<String, dynamic> toJson() => _$APIAudioRestoreResponseToJson(this);
}

/// Восстанавливает трек по его ID, после удаления, вызванного методом [audio_delete].
///
/// API: `audio.restore`.
Future<APIAudioRestoreResponse> audio_restore(
  String token,
  int audioID,
  int ownerID,
) async {
  var response = await vkAPIcall(
    "audio.restore",
    token,
    {
      "audio_id": audioID.toString(),
      "owner_id": ownerID.toString(),
    },
  );

  return APIAudioRestoreResponse.fromJson(jsonDecode(response.body));
}
