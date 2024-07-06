// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_lyrics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LyricTimestamp _$LyricTimestampFromJson(Map<String, dynamic> json) =>
    LyricTimestamp(
      line: json['line'] as String?,
      interlude: json['interlude'] as bool? ?? false,
      begin: (json['begin'] as num?)?.toInt(),
      end: (json['end'] as num?)?.toInt(),
    );

Map<String, dynamic> _$LyricTimestampToJson(LyricTimestamp instance) =>
    <String, dynamic>{
      'line': instance.line,
      'interlude': instance.interlude,
      'begin': instance.begin,
      'end': instance.end,
    };

Lyrics _$LyricsFromJson(Map<String, dynamic> json) => Lyrics(
      language: json['language'] as String?,
      timestamps: (json['timestamps'] as List<dynamic>?)
          ?.map((e) => LyricTimestamp.fromJson(e as Map<String, dynamic>))
          .toList(),
      text: (json['text'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$LyricsToJson(Lyrics instance) => <String, dynamic>{
      'language': instance.language,
      'timestamps': instance.timestamps,
      'text': instance.text,
    };

APIAudioGetLyricsRealResponse _$APIAudioGetLyricsRealResponseFromJson(
        Map<String, dynamic> json) =>
    APIAudioGetLyricsRealResponse(
      credits: json['credits'] as String,
      lyrics: Lyrics.fromJson(json['lyrics'] as Map<String, dynamic>),
      md5: json['md5'] as String,
    );

Map<String, dynamic> _$APIAudioGetLyricsRealResponseToJson(
        APIAudioGetLyricsRealResponse instance) =>
    <String, dynamic>{
      'credits': instance.credits,
      'lyrics': instance.lyrics,
      'md5': instance.md5,
    };

APIAudioGetLyricsResponse _$APIAudioGetLyricsResponseFromJson(
        Map<String, dynamic> json) =>
    APIAudioGetLyricsResponse(
      json['response'] == null
          ? null
          : APIAudioGetLyricsRealResponse.fromJson(
              json['response'] as Map<String, dynamic>),
      json['error'] == null
          ? null
          : APIError.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$APIAudioGetLyricsResponseToJson(
        APIAudioGetLyricsResponse instance) =>
    <String, dynamic>{
      'response': instance.response,
      'error': instance.error,
    };
