// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_stream_mix_audios.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

APIAudioGetStreamMixAudiosResponse _$APIAudioGetStreamMixAudiosResponseFromJson(
        Map<String, dynamic> json) =>
    APIAudioGetStreamMixAudiosResponse(
      response: (json['response'] as List<dynamic>?)
          ?.map((e) => Audio.fromJson(e as Map<String, dynamic>))
          .toList(),
      error: json['error'] == null
          ? null
          : APIError.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$APIAudioGetStreamMixAudiosResponseToJson(
        APIAudioGetStreamMixAudiosResponse instance) =>
    <String, dynamic>{
      'response': instance.response,
      'error': instance.error,
    };
