// ignore_for_file: non_constant_identifier_names

import "dart:convert";

import "package:json_annotation/json_annotation.dart";

import "../api.dart";
import "../shared.dart";

part "delete.g.dart";

/// Ответ для метода [audio_delete].
@JsonSerializable()
class APIAudioDeleteResponse {
  /// `1`, если всё в порядке.
  final int? response;

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

/// Удаляет трек из лайкнутых.
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
