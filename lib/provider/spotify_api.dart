import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../api/spotify/get_lyrics.dart";
import "../api/spotify/get_token.dart";
import "../api/spotify/search.dart";
import "../api/spotify/shared.dart";
import "../api/vk/audio/get_lyrics.dart";
import "../services/logger.dart";
import "shared_prefs.dart";

part "spotify_api.g.dart";

/// Класс для хранения данных авторизации Spotify.
///
/// [Provider] для получения этих данных: [spotifyAuthProvider].
class SpotifyAuthData {
  /// Значение Cookie `sp_dc`.
  String? spDC;

  /// Access-токен, полученный благодаря Cookie `sp_dc`.
  String? accessToken;

  /// [DateTime], отображающий время того, когда [accessToken] перестанет быть валидным.
  DateTime? expireDate;

  /// Указывает, что [accessToken] валиден, и им можно пользоваться.
  ///
  /// Возвращает `false`, если [spotifyAPIToken] пуст.
  bool get tokenValid =>
      expireDate != null ? DateTime.now().isBefore(expireDate!) : false;

  SpotifyAuthData({
    this.spDC,
  });
}

/// [Provider] для работы с API Spotify.
@riverpod
class SpotifyAPI extends _$SpotifyAPI {
  static final AppLogger logger = getLogger("SpotifyAPIProvider");

  @override
  SpotifyAuthData build() {
    final SharedPreferences prefs = ref.read(sharedPrefsProvider).requireValue;

    return SpotifyAuthData(
      spDC: prefs.getString("sp_dc"),
    );
  }

  /// Проверяет валидность Cookie `sp_dc` от Spotify в [SharedPreferences] ([sharedPrefsProvider]), а так же обновляет состояние этого Provider.
  Future<void> login(String spDC) async {
    final SharedPreferences prefs = ref.read(sharedPrefsProvider).requireValue;

    state.spDC = spDC;
    await refreshToken();

    // Авторизуем пользователя, и сохраняем флаг авторизации в [SharedPreferences].
    prefs.setString("sp_dc", spDC);

    // Обновляем состояние авторизации.
    ref.invalidate(spotifySPDCCookieProvider);
  }

  /// Обновляет поле [SpotifyAuthData.accessToken], если токен истёк ([SpotifyAuthData.tokenValid] = `false`), либо он не был установлен.
  Future<void> refreshToken() async {
    assert(
      state.spDC != null,
      "sp_dc cookie not set",
    );

    // Если токен ещё актуален, то ничего не делаем.
    if (state.accessToken != null && state.tokenValid) return;

    logger.d("Refreshing Spotify access token...");

    // Обновляем токен.
    final SpotifyAPIGetTokenResponse response =
        await spotify_get_token(state.spDC!);
    if (response.error != null) {
      throw Exception(
        "API Error: ${response.error!.message}",
      );
    }

    assert(
      !response.isAnonymous!,
      "Spotify used anonymous authorization",
    );

    // Всё ок, запоминаем новый токен.
    state.spDC = response.accessToken!;
    state.expireDate =
        DateTime.fromMillisecondsSinceEpoch(response.expirationTimestampMS!);

    logger.d(
      "Spotify accessToken will expire after ${Duration(milliseconds: response.expirationTimestampMS! - DateTime.now().millisecondsSinceEpoch)}",
    );
  }

  /// Возвращает текст трека при помощи API Spotify.
  Future<Lyrics?> spotifyGetTrackLyrics(
    String artist,
    String title,
    int duration,
  ) async {
    await refreshToken();

    // Выполняем поиск.
    // TODO: Сверка по названию.
    final SpotifyAPISearchResponse searchResponse = await spotify_search(
      state.accessToken!,
      artist,
      title,
    );
    final SpotifyTrack track = searchResponse.tracks.items.first;

    // Загружаем текст трека.
    final SpotifyAPIGetLyricsResponse? lyricsResponse =
        await spotify_get_lyrics(
      state.accessToken!,
      track.id,
    );

    // Если текст песни не дан, то ничего не делаем.
    if (lyricsResponse == null) return null;

    final SpotifyLyrics lyrics = lyricsResponse.lyrics;

    final int vkDurationMS = duration * 1000;
    final int spotifyDurationMS = track.durationMS;

    // Вычисляем множитель для текста песни.
    // Он нужен для того, что бы компенсировать разницу между длительностью трека в ВК и Spotify.
    double speedMultiplier = vkDurationMS / spotifyDurationMS;

    // Ввиду округления длительности треков в ВК, данный множитель используется лишь в случае, если разница больше, чем 1 секунда.
    if ((vkDurationMS - spotifyDurationMS).abs() <= 1000) {
      speedMultiplier = 1.0;
    }

    logger.d(
      "Spotify lyrics type: ${lyrics.syncType}, Spotify track duration: $spotifyDurationMS, VK track duration: $vkDurationMS (mult: $speedMultiplier)",
    );

    // Конвертируем формат текста песни Spotify в формат, принимаемый Flutter VK.
    List<String>? textLyrics;
    List<LyricTimestamp>? timestamps;

    // Текст не синхронизирован по времени.
    if (lyrics.syncType == "UNSYNCED") {
      textLyrics = lyrics.lines
          .map(
            (lyric) => lyric.words,
          )
          .toList();
    } else if (lyrics.syncType == "LINE_SYNCED") {
      timestamps = [];

      for (var index = 0; index < lyrics.lines.length; index++) {
        final SpotifyLyricLine line = lyrics.lines[index];
        final SpotifyLyricLine? nextLine =
            lyrics.lines.elementAtOrNull(index + 1);

        final String text = line.words.trim();
        final bool interlude = text == "♪";

        // Если строчка пуста, то пропускаем её.
        if (text.isEmpty) continue;

        timestamps.add(
          LyricTimestamp(
            line: !interlude ? line.words : null,
            begin: (line.startTimeMS * speedMultiplier).toInt(),
            end: ((line.endTimeMS != 0
                        ? line.endTimeMS
                        : nextLine?.startTimeMS ?? track.durationMS) *
                    speedMultiplier)
                .toInt(),
            interlude: interlude,
          ),
        );
      }
    } else {
      logger.w("Found unknown Spotify lyrics type: ${lyrics.syncType}");
    }

    return Lyrics(
      language: lyrics.language,
      text: textLyrics,
      timestamps: timestamps,
    );
  }
}

/// Возвращает значение Cookie `sp_dc` для Spotify.
@riverpod
String? spotifySPDCCookie(SpotifySPDCCookieRef ref) {
  final SharedPreferences prefs = ref.read(sharedPrefsProvider).requireValue;

  return prefs.getString("sp_dc");
}
