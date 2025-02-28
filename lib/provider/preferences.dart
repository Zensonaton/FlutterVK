import "package:flutter/material.dart";
import "package:json_annotation/json_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../enums.dart";
import "../services/db.dart"
    if (dart.library.js_interop) "../services/db_stub.dart";
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

  /// Список из JSON-ключей, которые не стоит экспортировать.
  static final List<String> exportIgnoreKeys = [
    "DBVersion",
    "ExportedSections",
  ];

  /// Указывает версию базы данных Isar. Используется для миграции.
  @JsonKey(name: "DBVersion", defaultValue: AppStorage.maxDBVersion)
  final int dbVersion;

  /// Указывает, что поле "Моя музыка" включено на экране с музыкой.
  @JsonKey(name: "MyMusicChipEnabled", defaultValue: true)
  final bool myMusicChipEnabled;

  /// Указывает, что поле "Ваши плейлисты" включено на экране с музыкой.
  @JsonKey(name: "PlaylistsChipEnabled", defaultValue: true)
  final bool playlistsChipEnabled;

  /// Указывает, что поле "В реальном времени" включено на экране с музыкой.
  @JsonKey(name: "RealtimePlaylistsChipEnabled", defaultValue: true)
  final bool realtimePlaylistsChipEnabled;

  /// Указывает, что поле "Плейлисты для Вас" включено на экране с музыкой.
  @JsonKey(name: "RecommendedPlaylistsChipEnabled", defaultValue: true)
  final bool recommendedPlaylistsChipEnabled;

  /// Указывает, что поле "Совпадения по вкусам" включено на экране с музыкой.
  @JsonKey(name: "SimilarMusicChipEnabled", defaultValue: true)
  final bool similarMusicChipEnabled;

  /// Указывает, что поле "Собрано редакцией" включено на экране с музыкой.
  @JsonKey(name: "ByVKChipEnabled", defaultValue: true)
  final bool byVKChipEnabled;

  /// Указывает, что при последнем прослушивании shuffle был включён.
  @JsonKey(name: "ShuffleEnabled", defaultValue: false)
  final bool shuffleEnabled;

  /// Указывает, что Discord Rich Presence включён.
  @JsonKey(name: "DiscordRPCEnabled", defaultValue: true)
  final bool discordRPCEnabled;

  /// Указывает, что настройка "пауза при минимальной громкости" включена.
  @JsonKey(name: "PauseOnMuteEnabled", defaultValue: false)
  final bool pauseOnMuteEnabled;

  /// Указывает, что при установке плеера на паузу, воспроизведение музыки будет автоматически остановлено ([VKMusicPlayer.stop]) через некоторое время.
  @JsonKey(name: "StopOnPauseEnabled", defaultValue: true)
  final bool stopOnPauseEnabled;

  /// Указывает, что полноэкранный плеер использует изображение трека в качестве фона.
  @JsonKey(name: "PlayerThumbAsBackground", defaultValue: true)
  final bool playerThumbAsBackground;

  /// Указывает, что включён показ текста трека в полноэкранном плеере.
  @JsonKey(name: "TrackLyricsEnabled", defaultValue: true)
  final bool trackLyricsEnabled;

  /// Указывает, что цвета плеера распространяются на всё приложение.
  @JsonKey(name: "PlayerColorsAppWide", defaultValue: true)
  final bool playerColorsAppWide;

  /// Указывает, какая тема приложения используется.
  @JsonKey(
    name: "Theme",
    toJson: intFromEnum,
    fromJson: _themeFromJson,
    defaultValue: ThemeMode.system,
  )
  final ThemeMode theme;
  static _themeFromJson(int value) => ThemeMode.values[value];

  /// Указывает, что включена OLED тема приложения.
  @JsonKey(name: "OLEDTheme", defaultValue: false)
  final bool oledTheme;

  /// Указывает поведение в случае закрытия приложения на OS Windows.
  @JsonKey(
    name: "CloseBehavior",
    toJson: intFromEnum,
    fromJson: _closeBehaviorFromJson,
    defaultValue: CloseBehavior.close,
  )
  final CloseBehavior closeBehavior;
  static _closeBehaviorFromJson(int value) => CloseBehavior.values[value];

  /// Указывает, что приложение показывает предупреждение при попытке сохранить уже лайкнутый трек.
  @JsonKey(name: "CheckBeforeFavorite", defaultValue: true)
  final bool checkBeforeFavorite;

  /// Указывает политику для автообновлений.
  @JsonKey(
    name: "UpdatePolicy",
    toJson: intFromEnum,
    fromJson: _updatePolicyFromJson,
    defaultValue: UpdatePolicy.dialog,
  )
  final UpdatePolicy updatePolicy;
  static _updatePolicyFromJson(int value) => UpdatePolicy.values[value];

  /// Указывает ветку для автообновлений.
  @JsonKey(
    name: "UpdateBranch",
    toJson: intFromEnum,
    fromJson: _updateBranchFromJson,
    defaultValue: UpdateBranch.releasesOnly,
  )
  final UpdateBranch updateBranch;
  static _updateBranchFromJson(int value) => UpdateBranch.values[value];

  /// Указывает, что приложение может загружать обложки треков с Deezer.
  @JsonKey(name: "DeezerThumbnails", defaultValue: false)
  final bool deezerThumbnails;

  /// Указывает, какой тип палитры цветов будет использоваться при извлечении цветов из обложек треков.
  @JsonKey(
    name: "DynamicSchemeType",
    toJson: intFromEnum,
    fromJson: _dynamicSchemeTypeFromJson,
    defaultValue: DynamicSchemeType.tonalSpot,
  )
  final DynamicSchemeType dynamicSchemeType;
  static _dynamicSchemeTypeFromJson(int value) =>
      DynamicSchemeType.values[value];

  /// Указывает, что полноэкранный плеер будет использовать изображение большого размера при Desktop Layout'е.
  @JsonKey(name: "FullscreenBigThumbnail", defaultValue: false)
  final bool fullscreenBigThumbnail;

  /// Указывает, что включено debug-логирование media_kit плеера.
  @JsonKey(name: "DebugPlayerLogging", defaultValue: false)
  final bool debugPlayerLogging;

  /// Указывает, что было показано предупреждение о том, что пользователь запустил бета-версию приложения.
  @JsonKey(name: "PreReleaseWarningShown", defaultValue: false)
  final bool preReleaseWarningShown;

  /// Указывает, что приложение будет загружать тексты песен с LRCLIB.
  @JsonKey(name: "LRCLIBEnabled", defaultValue: false)
  final bool lrcLibEnabled;

  /// Указывает, включён ли loop-mode для плеера.
  @JsonKey(name: "LoopModeEnabled", defaultValue: false)
  final bool loopModeEnabled;

  /// Указывает, какая громкость у плеера.
  ///
  /// Принимается значение от `0.0` (0%) либо `1.0` (100%).
  @JsonKey(name: "Volume", defaultValue: 1.0)
  final double volume;

  /// Указывает, в каких случаях трек будет перематываться в начало при попытке запустить предыдущий.
  @JsonKey(
    name: "RewindOnPreviousBehavior",
    toJson: intFromEnum,
    fromJson: _rewindOnPreviousBehaviorFromJson,
    defaultValue: RewindBehavior.always,
  )
  final RewindBehavior rewindOnPreviousBehavior;
  static _rewindOnPreviousBehaviorFromJson(int value) =>
      RewindBehavior.values[value];

  /// Указывает, включена ли настройка "спойлер следующего трека".
  @JsonKey(name: "SpoilerNextTrack", defaultValue: true)
  final bool spoilerNextTrack;

  /// Указывает, включён ли показ debugging-опций в "профиле" даже в release-режиме.
  @JsonKey(name: "DebugOptionsEnabled", defaultValue: false)
  final bool debugOptionsEnabled;

  /// Указывает, что будет использоваться альтернативный вид Slider'а у мини-плеера при Desktop Layout'е.
  @JsonKey(name: "AlternateDesktopMiniplayerSlider", defaultValue: false)
  final bool alternateDesktopMiniplayerSlider;

  /// Указывает, что вместо прогресса воспроизведения трека будет показано оставшееся время до конца трека.
  @JsonKey(name: "ShowRemainingTime", defaultValue: false)
  final bool showRemainingTime;

  /// Указывает, что при закрытии приложения на OS Android приложение не будет закрываться, а будет скрываться в фоне.
  @JsonKey(name: "AndroidKeepPlayingOnClose", defaultValue: false)
  final bool androidKeepPlayingOnClose;

  /// Указывает, что при нажатии на кнопку воспроизведения трека, будет запускаться воспроизведение случайного трека с включённым shuffle.
  @JsonKey(name: "ShuffleOnPlay", defaultValue: true)
  final bool shuffleOnPlay;

  /// Список из ранее экспортированных, либо импортированных секций для настройки "экспорт настроек".
  ///
  /// Названия секций берутся из [ExportedSections].
  @JsonKey(name: "ExportedSections", defaultValue: [])
  final List<String> exportedSections;

  /// Указывает, что будет плавный переход цветов у плеера перед окончанием воспроизведения текущего трека.
  @JsonKey(name: "CrossfadeColors", defaultValue: true)
  final bool crossfadeColors;

  /// Указывает, что название трека, который играет в данный момент, будет отображаться в заголовке окна.
  @JsonKey(name: "TrackTitleInWindowBar", defaultValue: true)
  final bool trackTitleInWindowBar;

  /// Указывает, что приложение будет отображать анимированные обложки с Apple Music.
  @JsonKey(name: "AppleMusicAnimatedCovers", defaultValue: false)
  final bool appleMusicAnimatedCovers;

  /// Возвращает [Map] из всех ключей этого класса, где value - тип ключа.
  static Map<String, Type> getKeyTypes() => {
        "DBVersion": int,
        "MyMusicChipEnabled": bool,
        "PlaylistsChipEnabled": bool,
        "RealtimePlaylistsChipEnabled": bool,
        "RecommendedPlaylistsChipEnabled": bool,
        "SimilarMusicChipEnabled": bool,
        "ByVKChipEnabled": bool,
        "ShuffleEnabled": bool,
        "DiscordRPCEnabled": bool,
        "PauseOnMuteEnabled": bool,
        "StopOnPauseEnabled": bool,
        "PlayerThumbAsBackground": bool,
        "TrackLyricsEnabled": bool,
        "PlayerColorsAppWide": bool,
        "Theme": ThemeMode,
        "OLEDTheme": bool,
        "CloseBehavior": CloseBehavior,
        "CheckBeforeFavorite": bool,
        "UpdatePolicy": UpdatePolicy,
        "UpdateBranch": UpdateBranch,
        "DeezerThumbnails": bool,
        "DynamicSchemeType": DynamicSchemeType,
        "FullscreenBigThumbnail": bool,
        "DebugPlayerLogging": bool,
        "PreReleaseWarningShown": bool,
        "LRCLIBEnabled": bool,
        "LoopModeEnabled": bool,
        "Volume": double,
        "RewindOnPreviousBehavior": RewindBehavior,
        "SpoilerNextTrack": bool,
        "DebugOptionsEnabled": bool,
        "AlternateDesktopMiniplayerSlider": bool,
        "ShowRemainingTime": bool,
        "AndroidKeepPlayingOnClose": bool,
        "ShuffleOnPlay": bool,
        "ExportedSections": List<String>,
        "CrossfadeColors": bool,
        "TrackTitleInWindowBar": bool,
        "AppleMusicAnimatedCovers": bool,
      };

  UserPreferences({
    this.dbVersion = AppStorage.maxDBVersion,
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
    this.shuffleOnPlay = true,
    this.exportedSections = const [],
    this.crossfadeColors = true,
    this.trackTitleInWindowBar = true,
    this.appleMusicAnimatedCovers = false,
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
    bool? shuffleOnPlay,
    List<String>? exportedSections,
    bool? crossfadeColors,
    bool? trackTitleInWindowBar,
    bool? appleMusicAnimatedCovers,
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
        shuffleOnPlay: shuffleOnPlay ?? this.shuffleOnPlay,
        exportedSections: exportedSections ?? this.exportedSections,
        crossfadeColors: crossfadeColors ?? this.crossfadeColors,
        trackTitleInWindowBar:
            trackTitleInWindowBar ?? this.trackTitleInWindowBar,
        appleMusicAnimatedCovers:
            appleMusicAnimatedCovers ?? this.appleMusicAnimatedCovers,
      );

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      _$UserPreferencesFromJson(json);

  /// Возвращает JSON-представление этого класса.
  ///
  /// Если Вы делаете экспорт настроек (например, как в функции "экспорт настроек"), то используйте [toExportedJson], что бы исключить ненужные ключи.
  Map<String, dynamic> toJson() => _$UserPreferencesToJson(this);

  /// Возвращает JSON-представление этого класса, но без ключей из [exportIgnoreKeys].
  Map<String, dynamic> toExportedJson() {
    final Map<String, dynamic> json = toJson();

    for (String key in exportIgnoreKeys) {
      json.remove(key);
    }

    return json;
  }
}

