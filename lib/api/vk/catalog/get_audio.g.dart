// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_audio.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AudioMix _$AudioMixFromJson(Map<String, dynamic> json) => AudioMix(
      id: json['id'] as String,
      backgroundAnimationUrl: json['background_animation_url'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
    );

Map<String, dynamic> _$AudioMixToJson(AudioMix instance) => <String, dynamic>{
      'id': instance.id,
      'background_animation_url': instance.backgroundAnimationUrl,
      'title': instance.title,
      'description': instance.description,
    };

SimillarPlaylist _$SimillarPlaylistFromJson(Map<String, dynamic> json) =>
    SimillarPlaylist(
      id: json['id'] as int,
      ownerID: json['owner_id'] as int,
      percentage: (json['percentage'] as num).toDouble(),
      audios:
          (json['audios'] as List<dynamic>).map((e) => e as String).toList(),
      color: json['color'] as String,
    );

Map<String, dynamic> _$SimillarPlaylistToJson(SimillarPlaylist instance) =>
    <String, dynamic>{
      'id': instance.id,
      'owner_id': instance.ownerID,
      'percentage': instance.percentage,
      'audios': instance.audios,
      'color': instance.color,
    };

BlockAction _$BlockActionFromJson(Map<String, dynamic> json) => BlockAction(
      sectionID: json['section_id'] as String?,
      title: json['title'] as String?,
      refItemsCount: json['ref_items_count'] as int?,
      refLayoutName: json['ref_layout_name'] as String?,
      refDataType: json['ref_data_type'] as String?,
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
      id: json['id'] as String,
      title: json['title'] as String?,
      dataType: json['data_type'] as String? ?? "none",
      layout: json['layout'],
      actions: (json['actions'] as List<dynamic>?)
          ?.map((e) => BlockAction.fromJson(e as Map<String, dynamic>))
          .toList(),
      audioIDs: (json['audios_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      playlistIDs: (json['playlists_ids'] as List<dynamic>?)
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
      id: json['id'] as String,
      title: json['title'] as String,
      url: json['url'] as String,
      blocks: (json['blocks'] as List<dynamic>?)
          ?.map((e) => SectionBlock.fromJson(e as Map<String, dynamic>))
          .toList(),
      actions: json['actions'] as List<dynamic>?,
    );

Map<String, dynamic> _$SectionToJson(Section instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'url': instance.url,
      'blocks': instance.blocks,
      'actions': instance.actions,
    };

Catalog _$CatalogFromJson(Map<String, dynamic> json) => Catalog(
      defaultSection: json['default_section'] as String,
      sections: (json['sections'] as List<dynamic>)
          .map((e) => Section.fromJson(e as Map<String, dynamic>))
          .toList(),
      header: json['header'],
      buttons: json['buttons'],
      pinnedSection: json['pinned_section'] as String?,
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
      audios: (json['audios'] as List<dynamic>)
          .map((e) => Audio.fromJson(e as Map<String, dynamic>))
          .toList(),
      playlists: (json['playlists'] as List<dynamic>)
          .map((e) => Playlist.fromJson(e as Map<String, dynamic>))
          .toList(),
      catalog: Catalog.fromJson(json['catalog'] as Map<String, dynamic>),
      recommendedPlaylists: (json['recommended_playlists'] as List<dynamic>)
          .map((e) => SimillarPlaylist.fromJson(e as Map<String, dynamic>))
          .toList(),
      audioStreamMixes: (json['audio_stream_mixes'] as List<dynamic>)
          .map((e) => AudioMix.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$APICatalogRealResponseToJson(
        APICatalogRealResponse instance) =>
    <String, dynamic>{
      'audios': instance.audios,
      'playlists': instance.playlists,
      'catalog': instance.catalog,
      'recommended_playlists': instance.recommendedPlaylists,
      'audio_stream_mixes': instance.audioStreamMixes,
    };

APICatalogGetAudioResponse _$APICatalogGetAudioResponseFromJson(
        Map<String, dynamic> json) =>
    APICatalogGetAudioResponse(
      response: json['response'] == null
          ? null
          : APICatalogRealResponse.fromJson(
              json['response'] as Map<String, dynamic>),
      error: json['error'] == null
          ? null
          : APIError.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$APICatalogGetAudioResponseToJson(
        APICatalogGetAudioResponse instance) =>
    <String, dynamic>{
      'response': instance.response,
      'error': instance.error,
    };
