import "shared.dart";

/// Возвращает объект [Audio] по переданным полям.
Audio _generateAudio(
  int id,
  String title,
  String artist,
  int duration, {
  String? albumTitle,
  String? albumThumbnail,
  String? audioPreview,
}) {
  String thumb(int size) =>
      "https://cdn-images.dzcdn.net/images/cover/$albumThumbnail/${size}x$size-000000-80-0-0.jpg";

  return Audio(
    id: id,
    ownerID: 1,
    title: title,
    artist: artist,
    duration: duration,
    url: audioPreview != null
        ? "https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview$audioPreview.plus.aac.ep.m4a"
        : null,
    isRestricted: audioPreview == null,
    album: albumTitle != null && albumThumbnail != null
        ? Album(
            id: 0,
            title: albumTitle,
            ownerID: 0,
            accessKey: "",
            thumbnails: Thumbnails(
              width: 1000,
              height: 1000,
              photo34: thumb(32),
              photo68: thumb(68),
              photo135: thumb(135),
              photo270: thumb(270),
              photo300: thumb(300),
              photo600: thumb(600),
              photo1200: thumb(1200),
            ),
          )
        : null,
  );
}

/// Возвращает объект [Playlist] по переданным полям.
Playlist _generatePlaylist(
  int id,
  int count,
  String title, {
  String? description,
  String? photo,
}) {
  return Playlist(
    id: id,
    ownerID: 1,
    count: count,
    title: title,
    description: description,
    photo: photo != null
        ? Thumbnails(
            width: 1000,
            height: 1000,
            photo34: photo,
            photo68: photo,
            photo135: photo,
            photo270: photo,
            photo300: photo,
            photo600: photo,
            photo1200: photo,
          )
        : null,
  );
}

