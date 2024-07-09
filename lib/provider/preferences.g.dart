// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserPreferences _$UserPreferencesFromJson(Map<String, dynamic> json) =>
    UserPreferences(
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
      playerColorsAppWide: json['PlayerColorsAppWide'] as bool? ?? false,
      theme: $enumDecodeNullable(_$ThemeModeEnumMap, json['Theme']) ??
          ThemeMode.system,
      oledTheme: json['OLEDTheme'] as bool? ?? false,
      closeBehavior:
          $enumDecodeNullable(_$CloseBehaviorEnumMap, json['CloseBehavior']) ??
              CloseBehavior.close,
      checkBeforeFavorite: json['CheckBeforeFavorite'] as bool? ?? true,
      updatePolicy:
          $enumDecodeNullable(_$UpdatePolicyEnumMap, json['UpdatePolicy']) ??
              UpdatePolicy.dialog,
      updateBranch:
          $enumDecodeNullable(_$UpdateBranchEnumMap, json['UpdateBranch']) ??
              UpdateBranch.releasesOnly,
      deezerThumbnails: json['DeezerThumbnails'] as bool? ?? false,
      dynamicSchemeType: $enumDecodeNullable(
              _$DynamicSchemeTypeEnumMap, json['DynamicSchemeType']) ??
          DynamicSchemeType.tonalSpot,
      spotifyLyrics: json['SpotifyLyrics'] as bool? ?? false,
      fullscreenBigThumbnail: json['FullscreenBigThumbnail'] as bool? ?? false,
      debugPlayerLogging: json['DebugPlayerLogging'] as bool? ?? false,
    );

Map<String, dynamic> _$UserPreferencesToJson(UserPreferences instance) =>
    <String, dynamic>{
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
      'SpotifyLyrics': instance.spotifyLyrics,
      'FullscreenBigThumbnail': instance.fullscreenBigThumbnail,
      'DebugPlayerLogging': instance.debugPlayerLogging,
    };

const _$ThemeModeEnumMap = {
  ThemeMode.system: 'system',
  ThemeMode.light: 'light',
  ThemeMode.dark: 'dark',
};

const _$CloseBehaviorEnumMap = {
  CloseBehavior.close: 'close',
  CloseBehavior.minimize: 'minimize',
  CloseBehavior.minimizeIfPlaying: 'minimizeIfPlaying',
};

const _$UpdatePolicyEnumMap = {
  UpdatePolicy.dialog: 'dialog',
  UpdatePolicy.popup: 'popup',
  UpdatePolicy.disabled: 'disabled',
};

const _$UpdateBranchEnumMap = {
  UpdateBranch.releasesOnly: 'releasesOnly',
  UpdateBranch.prereleases: 'prereleases',
};

const _$DynamicSchemeTypeEnumMap = {
  DynamicSchemeType.tonalSpot: 'tonalSpot',
  DynamicSchemeType.neutral: 'neutral',
  DynamicSchemeType.content: 'content',
  DynamicSchemeType.monochrome: 'monochrome',
};

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$preferencesHash() => r'b05ae61ecc33f6a591ac0a512f088138503b6424';

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
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
