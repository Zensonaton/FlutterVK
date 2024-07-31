// ignore_for_file: non_constant_identifier_names

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

/// {@template VKAPI.audio.edit}
/// Модифицирует параметры трека: его название [title], исполнителя [artist] или жанр [genreID].
/// {@endtemplate}
///
/// API: `audio.edit`.
Future<APIAudioEditResponse> audio_edit(
  String token,
  int id,
  int ownerID,
  String title,
  String artist,
  int genreID,
) async {
  var response = await callVkAPI(
    "audio.edit",
    token,
    {
      "artist": artist,
      "title": title,
      "audio_id": id.toString(),
      "owner_id": ownerID.toString(),
      "genre_id": genreID.toString(),
    },
  );

  return APIAudioEditResponse.fromJson(response.data);
}
