// ignore_for_file: non_constant_identifier_names

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

  APIAudioRestoreResponse({
    this.response,
    this.error,
  });

  factory APIAudioRestoreResponse.fromJson(Map<String, dynamic> json) =>
      _$APIAudioRestoreResponseFromJson(json);
  Map<String, dynamic> toJson() => _$APIAudioRestoreResponseToJson(this);
}

/// {@template VKAPI.audio.restore}
/// Восстанавливает трек по его ID после удаления методом `delete`.
/// {@endtemplate}
///
/// API: `audio.restore`.
Future<APIAudioRestoreResponse> audio_restore(
  String token,
  int id,
  int ownerID,
) async {
  var response = await callVkAPI(
    "audio.restore",
    token,
    {
      "audio_id": id.toString(),
      "owner_id": ownerID.toString(),
    },
  );

  return APIAudioRestoreResponse.fromJson(response.data);
}
