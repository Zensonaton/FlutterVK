// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_dislike.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

APIAudioAddDislikeResponse _$APIAudioAddDislikeResponseFromJson(
        Map<String, dynamic> json) =>
    APIAudioAddDislikeResponse(
      json['response'] == null
          ? false
          : boolFromInt((json['response'] as num?)?.toInt()),
      json['error'] == null
          ? null
          : APIError.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$APIAudioAddDislikeResponseToJson(
        APIAudioAddDislikeResponse instance) =>
    <String, dynamic>{
      'response': instance.response,
      'error': instance.error,
    };