/// [Provider] для хранения настроек пользователя.
@riverpod
class Preferences extends _$Preferences {
  static final AppLogger logger = getLogger("Preferences");

  @override
  UserPreferences build() {
    return UserPreferences.fromJson(getPreferencesMap());
  }

  /// Загружает [sharedPrefsProvider], и возвращает [Map], содержащий в себе изменённые настройки.
  Map<String, dynamic> getPreferencesMap() {
    final SharedPreferences prefs = ref.read(sharedPrefsProvider);

    final Map<String, dynamic> map = {};
    final Iterable<String> keys = UserPreferences.getKeyTypes().keys;
    for (String key in keys) {
      map[key] = prefs.get(key);
    }

    return map;
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

      // Если передан null, то удаляем ключ из SharedPreferences, если он там есть.
      if (newValue == null) {
        if (prefs.containsKey(key)) hasChanges = true;
        prefs.remove(key);

        continue;
      }

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
      } else if (newValue is List<String>) {
        prefs.setStringList(key, newValue);
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

  /// Производит объединение текущего состояния с новым состоянием.
  void setFromJson(
    Map<String, dynamic> json, {
    bool useExportIgnoreKeys = true,
  }) {
    final Map<String, dynamic> newJson = state.toJson();
    for (MapEntry<String, dynamic> entry in json.entries) {
      final value = entry.value;
      if (value == null) continue;

      if (useExportIgnoreKeys &&
          UserPreferences.exportIgnoreKeys.contains(entry.key)) {
        continue;
      }

      newJson[entry.key] = entry.value;
    }

    state = UserPreferences.fromJson(newJson);
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

  void setShuffleOnPlay(bool enabled) =>
      state = state.copyWith(shuffleOnPlay: enabled);

  void setExportedSections(List<String> sections) =>
      state = state.copyWith(exportedSections: sections);

  void setCrossfadeColors(bool enabled) =>
      state = state.copyWith(crossfadeColors: enabled);

  void setTrackTitleInWindowBar(bool enabled) =>
      state = state.copyWith(trackTitleInWindowBar: enabled);

  void setAppleMusicAnimatedCovers(bool enabled) =>
      state = state.copyWith(appleMusicAnimatedCovers: enabled);
}
