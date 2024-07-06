// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SpotifyTrack _$SpotifyTrackFromJson(Map<String, dynamic> json) => SpotifyTrack(
      durationMS: (json['duration_ms'] as num).toInt(),
      name: json['name'] as String,
      explicit: json['explicit'] as bool,
      id: json['id'] as String,
    );

Map<String, dynamic> _$SpotifyTrackToJson(SpotifyTrack instance) =>
    <String, dynamic>{
      'duration_ms': instance.durationMS,
      'name': instance.name,
      'explicit': instance.explicit,
      'id': instance.id,
    };

Tracks _$TracksFromJson(Map<String, dynamic> json) => Tracks(
      href: json['href'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => SpotifyTrack.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TracksToJson(Tracks instance) => <String, dynamic>{
      'href': instance.href,
      'items': instance.items,
    };

SpotifyAPISearchResponse _$SpotifyAPISearchResponseFromJson(
        Map<String, dynamic> json) =>
    SpotifyAPISearchResponse(
      tracks: Tracks.fromJson(json['tracks'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SpotifyAPISearchResponseToJson(
        SpotifyAPISearchResponse instance) =>
    <String, dynamic>{
      'tracks': instance.tracks,
    };