/// Список из всех фейковых треков.
final List<Audio> fakeAudios = [
  _generateAudio(
    0,
    "Ticking",
    "Nick Leng",
    4 * 60 + 26,
    albumTitle: "Ticking",
    albumThumbnail: "57d926acba5c784e792e9640760fd08f",
    audioPreview:
        "125/v4/f9/c6/81/f9c681b2-0437-bf06-72d6-9a9652e9e49c/mzaf_4238613517082451431",
  ),
  _generateAudio(
    1,
    "Numbers",
    "Daughter",
    4 * 60 + 17,
    albumTitle: "Not To Disappear",
    albumThumbnail: "179cbd8a9eebfe96120a40634b86084d",
    audioPreview:
        "126/v4/3d/ed/55/3ded55b5-dff4-aa10-2818-2d7e832cb4a4/mzaf_8000652889695914581",
  ),
  _generateAudio(
    2,
    "Roman Empire",
    "MISSIO",
    3 * 60 + 55,
    albumTitle: "Can You Feel The Sun",
    albumThumbnail: "61375784a822197dc2580fafde358228",
    audioPreview:
        "125/v4/a8/bb/ff/a8bbffff-269e-d4bc-e011-eb8824edf393/mzaf_2112904023473699358",
  ),
  _generateAudio(
    3,
    "still feel.",
    "half·alive",
    4 * 60 + 7,
    albumTitle: "still feel.",
    albumThumbnail: "c4d3b0a0b97749f8f1b78ac3382ca911",
    audioPreview:
        "125/v4/23/2a/7b/232a7bb8-bf05-d483-ec27-b5c102c5c6ec/mzaf_6276788988620577668",
  ),
  _generateAudio(
    4,
    "Lipstick On The Glass",
    "Wolf Alice",
    4 * 60 + 8,
    albumTitle: "Blue Weekend (Tour Deluxe)",
    albumThumbnail: "d724ecbca183e21f0bdcb23d45fa55ed",
    audioPreview:
        "125/v4/bb/c2/f9/bbc2f9bf-d37f-33d5-f5b4-91e4e9280e5b/mzaf_9372306912972148340",
  ),
  _generateAudio(
    5,
    "Beautiful Crime",
    "Tamer",
    4 * 60 + 32,
    albumTitle: "Beautiful Crime",
    albumThumbnail: "11d1a53197e54bc432ca78915bc98423",
    audioPreview:
        "115/v4/b7/97/aa/b797aa07-0c6f-9894-d440-e5e91a4d9453/mzaf_983904452722353343",
  ),
  _generateAudio(
    6,
    "Tear in My Heart",
    "twenty one pilots",
    3 * 60 + 8,
    albumTitle: "Blurryface",
    albumThumbnail: "dbbde1014cda9b101412a8e27add0ad2",
    audioPreview:
        "122/v4/e4/b3/ff/e4b3ff46-08b2-ce4e-23b6-8f325c0ccc64/mzaf_2671200519279539735",
  ),
  _generateAudio(
    7,
    "каждый раз",
    "Монеточка",
    3 * 60 + 0,
    albumTitle: "Раскраски для взрослых",
    albumThumbnail: "9fba98e5285370a43e0e0d299c559c0c",
    audioPreview:
        "115/v4/3f/68/ac/3f68ac28-1f60-3220-7510-4a561106a5fe/mzaf_1860008394311371846",
  ),
  _generateAudio(
    8,
    "The Other Side Of Paradise",
    "Glass Animals",
    5 * 60 + 20,
    albumTitle: "How To Be A Human Being",
    albumThumbnail: "dbf4b069d3f3789a28dc687186856fa2",
    audioPreview:
        "116/v4/21/5e/9f/215e9f7c-7c3e-b544-6450-02b470c9acd4/mzaf_523271451539799897",
  ),
  _generateAudio(
    9,
    "Navigating",
    "twenty one pilots",
    3 * 60 + 43,
    albumTitle: "Clancy",
    albumThumbnail: "4f2819429ed92d35a649d609e39b29b5",
    audioPreview:
        "211/v4/75/8e/71/758e715a-9395-887d-848a-cf0395386473/mzaf_4519887014210130411",
  ),
  _generateAudio(
    10,
    "No Chances",
    "twenty one pilots",
    3 * 60 + 46,
    albumTitle: "Scaled and Icy",
    albumThumbnail: "be27806d176aa93025870b8b02642a39",
    audioPreview:
        "211/v4/a3/2b/e6/a32be682-f002-8fff-c9aa-ede21397b012/mzaf_840087966137445900",
  ),
  _generateAudio(
    11,
    "Jumpsuit",
    "twenty one pilots",
    3 * 60 + 58,
    albumTitle: "Trench",
    albumThumbnail: "765dc8aba0e893fc6d55af08572fc902",
    audioPreview:
        "211/v4/5c/26/00/5c260021-b03e-6d5f-47e8-28082105c10a/mzaf_14454046570587588128",
  ),
  _generateAudio(
    12,
    "Level of Concern",
    "twenty one pilots",
    3 * 60 + 40,
    albumTitle: "Scaled And Icy (Livestream Version)",
    albumThumbnail: "ad8c6068b54ba335fb2c375ca95f06d3",
    audioPreview:
        "112/v4/b9/21/e2/b921e233-a3d5-c8e4-36f0-5156bfbf594a/mzaf_5699053398318213530",
  ),
  _generateAudio(
    13,
    "Car Radio",
    "twenty one pilots",
    4 * 60 + 27,
    albumTitle: "Vessel",
    albumThumbnail: "b44fcb9ab89663fa6a965958cc48b177",
    audioPreview:
        "116/v4/66/5f/36/665f36d4-68b5-ce15-8d94-8e17ac70063c/mzaf_1732378869481941530",
  ),
  _generateAudio(
    14,
    "It's A Trip!",
    "Joywave",
    3 * 60 + 3,
    albumTitle: "Content",
    albumThumbnail: "26da5e2ce4133329d7596f0cbfcb10da",
    audioPreview:
        "116/v4/89/ed/04/89ed0488-af6f-3317-11e0-93b52e8488ab/mzaf_589910161370972004",
  ),
  _generateAudio(
    15,
    "Void in Blue",
    "Glare",
    4 * 60 + 39,
    albumTitle: "Void in Blue",
    albumThumbnail: "49bfada94e331e50648f01f8c29d234d",
    audioPreview:
        "115/v4/92/cf/10/92cf101c-feff-1689-68e0-7cb1c117b5c7/mzaf_16053808407237269015",
  ),
  _generateAudio(
    16,
    "Unreal",
    "Jetha",
    2 * 60 + 28,
    albumTitle: "Unreal",
    albumThumbnail: "09f27aa2819fd762ae9f94a596cc979f",
    audioPreview:
        "126/v4/cb/52/66/cb526668-d630-6380-56dc-1e5624bbbc2a/mzaf_5936713884977593963",
  ),
  _generateAudio(
    17,
    "Heaven",
    "Normandie",
    3 * 60 + 3,
    albumTitle: "White Flag",
    albumThumbnail: "8a82893317f5a168705020496f1e0435",
    audioPreview:
        "115/v4/f6/e3/58/f6e358c1-066b-4f4c-fa4a-122b31483647/mzaf_181053401339510586",
  ),
  _generateAudio(
    18,
    "Ирония",
    "лампабикт",
    2 * 60 + 37,
    albumTitle: "Cинонимы к слову искренность",
    albumThumbnail: "98aa0efc5a08a84ec03f698c3a06d81a",
    audioPreview:
        "125/v4/d7/f0/a7/d7f0a748-c277-e8b1-09f2-16dedd097486/mzaf_10612065178896338922",
  ),
  _generateAudio(
    19,
    "Город",
    "PRAVADA",
    3 * 60 + 30,
    albumTitle: "Романтика",
    albumThumbnail: "7ca291e67437219568baae192368725f",
    audioPreview:
        "125/v4/c6/ff/0d/c6ff0d6d-7062-daf8-bec1-da659595f372/mzaf_10774097155043886918",
  ),
  _generateAudio(
    20,
    "Hallucinations",
    "PVRIS",
    3 * 60 + 43,
    albumTitle: "Use Me (Deluxe)",
    albumThumbnail: "ad0305c8b22d554bd2e10959283ab384",
    audioPreview:
        "125/v4/6c/da/65/6cda6565-d6e7-f9e2-6185-69e783f38949/mzaf_18336206492100614680",
  ),
  _generateAudio(
    21,
    "Castle",
    "Halsey",
    4 * 60 + 37,
    albumTitle: "BADLANDS",
    albumThumbnail: "1c77a03c97268794dec3ccc2bd488329",
    audioPreview:
        "112/v4/7b/d6/4c/7bd64c34-686d-5cb0-c8c8-af42bd3fa227/mzaf_16511766512308250172",
  ),
  _generateAudio(
    22,
    "Golden Dandelions",
    "Barns Courtney",
    3 * 60 + 25,
    albumTitle: "The Attractions Of Youth",
    albumThumbnail: "bc5ac4dbf0bab3e00ca150a87bdf4c5d",
    audioPreview:
        "125/v4/59/8c/cc/598cccc0-3695-3890-079d-b32b92e66ef3/mzaf_1182003501534502992",
  ),
  _generateAudio(
    23,
    "Make Me Fade",
    "K.Flay",
    4 * 60 + 39,
    albumTitle: "Tunesdays",
    albumThumbnail: "e67d210d47c61ddc8591423b0ea8f849",
    audioPreview:
        "125/v4/90/07/6a/90076a74-1fdc-3db6-84f4-06b2324e7b7d/mzaf_9037907578081838895",
  ),
  _generateAudio(
    24,
    "Castaway",
    "Barns Courtney",
    2 * 60 + 44,
    albumTitle: "404",
    albumThumbnail: "db387628f6747de11ad73f66ff03771c",
    audioPreview:
        "125/v4/90/81/0d/90810d6a-550b-5cc9-5182-45b73ec3b7dd/mzaf_5829929871405500944",
  ),

  //
  _generateAudio(
    25,
    "Pump Up The Jam",
    "Technotronic",
    5 * 60 + 20,
    albumTitle: "Pump Up The Jam",
    albumThumbnail: "8ddb94a0ba17254188a54d18b6173f7f",
    audioPreview:
        "115/v4/44/b6/a5/44b6a5d0-cd4c-1991-79b3-6da127867e13/mzaf_6809675205265410909",
  ),
  _generateAudio(
    26,
    "Never Gonna Give You Up",
    "Rick Astley",
    3 * 60 + 31,
    albumTitle: "The Best of Me",
    albumThumbnail: "fe779e632872f7c6e9f1c84ffa7afc33",
    audioPreview:
        "126/v4/1c/0f/a0/1c0fa075-b42d-1f99-a09e-0e440563c4fe/mzaf_13425254859660425668",
  ),

  //
  _generateAudio(
    27,
    "Overcompensate",
    "twenty one pilots",
    3 * 60 + 56,
    albumTitle: "Clancy",
    albumThumbnail: "4f2819429ed92d35a649d609e39b29b5",
    audioPreview:
        "211/v4/cd/f8/fb/cdf8fb01-32a1-6eab-c80d-83102ae6d850/mzaf_10717994072469548193",
  ),
  _generateAudio(
    28,
    "Holding On to You",
    "twenty one pilots",
    4 * 60 + 23,
    albumTitle: "Vessel",
    albumThumbnail: "b44fcb9ab89663fa6a965958cc48b177",
    audioPreview:
        "116/v4/d4/bc/1d/d4bc1df0-65b9-2b86-7fb9-94e81a9d8ac7/mzaf_12255726039382995618",
  ),
  _generateAudio(
    29,
    "Vignette",
    "twenty one pilots",
    3 * 60 + 22,
    albumTitle: "Clancy",
    albumThumbnail: "4f2819429ed92d35a649d609e39b29b5",
    audioPreview:
        "211/v4/1a/c3/ba/1ac3bade-6891-3963-6479-f7b105542b8c/mzaf_17735710838258422848",
  ),
  _generateAudio(
    30,
    "Car Radio",
    "twenty one pilots",
    4 * 60 + 27,
    albumTitle: "Vessel",
    albumThumbnail: "b44fcb9ab89663fa6a965958cc48b177",
    audioPreview:
        "116/v4/66/5f/36/665f36d4-68b5-ce15-8d94-8e17ac70063c/mzaf_1732378869481941530",
  ),
  _generateAudio(
    31,
    "The Judge",
    "twenty one pilots",
    4 * 60 + 56,
    albumTitle: "Blurryface",
    albumThumbnail: "dbbde1014cda9b101412a8e27add0ad2",
    audioPreview:
        "211/v4/ff/a9/c5/ffa9c529-f686-adef-cd1c-996d8da7d5f7/mzaf_11006459311899432975",
  ),
  _generateAudio(
    32,
    "The Craving",
    "twenty one pilots",
    2 * 60 + 54,
    albumTitle: "Clancy",
    albumThumbnail: "4f2819429ed92d35a649d609e39b29b5",
    audioPreview:
        "211/v4/8e/d8/04/8ed80480-c9b0-2792-a99b-0962b64ceb85/mzaf_5436040253937643825",
  ),
  _generateAudio(
    33,
    "Tear in My Heart",
    "twenty one pilots",
    3 * 60 + 8,
    albumTitle: "Blurryface",
    albumThumbnail: "dbbde1014cda9b101412a8e27add0ad2",
    audioPreview:
        "122/v4/e4/b3/ff/e4b3ff46-08b2-ce4e-23b6-8f325c0ccc64/mzaf_2671200519279539735",
  ),
  _generateAudio(
    34,
    "Backslide",
    "twenty one pilots",
    3 * 60 + 0,
    albumTitle: "Clancy",
    albumThumbnail: "4f2819429ed92d35a649d609e39b29b5",
    audioPreview:
        "211/v4/46/0a/80/460a80f1-5cfa-7219-2062-10bb0833af83/mzaf_2655288735530209172",
  ),
  _generateAudio(
    35,
    "Shy Away",
    "twenty one pilots",
    2 * 60 + 55,
    albumTitle: "Scaled and Icy",
    albumThumbnail: "be27806d176aa93025870b8b02642a39",
    audioPreview:
        "211/v4/6e/71/60/6e716029-5820-4fbe-64ed-9f3ab40aa507/mzaf_13264443382246128088",
  ),
  _generateAudio(
    36,
    "Heathens",
    "twenty one pilots",
    2 * 60 + 56,
    albumTitle: "Heathens",
    albumThumbnail: "3dfc8c9e406cf1bba8ce0695a44a9b7e",
    audioPreview:
        "112/v4/12/fb/a2/12fba29a-7054-99ce-0a5b-1eba51bc78de/mzaf_6464048370138404314",
  ),
  _generateAudio(
    37,
    "Next Semester",
    "twenty one pilots",
    3 * 60 + 54,
    albumTitle: "Clancy",
    albumThumbnail: "4f2819429ed92d35a649d609e39b29b5",
    audioPreview:
        "211/v4/4e/9c/56/4e9c5660-26a7-3e51-eb98-7ea20ac16bb6/mzaf_17831256129725016829",
  ),
  _generateAudio(
    38,
    "Routines in the Night",
    "twenty one pilots",
    3 * 60 + 23,
    albumTitle: "Clancy",
    albumThumbnail: "4f2819429ed92d35a649d609e39b29b5",
    audioPreview:
        "221/v4/73/69/73/7369736e-09ed-b547-ee5e-fc2a2ba53e8f/mzaf_16789587142665742936",
  ),
  _generateAudio(
    39,
    "Addict With A Pen",
    "twenty one pilots",
    4 * 60 + 46,
    albumTitle: "Twenty One Pilots",
    albumThumbnail: "fbbd791bc2a1e9cfad3f61131aff09bb",
    audioPreview:
        "221/v4/71/56/fa/7156fa14-6f74-22e4-a7ee-3cd5d4d8343f/mzaf_3801080671806035606",
  ),
  _generateAudio(
    40,
    "Migraine",
    "twenty one pilots",
    4 * 60 + 46,
    albumTitle: "Vessel",
    albumThumbnail: "b44fcb9ab89663fa6a965958cc48b177",
    audioPreview:
        "116/v4/5e/e3/87/5ee387f9-dc72-0edd-c62f-65d4a2623bdd/mzaf_11232159465062774420",
  ),
  _generateAudio(
    41,
    "Forest",
    "twenty one pilots",
    4 * 60 + 11,
    albumTitle: "Regional At Best",
    albumThumbnail: "e276d1f527dc726a47cb10a87cf90742",
    audioPreview:
        "126/v4/1c/0f/a0/1c0fa075-b42d-1f99-a09e-0e440563c4fe/mzaf_13425254859660425668", // В Apple Music нету RAB.
  ),
  _generateAudio(
    42,
    "Fall Away",
    "twenty one pilots",
    3 * 60 + 2,
    albumTitle: "Twenty One Pilots",
    albumThumbnail: "fbbd791bc2a1e9cfad3f61131aff09bb",
    audioPreview:
        "211/v4/0c/b5/26/0cb526fc-10d1-7bd6-5092-1195d50a81a9/mzaf_11835555771245932229",
  ),
  _generateAudio(
    43,
    "Mulberry Street",
    "twenty one pilots",
    3 * 60 + 44,
    albumTitle: "Scaled and Icy",
    albumThumbnail: "be27806d176aa93025870b8b02642a39",
    audioPreview:
        "211/v4/73/7d/13/737d13f6-f45d-4ca7-1b3f-8c6fca3c6cd5/mzaf_12676697918855589987",
  ),
  _generateAudio(
    44,
    "Navigating",
    "twenty one pilots",
    3 * 60 + 43,
    albumTitle: "Clancy",
    albumThumbnail: "4f2819429ed92d35a649d609e39b29b5",
    audioPreview:
        "211/v4/75/8e/71/758e715a-9395-887d-848a-cf0395386473/mzaf_4519887014210130411",
  ),
  _generateAudio(
    45,
    "Nico and the Niners",
    "twenty one pilots",
    3 * 60 + 45,
    albumTitle: "Trench",
    albumThumbnail: "765dc8aba0e893fc6d55af08572fc902",
    audioPreview:
        "221/v4/a2/8d/bf/a28dbff5-7468-feb2-1d79-a4c503b63f04/mzaf_13167619392699395431",
  ),
  _generateAudio(
    46,
    "Heavydirtysoul",
    "twenty one pilots",
    3 * 60 + 54,
    albumTitle: "Blurryface",
    albumThumbnail: "dbbde1014cda9b101412a8e27add0ad2",
    audioPreview:
        "211/v4/15/b0/22/15b02292-c856-0543-cc70-6cae2d5a288f/mzaf_959704183389971976",
  ),
  _generateAudio(
    47,
    "My Blood",
    "twenty one pilots",
    3 * 60 + 49,
    albumTitle: "Trench",
    albumThumbnail: "765dc8aba0e893fc6d55af08572fc902",
    audioPreview:
        "211/v4/8e/0f/34/8e0f3420-cab4-470c-14ef-5f912b3a1413/mzaf_16346764626186892860",
  ),
  _generateAudio(
    48,
    "Oldies Station",
    "twenty one pilots",
    3 * 60 + 48,
    albumTitle: "Clancy",
    albumThumbnail: "4f2819429ed92d35a649d609e39b29b5",
    audioPreview:
        "211/v4/fd/fe/9d/fdfe9db0-7850-8406-b33a-cc61cd56c2bd/mzaf_1505301398935954211",
  ),
  _generateAudio(
    49,
    "Fake You Out",
    "twenty one pilots",
    3 * 60 + 51,
    albumTitle: "Vessel",
    albumThumbnail: "b44fcb9ab89663fa6a965958cc48b177",
    audioPreview:
        "126/v4/85/70/ea/8570ea1d-2fd3-a367-a5d2-3590a8cdb0ec/mzaf_3507390111574458632",
  ),
  _generateAudio(
    50,
    "Guns for Hands",
    "twenty one pilots",
    4 * 60 + 34,
    albumTitle: "Vessel",
    albumThumbnail: "b44fcb9ab89663fa6a965958cc48b177",
    audioPreview:
        "126/v4/96/43/af/9643afb0-23d2-0b91-c889-39ccf3303399/mzaf_17537628521382096998",
  ),
  _generateAudio(
    51,
    "Lavish",
    "twenty one pilots",
    3 * 60 + 29,
    albumTitle: "Clancy",
    albumThumbnail: "4f2819429ed92d35a649d609e39b29b5",
    audioPreview:
        "211/v4/e3/47/bc/e347bc67-23fe-0f9e-09cb-cd82b9d192ff/mzaf_12582489574810742944",
  ),
  _generateAudio(
    52,
    "Ride",
    "twenty one pilots",
    3 * 60 + 8,
    albumTitle: "Blurryface",
    albumThumbnail: "dbbde1014cda9b101412a8e27add0ad2",
    audioPreview:
        "221/v4/55/46/e6/5546e64f-213d-05cb-b22b-e6d2e8b0253f/mzaf_1205068553244250610",
  ),
  _generateAudio(
    53,
    "Paladin Strait",
    "twenty one pilots",
    6 * 60 + 28,
    albumTitle: "Clancy",
    albumThumbnail: "4f2819429ed92d35a649d609e39b29b5",
    audioPreview:
        "211/v4/18/eb/62/18eb620b-eb6d-4454-a474-dd94a46de923/mzaf_5674759287338107706",
  ),
  _generateAudio(
    54,
    "Jumpsuit",
    "twenty one pilots",
    3 * 60 + 58,
    albumTitle: "Trench",
    albumThumbnail: "765dc8aba0e893fc6d55af08572fc902",
    audioPreview:
        "211/v4/5c/26/00/5c260021-b03e-6d5f-47e8-28082105c10a/mzaf_14454046570587588128",
  ),
  _generateAudio(
    55,
    "Midwest Indigo",
    "twenty one pilots",
    3 * 60 + 16,
    albumTitle: "Clancy",
    albumThumbnail: "4f2819429ed92d35a649d609e39b29b5",
    audioPreview:
        "221/v4/70/4d/9a/704d9acb-6576-0320-5aa7-d12269d5a5f5/mzaf_3167110973298476961",
  ),
  _generateAudio(
    56,
    "Stressed Out",
    "twenty one pilots",
    3 * 60 + 22,
    albumTitle: "Blurryface",
    albumThumbnail: "dbbde1014cda9b101412a8e27add0ad2",
    audioPreview:
        "221/v4/63/a0/d9/63a0d94f-a9f1-f34a-5fb1-7860fe6a5d94/mzaf_11664749249828126743",
  ),
  _generateAudio(
    57,
    "Trees",
    "twenty one pilots",
    4 * 60 + 27,
    albumTitle: "Vessel",
    albumThumbnail: "b44fcb9ab89663fa6a965958cc48b177",
    audioPreview:
        "211/v4/28/19/7b/28197b59-0ae7-a4d1-4864-130fff3b4e1c/mzaf_9150957879362061963",
  ),
];

