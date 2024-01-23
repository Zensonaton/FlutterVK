/// URL для основной OAuth-авторизацией (Kate Mobile).
const String vkMainOAuthURL =
    "https://oauth.vk.com/authorize?client_id=2685278&scope=69634&redirect_uri=https://oauth.vk.com/blank.html&display=page&response_type=token&revoke=1";

/// URL для вторичной OAuth-авторизации для списка рекомендаций (VK Admin).
const String vkMusicRecommendationsOAuthURL =
    "https://oauth.vk.com/authorize?client_id=6121396&scope=65546&redirect_uri=https://oauth.vk.com/blank.html&display=page&response_type=token&revoke=1";

/// Ссылка на Github-репозиторий данного приложения.
const String repoURL = "https://github.com/Zensonaton/FlutterVK";

/// Начало любого URL, связанный с API ВКонтакте.
const String vkAPIBaseURL = "https://api.vk.com/method/";

/// Версия API.
const String vkAPIversion = "5.199";

/// Перечисление всех полей для API-методов по типу `users.get`.
const String vkAPIallUserFields =
    "activities, about, blacklisted, blacklisted_by_me, books, bdate, can_be_invited_group, can_post, can_see_all_posts, can_see_audio, can_send_friend_request, can_write_private_message, career, common_count, connections, contacts, city, country, crop_photo, domain, education, exports, followers_count, friend_status, has_photo, has_mobile, home_town, photo_100, photo_200, photo_200_orig, photo_400_orig, photo_50, sex, site, schools, screen_name, status, verified, games, interests, is_favorite, is_friend, is_hidden_from_feed, last_seen, maiden_name, military, movies, music, nickname, occupation, online, personal, photo_id, photo_max, photo_max_orig, quotes, relation, relatives, timezone, tv, universities";

/// User-Agent для запросов, связанных с Kate Mobile.
const String vkAPIKateMobileUA =
    "KateMobileAndroid/109.1 lite-550 (Android 13; SDK 33; x86_64; Google Pixel 5; ru)";

/// Значение скругления многих элементов интерфейса.
const double globalBorderRadius = 6;

/// Словарь с перечислением ID и названий жанров для треков ВКонтакте.
///
/// Информация взята из API ВКонтакте: https://dev.vk.com/ru/reference/objects/audio-genres?ref=old_portal.
const Map<int, String> musicGenres = {
  1: "Rock",
  2: "Pop",
  3: "Rap & Hip-Hop",
  4: "Easy Listening",
  5: "House & Dance",
  6: "Instrumental",
  7: "Metal",
  21: "Alternative",
  8: "Dubstep",
  1001: "Jazz & Blues",
  10: "Drum & Bass",
  11: "Trance",
  12: "Chanson",
  13: "Ethnic",
  14: "Acoustic & Vocal",
  15: "Reggae",
  16: "Classical",
  17: "Indie Pop",
  19: "Speech",
  22: "Electropop & Disco",
  18: "Other",
};

/// ID приложения Discord, используемый для работы Rich Presence.
///
/// Олицетворяет приложение "Flutter VK".
const int discordAppID = 1195224178996027412;

/// ID группы ВКонтакте "VK Музыка".
///
/// Используется для идентификации плейлистов "сделано редакцией (ВКонтакте)", поскольку они делаются именно этой группой.
const int vkMusicGroupID = -147845620;

/// Случайные названия треков, используемые в Skeleton Loader'ах.
const List<String> fakeTrackNames = [
  "Track",
  "Track Name",
  "Flutter VK",
  "Test",
  "Super long track name",
  "Audio",
  "Test track",
  "Blood In The Water",
];

/// Случайные названия плейлистов, используемые в Skeleton Loader'ах.
const List<String> fakePlaylistNames = [
  "Playlist",
  "Playlist of the day",
  "Track",
  "My playlist",
  "Wow",
  "My play",
  "Suuuuper long playlist name used for something!"
];

/// Случайные строчки текстов песен, используемые в Skeleton Loader'ах.
const List<String> fakeTrackLyrics = [
  "Blinding lights.",
  "AAAH! Behind you!",
  "Some kind of text",
  "Flutter VK",
  "Wow",
  "Yeah",
  "Meow",
  "Track ...",
  "Test Line That Is A Little Bit Long",
  "That Line Is Longer Than Any Other In This List, right! Isn't this awesome?",
  "What do you see before it's over?",
  "Something",
  "Middle sized lyric",
  "VK API sucks",
];

/// Значение от 0.0 до 1.0, указывающее то, начиная с какого процента "прослушанности" трека появляется надпись "Сыграет следующим: Артист - Трек" в интерфейсе проигрывателя.
const double nextPlayingTextProgress = 0.85;
