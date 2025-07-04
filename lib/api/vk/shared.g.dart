// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

APIUser _$APIUserFromJson(Map<String, dynamic> json) => APIUser(
      id: (json['id'] as num).toInt(),
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      deactivated: json['deactivated'] as String?,
      isClosed: json['is_closed'] as bool? ?? false,
      canAccessClosed: json['can_access_closed'] as bool? ?? false,
      about: json['about'] as String?,
      activities: json['activities'] as String?,
      bdate: json['bdate'] as String?,
      blacklisted: boolFromInt((json['blacklisted'] as num?)?.toInt()),
      blacklistedByMe:
          boolFromInt((json['blacklisted_by_me'] as num?)?.toInt()),
      books: json['books'] as String?,
      canPost: boolFromInt((json['can_post'] as num?)?.toInt()),
      canSeeAllPosts: boolFromInt((json['can_see_all_posts'] as num?)?.toInt()),
      canSeeAudio: boolFromInt((json['can_see_audio'] as num?)?.toInt()),
      canSendFriendRequest:
          boolFromInt((json['can_send_friend_request'] as num?)?.toInt()),
      canWritePrivateMessage:
          boolFromInt((json['can_write_private_message'] as num?)?.toInt()),
      career: json['career'],
      city: json['city'],
      commonCount: (json['common_count'] as num?)?.toInt(),
      contacts: json['contacts'],
      country: json['country'],
      cropPhoto: json['crop_photo'],
      domain: json['domain'] as String?,
      education: json['education'],
      exports: json['exports'],
      firstNameNom: json['first_name_nom'] as String?,
      firstNameGen: json['first_name_gen'] as String?,
      firstNameDat: json['first_name_dat'] as String?,
      firstNameAcc: json['first_name_acc'] as String?,
      firstNameIns: json['first_name_ins'] as String?,
      firstNameAbl: json['first_name_abl'] as String?,
      followersCount: (json['followers_count'] as num?)?.toInt(),
      friendStatus: (json['friend_status'] as num?)?.toInt(),
      games: json['games'] as String?,
      hasMobile: boolFromInt((json['has_mobile'] as num?)?.toInt()),
      hasPhoto: boolFromInt((json['has_photo'] as num?)?.toInt()),
      homeTown: json['home_town'] as String?,
      interests: json['interests'] as String?,
      isFavorite: json['is_favorite'] == null
          ? false
          : boolFromInt((json['is_favorite'] as num?)?.toInt()),
      isFriend: json['is_friend'] == null
          ? false
          : boolFromInt((json['is_friend'] as num?)?.toInt()),
      isHiddenFromFeed: json['is_hidden_from_feed'] == null
          ? false
          : boolFromInt((json['is_hidden_from_feed'] as num?)?.toInt()),
      isNoIndex: json['is_no_index'] == null
          ? false
          : boolFromInt((json['is_no_index'] as num?)?.toInt()),
      lastNameNom: json['last_name_nom'] as String?,
      lastNameGen: json['last_name_gen'] as String?,
      lastNameDat: json['last_name_dat'] as String?,
      lastNameAcc: json['last_name_acc'] as String?,
      lastNameIns: json['last_name_ins'] as String?,
      lastNameAbl: json['last_name_abl'] as String?,
      lastSeen: json['last_seen'],
      lists: json['lists'] as String?,
      maidenName: json['maiden_name'] as String?,
      military: json['military'],
      movies: json['movies'] as String?,
      music: json['music'] as String?,
      nickname: json['nickname'] as String?,
      occupation: json['occupation'],
      online: (json['online'] as num?)?.toInt(),
      personal: json['personal'],
      photo50: json['photo_50'] as String?,
      photo100: json['photo_100'] as String?,
      photo200orig: json['photo_200_orig'] as String?,
      photo200: json['photo_200'] as String?,
      photo400orig: json['photo_400_orig'] as String?,
      photoID: json['photo_id'] as String?,
      photoMax: json['photo_max'] as String?,
      photoMaxOrig: json['photo_max_orig'] as String?,
      quoutes: json['quoutes'] as String?,
      relatives: json['relatives'],
      relation: (json['relation'] as num?)?.toInt(),
      schools: json['schools'],
      screenName: json['screen_name'] as String?,
      sex: (json['sex'] as num?)?.toInt(),
      site: json['site'] as String?,
      status: json['status'] as String?,
      timezone: json['timezone'] as num?,
      trending: (json['trending'] as num?)?.toInt(),
      tv: json['tv'] as String?,
      universities: json['universities'],
      verified: (json['verified'] as num?)?.toInt(),
      wallDefault: json['wall_default'] as String?,
    )
      ..connections = (json['connections'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      )
      ..counters = (json['counters'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toInt()),
      );

Thumbnails _$ThumbnailsFromJson(Map<String, dynamic> json) => Thumbnails(
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
      photo34: json['photo_34'] as String,
      photo68: json['photo_68'] as String,
      photo135: json['photo_135'] as String,
      photo270: json['photo_270'] as String,
      photo300: json['photo_300'] as String,
      photo600: json['photo_600'] as String,
      photo1200: json['photo_1200'] as String,
    );

Map<String, dynamic> _$ThumbnailsToJson(Thumbnails instance) =>
    <String, dynamic>{
      'width': instance.width,
      'height': instance.height,
      'photo_34': instance.photo34,
      'photo_68': instance.photo68,
      'photo_135': instance.photo135,
      'photo_270': instance.photo270,
      'photo_300': instance.photo300,
      'photo_600': instance.photo600,
      'photo_1200': instance.photo1200,
    };

Playlist _$PlaylistFromJson(Map<String, dynamic> json) => Playlist(
      id: (json['id'] as num).toInt(),
      ownerID: (json['owner_id'] as num).toInt(),
      type: (json['type'] as num?)?.toInt() ?? 0,
      title: json['title'] as String?,
      description: emptyStringAsNull(json['description'] as String?),
      count: (json['count'] as num).toInt(),
      accessKey: json['access_key'] as String?,
      followers: (json['followers'] as num?)?.toInt(),
      plays: (json['plays'] as num?)?.toInt(),
      createTime: (json['create_time'] as num?)?.toInt(),
      updateTime: (json['update_time'] as num?)?.toInt(),
      isFollowing: json['is_following'] as bool? ?? false,
      subtitleBadge: json['subtitle_badge'] as bool? ?? false,
      playButton: json['play_button'] as bool? ?? false,
      albumType: json['album_type'] as String? ?? "playlist",
      exclusive: json['exclusive'] as bool? ?? false,
      subtitle: emptyStringAsNull(json['subtitle'] as String?),
      genres: json['genres'],
      photo: json['photo'] == null
          ? null
          : Thumbnails.fromJson(json['photo'] as Map<String, dynamic>),
      permissions: json['permissions'],
      meta: json['meta'],
    );

Map<String, dynamic> _$PlaylistToJson(Playlist instance) => <String, dynamic>{
      'id': instance.id,
      'owner_id': instance.ownerID,
      'type': instance.type,
      'title': instance.title,
      'description': instance.description,
      'subtitle': instance.subtitle,
      'count': instance.count,
      'access_key': instance.accessKey,
      'followers': instance.followers,
      'plays': instance.plays,
      'create_time': instance.createTime,
      'update_time': instance.updateTime,
      'genres': instance.genres,
      'is_following': instance.isFollowing,
      'photo': instance.photo?.toJson(),
      'permissions': instance.permissions,
      'subtitle_badge': instance.subtitleBadge,
      'play_button': instance.playButton,
      'album_type': instance.albumType,
      'meta': instance.meta,
      'exclusive': instance.exclusive,
    };

Album _$AlbumFromJson(Map<String, dynamic> json) => Album(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      ownerID: (json['owner_id'] as num?)?.toInt(),
      accessKey: json['access_key'] as String?,
      thumbnails: json['thumb'] == null
          ? null
          : Thumbnails.fromJson(json['thumb'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AlbumToJson(Album instance) => <String, dynamic>{
      'id': instance.id,
      'owner_id': instance.ownerID,
      'title': instance.title,
      'access_key': instance.accessKey,
      'thumb': instance.thumbnails?.toJson(),
    };

Audio _$AudioFromJson(Map<String, dynamic> json) => Audio(
      id: (json['id'] as num).toInt(),
      ownerID: (json['owner_id'] as num).toInt(),
      artist: json['artist'] as String,
      title: json['title'] as String,
      duration: (json['duration'] as num).toInt(),
      subtitle: json['subtitle'] as String?,
      accessKey: json['access_key'] as String?,
      ads: json['ads'],
      isExplicit: json['is_explicit'] as bool? ?? false,
      isFocusTrack: json['is_focus_track'] as bool?,
      isLicensed: json['is_licensed'] as bool?,
      isRestricted: json['content_restricted'] == null
          ? false
          : boolFromInt((json['content_restricted'] as num?)?.toInt()),
      shortVideosAllowed: json['short_videos_allowed'] as bool?,
      storiesAllowed: json['stories_allowed'] as bool?,
      storiesCoverAllowed: json['stories_cover_allowed'] as bool?,
      trackCode: json['track_code'] as String?,
      url: emptyStringAsNull(json['url'] as String?),
      date: (json['date'] as num?)?.toInt(),
      album: json['album'] == null
          ? null
          : Album.fromJson(json['album'] as Map<String, dynamic>),
      hasLyrics: json['has_lyrics'] as bool? ?? false,
      albumID: (json['album_id'] as num?)?.toInt(),
      genreID: (json['genre_id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$AudioToJson(Audio instance) => <String, dynamic>{
      'id': instance.id,
      'owner_id': instance.ownerID,
      'artist': instance.artist,
      'title': instance.title,
      'duration': instance.duration,
      'subtitle': instance.subtitle,
      'access_key': instance.accessKey,
      'ads': instance.ads,
      'is_explicit': instance.isExplicit,
      'is_focus_track': instance.isFocusTrack,
      'is_licensed': instance.isLicensed,
      'content_restricted': intFromBool(instance.isRestricted),
      'short_videos_allowed': instance.shortVideosAllowed,
      'stories_allowed': instance.storiesAllowed,
      'stories_cover_allowed': instance.storiesCoverAllowed,
      'track_code': instance.trackCode,
      'url': instance.url,
      'date': instance.date,
      'album': instance.album?.toJson(),
      'has_lyrics': instance.hasLyrics,
      'album_id': instance.albumID,
      'genre_id': instance.genreID,
    };
