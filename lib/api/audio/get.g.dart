// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

APIAudioGetRealResponse _$APIAudioGetRealResponseFromJson(
        Map<String, dynamic> json) =>
    APIAudioGetRealResponse(
      json['count'] as int,
      (json['items'] as List<dynamic>)
          .map((e) => Audio.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$APIAudioGetRealResponseToJson(
        APIAudioGetRealResponse instance) =>
    <String, dynamic>{
      'count': instance.count,
      'items': instance.items,
    };

APIAudioGetResponse _$APIAudioGetResponseFromJson(Map<String, dynamic> json) =>
    APIAudioGetResponse(
      json['response'] == null
          ? null
          : APIAudioGetRealResponse.fromJson(
              json['response'] as Map<String, dynamic>),
      json['error'] == null
          ? null
          : APIError.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$APIAudioGetResponseToJson(
        APIAudioGetResponse instance) =>
    <String, dynamic>{
      'response': instance.response,
      'error': instance.error,
    };
