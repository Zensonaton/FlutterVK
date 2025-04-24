// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_playlists.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

APIAudioGetPlaylistsResponse _$APIAudioGetPlaylistsResponseFromJson(
        Map<String, dynamic> json) =>
    APIAudioGetPlaylistsResponse(
      count: (json['count'] as num).toInt(),
      items: (json['items'] as List<dynamic>)
          .map((e) => Playlist.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
