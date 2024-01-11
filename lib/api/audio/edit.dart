// ignore_for_file: non_constant_identifier_names

import "dart:convert";

import "package:json_annotation/json_annotation.dart";

import "../api.dart";
import "../shared.dart";

part "edit.g.dart";

/// Ответ для метода [audio_edit].
@JsonSerializable()
class APIAudioEditResponse {
  /// Объект ответа.
  final int? response;

  /// Объект ошибки.
  final APIError? error;

  APIAudioEditResponse(
    this.response,
    this.error,
  );

  factory APIAudioEditResponse.fromJson(Map<String, dynamic> json) =>
      _$APIAudioEditResponseFromJson(json);
  Map<String, dynamic> toJson() => _$APIAudioEditResponseToJson(this);
}

/// Модифицирует параметры трека: его название ([title]) и/ли исполнителя ([artist]).
///
/// API: `audio.edit`.
Future<APIAudioEditResponse> audio_edit(
  String token,
  int ownerID,
  int audioID,
  String title,
  String artist,
) async {
  var response = await vkAPIcall(
    "audio.edit",
    token,
    {
      "artist": artist,
      "title": title,
      "audio_id": audioID.toString(),
      "owner_id": ownerID.toString(),
    },
  );

  return APIAudioEditResponse.fromJson(jsonDecode(response.body));
}
