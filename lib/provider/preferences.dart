import "package:flutter/material.dart";
import "package:json_annotation/json_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../enums.dart";
import "../utils.dart";
import "shared_prefs.dart";

part "preferences.g.dart";

/// Класс с настройками пользователя.
///
/// Не стоит путать с [Preferences] или [preferencesProvider].
@JsonSerializable()
class UserPreferences {
  /// Указывает, что поле "Моя музыка" включено на экране с музыкой.
  @JsonKey(name: "MyMusicChipEnabled")
  final bool myMusicChipEnabled;

  /// Указывает, что поле "Ваши плейлисты" включено на экране с музыкой.
  @JsonKey(name: "PlaylistsChipEnabled")
  final bool playlistsChipEnabled;

  /// Указывает, что поле "В реальном времени" включено на экране с музыкой.
  @JsonKey(name: "RealtimePlaylistsChipEnabled")
  final bool realtimePlaylistsChipEnabled;

  /// Указывает, что поле "Плейлисты для Вас" включено на экране с музыкой.
  @JsonKey(name: "RecommendedPlaylistsChipEnabled")
  final bool recommendedPlaylistsChipEnabled;

  /// Указывает, что поле "Совпадения по вкусам" включено на экране с музыкой.
  @JsonKey(name: "SimilarMusicChipEnabled")
  final bool similarMusicChipEnabled;

  /// Указывает, что поле "Собрано редакцией" включено на экране с музыкой.
  @JsonKey(name: "ByVKChipEnabled")
  final bool byVKChipEnabled;

  /// Указывает, что при последнем прослушивании shuffle был включён.
  @JsonKey(name: "ShuffleEnabled")
  final bool shuffleEnabled;

  /// Указывает, что Discord Rich Presence включён.
  @JsonKey(name: "DiscordRPCEnabled")
  final bool discordRPCEnabled;

  /// Указывает, что настройка "пауза при минимальной громкости" включена.
  @JsonKey(name: "PauseOnMuteEnabled")
  final bool pauseOnMuteEnabled;

  /// Указывает, что при установке плеера на паузу, воспроизведение музыки будет автоматически остановлено ([VKMusicPlayer.stop]) через некоторое время.
  @JsonKey(name: "StopOnPauseEnabled")
  final bool stopOnPauseEnabled;

  /// Указывает, что полноэкранный плеер использует изображение трека в качестве фона.
  @JsonKey(name: "PlayerThumbAsBackground")
  final bool playerThumbAsBackground;

  /// Указывает, что включён показ текста трека в полноэкранном плеере.
  @JsonKey(name: "TrackLyricsEnabled")
  final bool trackLyricsEnabled;

  /// Указывает, что цвета плеера распространяются на всё приложение.
  @JsonKey(name: "PlayerColorsAppWide")
  final bool playerColorsAppWide;

  /// Указывает, какая тема приложения используется.
  @JsonKey(name: "Theme", toJson: intFromEnum)
  final ThemeMode theme;

  /// Указывает, что включена OLED тема приложения.
  @JsonKey(name: "OLEDTheme")
  final bool oledTheme;

  /// Указывает поведение в случае закрытия приложения.
  @JsonKey(name: "CloseBehavior", toJson: intFromEnum)
  final CloseBehavior closeBehavior;

  /// Указывает, что приложение показывает предупреждение при попытке сохранить уже лайкнутый трек.
  @JsonKey(name: "CheckBeforeFavorite")
  final bool checkBeforeFavorite;

  /// Указывает политику для автообновлений.
  @JsonKey(name: "UpdatePolicy", toJson: intFromEnum)
  final UpdatePolicy updatePolicy;

  /// Указывает ветку для автообновлений.
  @JsonKey(name: "UpdateBranch", toJson: intFromEnum)
  final UpdateBranch updateBranch;

  /// Указывает, что приложение может загружать обложки треков с Deezer.
  @JsonKey(name: "DeezerThumbnails")
  final bool deezerThumbnails;

  /// Указывает, какой тип палитры цветов будет использоваться при извлечении цветов из обложек треков.
  @JsonKey(name: "DynamicSchemeType", toJson: intFromEnum)
  final DynamicSchemeType dynamicSchemeType;

  /// Указывает, что полноэкранный плеер будет использовать изображение большого размера при Desktop Layout'е.
  @JsonKey(name: "FullscreenBigThumbnail")
  final bool fullscreenBigThumbnail;

  /// Указывает, что включено debug-логирование media_kit плеера.
  @JsonKey(name: "DebugPlayerLogging")
  final bool debugPlayerLogging;

