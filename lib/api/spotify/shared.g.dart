// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SpotifyAPIError _$SpotifyAPIErrorFromJson(Map<String, dynamic> json) =>
    SpotifyAPIError(
      code: (json['code'] as num).toInt(),
      message: json['message'] as String,
    );

Map<String, dynamic> _$SpotifyAPIErrorToJson(SpotifyAPIError instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
    };

SpotifyLyricLine _$SpotifyLyricLineFromJson(Map<String, dynamic> json) =>
    SpotifyLyricLine(
      startTimeMS: int.parse(json['startTimeMs'] as String),
      endTimeMS: int.parse(json['endTimeMs'] as String),
      words: json['words'] as String,
    );

Map<String, dynamic> _$SpotifyLyricLineToJson(SpotifyLyricLine instance) =>
    <String, dynamic>{
      'startTimeMs': instance.startTimeMS,
      'endTimeMs': instance.endTimeMS,
      'words': instance.words,
    };

SpotifyLyrics _$SpotifyLyricsFromJson(Map<String, dynamic> json) =>
    SpotifyLyrics(
      syncType: json['syncType'] as String,
      lines: (json['lines'] as List<dynamic>)
          .map((e) => SpotifyLyricLine.fromJson(e as Map<String, dynamic>))
          .toList(),
      provider: json['provider'] as String,
      providerLyricsID: int.parse(json['providerLyricsId'] as String),
      language: json['language'] as String,
    );

Map<String, dynamic> _$SpotifyLyricsToJson(SpotifyLyrics instance) =>
    <String, dynamic>{
      'syncType': instance.syncType,
      'lines': instance.lines,
      'provider': instance.provider,
      'providerLyricsId': instance.providerLyricsID,
      'language': instance.language,
    };
