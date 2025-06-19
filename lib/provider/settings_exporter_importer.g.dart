// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_exporter_importer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExportedThumbnail _$ExportedThumbnailFromJson(Map<String, dynamic> json) =>
    ExportedThumbnail(
      photoSmall: json['photoSmall'] as String,
      photoMedium: json['photoMedium'] as String,
      photoBig: json['photoBig'] as String,
      photoMax: json['photoMax'] as String,
    );

Map<String, dynamic> _$ExportedThumbnailToJson(ExportedThumbnail instance) =>
    <String, dynamic>{
      'photoSmall': instance.photoSmall,
      'photoMedium': instance.photoMedium,
      'photoBig': instance.photoBig,
      'photoMax': instance.photoMax,
    };

ExportedAudio _$ExportedAudioFromJson(Map<String, dynamic> json) =>
    ExportedAudio(
      id: (json['id'] as num).toInt(),
      ownerID: (json['ownerID'] as num).toInt(),
      playlistOwnerID: (json['playlistOwnerID'] as num).toInt(),
      playlistID: (json['playlistID'] as num).toInt(),
      isExported: json['isExported'] as bool?,
      forceDeezerThumbs: json['forceDeezerThumbs'] as bool?,
      deezerThumbs: json['deezerThumbs'] == null
          ? null
          : ExportedThumbnail.fromJson(
              json['deezerThumbs'] as Map<String, dynamic>),
      isCached: json['isCached'] as bool?,
      replacedLocally: json['replacedLocally'] as bool?,
      debugComment: json['debugComment'] as String?,
    );

Map<String, dynamic> _$ExportedAudioToJson(ExportedAudio instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ownerID': instance.ownerID,
      'playlistOwnerID': instance.playlistOwnerID,
      'playlistID': instance.playlistID,
      if (instance.isExported case final value?) 'isExported': value,
      if (instance.forceDeezerThumbs case final value?)
        'forceDeezerThumbs': value,
      if (instance.deezerThumbs?.toJson() case final value?)
        'deezerThumbs': value,
      if (instance.isCached case final value?) 'isCached': value,
      if (instance.replacedLocally case final value?) 'replacedLocally': value,
    };

ExportedSections _$ExportedSectionsFromJson(Map<String, dynamic> json) =>
    ExportedSections(
      settings: json['settings'] as Map<String, dynamic>?,
      modifiedThumbnails: (json['modifiedThumbnails'] as List<dynamic>?)
          ?.map((e) => ExportedAudio.fromJson(e as Map<String, dynamic>))
          .toList(),
      modifiedLyrics: (json['modifiedLyrics'] as List<dynamic>?)
          ?.map((e) => ExportedAudio.fromJson(e as Map<String, dynamic>))
          .toList(),
      modifiedLocalMetadata: (json['modifiedLocalMetadata'] as List<dynamic>?)
          ?.map((e) => ExportedAudio.fromJson(e as Map<String, dynamic>))
          .toList(),
      cachedRestricted: (json['cachedRestricted'] as List<dynamic>?)
          ?.map((e) => ExportedAudio.fromJson(e as Map<String, dynamic>))
          .toList(),
      locallyReplacedAudios: (json['locallyReplacedAudios'] as List<dynamic>?)
          ?.map((e) => ExportedAudio.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ExportedSectionsToJson(ExportedSections instance) =>
    <String, dynamic>{
      if (instance.settings case final value?) 'settings': value,
      if (instance.modifiedThumbnails?.map((e) => e.toJson()).toList()
          case final value?)
        'modifiedThumbnails': value,
      if (instance.modifiedLyrics?.map((e) => e.toJson()).toList()
          case final value?)
        'modifiedLyrics': value,
      if (instance.modifiedLocalMetadata?.map((e) => e.toJson()).toList()
          case final value?)
        'modifiedLocalMetadata': value,
      if (instance.cachedRestricted?.map((e) => e.toJson()).toList()
          case final value?)
        'cachedRestricted': value,
      if (instance.locallyReplacedAudios?.map((e) => e.toJson()).toList()
          case final value?)
        'locallyReplacedAudios': value,
    };

ExportedAudiosInfoMetadata _$ExportedAudiosInfoMetadataFromJson(
        Map<String, dynamic> json) =>
    ExportedAudiosInfoMetadata(
      exporterVersion: (json['exporterVersion'] as num).toInt(),
      appVersion: json['appVersion'] as String,
      exportStartedAt: (json['exportStartedAt'] as num).toInt(),
      exportedAt: (json['exportedAt'] as num).toInt(),
      hash: json['hash'] as String?,
      sections:
          ExportedSections.fromJson(json['sections'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ExportedAudiosInfoMetadataToJson(
        ExportedAudiosInfoMetadata instance) =>
    <String, dynamic>{
      'exporterVersion': instance.exporterVersion,
      'appVersion': instance.appVersion,
      'exportStartedAt': instance.exportStartedAt,
      'exportedAt': instance.exportedAt,
      'hash': instance.hash,
      'sections': instance.sections.toJson(),
    };

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$settingsExporterHash() => r'145eb1de25d26b7a0c06ea376473a27f1896f317';

/// [Provider] для получения объекта [SettingsExporter].
///
/// Copied from [settingsExporter].
@ProviderFor(settingsExporter)
final settingsExporterProvider = AutoDisposeProvider<SettingsExporter>.internal(
  settingsExporter,
  name: r'settingsExporterProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$settingsExporterHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SettingsExporterRef = AutoDisposeProviderRef<SettingsExporter>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
