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

APIAudioGetLyricsResponse _$APIAudioGetLyricsResponseFromJson(
        Map<String, dynamic> json) =>
    APIAudioGetLyricsResponse(
      credits: json['credits'] as String,
      lyrics: Lyrics.fromJson(json['lyrics'] as Map<String, dynamic>),
      md5: json['md5'] as String,
    );

Map<String, dynamic> _$APIAudioGetLyricsResponseToJson(
        APIAudioGetLyricsResponse instance) =>
    <String, dynamic>{
      'credits': instance.credits,
      'lyrics': instance.lyrics,
      'md5': instance.md5,
    };
