// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

APIAudioSearchRealResponse _$APIAudioSearchRealResponseFromJson(
        Map<String, dynamic> json) =>
    APIAudioSearchRealResponse(
      count: (json['count'] as num).toInt(),
      items: (json['items'] as List<dynamic>)
          .map((e) => Audio.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$APIAudioSearchRealResponseToJson(
        APIAudioSearchRealResponse instance) =>
    <String, dynamic>{
      'count': instance.count,
      'items': instance.items,
    };

APIAudioSearchResponse _$APIAudioSearchResponseFromJson(
        Map<String, dynamic> json) =>
    APIAudioSearchResponse(
      response: json['response'] == null
          ? null
          : APIAudioSearchRealResponse.fromJson(
              json['response'] as Map<String, dynamic>),
      error: json['error'] == null
          ? null
          : APIError.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$APIAudioSearchResponseToJson(
        APIAudioSearchResponse instance) =>
    <String, dynamic>{
      'response': instance.response,
      'error': instance.error,
    };
