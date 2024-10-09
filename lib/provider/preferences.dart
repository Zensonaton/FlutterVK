import "package:flutter/material.dart";
import "package:json_annotation/json_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../enums.dart";
import "../services/db.dart";
import "../services/logger.dart";
import "../utils.dart";
import "shared_prefs.dart";

part "preferences.g.dart";

/// Класс с настройками пользователя.
///
/// Не стоит путать с [Preferences] или [preferencesProvider].
@JsonSerializable()
class UserPreferences {
  /// Список из JSON-ключей, которые обязаны находиться в SharedPreferences, даже если их значение равно стандартному.
  static final List<String> ignoreDefaultKeys = [
    "DBVersion",
  ];

  /// Указывает версию базы данных Isar. Используется для миграции.
  @JsonKey(name: "DBVersion")
  final int dbVersion;

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

  /// Указывает поведение в случае закрытия приложения на OS Windows.
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

  /// Указывает, что было показано предупреждение о том, что пользователь запустил бета-версию приложения.
  @JsonKey(name: "PreReleaseWarningShown")
  final bool preReleaseWarningShown;

  /// Указывает, что приложение будет загружать тексты песен с LRCLIB.
  @JsonKey(name: "LRCLIBEnabled")
  final bool lrcLibEnabled;

  /// Указывает, включён ли loop-mode для плеера.
  @JsonKey(name: "LoopModeEnabled")
  final bool loopModeEnabled;

  /// Указывает, какая громкость у плеера.
  ///
  /// Принимается значение от `0.0` (0%) либо `1.0` (100%).
  @JsonKey(name: "Volume")
  final double volume;

  /// Указывает, в каких случаях трек будет перематываться в начало при попытке запустить предыдущий.
  @JsonKey(name: "RewindOnPreviousBehavior", toJson: intFromEnum)
  final RewindBehavior rewindOnPreviousBehavior;

  /// Указывает, включена ли настройка "спойлер следующего трека".
  @JsonKey(name: "SpoilerNextTrack")
  final bool spoilerNextTrack;

  /// Указывает, включён ли показ debugging-опций в "профиле" даже в release-режиме.
  @JsonKey(name: "DebugOptionsEnabled")
  final bool debugOptionsEnabled;

  /// Указывает, что будет использоваться альтернативный вид Slider'а у мини-плеера при Desktop Layout'е.
  @JsonKey(name: "AlternateDesktopMiniplayerSlider")
  final bool alternateDesktopMiniplayerSlider;

  /// Указывает, что вместо прогресса воспроизведения трека будет показано оставшееся время до конца трека.
  @JsonKey(name: "ShowRemainingTime")
  final bool showRemainingTime;

  /// Указывает, что при закрытии приложения на OS Android приложение не будет закрываться, а будет скрываться в фоне.
  @JsonKey(name: "AndroidKeepPlayingOnClose")
  final bool androidKeepPlayingOnClose;

  UserPreferences({
    this.dbVersion = IsarDBMigrator.maxDBVersion,
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
    this.preReleaseWarningShown = false,
    this.lrcLibEnabled = false,
    this.loopModeEnabled = false,
    this.volume = 1.0,
    this.rewindOnPreviousBehavior = RewindBehavior.always,
    this.spoilerNextTrack = true,
    this.debugOptionsEnabled = false,
    this.alternateDesktopMiniplayerSlider = false,
    this.showRemainingTime = false,
    this.androidKeepPlayingOnClose = false,
  });

  /// Делает копию этого класа с новыми передаваемыми значениями.
  UserPreferences copyWith({
    int? dbVersion,
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
    bool? preReleaseWarningShown,
    bool? lrcLibEnabled,
    bool? loopModeEnabled,
    double? volume,
    RewindBehavior? rewindOnPreviousBehavior,
    bool? spoilerNextTrack,
    bool? debugOptionsEnabled,
    bool? alternateDesktopMiniplayerSlider,
    bool? showRemainingTime,
    bool? androidKeepPlayingOnClose,
  }) =>
      UserPreferences(
        dbVersion: dbVersion ?? this.dbVersion,
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
        preReleaseWarningShown:
            preReleaseWarningShown ?? this.preReleaseWarningShown,
        lrcLibEnabled: lrcLibEnabled ?? this.lrcLibEnabled,
        loopModeEnabled: loopModeEnabled ?? this.loopModeEnabled,
        volume: volume ?? this.volume,
        rewindOnPreviousBehavior:
            rewindOnPreviousBehavior ?? this.rewindOnPreviousBehavior,
        spoilerNextTrack: spoilerNextTrack ?? this.spoilerNextTrack,
        debugOptionsEnabled: debugOptionsEnabled ?? this.debugOptionsEnabled,
        alternateDesktopMiniplayerSlider: alternateDesktopMiniplayerSlider ??
            this.alternateDesktopMiniplayerSlider,
        showRemainingTime: showRemainingTime ?? this.showRemainingTime,
        androidKeepPlayingOnClose:
            androidKeepPlayingOnClose ?? this.androidKeepPlayingOnClose,
      );

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      _$UserPreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$UserPreferencesToJson(this);
}

