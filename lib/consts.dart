/// URL для основной OAuth-авторизацией (Kate Mobile).
const String vkMainOAuthURL =
    "https://oauth.vk.com/authorize?client_id=2685278&scope=69634&redirect_uri=https://oauth.vk.com/blank.html&display=page&response_type=token&revoke=1";

/// URL для вторичной OAuth-авторизации для списка рекомендаций (VK Admin).
const String vkMusicRecommendationsOAuthURL =
    "https://oauth.vk.com/authorize?client_id=6121396&scope=65546&redirect_uri=https://oauth.vk.com/blank.html&display=page&response_type=token&revoke=1";

/// Имя владельца репозитория. Используется для проверки обновлений.
///
/// К примеру, у репозитория `Zensonaton/FlutterVK` эта переменная будет равна значению `Zensonaton`.
const String repoOwner = "Zensonaton";

/// Имя репозитория. Используется для проверки обновлений.
///
/// К примеру, у репозитория `Zensonaton/FlutterVK` эта переменная будет равна значению `FlutterVK`.
const String repoName = "FlutterVK";

/// Ссылка на Github-репозиторий данного приложения.
String get repoURL => "https://github.com/$repoOwner/$repoName";

/// Значение скругления многих элементов интерфейса.
const double globalBorderRadius = 6;

/// ID приложения Discord, используемый для работы Rich Presence.
///
/// Олицетворяет приложение "Flutter VK".
const int discordAppID = 1195224178996027412;

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
  "Test lyric",
];

/// Значение от 0.0 до 1.0, указывающее то, начиная с какого процента "прослушанности" трека появляется надпись "Сыграет следующим: Артист - Трек" в интерфейсе проигрывателя.
const double nextPlayingTextProgress = 0.85;
