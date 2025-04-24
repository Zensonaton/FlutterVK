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

Lyrics _$LyricsFromJson(Map<String, dynamic> json) => Lyrics(
      language: json['language'] as String?,
      timestamps: (json['timestamps'] as List<dynamic>?)
          ?.map((e) => LyricTimestamp.fromJson(e as Map<String, dynamic>))
          .toList(),
      text: (json['text'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

APIAudioGetLyricsResponse _$APIAudioGetLyricsResponseFromJson(
        Map<String, dynamic> json) =>
    APIAudioGetLyricsResponse(
      credits: json['credits'] as String,
      lyrics: Lyrics.fromJson(json['lyrics'] as Map<String, dynamic>),
      md5: json['md5'] as String,
    );
