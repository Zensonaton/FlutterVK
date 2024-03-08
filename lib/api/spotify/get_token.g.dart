// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_token.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SpotifyAPIGetTokenResponse _$SpotifyAPIGetTokenResponseFromJson(
        Map<String, dynamic> json) =>
    SpotifyAPIGetTokenResponse(
      clientID: json['clientId'] as String?,
      accessToken: json['accessToken'] as String?,
      expirationTimestampMS: json['accessTokenExpirationTimestampMs'] as int?,
      isAnonymous: json['isAnonymous'] as bool?,
      error: json['error'] == null
          ? null
          : SpotifyAPIError.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SpotifyAPIGetTokenResponseToJson(
        SpotifyAPIGetTokenResponse instance) =>
    <String, dynamic>{
      'clientId': instance.clientID,
      'accessToken': instance.accessToken,
      'accessTokenExpirationTimestampMs': instance.expirationTimestampMS,
      'isAnonymous': instance.isAnonymous,
      'error': instance.error,
    };
