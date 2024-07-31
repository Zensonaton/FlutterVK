// ignore_for_file: non_constant_identifier_names

import "package:json_annotation/json_annotation.dart";

import "../api.dart";
import "../shared.dart";

part "send_start_event.g.dart";

/// Ответ для метода [audio_send_start_event].
@JsonSerializable()
class APIAudioSendStartEventResponse {
  final dynamic response;

  /// Объект ошибки.
  final APIError? error;

  APIAudioSendStartEventResponse({
    this.response,
    this.error,
  });

  factory APIAudioSendStartEventResponse.fromJson(Map<String, dynamic> json) =>
      _$APIAudioSendStartEventResponseFromJson(json);
  Map<String, dynamic> toJson() => _$APIAudioSendStartEventResponseToJson(this);
}

/// {@template VKAPI.audio.sendStartEvent}
/// Информирует ВКонтакте о том, что передавемый ID трека ([ExtendedAudio.mediaKey]) сейчас прослушивается.
///
/// Благодаря этому методу, рекомендации ВКонтакте перестают рекомендовать этот трек снова и снова.
/// {@endtemplate}
///
/// API: `audio.sendStartEvent`.
Future<APIAudioSendStartEventResponse> audio_send_start_event(
  String token,
  String mediaKey,
) async {
  var response = await callVkAPI(
    "audio.sendStartEvent",
    token,
    {
      "uuid": "abcdef:abcdef", // Понятия не имею что это за параша.
      "audio_id": mediaKey,
    },
  );

  return APIAudioSendStartEventResponse.fromJson(response.data);
}
