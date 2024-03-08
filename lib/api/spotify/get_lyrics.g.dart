// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_lyrics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SpotifyAPIGetLyricsResponse _$SpotifyAPIGetLyricsResponseFromJson(
        Map<String, dynamic> json) =>
    SpotifyAPIGetLyricsResponse(
      lyrics: SpotifyLyrics.fromJson(json['lyrics'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SpotifyAPIGetLyricsResponseToJson(
        SpotifyAPIGetLyricsResponse instance) =>
    <String, dynamic>{
      'lyrics': instance.lyrics,
    };
