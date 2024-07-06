// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_get_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

APIAudioGetDataRealResponse _$APIAudioGetDataRealResponseFromJson(
        Map<String, dynamic> json) =>
    APIAudioGetDataRealResponse(
      audioCount: (json['audioCount'] as num).toInt(),
      audios: (json['audios'] as List<dynamic>)
          .map((e) => Audio.fromJson(e as Map<String, dynamic>))
          .toList(),
      playlistsCount: (json['playlistsCount'] as num).toInt(),
      playlists: (json['playlists'] as List<dynamic>)
          .map((e) => Playlist.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$APIAudioGetDataRealResponseToJson(
        APIAudioGetDataRealResponse instance) =>
    <String, dynamic>{
      'audioCount': instance.audioCount,
      'audios': instance.audios,
      'playlistsCount': instance.playlistsCount,
      'playlists': instance.playlists,
    };

APIAudioGetDataResponse _$APIAudioGetDataResponseFromJson(
        Map<String, dynamic> json) =>
    APIAudioGetDataResponse(
      response: json['response'] == null
          ? null
          : APIAudioGetDataRealResponse.fromJson(
              json['response'] as Map<String, dynamic>),
      error: json['error'] == null
          ? null
          : APIError.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$APIAudioGetDataResponseToJson(
        APIAudioGetDataResponse instance) =>
    <String, dynamic>{
      'response': instance.response,
      'error': instance.error,
    };
