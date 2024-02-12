// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_playlists.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

APIAudioGetPlaylistsRealResponse _$APIAudioGetPlaylistsRealResponseFromJson(
        Map<String, dynamic> json) =>
    APIAudioGetPlaylistsRealResponse(
      json['count'] as int,
      (json['items'] as List<dynamic>)
          .map((e) => AudioPlaylist.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$APIAudioGetPlaylistsRealResponseToJson(
        APIAudioGetPlaylistsRealResponse instance) =>
    <String, dynamic>{
      'count': instance.count,
      'items': instance.items,
    };

APIAudioGetPlaylistsResponse _$APIAudioGetPlaylistsResponseFromJson(
        Map<String, dynamic> json) =>
    APIAudioGetPlaylistsResponse(
      json['response'] == null
          ? null
          : APIAudioGetPlaylistsRealResponse.fromJson(
              json['response'] as Map<String, dynamic>),
      json['error'] == null
          ? null
          : APIError.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$APIAudioGetPlaylistsResponseToJson(
        APIAudioGetPlaylistsResponse instance) =>
    <String, dynamic>{
      'response': instance.response,
      'error': instance.error,
    };
