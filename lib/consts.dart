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
const double globalBorderRadius = 8;

/// Расстояние между треками.
const double trackTileSpacing = 8;

/// ID приложения Discord, используемый для работы Rich Presence.
///
/// Олицетворяет приложение "Flutter VK".
const int discordAppID = 1195224178996027412;

/// Название README-файла в папке с кэшом треков.
const String tracksCacheReadmeFileName = "Abc_123_README.txt";

/// Магическая константа, характеризующая размер в мегабайтах у одной минуты `mp3`-трека.
const double trackSizePerMin = 2.2;

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
  "Suuuuper long playlist name used for something!",
];

/// Случайные строчки текстов песен, используемые в Skeleton Loader'ах.
const List<String> fakeTrackLyrics = [
  "Blinding lights.",
  "AAAH! Behind you!",
  "Some kind of text",
  "Flutter VK",
  "Wow",
  "Yeah",
  "STAND UP STRAIGHT NOW,",
  "CAN'T BREAK DOWN",
  "GRADUATE NOW!",
  "I DON'T WANNA BE HERE,",
  "I DON'T WANNA BE HERE,",
  "WHAT'S ABOUT TO HAPPEN-",
  "WHAT'S ABOUT TO HAPPEN?",
  "Oh oh ohhhhhhh",
  "Woah",
  "Woah",
  "Oh oh ohhhhhhh",
  "Can't change what you've done,",
  "Start fresh next semester",
  "Oh oh ohhhhhhh",
  "Track",
  "...",
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

/// URL на страницу с авторизацией Spotify.
const String spotifyAuthUrl = "https://accounts.spotify.com";

/// URL на страницу с информацией по получению значения Cookie `sp_dc` из браузера.
const String wikiSpotifySPDCcookie =
    "https://github.com/Zensonaton/FlutterVK/wiki/Получение-значения-sp_dc-для-авторизации-Spotify";
