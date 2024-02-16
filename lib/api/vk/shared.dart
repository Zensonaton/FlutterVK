import "package:json_annotation/json_annotation.dart";

import "../../utils.dart";

part "shared.g.dart";

/// Объект ошибки API ВКонтакте.
@JsonSerializable()
class APIError {
  /// Код ошибки.
  @JsonKey(name: "error_code")
  final int errorCode;

  /// Текст ошибки.
  @JsonKey(name: "error_msg")
  final String errorMessage;

  /// Переданные параметры запроса.
  @JsonKey(name: "request_params")
  final List<Map<String, String>> requestParams;

  /// ID изображения каптчи.
  @JsonKey(name: "captcha_sid")
  final String? captchaSID;

  /// URL на изображение каптчи.
  @JsonKey(name: "captcha_img")
  final String? captchaUrl;

  APIError(
    this.errorCode,
    this.errorMessage,
    this.requestParams,
    this.captchaSID,
    this.captchaUrl,
  );

  factory APIError.fromJson(Map<String, dynamic> json) =>
      _$APIErrorFromJson(json);
  Map<String, dynamic> toJson() => _$APIErrorToJson(this);
}

/// Объект, олицетворяющий пользователя ВКонтакте.
@JsonSerializable()
class User {
  /// ID пользователя.
  final int id;

  /// Имя пользователя.
  @JsonKey(name: "first_name")
  final String firstName;

  /// Фамилия пользователя.
  @JsonKey(name: "last_name")
  final String lastName;

  /// Возвращается, если страница удалена или заблокирована.
  final String? deactivated;

  /// Указывает, что профиль пользователя закрыт настройками приватности.
  @JsonKey(name: "is_closed")
  final bool isClosed;

  /// Указывает, что владелец текущей страницы может видеть профиль даже если [isClosed] = true.
  @JsonKey(name: "can_access_closed")
  final bool canAccessClosed;

  /// Содержимое поля «О себе» из профиля.
  final String? about;

  /// Содержимое поля «Деятельность» из профиля.
  final String? activities;

  /// Дата рождения. Возвращается в формате D.M.YYYY или D.M (если год рождения скрыт). Если дата рождения скрыта целиком, поле отсутствует в ответе.
  final String? bdate;

  /// Информация о том, находится ли текущий пользователь в черном списке. Возможные значения:
  ///
  /// `1` - находится.
  /// `0` - не находится.
  final int? blacklisted;

  /// Информация о том, находится ли пользователь в черном списке у текущего пользователя. Возможные значения:
  ///
  /// `1` - находится.
  /// `0 - не находится.
  @JsonKey(name: "blacklisted_by_me")
  final int? blacklistedByMe;

  /// Содержимое поля «Любимые книги» из профиля пользователя.
  final String? books;

  /// Информация о том, может ли текущий пользователь оставлять записи на стене. Возможные значения:
  ///
  /// `1` - может.
  /// `0` - не может.
  @JsonKey(name: "can_post")
  final int? canPost;

  /// Информация о том, может ли текущий пользователь видеть чужие записи на стене. Возможные значения:
  ///
  /// `1` - может.
  /// `0` - не может.
  @JsonKey(name: "can_see_all_posts")
  final int? canSeeAllPosts;

  /// Информация о том, может ли текущий пользователь видеть аудиозаписи. Возможные значения:
  ///
  /// `1` - может.
  /// `0` - не может.
  @JsonKey(name: "can_see_audio")
  final int? canSeeAudio;

  /// Информация о том, будет ли отправлено уведомление пользователю о заявке в друзья от текущего пользователя. Возможные значения:
  ///
  /// `1` - уведомление будет отправлено.
  /// `0` - уведомление не будет отправлено.
  @JsonKey(name: "can_send_friend_request")
  final int? canSendFriendRequest;

  /// Информация о том, может ли текущий пользователь отправить личное сообщение. Возможные значения:
  ///
  /// `1` - может.
  /// `0` - не может.
  @JsonKey(name: "can_write_private_message")
  final int? canWritePrivateMessage;

  /// Информация о карьере пользователя. Объект, содержащий следующие поля:
  final dynamic career;

  /// Информация о городе, указанном на странице пользователя в разделе «Контакты».
  final dynamic city;

