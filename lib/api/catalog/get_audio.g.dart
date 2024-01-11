// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_audio.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BlockAction _$BlockActionFromJson(Map<String, dynamic> json) => BlockAction(
      json['section_id'] as String?,
      json['title'] as String?,
      json['ref_items_count'] as int?,
      json['ref_layout_name'] as String?,
      json['ref_data_type'] as String?,
    );

Map<String, dynamic> _$BlockActionToJson(BlockAction instance) =>
    <String, dynamic>{
      'section_id': instance.sectionID,
      'title': instance.title,
      'ref_items_count': instance.refItemsCount,
      'ref_layout_name': instance.refLayoutName,
      'ref_data_type': instance.refDataType,
    };

SectionBlock _$SectionBlockFromJson(Map<String, dynamic> json) => SectionBlock(
      json['id'] as String,
      json['title'] as String?,
      json['data_type'] as String,
      json['layout'],
      (json['actions'] as List<dynamic>?)
          ?.map((e) => BlockAction.fromJson(e as Map<String, dynamic>))
          .toList(),
      (json['audios_ids'] as List<dynamic>?)?.map((e) => e as String).toList(),
      (json['playlists_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$SectionBlockToJson(SectionBlock instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'data_type': instance.dataType,
      'layout': instance.layout,
      'actions': instance.actions,
      'audios_ids': instance.audioIDs,
      'playlists_ids': instance.playlistIDs,
    };

Section _$SectionFromJson(Map<String, dynamic> json) => Section(
      json['id'] as String,
      json['title'] as String,
      json['url'] as String,
      (json['blocks'] as List<dynamic>?)
          ?.map((e) => SectionBlock.fromJson(e as Map<String, dynamic>))
          .toList(),
      json['actions'] as List<dynamic>?,
    );

Map<String, dynamic> _$SectionToJson(Section instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'url': instance.url,
      'blocks': instance.blocks,
      'actions': instance.actions,
    };

Catalog _$CatalogFromJson(Map<String, dynamic> json) => Catalog(
      json['default_section'] as String,
      (json['sections'] as List<dynamic>)
          .map((e) => Section.fromJson(e as Map<String, dynamic>))
          .toList(),
      json['header'],
      json['buttons'],
      json['pinned_section'] as String?,
    );

Map<String, dynamic> _$CatalogToJson(Catalog instance) => <String, dynamic>{
      'default_section': instance.defaultSection,
      'sections': instance.sections,
      'header': instance.header,
      'buttons': instance.buttons,
      'pinned_section': instance.pinnedSection,
    };

APICatalogRealResponse _$APICatalogRealResponseFromJson(
        Map<String, dynamic> json) =>
    APICatalogRealResponse(
      (json['audios'] as List<dynamic>)
          .map((e) => Audio.fromJson(e as Map<String, dynamic>))
          .toList(),
      (json['playlists'] as List<dynamic>)
          .map((e) => AudioPlaylist.fromJson(e as Map<String, dynamic>))
          .toList(),
      Catalog.fromJson(json['catalog'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$APICatalogRealResponseToJson(
        APICatalogRealResponse instance) =>
    <String, dynamic>{
      'audios': instance.audios,
      'playlists': instance.playlists,
      'catalog': instance.catalog,
    };

APICatalogGetAudioResponse _$APICatalogGetAudioResponseFromJson(
        Map<String, dynamic> json) =>
    APICatalogGetAudioResponse(
      json['response'] == null
          ? null
          : APICatalogRealResponse.fromJson(
              json['response'] as Map<String, dynamic>),
      json['error'] == null
          ? null
          : APIError.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$APICatalogGetAudioResponseToJson(
        APICatalogGetAudioResponse instance) =>
    <String, dynamic>{
      'response': instance.response,
      'error': instance.error,
    };