  UserPreferences({
    this.myMusicChipEnabled = true,
    this.playlistsChipEnabled = true,
    this.realtimePlaylistsChipEnabled = true,
    this.recommendedPlaylistsChipEnabled = true,
    this.similarMusicChipEnabled = true,
    this.byVKChipEnabled = true,
    this.shuffleEnabled = false,
    this.discordRPCEnabled = true,
    this.pauseOnMuteEnabled = false,
    this.stopOnPauseEnabled = true,
    this.playerThumbAsBackground = true,
    this.trackLyricsEnabled = true,
    this.playerColorsAppWide = true,
    this.theme = ThemeMode.system,
    this.oledTheme = false,
    this.closeBehavior = CloseBehavior.close,
    this.checkBeforeFavorite = true,
    this.updatePolicy = UpdatePolicy.dialog,
    this.updateBranch = UpdateBranch.releasesOnly,
    this.deezerThumbnails = false,
    this.dynamicSchemeType = DynamicSchemeType.tonalSpot,
    this.fullscreenBigThumbnail = false,
    this.debugPlayerLogging = false,
  });

  /// Делает копию этого класа с новыми передаваемыми значениями.
  UserPreferences copyWith({
    bool? myMusicChipEnabled,
    bool? playlistsChipEnabled,
    bool? realtimePlaylistsChipEnabled,
    bool? recommendedPlaylistsChipEnabled,
    bool? similarMusicChipEnabled,
    bool? byVKChipEnabled,
    bool? shuffleEnabled,
    bool? discordRPCEnabled,
    bool? pauseOnMuteEnabled,
    bool? stopOnPauseEnabled,
    bool? playerThumbAsBackground,
    bool? trackLyricsEnabled,
    bool? playerColorsAppWide,
    ThemeMode? theme,
    bool? oledTheme,
    CloseBehavior? closeBehavior,
    bool? checkBeforeFavorite,
    UpdatePolicy? updatePolicy,
    UpdateBranch? updateBranch,
    bool? deezerThumbnails,
    DynamicSchemeType? dynamicSchemeType,
    bool? fullscreenBigThumbnail,
    bool? debugPlayerLogging,
  }) =>
      UserPreferences(
        myMusicChipEnabled: myMusicChipEnabled ?? this.myMusicChipEnabled,
        playlistsChipEnabled: playlistsChipEnabled ?? this.playlistsChipEnabled,
        realtimePlaylistsChipEnabled:
            realtimePlaylistsChipEnabled ?? this.realtimePlaylistsChipEnabled,
        recommendedPlaylistsChipEnabled: recommendedPlaylistsChipEnabled ??
            this.recommendedPlaylistsChipEnabled,
        similarMusicChipEnabled:
            similarMusicChipEnabled ?? this.similarMusicChipEnabled,
        byVKChipEnabled: byVKChipEnabled ?? this.byVKChipEnabled,
        shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
        discordRPCEnabled: discordRPCEnabled ?? this.discordRPCEnabled,
        pauseOnMuteEnabled: pauseOnMuteEnabled ?? this.pauseOnMuteEnabled,
        stopOnPauseEnabled: stopOnPauseEnabled ?? this.stopOnPauseEnabled,
        playerThumbAsBackground:
            playerThumbAsBackground ?? this.playerThumbAsBackground,
        trackLyricsEnabled: trackLyricsEnabled ?? this.trackLyricsEnabled,
        playerColorsAppWide: playerColorsAppWide ?? this.playerColorsAppWide,
        theme: theme ?? this.theme,
        oledTheme: oledTheme ?? this.oledTheme,
        closeBehavior: closeBehavior ?? this.closeBehavior,
        checkBeforeFavorite: checkBeforeFavorite ?? this.checkBeforeFavorite,
        updatePolicy: updatePolicy ?? this.updatePolicy,
        updateBranch: updateBranch ?? this.updateBranch,
        deezerThumbnails: deezerThumbnails ?? this.deezerThumbnails,
        dynamicSchemeType: dynamicSchemeType ?? this.dynamicSchemeType,
        fullscreenBigThumbnail:
            fullscreenBigThumbnail ?? this.fullscreenBigThumbnail,
        debugPlayerLogging: debugPlayerLogging ?? this.debugPlayerLogging,
      );

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      _$UserPreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$UserPreferencesToJson(this);
}

