// ignore_for_file: non_constant_identifier_names

import "package:json_annotation/json_annotation.dart";

import "../api.dart";
import "../shared.dart";

part "add.g.dart";

/// Ответ для метода [audio_add].
@JsonSerializable()
class APIAudioAddResponse {
  /// Относительный для данного пользователя сохранённый ID трека.
  final int? response;

  /// Объект ошибки.
  final APIError? error;

  APIAudioAddResponse({
    this.response,
    this.error,
  });

  factory APIAudioAddResponse.fromJson(Map<String, dynamic> json) =>
      _$APIAudioAddResponseFromJson(json);
  Map<String, dynamic> toJson() => _$APIAudioAddResponseToJson(this);
}

/// {@template VKAPI.audio.add}
/// Копирует трек с указанным ID ([ExtendedAudio.id], [ExtendedAudio.ownerID]) к данному пользователю, передавая относительный для данного пользователя сохранённый ID трека.
///
/// После добавления трека, его можно удалить методом `delete`.
/// {@endtemplate}
///
/// API: `audio.add`.
Future<APIAudioAddResponse> audio_add(
  String token,
  int id,
  int ownerID,
) async {
  final response = await callVkAPI(
    "audio.add",
    token,
    {
      "audio_id": id.toString(),
      "owner_id": ownerID.toString(),
    },
  );

  return APIAudioAddResponse.fromJson(response.data);
}