  /// Количество общих друзей с текущим пользователем.
  @JsonKey(name: "common_count")
  final int? commonCount;

  /// Возвращает данные об указанных в профиле сервисах пользователя, таких как: skype, livejournal. Для каждого сервиса возвращается отдельное поле с типом string, содержащее никнейм пользователя.
  ///
  /// Пример вывода:
  /// ```dart
  /// {
  ///   "skype": "username"
  /// }
  /// ```
  Map<String, String>? connections;

  /// Информация о телефонных номерах пользователя
  final dynamic contacts;

  /// Количество различных объектов у пользователя.
  Map<String, int>? counters;

  /// Информация о стране, указанной на странице пользователя в разделе «Контакты».
  final dynamic country;

  /// Возвращает данные о точках, по которым вырезаны профильная и миниатюрная фотографии пользователя, при наличии.
  @JsonKey(name: "crop_photo")
  final dynamic cropPhoto;

  /// Короткий адрес страницы. Возвращается строка, содержащая короткий адрес страницы (например, `andrew`). Если он не назначен, возвращается "id"+user_id, например, `id35828305`.
  final String? domain;

  /// Информация о высшем учебном заведении пользователя.
  final dynamic education;

  /// Внешние сервисы, в которые настроен экспорт из ВК (`livejournal`).
  final dynamic exports;

  /// Имя пользователя в именительном падеже.
  @JsonKey(name: "first_name_nom")
  final String? firstNameNom;

  /// Имя пользователя в родительном падеже.
  @JsonKey(name: "first_name_gen")
  final String? firstNameGen;

  /// Имя пользователя в дательном падеже.
  @JsonKey(name: "first_name_dat")
  final String? firstNameDat;

  /// Имя пользователя в винительном падеже.
  @JsonKey(name: "first_name_acc")
  final String? firstNameAcc;

  /// Имя пользователя в творительном падеже.
  @JsonKey(name: "first_name_ins")
  final String? firstNameIns;

  /// Имя пользователя в предложном падеже.
  @JsonKey(name: "first_name_abl")
  final String? firstNameAbl;

  /// Количество подписчиков пользователя.
  @JsonKey(name: "followers_count")
  final int? followersCount;

  /// Статус дружбы с пользователем.
  ///
  /// Возможные значения:
  /// `0` - не является другом.
  /// `1` - отправлена заявка/подписка пользователю.
  /// `2` - имеется входящая заявка/подписка от пользователя.
  /// `3` - является другом.
  @JsonKey(name: "friend_status")
  final int? friendStatus;

  /// Содержимое поля «Любимые игры» из профиля.
  final String? games;

  /// Информация о том, известен ли номер мобильного телефона пользователя.
  ///
  /// Возможные значения:
  /// `1` - известен.
  /// `0` - не известен.
  @JsonKey(name: "has_mobile")
  final int? hasMobile;

  /// Информация о том, установил ли пользователь фотографию для профиля.
  ///
  /// Возможные значения:
  /// `1` - установил.
  /// `0` - не установил.
  @JsonKey(name: "has_photo")
  final int? hasPhoto;

  /// Название родного города.
  @JsonKey(name: "home_town")
  final String? homeTown;

  /// Содержимое поля «Интересы» из профиля.
  final String? interests;

  /// Информация о том, есть ли пользователь в закладках у текущего пользователя.
  ///
  /// Возможные значения:
  /// `1` - есть.
  /// `0` - нет.
  @JsonKey(name: "is_favorite")
  final int? isFavorite;

  /// Информация о том, является ли пользователь другом текущего пользователя.
  ///
  /// Возможные значения:
  /// `1` - да.
  /// `0` - нет.
  @JsonKey(name: "is_friend")
  final int? isFriend;

  /// Информация о том, скрыт ли пользователь из ленты новостей текущего пользователя.
  ///
  /// Возможные значения:
  /// `1` - да.
  /// `0` - нет.
  @JsonKey(name: "is_hidden_from_feed")
  final int? isHiddenFromFeed;

  /// Индексируется ли профиль поисковыми сайтами.
  ///
  /// Возможные значения:
  /// `1` - профиль скрыт от поисковых сайтов.
  /// `0` - профиль доступен поисковым сайтам.
  @JsonKey(name: "is_no_index")
  final int? isNoIndex;

