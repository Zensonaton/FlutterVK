// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_audio_search.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Suggestion _$SuggestionFromJson(Map<String, dynamic> json) => Suggestion(
      id: json['id'] as String?,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      context: json['context'] as String?,
    );

Map<String, dynamic> _$SuggestionToJson(Suggestion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'subtitle': instance.subtitle,
      'context': instance.context,
    };

APICatalogGetAudioSearchResponse _$APICatalogGetAudioSearchResponseFromJson(
        Map<String, dynamic> json) =>
    APICatalogGetAudioSearchResponse(
      suggestions: (json['suggestions'] as List<dynamic>)
          .map((e) => Suggestion.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$APICatalogGetAudioSearchResponseToJson(
        APICatalogGetAudioSearchResponse instance) =>
    <String, dynamic>{
      'suggestions': instance.suggestions.map((e) => e.toJson()).toList(),
    };