/// [Provider] для хранения настроек пользователя.
@riverpod
class Preferences extends _$Preferences {
  @override
  UserPreferences build() {
    final SharedPreferences prefs = ref.read(sharedPrefsProvider);

    return UserPreferences().copyWith(
      myMusicChipEnabled: prefs.getBool("MyMusicChipEnabled"),
      playlistsChipEnabled: prefs.getBool("PlaylistsChipEnabled"),
      realtimePlaylistsChipEnabled:
          prefs.getBool("RealtimePlaylistsChipEnabled"),
      recommendedPlaylistsChipEnabled:
          prefs.getBool("RecommendedPlaylistsChipEnabled"),
      similarMusicChipEnabled: prefs.getBool("SimilarMusicChipEnabled"),
      byVKChipEnabled: prefs.getBool("ByVKChipEnabled"),
      shuffleEnabled: prefs.getBool("ShuffleEnabled"),
      discordRPCEnabled: prefs.getBool("DiscordRPCEnabled"),
      pauseOnMuteEnabled: prefs.getBool("PauseOnMuteEnabled"),
      stopOnPauseEnabled: prefs.getBool("StopOnPauseEnabled"),
      playerThumbAsBackground: prefs.getBool("PlayerThumbAsBackground"),
      trackLyricsEnabled: prefs.getBool("TrackLyricsEnabled"),
      playerColorsAppWide: prefs.getBool("PlayerColorsAppWide"),
      theme: ThemeMode.values[prefs.getInt("Theme") ?? 0],
      oledTheme: prefs.getBool("OLEDTheme"),
      closeBehavior: CloseBehavior.values[prefs.getInt("CloseBehavior") ?? 0],
      checkBeforeFavorite: prefs.getBool("CheckBeforeFavorite"),
      updatePolicy: UpdatePolicy.values[prefs.getInt("UpdatePolicy") ?? 0],
      updateBranch: UpdateBranch.values[prefs.getInt("UpdateBranch") ?? 0],
      deezerThumbnails: prefs.getBool("DeezerThumbnails"),
      dynamicSchemeType:
          DynamicSchemeType.values[prefs.getInt("DynamicSchemeType") ?? 0],
      fullscreenBigThumbnail: prefs.getBool("FullscreenBigThumbnail"),
      debugPlayerLogging: prefs.getBool("DebugPlayerLogging"),
    );
  }

  @override
  set state(UserPreferences newState) {
    final SharedPreferences prefs = ref.read(sharedPrefsProvider);

    final Map<String, dynamic> oldJson = state.toJson();
    final Map<String, dynamic> json = newState.toJson();

    for (String key in json.keys) {
      final dynamic newValue = json[key];
      if (oldJson[key] == newValue) continue;

      if (newValue is bool) {
        prefs.setBool(key, newValue);
      } else if (newValue is int) {
        prefs.setInt(key, newValue);
      } else if (newValue is double) {
        prefs.setDouble(key, newValue);
      } else if (newValue is String) {
        prefs.setString(key, newValue);
      } else if (newValue == null) {
        prefs.remove(key);
      } else {
        throw Exception(
          "'$key' has an unsupported type: ${newValue.runtimeType}",
        );
      }
    }

    super.state = newState;
  }

  void setMyMusicChipEnabled(bool enabled) =>
      state = state.copyWith(myMusicChipEnabled: enabled);

  void setPlaylistsChipEnabled(bool enabled) =>
      state = state.copyWith(playlistsChipEnabled: enabled);

  void setRealtimePlaylistsChipEnabled(bool enabled) =>
      state = state.copyWith(realtimePlaylistsChipEnabled: enabled);

  void setRecommendedPlaylistsChipEnabled(bool enabled) =>
      state = state.copyWith(recommendedPlaylistsChipEnabled: enabled);

  void setSimilarMusicChipEnabled(bool enabled) =>
      state = state.copyWith(similarMusicChipEnabled: enabled);

  void setByVKChipEnabled(bool enabled) =>
      state = state.copyWith(byVKChipEnabled: enabled);

  void setShuffleEnabled(bool enabled) =>
      state = state.copyWith(shuffleEnabled: enabled);

  void setDiscordRPCEnabled(bool enabled) =>
      state = state.copyWith(discordRPCEnabled: enabled);

  void setPauseOnMuteEnabled(bool enabled) =>
      state = state.copyWith(pauseOnMuteEnabled: enabled);

  void setStopOnPauseEnabled(bool enabled) =>
      state = state.copyWith(stopOnPauseEnabled: enabled);

  void setPlayerThumbAsBackground(bool enabled) =>
      state = state.copyWith(playerThumbAsBackground: enabled);

  void setTrackLyricsEnabled(bool enabled) =>
      state = state.copyWith(trackLyricsEnabled: enabled);

  void setPlayerColorsAppWide(bool enabled) =>
      state = state.copyWith(playerColorsAppWide: enabled);

  void setTheme(ThemeMode theme) => state = state.copyWith(theme: theme);

  void setOLEDThemeEnabled(bool enabled) =>
      state = state.copyWith(oledTheme: enabled);

  void setCloseBehavior(CloseBehavior behavior) =>
      state = state.copyWith(closeBehavior: behavior);

  void setCheckBeforeFavorite(bool enabled) =>
      state = state.copyWith(checkBeforeFavorite: enabled);

  void setUpdatePolicy(UpdatePolicy policy) =>
      state = state.copyWith(updatePolicy: policy);

  void setUpdateBranch(UpdateBranch branch) =>
      state = state.copyWith(updateBranch: branch);

  void setDeezerThumbnails(bool enabled) =>
      state = state.copyWith(deezerThumbnails: enabled);

  void setDynamicSchemeType(DynamicSchemeType dynamicScheme) =>
      state = state.copyWith(dynamicSchemeType: dynamicScheme);

  void setFullscreenBigThumbnailEnabled(bool enabled) =>
      state = state.copyWith(fullscreenBigThumbnail: enabled);

  void setDebugPlayerLogging(bool enabled) =>
      state = state.copyWith(debugPlayerLogging: enabled);
}
