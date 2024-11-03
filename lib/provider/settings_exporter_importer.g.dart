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

Map<String, dynamic> _$ExportedAudioToJson(ExportedAudio instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'ownerID': instance.ownerID,
    'playlistOwnerID': instance.playlistOwnerID,
    'playlistID': instance.playlistID,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('isExported', instance.isExported);
  writeNotNull('forceDeezerThumbs', instance.forceDeezerThumbs);
  writeNotNull('deezerThumbs', instance.deezerThumbs);
  writeNotNull('isCached', instance.isCached);
  writeNotNull('replacedLocally', instance.replacedLocally);
  return val;
}

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

Map<String, dynamic> _$ExportedSectionsToJson(ExportedSections instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('settings', instance.settings);
  writeNotNull('modifiedThumbnails', instance.modifiedThumbnails);
  writeNotNull('modifiedLyrics', instance.modifiedLyrics);
  writeNotNull('modifiedLocalMetadata', instance.modifiedLocalMetadata);
  writeNotNull('cachedRestricted', instance.cachedRestricted);
  writeNotNull('locallyReplacedAudios', instance.locallyReplacedAudios);
  return val;
}

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
      'sections': instance.sections,
    };

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$settingsExporterHash() => r'75c5fb83b798940fc91c80434c763f8b5f1c1d92';

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

typedef SettingsExporterRef = AutoDisposeProviderRef<SettingsExporter>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