  /// Фамилия пользователя в именительном падеже.
  @JsonKey(name: "last_name_nom")
  final String? lastNameNom;

  /// Фамилия пользователя в родительном падеже.
  @JsonKey(name: "last_name_gen")
  final String? lastNameGen;

  /// Фамилия пользователя в дательном падеже.
  @JsonKey(name: "last_name_dat")
  final String? lastNameDat;

  /// Фамилия пользователя в винительном падеже.
  @JsonKey(name: "last_name_acc")
  final String? lastNameAcc;

  /// Фамилия пользователя в творительном падеже.
  @JsonKey(name: "last_name_ins")
  final String? lastNameIns;

  /// Фамилия пользователя в предложном падеже.
  @JsonKey(name: "last_name_abl")
  final String? lastNameAbl;

  /// Время последнего посещения.
  @JsonKey(name: "last_seen")
  final dynamic lastSeen;

  /// Разделенные запятой идентификаторы списков друзей, в которых состоит пользователь. Доступно только для метода `friends.get`.
  final String? lists;

  /// Девичья фамилия.
  @JsonKey(name: "maiden_name")
  final String? maidenName;

  /// Информация о военной службе пользователя.
  final dynamic military;

  /// Содержимое поля «Любимые фильмы» из профиля пользователя.
  final String? movies;

  /// Содержимое поля «Любимая музыка» из профиля пользователя.
  final String? music;

  /// Никнейм (отчество) пользователя.
  final String? nickname;

  /// Информация о текущем роде занятия пользователя.
  final dynamic occupation;

  /// Информация о том, находится ли пользователь сейчас на сайте.
  final int? online;

  /// Информация о полях из раздела «Жизненная позиция».
  final dynamic personal;

  /// URL квадратной фотографии пользователя, имеющей ширину 50 пикселей. В случае отсутствия у пользователя фотографии возвращается `https://vk.com/images/camera_50.png`.
  @JsonKey(name: "photo_50")
  final String? photo50;

  /// URL квадратной фотографии пользователя, имеющей ширину 100 пикселей. В случае отсутствия у пользователя фотографии возвращается `https://vk.com/images/camera_100.png`.
  @JsonKey(name: "photo_100")
  final String? photo100;

  /// URL фотографии пользователя, имеющей ширину 200 пикселей. В случае отсутствия у пользователя фотографии возвращается `https://vk.com/images/camera_200.png`.
  @JsonKey(name: "photo_200_orig")
  final String? photo200orig;

  /// URL квадратной фотографии пользователя, имеющей ширину 200 пикселей. В случае отсутствия у пользователя фотографии возвращается `https://vk.com/images/camera_200.png`.
  @JsonKey(name: "photo_200")
  final String? photo200;

  /// URL фотографии пользователя, имеющей ширину 400 пикселей. В случае отсутствия у пользователя фотографии возвращается `https://vk.com/images/camera_400.png`.
  @JsonKey(name: "photo_400_orig")
  final String? photo400orig;

  /// Строковый идентификатор главной фотографии профиля пользователя в формате `{user_id}_{photo_id}`, например, `6492_192164258`.
  @JsonKey(name: "photo_id")
  final String? photoID;

  /// URL квадратной фотографии с максимальной шириной. Может быть возвращена фотография, имеющая ширину как 200, так и 100 пикселей. В случае отсутствия у пользователя фотографии возвращается `https://vk.com/images/camera_200.png`.
  @JsonKey(name: "photo_max")
  final String? photoMax;

  /// URL фотографии максимального размера. Может быть возвращена фотография, имеющая ширину как 400, так и 200 пикселей. В случае отсутствия у пользователя фотографии возвращается `https://vk.com/images/camera_400.png`.
  @JsonKey(name: "photo_max_orig")
  final String? photoMaxOrig;

  /// Любимые цитаты.
  final String? quoutes;

  /// Список родственников.
  final dynamic relatives;

