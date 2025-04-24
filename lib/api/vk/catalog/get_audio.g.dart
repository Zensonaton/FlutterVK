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

SimillarPlaylist _$SimillarPlaylistFromJson(Map<String, dynamic> json) =>
    SimillarPlaylist(
      id: (json['id'] as num).toInt(),
      ownerID: (json['owner_id'] as num).toInt(),
      percentage: (json['percentage'] as num).toDouble(),
      audios:
          (json['audios'] as List<dynamic>).map((e) => e as String).toList(),
      color: json['color'] as String,
    );

BlockAction _$BlockActionFromJson(Map<String, dynamic> json) => BlockAction(
      sectionID: json['section_id'] as String?,
      title: json['title'] as String?,
      refItemsCount: (json['ref_items_count'] as num?)?.toInt(),
      refLayoutName: json['ref_layout_name'] as String?,
      refDataType: json['ref_data_type'] as String?,
    );

SectionBlock _$SectionBlockFromJson(Map<String, dynamic> json) => SectionBlock(
      id: json['id'] as String?,
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

Section _$SectionFromJson(Map<String, dynamic> json) => Section(
      id: json['id'] as String?,
      title: json['title'] as String?,
      url: json['url'] as String?,
      blocks: (json['blocks'] as List<dynamic>?)
          ?.map((e) => SectionBlock.fromJson(e as Map<String, dynamic>))
          .toList(),
      actions: json['actions'] as List<dynamic>?,
    );

Catalog _$CatalogFromJson(Map<String, dynamic> json) => Catalog(
      defaultSection: json['default_section'] as String?,
      sections: (json['sections'] as List<dynamic>)
          .map((e) => Section.fromJson(e as Map<String, dynamic>))
          .toList(),
      header: json['header'],
      buttons: json['buttons'],
      pinnedSection: json['pinned_section'] as String?,
    );

APICatalogGetAudioResponse _$APICatalogGetAudioResponseFromJson(
        Map<String, dynamic> json) =>
    APICatalogGetAudioResponse(
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
      audioStreamMixes: (json['audio_stream_mixes'] as List<dynamic>?)
              ?.map((e) => AudioMix.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$APICatalogGetAudioResponseToJson(
        APICatalogGetAudioResponse instance) =>
    <String, dynamic>{
      'audios': instance.audios,
      'playlists': instance.playlists,
      'catalog': instance.catalog,
      'recommended_playlists': instance.recommendedPlaylists,
      'audio_stream_mixes': instance.audioStreamMixes,
    };
