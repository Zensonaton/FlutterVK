// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mass_get_audio.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

APIMassAudioGetResponse _$APIMassAudioGetResponseFromJson(
        Map<String, dynamic> json) =>
    APIMassAudioGetResponse(
      audioCount: (json['audioCount'] as num).toInt(),
      audios: (json['audios'] as List<dynamic>)
          .map((e) => Audio.fromJson(e as Map<String, dynamic>))
          .toList(),
      playlistsCount: (json['playlistsCount'] as num).toInt(),
      playlists: (json['playlists'] as List<dynamic>)
          .map((e) => Playlist.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