/// Список из фейковых треков для блока "Моя музыка".
final List<Audio> fakeMyMusicAudio = fakeAudios.sublist(0, 25);

/// Список из фейковых треков для плейлиста "Cunk's favorites".
final List<Audio> fakeCunksFavoritesAudio = fakeAudios.sublist(25, 27);

/// Список из фейковых треков для плейлиста "twenty one pilots: Clancy Tour".
final List<Audio> fakeClancyTourAudio = fakeAudios.sublist(27, 58);

/// Список из фейковых треков для различных плейлистов.
final List<Audio> fakePlaylistAudios = fakeAudios.sublist(20, 25);

/// Список из всех фейковых плейлистов.
final List<Playlist> fakePlaylists = [
  _generatePlaylist(
    1,
    fakeClancyTourAudio.length,
    "twenty one pilots: Clancy Tour",
    description: "Not Done. Not Done. Josh Dun.",
    photo:
        "https://image-cdn-ak.spotifycdn.com/image/ab67706c0000da849d786953766082aac6663caa",
  ),
  _generatePlaylist(
    2,
    fakeCunksFavoritesAudio.length,
    "Cunk's favorites",
    description: "Philomena Cunk's favorite tracks.",
    photo:
        "https://d.newsweek.com/en/full/2526949/cul-spotlight-philomena-cunk.jpg",
  ),

  //
  _generatePlaylist(
    3,
    fakePlaylistAudios.length,
    "Плейлист дня 5",
    description: "Вы слушали: Barns Courtney",
    photo:
        "https://sun9-58.userapi.com/impg/2-JGMQwC7BiNpoTpx55qAbdPUP34WYfWPwhDkg/4crRGYPW35I.jpg?size=594x594&quality=95&sign=8d9fa5c85ceec6bca1fe8257c8e059ac",
  ),
  _generatePlaylist(
    4,
    fakePlaylistAudios.length,
    "Плейлист дня 4",
    description: "Вы слушали: PVRIS",
    photo:
        "https://sun9-8.userapi.com/impg/nmUhJ9lBuKZMeFQjNKwxljS9DCeqVJ6Ucv52nw/PMpsT2aabpM.jpg?size=594x594&quality=95&sign=9af143e60bcb63afe1cfde03fcd1eca3",
  ),
  _generatePlaylist(
    5,
    fakePlaylistAudios.length,
    "Плейлист дня 3",
    description: "Вы слушали: Halsey",
    photo:
        "https://sun9-55.userapi.com/impg/-JTza8mHnok1Bsmq3rIMAWIddKAuqd36L-UuWQ/6eYONHdgMcA.jpg?size=594x594&quality=95&sign=d17e1f8d46a2110941b1dd53449714d7",
  ),
  _generatePlaylist(
    6,
    fakePlaylistAudios.length,
    "Плейлист дня 2",
    description: "Вы слушали: K.Flay",
    photo:
        "https://sun9-80.userapi.com/impg/9-DgMdFLPwrzPQjWn8GZMiQuFjW9tHfsduz76Q/1MPkrrd1_0o.jpg?size=594x594&quality=95&sign=b48a0471067b9ddfabd5adf5882e43c4",
  ),
  _generatePlaylist(
    7,
    fakePlaylistAudios.length,
    "Плейлист дня 1",
    description: "Вы слушали: Barns Courtney",
    photo:
        "https://sun9-58.userapi.com/impg/En9RJve4G4LfmhXmxhXfH8brff5vtigGshPS0g/Qq8hxKZ0rdo.jpg?size=594x594&quality=95&sign=b8ddb197b06319d1c7093d77bb78d4b7",
  ),
  _generatePlaylist(
    8,
    fakePlaylistAudios.length,
    "Открытия",
    description: "Новое для вас",
    photo:
        "https://sun9-42.userapi.com/impg/fq_Sxi2t6ktoLYt0dWMvfYXEMGFwYjxGo7np6g/IZzoFJLlB9A.jpg?size=594x594&quality=95&sign=8d2709c4a02a3a6612727a462dc2b1fd",
  ),
  _generatePlaylist(
    9,
    fakePlaylistAudios.length,
    "Новинки",
    description: "обновлён в субботу",
    photo:
        "https://sun9-78.userapi.com/impg/QW179rl3Z27NE2xC08HEIPcE5_d_3WRdfzZ-WA/OJv0uSWaJj4.jpg?size=594x594&quality=95&sign=e834719f3012eba67c4440a5d7a35fa1",
  ),
  _generatePlaylist(
    10,
    fakePlaylistAudios.length,
    "Плейлист недели",
    description: "Barns Courtney и другие",
    photo:
        "https://sun9-80.userapi.com/impg/k0wOemKsoftjpBhlXfi-6k_OQnEnyPHu6utwZA/Hzw_TbFr4M8.jpg?size=594x594&quality=95&sign=83a8731d840e713da33e9c049a34c5e5",
  ),
];

/// Фейковые плейлисты для раздела "Ваши плейлисты".
final List<Playlist> fakeYourPlaylists = fakePlaylists.sublist(0, 2);

/// Фейковые плейлисты для раздела "Плейлисты для Вас".
final List<Playlist> fakeForYouPlaylists = fakePlaylists.sublist(2, 10);

/// Фейковые плейлисты для раздела "Собрано редакцией".
final List<Playlist> fakeMadeByVKPlaylists = [];
