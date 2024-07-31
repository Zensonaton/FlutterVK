// ignore_for_file: non_constant_identifier_names

import "package:json_annotation/json_annotation.dart";

import "../../../utils.dart";
import "../api.dart";
import "../shared.dart";

part "add_dislike.g.dart";

/// Ответ для метода [audio_add_dislike].
@JsonSerializable()
class APIAudioAddDislikeResponse {
  /// Указывает, удачный ли запрос.
  @JsonKey(fromJson: boolFromInt, defaultValue: false)
  final bool response;

  /// Объект ошибки.
  final APIError? error;

  APIAudioAddDislikeResponse(
    this.response,
    this.error,
  );

  factory APIAudioAddDislikeResponse.fromJson(Map<String, dynamic> json) =>
      _$APIAudioAddDislikeResponseFromJson(json);
  Map<String, dynamic> toJson() => _$APIAudioAddDislikeResponseToJson(this);
}

/// {@template VKAPI.audio.addDislike}
/// Помечает список аудиозаписей ([ExtendedAudio.mediaKey]) как дизлайкнутые.
/// {@endtemplate}
///
/// API: `audio.addDislike`.
Future<APIAudioAddDislikeResponse> audio_add_dislike(
  String token,
  List<String> mediaKeys,
) async {
  final response = await callVkAPI(
    "audio.addDislike",
    token,
    {
      "audio_ids": mediaKeys.join(","),
    },
  );

  return APIAudioAddDislikeResponse.fromJson(response.data);
}