  /// Семейное положение.
  ///
  /// Возможные значения:
  /// `1` - не женат/не замужем.
  /// `2` - есть друг/есть подруга.
  /// `3` - помолвлен/помолвлена.
  /// `4` - женат/замужем.
  /// `5` - всё сложно.
  /// `6` - в активном поиске.
  /// `7` - влюблён/влюблена.
  /// `8` - в гражданском браке.
  /// `0` - не указано.
  final int? relation;

  /// Список школ, в которых учился пользователь.
  final dynamic schools;

  /// Короткое имя страницы.
  @JsonKey(name: "screen_name")
  final String? screenName;

  /// Пол.
  ///
  /// Возможные значения:
  /// `1` - мужской.
  /// `2` - женский.
  /// `0` - пол не указан.
  final int? sex;

  /// Адрес сайта, указанный в профиле.
  final String? site;

  /// Статус пользователя. Возвращается строка, содержащая текст статуса, расположенного в профиле под именем.
  final String? status;

  /// Временная зона.
  final num? timezone;

  /// Информация о том, есть ли на странице пользователя «огонёк».
  final int? trending;

  /// Любимые телешоу.
  final String? tv;

  /// Список вузов, в которых учился пользователь.
  final dynamic universities;

  /// Возвращается `1`, если страница пользователя верифицирована, `0` — если нет.
  final int? verified;

  /// Режим стены по умолчанию. Возможные значения: `owner`, `all`.
  @JsonKey(name: "wall_default")
  final String? wallDefault;

  User(
    this.id,
    this.firstName,
    this.lastName,
    this.deactivated,
    this.isClosed,
    this.canAccessClosed,
    this.about,
    this.activities,
    this.bdate,
    this.blacklisted,
    this.blacklistedByMe,
    this.books,
    this.canPost,
    this.canSeeAllPosts,
    this.canSeeAudio,
    this.canSendFriendRequest,
    this.canWritePrivateMessage,
    this.career,
    this.city,
    this.commonCount,
    this.contacts,
    this.country,
    this.cropPhoto,
    this.domain,
    this.education,
    this.exports,
    this.firstNameNom,
    this.firstNameGen,
    this.firstNameDat,
    this.firstNameAcc,
    this.firstNameIns,
    this.firstNameAbl,
    this.followersCount,
    this.friendStatus,
    this.games,
    this.hasMobile,
    this.hasPhoto,
    this.homeTown,
    this.interests,
    this.isFavorite,
    this.isFriend,
    this.isHiddenFromFeed,
    this.isNoIndex,
    this.lastNameNom,
    this.lastNameGen,
    this.lastNameDat,
    this.lastNameAcc,
    this.lastNameIns,
    this.lastNameAbl,
    this.lastSeen,
    this.lists,
    this.maidenName,
    this.military,
    this.movies,
    this.music,
    this.nickname,
    this.occupation,
    this.online,
    this.personal,
    this.photo50,
    this.photo100,
    this.photo200orig,
    this.photo200,
    this.photo400orig,
    this.photoID,
    this.photoMax,
    this.photoMaxOrig,
    this.quoutes,
    this.relatives,
    this.relation,
    this.schools,
    this.screenName,
    this.sex,
    this.site,
    this.status,
    this.timezone,
    this.trending,
    this.tv,
    this.universities,
    this.verified,
    this.wallDefault,
  );

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}

/// Объект, олицетворяющий изображения альбома аудиозаписи ВКонтакте.
@JsonSerializable()
class AudioThumbnails {
  /// Ширина изображения альбома.
  final int width;

  /// Высота изображения альбома.
  final int height;

  /// URL на изображение альбома в размере `34`.
  @JsonKey(name: "photo_34")
  final String? photo34;

  /// URL на изображение альбома в размере `68`.
  @JsonKey(name: "photo_68")
  final String? photo68;

  /// URL на изображение альбома в размере `135`.
  @JsonKey(name: "photo_135")
  final String? photo135;

  /// URL на изображение альбома в размере `270`.
  @JsonKey(name: "photo_270")
  final String? photo270;

  /// URL на изображение альбома в размере `300`.
  @JsonKey(name: "photo_300")
  final String? photo300;

  /// URL на изображение альбома в размере `600`.
  @JsonKey(name: "photo_600")
  final String? photo600;

  /// URL на изображение альбома в размере `1200`.
  @JsonKey(name: "photo_1200")
  final String? photo1200;

