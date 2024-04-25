// ignore_for_file: non_constant_identifier_names

import "dart:convert";

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

/// Помечает передаваемые треки как дизлайкнутые.
///
/// API: `audio.addDislike`.
Future<APIAudioAddDislikeResponse> audio_add_dislike(
  String token,
  List<String> ids,
) async {
  var response = await vkAPIcall(
    "audio.addDislike",
    token,
    {
      "audio_ids": ids.join(","),
    },
  );

  return APIAudioAddDislikeResponse.fromJson(jsonDecode(response.body));
}
