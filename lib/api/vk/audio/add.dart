// ignore_for_file: non_constant_identifier_names

import "dart:convert";

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

/// Копирует трек с указанным ID к данному пользователю, передавая относительный для данного пользователя сохранённый ID трека. После добавления трека, его можно удалить методом [audio_delete].
///
/// API: `audio.add`.
Future<APIAudioAddResponse> audio_add(
  String token,
  int audioID,
  int ownerID,
) async {
  var response = await vkAPIcall(
    "audio.add",
    token,
    {
      "audio_id": audioID.toString(),
      "owner_id": ownerID.toString(),
    },
  );

  return APIAudioAddResponse.fromJson(jsonDecode(response.body));
}