  AudioThumbnails(
    this.width,
    this.height,
    this.photo34,
    this.photo68,
    this.photo135,
    this.photo270,
    this.photo300,
    this.photo600,
    this.photo1200,
  );

  factory AudioThumbnails.fromJson(Map<String, dynamic> json) =>
      _$AudioThumbnailsFromJson(json);
  Map<String, dynamic> toJson() => _$AudioThumbnailsToJson(this);
}

/// Объект, олицетворяющий плейлист ВКонтакте.
@JsonSerializable()
class AudioPlaylist {
  /// ID плейлиста.
  final int id;

  /// ID владельца плейлиста.
  @JsonKey(name: "owner_id")
  final int ownerID;

  final int type;

  /// Название плейлиста.
  final String? title;

  /// Описание плейлиста. Иногда пустует.
  @JsonKey(fromJson: emptyStringAsNull)
  final String? description;

  /// Подпись плейлиста, обычно присутствует в плейлистах-рекомендациях.
  final String? subtitle;

  /// Количество аудиозаписей в данном плейлисте.
  int count;

  /// Ключ доступа.
  @JsonKey(name: "access_key")
  final String? accessKey;

  /// Количество подписчиков плейлиста.
  final int followers;

  /// Количество проигрываний плейлиста.
  final int plays;

  /// Timestamp создания плейлиста.
  @JsonKey(name: "create_time")
  final int? createTime;

  /// Timestamp последнего обновления плейлиста.
  @JsonKey(name: "update_time")
  final int? updateTime;

  /// Список жанров.
  final dynamic genres;

  /// Указывает, подписан ли данный пользователь на данный плейлист или нет.
  @JsonKey(name: "is_following")
  final bool isFollowing;

  /// Фотография плейлиста.
  final AudioThumbnails? photo;

  /// Разрешения для данного плейлиста.
  final dynamic permissions;

  @JsonKey(name: "subtitle_badge")
  final bool subtitleBadge;

  @JsonKey(name: "play_button")
  final bool playButton;

  /// Тип данного альбома. Чаще всего `playlist`.
  @JsonKey(name: "album_type")
  final String albumType;

  final dynamic meta;

  /// Указывает, что это эксклюзив.
  final bool exclusive;

  /// Возвращает строку, которая используется как идентификатор пользователя и медиа.
  String get mediaKey => "${ownerID}_$id";

  @override
  bool operator ==(covariant AudioPlaylist other) {
    if (identical(this, other)) return true;

    return other.runtimeType == AudioPlaylist && other.mediaKey == mediaKey;
  }

  @override
  int get hashCode => mediaKey.hashCode;

  AudioPlaylist({
    required this.id,
    required this.ownerID,
    this.type = 0,
    this.title,
    this.description,
    required this.count,
    this.accessKey,
    this.followers = 0,
    this.plays = 0,
    this.createTime,
    this.updateTime,
    this.isFollowing = false,
    this.subtitleBadge = false,
    this.playButton = false,
    this.albumType = "playlist",
    this.exclusive = false,
    this.subtitle,
    this.genres,
    this.photo,
    this.permissions,
    this.meta,
  });

  factory AudioPlaylist.fromJson(Map<String, dynamic> json) =>
      _$AudioPlaylistFromJson(json);
  Map<String, dynamic> toJson() => _$AudioPlaylistToJson(this);
}

/// Объект, олицетворяющий альбом аудиозаписи ВКонтакте.
@JsonSerializable()
class AudioAlbum {
  /// ID альбома.
  final int id;

  /// Название альбома.
  final String title;

  /// ID владельца альбома.
  @JsonKey(name: "owner_id")
  final int ownerID;

  /// Ключ доступа.
  @JsonKey(name: "access_key")
  final String accessKey;

  /// Изображения альбома.
  final AudioThumbnails? thumb;

  /// Возвращает строку, которая используется как идентификатор пользователя и медиа.
  String get mediaKey => "${ownerID}_$id";

  @override
  bool operator ==(covariant AudioAlbum other) {
    if (identical(this, other)) return true;

    return other.runtimeType == AudioAlbum && other.mediaKey == mediaKey;
  }

