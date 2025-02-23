// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserPreferences _$UserPreferencesFromJson(Map<String, dynamic> json) =>
    UserPreferences(
      dbVersion: (json['DBVersion'] as num?)?.toInt() ?? 1,
      myMusicChipEnabled: json['MyMusicChipEnabled'] as bool? ?? true,
      playlistsChipEnabled: json['PlaylistsChipEnabled'] as bool? ?? true,
      realtimePlaylistsChipEnabled:
          json['RealtimePlaylistsChipEnabled'] as bool? ?? true,
      recommendedPlaylistsChipEnabled:
          json['RecommendedPlaylistsChipEnabled'] as bool? ?? true,
      similarMusicChipEnabled: json['SimilarMusicChipEnabled'] as bool? ?? true,
      byVKChipEnabled: json['ByVKChipEnabled'] as bool? ?? true,
      shuffleEnabled: json['ShuffleEnabled'] as bool? ?? false,
      discordRPCEnabled: json['DiscordRPCEnabled'] as bool? ?? true,
      pauseOnMuteEnabled: json['PauseOnMuteEnabled'] as bool? ?? false,
      stopOnPauseEnabled: json['StopOnPauseEnabled'] as bool? ?? true,
      playerThumbAsBackground: json['PlayerThumbAsBackground'] as bool? ?? true,
      trackLyricsEnabled: json['TrackLyricsEnabled'] as bool? ?? true,
      playerColorsAppWide: json['PlayerColorsAppWide'] as bool? ?? true,
      theme: json['Theme'] == null
          ? ThemeMode.system
          : UserPreferences._themeFromJson((json['Theme'] as num).toInt()),
      oledTheme: json['OLEDTheme'] as bool? ?? false,
      closeBehavior: json['CloseBehavior'] == null
          ? CloseBehavior.close
          : UserPreferences._closeBehaviorFromJson(
              (json['CloseBehavior'] as num).toInt()),
      checkBeforeFavorite: json['CheckBeforeFavorite'] as bool? ?? true,
      updatePolicy: json['UpdatePolicy'] == null
          ? UpdatePolicy.dialog
          : UserPreferences._updatePolicyFromJson(
              (json['UpdatePolicy'] as num).toInt()),
      updateBranch: json['UpdateBranch'] == null
          ? UpdateBranch.releasesOnly
          : UserPreferences._updateBranchFromJson(
              (json['UpdateBranch'] as num).toInt()),
      deezerThumbnails: json['DeezerThumbnails'] as bool? ?? false,
      dynamicSchemeType: json['DynamicSchemeType'] == null
          ? DynamicSchemeType.tonalSpot
          : UserPreferences._dynamicSchemeTypeFromJson(
              (json['DynamicSchemeType'] as num).toInt()),
      fullscreenBigThumbnail: json['FullscreenBigThumbnail'] as bool? ?? false,
      debugPlayerLogging: json['DebugPlayerLogging'] as bool? ?? false,
      preReleaseWarningShown: json['PreReleaseWarningShown'] as bool? ?? false,
      lrcLibEnabled: json['LRCLIBEnabled'] as bool? ?? false,
      loopModeEnabled: json['LoopModeEnabled'] as bool? ?? false,
      volume: (json['Volume'] as num?)?.toDouble() ?? 1.0,
      rewindOnPreviousBehavior: json['RewindOnPreviousBehavior'] == null
          ? RewindBehavior.always
          : UserPreferences._rewindOnPreviousBehaviorFromJson(
              (json['RewindOnPreviousBehavior'] as num).toInt()),
      spoilerNextTrack: json['SpoilerNextTrack'] as bool? ?? true,
      debugOptionsEnabled: json['DebugOptionsEnabled'] as bool? ?? false,
      alternateDesktopMiniplayerSlider:
          json['AlternateDesktopMiniplayerSlider'] as bool? ?? false,
      showRemainingTime: json['ShowRemainingTime'] as bool? ?? false,
      androidKeepPlayingOnClose:
          json['AndroidKeepPlayingOnClose'] as bool? ?? false,
      shuffleOnPlay: json['ShuffleOnPlay'] as bool? ?? true,
      exportedSections: (json['ExportedSections'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      crossfadeColors: json['CrossfadeColors'] as bool? ?? true,
      trackTitleInWindowBar: json['TrackTitleInWindowBar'] as bool? ?? true,
    );

Map<String, dynamic> _$UserPreferencesToJson(UserPreferences instance) =>
    <String, dynamic>{
      'DBVersion': instance.dbVersion,
      'MyMusicChipEnabled': instance.myMusicChipEnabled,
      'PlaylistsChipEnabled': instance.playlistsChipEnabled,
      'RealtimePlaylistsChipEnabled': instance.realtimePlaylistsChipEnabled,
      'RecommendedPlaylistsChipEnabled':
          instance.recommendedPlaylistsChipEnabled,
      'SimilarMusicChipEnabled': instance.similarMusicChipEnabled,
      'ByVKChipEnabled': instance.byVKChipEnabled,
      'ShuffleEnabled': instance.shuffleEnabled,
      'DiscordRPCEnabled': instance.discordRPCEnabled,
      'PauseOnMuteEnabled': instance.pauseOnMuteEnabled,
      'StopOnPauseEnabled': instance.stopOnPauseEnabled,
      'PlayerThumbAsBackground': instance.playerThumbAsBackground,
      'TrackLyricsEnabled': instance.trackLyricsEnabled,
      'PlayerColorsAppWide': instance.playerColorsAppWide,
      'Theme': intFromEnum(instance.theme),
      'OLEDTheme': instance.oledTheme,
      'CloseBehavior': intFromEnum(instance.closeBehavior),
      'CheckBeforeFavorite': instance.checkBeforeFavorite,
      'UpdatePolicy': intFromEnum(instance.updatePolicy),
      'UpdateBranch': intFromEnum(instance.updateBranch),
      'DeezerThumbnails': instance.deezerThumbnails,
      'DynamicSchemeType': intFromEnum(instance.dynamicSchemeType),
      'FullscreenBigThumbnail': instance.fullscreenBigThumbnail,
      'DebugPlayerLogging': instance.debugPlayerLogging,
      'PreReleaseWarningShown': instance.preReleaseWarningShown,
      'LRCLIBEnabled': instance.lrcLibEnabled,
      'LoopModeEnabled': instance.loopModeEnabled,
      'Volume': instance.volume,
      'RewindOnPreviousBehavior':
          intFromEnum(instance.rewindOnPreviousBehavior),
      'SpoilerNextTrack': instance.spoilerNextTrack,
      'DebugOptionsEnabled': instance.debugOptionsEnabled,
      'AlternateDesktopMiniplayerSlider':
          instance.alternateDesktopMiniplayerSlider,
      'ShowRemainingTime': instance.showRemainingTime,
      'AndroidKeepPlayingOnClose': instance.androidKeepPlayingOnClose,
      'ShuffleOnPlay': instance.shuffleOnPlay,
      'ExportedSections': instance.exportedSections,
      'CrossfadeColors': instance.crossfadeColors,
      'TrackTitleInWindowBar': instance.trackTitleInWindowBar,
    };

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$preferencesHash() => r'dd57047993f2d468dcf5a3c91ce37c410459cd64';

/// [Provider] для хранения настроек пользователя.
///
/// Copied from [Preferences].
@ProviderFor(Preferences)
final preferencesProvider =
    AutoDisposeNotifierProvider<Preferences, UserPreferences>.internal(
  Preferences.new,
  name: r'preferencesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$preferencesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Preferences = AutoDisposeNotifier<UserPreferences>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
