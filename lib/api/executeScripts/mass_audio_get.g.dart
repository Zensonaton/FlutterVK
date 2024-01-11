// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mass_audio_get.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

APIMassAudioGetRealResponse _$APIMassAudioGetRealResponseFromJson(
        Map<String, dynamic> json) =>
    APIMassAudioGetRealResponse(
      json['audioCount'] as int,
      (json['audios'] as List<dynamic>)
          .map((e) => Audio.fromJson(e as Map<String, dynamic>))
          .toList(),
      json['playlistsCount'] as int,
      (json['playlists'] as List<dynamic>)
          .map((e) => AudioPlaylist.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$APIMassAudioGetRealResponseToJson(
        APIMassAudioGetRealResponse instance) =>
    <String, dynamic>{
      'audioCount': instance.audioCount,
      'audios': instance.audios,
      'playlistsCount': instance.playlistsCount,
      'playlists': instance.playlists,
    };

APIMassAudioGetResponse _$APIMassAudioGetResponseFromJson(
        Map<String, dynamic> json) =>
    APIMassAudioGetResponse(
      json['response'] == null
          ? null
          : APIMassAudioGetRealResponse.fromJson(
              json['response'] as Map<String, dynamic>),
      json['error'] == null
          ? null
          : APIError.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$APIMassAudioGetResponseToJson(
        APIMassAudioGetResponse instance) =>
    <String, dynamic>{
      'response': instance.response,
      'error': instance.error,
    };
