// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mass_audio_albums.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

APIMassAudioAlbumsResponse _$APIMassAudioAlbumsResponseFromJson(
        Map<String, dynamic> json) =>
    APIMassAudioAlbumsResponse(
      response: (json['response'] as List<dynamic>?)
          ?.map((e) => Audio.fromJson(e as Map<String, dynamic>))
          .toList(),
      error: json['error'] == null
          ? null
          : APIError.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$APIMassAudioAlbumsResponseToJson(
        APIMassAudioAlbumsResponse instance) =>
    <String, dynamic>{
      'response': instance.response,
      'error': instance.error,
    };
