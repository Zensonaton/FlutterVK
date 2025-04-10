/// Название для приложения.
const String appName = "Flutter VK";

/// Указывает, что запущена pre-release (бета) версия приложения.
bool isPrerelease = const String.fromEnvironment("PRERELEASE").isNotEmpty;

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

/// Ссылка на Telegram-канал данного приложения.
const String telegramURL = "https://t.me/FlutterVKCI";

/// Обычный User-Agent браузера Firefox.
const String browserUA =
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:130.0) Gecko/20100101 Firefox/130.0";

/// Количество секунд, которое используется при перемотке трека при помощи кнопок "вперед" и "назад" на клавиатуре.
const int seekSeconds = 5;

/// Значение скругления многих элементов интерфейса.
const double globalBorderRadius = 8;

/// Расстояние между треками.
const double trackTileSpacing = 8;

/// Значение от 0.0 до 1.0, указывающее то, начиная с какого процента "прослушанности" трека появляется надпись "Сыграет следующим: Артист - Трек" в интерфейсе проигрывателя.
const double nextPlayingTextProgress = 0.85;

/// Магическая константа, характеризующая размер в мегабайтах у одной минуты `mp3`-трека.
const double trackSizePerMin = 1.5;

/// Название README-файла в папке с загруженными треками.
const String downloadedTracksReadmeFilename = "Abc_123_README.txt";

/// Случайные названия треков, используемые в Skeleton Loader'ах.
const List<String> fakeTrackNames = [
  "Track",
  "Track Name",
  appName,
  "Test",
  "Super long track name",
  "Audio",
  "Test track",
  "Nico and the Niners",
  "Blood In The Water",
  "Title here",
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
  appName,
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

/// Символ Explicit.
const String explicitChar = "🅴";
