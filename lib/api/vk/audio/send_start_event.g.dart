// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'send_start_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

APIAudioSendStartEventResponse _$APIAudioSendStartEventResponseFromJson(
        Map<String, dynamic> json) =>
    APIAudioSendStartEventResponse(
      response: json['response'],
      error: json['error'] == null
          ? null
          : APIError.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$APIAudioSendStartEventResponseToJson(
        APIAudioSendStartEventResponse instance) =>
    <String, dynamic>{
      'response': instance.response,
      'error': instance.error,
    };
