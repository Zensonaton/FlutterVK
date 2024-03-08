// ignore_for_file: non_constant_identifier_names

import "dart:convert";

import "package:json_annotation/json_annotation.dart";

import "../api.dart";
import "shared.dart";

part "get_token.g.dart";

@JsonSerializable()
class SpotifyAPIGetTokenResponse {
  /// ID клиента.
  @JsonKey(name: "clientId")
  final String? clientID;

  /// Access-токен Spotify.
  final String? accessToken;

  /// UNIX-время истечения данного токена в миллисекундах.
  @JsonKey(name: "accessTokenExpirationTimestampMs")
  final int? expirationTimestampMS;

  /// Указывает, что данный токен является анонимным (т.е., авторизация без токена). Если проводилась авторизация от имени пользователя, то данное поле обязано быть `false`.
  final bool? isAnonymous;

  /// Опциональный текст ошибки.
  final SpotifyAPIError? error;

  SpotifyAPIGetTokenResponse({
    required this.clientID,
    required this.accessToken,
    required this.expirationTimestampMS,
    required this.isAnonymous,
    this.error,
  });

  factory SpotifyAPIGetTokenResponse.fromJson(Map<String, dynamic> json) =>
      _$SpotifyAPIGetTokenResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SpotifyAPIGetTokenResponseToJson(this);
}

/// Возвращает специальный API-токен для работы с API Spotify, по передаваемому значению Cookie `sp_dc`.
Future<SpotifyAPIGetTokenResponse> spotify_get_token(
  String spDC,
) async {
  var response = await apiGet(
    "https://open.spotify.com/get_access_token?reason=transport&productType=web_player",
    cookies: {
      "sp_dc": spDC,
    },
  );

  return SpotifyAPIGetTokenResponse.fromJson(jsonDecode(response.body));
}