/// [Provider] для хранения настроек пользователя.
@riverpod
class Preferences extends _$Preferences {
  static final AppLogger logger = getLogger("Preferences");

  @override
  UserPreferences build() {
    final SharedPreferences prefs = ref.read(sharedPrefsProvider);

    return UserPreferences().copyWith(
      dbVersion: prefs.getInt("DBVersion"),
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
      preReleaseWarningShown: prefs.getBool("PreReleaseWarningShown"),
      lrcLibEnabled: prefs.getBool("LRCLIBEnabled"),
      loopModeEnabled: prefs.getBool("LoopModeEnabled"),
      volume: prefs.getDouble("Volume"),
      rewindOnPreviousBehavior:
          RewindBehavior.values[prefs.getInt("RewindOnPreviousBehavior") ?? 0],
      spoilerNextTrack: prefs.getBool("SpoilerNextTrack"),
      debugOptionsEnabled: prefs.getBool("DebugOptionsEnabled"),
      alternateDesktopMiniplayerSlider:
          prefs.getBool("AlternateDesktopMiniplayerSlider"),
      showRemainingTime: prefs.getBool("ShowRemainingTime"),
      androidKeepPlayingOnClose: prefs.getBool("AndroidKeepPlayingOnClose"),
    );
  }

  @override
  set state(UserPreferences newState) {
    final SharedPreferences prefs = ref.read(sharedPrefsProvider);

    final Map<String, dynamic> defaultJson = UserPreferences().toJson();
    final Map<String, dynamic> oldJson = state.toJson();
    final Map<String, dynamic> newJson = newState.toJson();
    bool hasChanges = false;

    // Проходимся по новому списку из ключей и значений.
    for (MapEntry<String, dynamic> entry in newJson.entries) {
      final String key = entry.key;

      dynamic newValue = entry.value;
      dynamic oldValue = oldJson[key];
      dynamic defValue = defaultJson[key];

      // Если значение равно стандартному, то удаляем ключ из SharedPreferences.
      // Единственное, когда так делать не стоит - это когда ключ есть в списке ignoreDefaultKeys.
      if (newValue == defValue &&
          !UserPreferences.ignoreDefaultKeys.contains(key)) {
        newValue = null;
      }

      // Если ничего не изменилось, то пропускаем ключ.
      if (newValue == oldValue) continue;

      // Мы получили новое значение, теперь его нужно записать в SharedPreferences.
      hasChanges = true;
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

    // Если были изменения, то обновляем состояние.
    if (hasChanges) {
      logger.d("Preferences updated");

      super.state = newState;
    }
  }

  void setDBVersion(int version) => state = state.copyWith(dbVersion: version);

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

  void setPreReleaseWarningShown(bool enabled) =>
      state = state.copyWith(preReleaseWarningShown: enabled);

  void setLRCLIBEnabled(bool enabled) =>
      state = state.copyWith(lrcLibEnabled: enabled);

  void setLoopModeEnabled(bool enabled) =>
      state = state.copyWith(loopModeEnabled: enabled);

  void setVolume(double volume) => state = state.copyWith(volume: volume);

  void setRewindOnPreviousBehavior(RewindBehavior behavior) =>
      state = state.copyWith(rewindOnPreviousBehavior: behavior);

  void setSpoilerNextTrackEnabled(bool enabled) =>
      state = state.copyWith(spoilerNextTrack: enabled);

  void setDebugOptionsEnabled(bool enabled) =>
      state = state.copyWith(debugOptionsEnabled: enabled);

  void setAlternateDesktopMiniplayerSlider(bool enabled) =>
      state = state.copyWith(alternateDesktopMiniplayerSlider: enabled);

  void setShowRemainingTime(bool enabled) =>
      state = state.copyWith(showRemainingTime: enabled);

  void setAndroidKeepPlayingOnClose(bool enabled) =>
      state = state.copyWith(androidKeepPlayingOnClose: enabled);
}