  @override
  int get hashCode => mediaKey.hashCode;

  AudioAlbum(
    this.id,
    this.title,
    this.ownerID,
    this.accessKey,
    this.thumb,
  );

  factory AudioAlbum.fromJson(Map<String, dynamic> json) =>
      _$AudioAlbumFromJson(json);
  Map<String, dynamic> toJson() => _$AudioAlbumToJson(this);
}

/// Объект, олицетворяющий аудиозапись ВКонтакте.
@JsonSerializable()
class Audio {
  /// ID аудиозаписи.
  int id;

  /// ID владельца аудиозаписи.
  @JsonKey(name: "owner_id")
  int ownerID;

  /// Имя исполнителя.
  String artist;

  /// Название аудиозаписи.
  String title;

  /// Длительность аудиозаписи в секундах.
  final int duration;

  /// Подпись трека.
  final String? subtitle;

  /// Ключ доступа.
  @JsonKey(name: "access_key")
  String accessKey;

  /// Объект с информацией по рекламе.
  final dynamic ads;

  /// Указывает, если это Explicit-аудиозапись.
  @JsonKey(name: "is_explicit")
  final bool isExplicit;

  @JsonKey(name: "is_focus_track")
  final bool? isFocusTrack;

  /// Указывает, если эта запись лицензирована.
  @JsonKey(name: "is_licensed")
  final bool? isLicensed;

  /// Указывает, что данный трек ограничен.
  @JsonKey(
    name: "content_restricted",
    fromJson: boolFromInt,
    toJson: intFromBool,
    defaultValue: false,
  )
  final bool isRestricted;

  /// Разрешено ли создание коротких видео с этой аудиозаписью?
  @JsonKey(name: "short_videos_allowed")
  final bool? shortVideosAllowed;

  /// Разрешено ли создание историй с этой аудиозаписью?
  @JsonKey(name: "stories_allowed")
  final bool? storiesAllowed;

  @JsonKey(name: "stories_cover_allowed")
  final bool? storiesCoverAllowed;

  /// Строка для отслеживания.
  @JsonKey(name: "track_code")
  final String? trackCode;

  /// URL на `mp3` данной аудиозаписи.
  ///
  /// Очень часто он отсутствует, выдавая пустую строку.
  final String url;

  /// Timestamp добавления аудиозаписи.
  final int date;

  /// Информация об альбоме данной аудиозаписи.
  AudioAlbum? album;

  /// Указывает наличие текста песни.
  @JsonKey(name: "has_lyrics")
  final bool hasLyrics;

  /// ID альбома, в котором находится аудиозапись, если она присвоена к какому-либо альбому.
  @JsonKey(name: "album_id")
  final int? albumID;

  /// ID жанра аудиозаписи. Список жанров описан [здесь](https://dev.vk.com/ru/reference/objects/audio-genres).
  @JsonKey(name: "genre_id")
  int? genreID;

  /// Возвращает строку, которая используется как идентификатор пользователя и медиа.
  ///
  /// Выглядит как `123456_123456789`.
  String get mediaKey => "${ownerID}_$id";

  /// Возвращает URL данного трека, который используется при нажатии на кнопку "поделиться".
  String get trackUrl => "https://vk.com/audio${ownerID}_${id}_$accessKey";

  @override
  bool operator ==(covariant Audio other) {
    if (identical(this, other)) return true;

    return other.runtimeType == Audio && other.mediaKey == mediaKey;
  }

  @override
  int get hashCode => mediaKey.hashCode;

  Audio({
    required this.id,
    required this.ownerID,
    required this.artist,
    required this.title,
    required this.duration,
    this.subtitle,
    required this.accessKey,
    this.ads,
    this.isExplicit = false,
    this.isFocusTrack,
    this.isLicensed,
    this.isRestricted = false,
    this.shortVideosAllowed,
    this.storiesAllowed,
    this.storiesCoverAllowed,
    this.trackCode,
    required this.url,
    required this.date,
    this.album,
    this.hasLyrics = false,
    this.albumID,
    this.genreID,
  });

  factory Audio.fromJson(Map<String, dynamic> json) => _$AudioFromJson(json);
  Map<String, dynamic> toJson() => _$AudioToJson(this);
}
