import "dart:async";

import "package:cached_network_image/cached_network_image.dart";
import "package:collection/collection.dart";
import "package:declarative_refresh_indicator/declarative_refresh_indicator.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:just_audio/just_audio.dart";
import "package:provider/provider.dart";
import "package:responsive_builder/responsive_builder.dart";

import "../../api/vk/api.dart";
import "../../api/vk/catalog/get_audio.dart";
import "../../api/vk/executeScripts/mass_audio_get.dart";
import "../../api/vk/shared.dart";
import "../../consts.dart";
import "../../db/schemas/playlists.dart";
import "../../main.dart";
import "../../provider/user.dart";
import "../../services/cache_manager.dart";
import "../../services/logger.dart";
import "../../utils.dart";
import "../../widgets/dialogs.dart";
import "../../widgets/fallback_audio_photo.dart";
import "../../widgets/page_route_builders.dart";
import "../home.dart";
import "music/categories/by_vk_playlists.dart";
import "music/categories/my_music.dart";
import "music/categories/my_playlists.dart";
import "music/categories/realtime_playlists.dart";
import "music/categories/recommended_playlists.dart";
import "music/categories/simillar_music.dart";
import "music/playlist.dart";
import "music/search.dart";
import "profile.dart";

/// Загружает всю информацию пользователя (плейлисты, треки, рекомендации) для раздела «музыка», присваивая её в объект [UserProvider]. Если таковая информация уже присутствует, то данный вызов будет проигнорирован.
///
/// Если [forceUpdate] = true, то данный метод загрузит информацию для раздела музыки даже если в [UserProvider] таковая информация уже есть.
Future<void> ensureUserAudioAllInformation(
  BuildContext context, {
  bool forceUpdate = false,
}) async {
  // Загружаем плейлисты из БД.
  await loadDBUserPlaylists(
    context,
  );

  if (!context.mounted) return;

  // Делаем API-запросы, получаем список плейлистов из ВКонтакте, если есть доступ к интернету.
  if (connectivityManager.hasConnection) {
    await Future.wait([
      // Список фаворитных треков (со списком треков), а так же плейлисты пользователя (без списка треков).
      ensureUserAudioBasicInfo(
        context,
        forceUpdate: forceUpdate,
      ),

      // Рекомендации.
      ensureUserAudioRecommendations(
        context,
        forceUpdate: forceUpdate,
      ),
    ]);
  }

  if (!context.mounted) return;

  // После полной загрузки, делаем загрузку остальных данных.
  if (connectivityManager.hasConnection) {
    await loadCachedTracksInformation(
      context,
      forceUpdate: forceUpdate,
    );
  }

  return;
}

/// Загружает информацию по плейлистам, их трекам и рекомендованным плейлистам из базы данных Isar. Ничего не делает, если данные уже были загружены.
Future<void> loadDBUserPlaylists(
  BuildContext context,
) async {
  final UserProvider user = Provider.of<UserProvider>(context, listen: false);
  final AppLogger logger = getLogger("loadDBUserPlaylists");

  // Если информация с БД уже загружена, то ничего не делаем.
  if (user.favoritesPlaylist?.audios != null) return;

  logger.d("Loading playlists and track list from Isar DB");

  // Получаем список плейлистов.
  final List<DBPlaylist?> playlists = await appStorage.getPlaylists();

  // Добавляем плейлисты.
  for (DBPlaylist? playlist in playlists) {
    if (playlist == null) {
      logger.e(
        "Found null playlist: $playlist",
      );

      continue;
    }

    user.updatePlaylist(
      playlist.asExtendedPlaylist,
      saveToDB: false,
    );
  }

  user.markUpdated(false);
}

/// Загружает информацию (плейлисты, треки) для раздела «музыка», присваивая её в объект [UserProvider], после чего сохраняет всё в базу данных приложения, если [saveToDB] равен true.
///
/// Если информация о плейлистах и треках уже присутствует, то данный вызов будет проигнорирован. [forceUpdate] отключает проверку на присутствие данных.
Future<void> ensureUserAudioBasicInfo(
  BuildContext context, {
  bool saveToDB = true,
  bool forceUpdate = false,
}) async {
  final UserProvider user = Provider.of<UserProvider>(context, listen: false);
  final AppLogger logger = getLogger("ensureUserAudioInfo");

  // Если информация уже загружена, то ничего не делаем.
  if (!forceUpdate &&
      (user.favoritesPlaylist?.audios != null &&
          (user.favoritesPlaylist?.areTracksLive ?? false))) return;

  logger.d("Loading music information (force: $forceUpdate)");

  // Получаем информацию по музыке, вместе с альбомами, если пользователь добавил токен от VK Admin.
  try {
    final APIMassAudioGetResponse response =
        await user.scriptMassAudioGetWithAlbums(user.id!);
    raiseOnAPIError(response);

    user.playlistsCount = response.response!.playlistsCount;

    // Создаём список из плейлистов пользователя, а так же добавляем их в память.
    user.updatePlaylists(
      [
        // Фейковый плейлист для лайкнутых треков.
        ExtendedPlaylist(
          id: 0,
          ownerID: user.id!,
          count: response.response!.audioCount,
          audios: response.response!.audios
              .map(
                (Audio audio) => ExtendedAudio.fromAPIAudio(
                  audio,
                  isLiked: true,
                ),
              )
              .toList(),
          isLiveData: true,
          areTracksLive: true,
        ),

        // Все остальные плейлисты пользователя.
        // Мы помечаем что плейлисты являются кэшированными.
        ...response.response!.playlists.map(
          (playlist) => ExtendedPlaylist.fromAudioPlaylist(
            playlist,
          ),
        ),
      ],
      saveToDB: saveToDB,
    );

    // Запускаем задачу по кэшированию плейлиста с фаворитными треками.
    //
    // Запуск кэширования у других плейлистов происходит в ином месте:
    // Данный метод НЕ загружает содержимое у других плейлистов.
    if (user.favoritesPlaylist!.cacheTracks ?? false) {
      downloadManager.cachePlaylist(user: user, user.favoritesPlaylist!);
    }

    user.markUpdated(false);
  } catch (e, stackTrace) {
    logger.e(
      "Ошибка при загрузке информации по трекам и плейлистам для раздела музыки: ",
      error: e,
      stackTrace: stackTrace,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.music_basicDataLoadError(
              e.toString(),
            ),
          ),
        ),
      );
    }
  }
}

/// Загружает информацию по рекомендациям для раздела «музыка», присваивая её в объект [UserProvider], после чего сохраняет всё в базу данных приложения, если [saveToDB] равен true.
///
/// Данный метод работает лишь в том случае, если у пользователя есть присвоенный токен рекомендаций (т.е., токен приложения VK Admin). Если [UserProvider] не имеет данного токена, то вызов будет проигнорирован.
///
/// Если информация о рекомендациях уже присутствует, то данный вызов будет проигнорирован. [forceUpdate] отключает проверку на присутствие данных.
Future<void> ensureUserAudioRecommendations(
  BuildContext context, {
  bool saveToDB = true,
  bool forceUpdate = false,
}) async {
  final UserProvider user = Provider.of<UserProvider>(context, listen: false);
  final AppLogger logger = getLogger("ensureUserAudioRecommendations");

  /// Парсит список из плейлистов, возвращая список плейлистов из раздела "Какой сейчас вайб?".
  List<ExtendedPlaylist> parseMoodPlaylists(
    APICatalogGetAudioResponse response,
  ) {
    final Section mainSection = response.response!.catalog.sections[0];

    // Ищем блок с рекомендуемыми плейлистами.
    SectionBlock moodPlaylistsBlock = mainSection.blocks!.firstWhere(
      (SectionBlock block) =>
          block.dataType == "music_playlists" &&
          block.layout["style"] == "unopenable",
      orElse: () => throw AssertionError(
        "Блок с разделом 'Какой сейчас вайб?' не был найден",
      ),
    );

    // Извлекаем список ID плейлистов из этого блока.
    final List<String> moodPlaylistIDs = moodPlaylistsBlock.playlistIDs!;

    // Достаём те плейлисты, которые рекомендуются нами ВКонтакте.
    // Превращаем объекты типа AudioPlaylist в ExtendedPlaylist.
    return response.response!.playlists
        .where(
          (Playlist playlist) => moodPlaylistIDs.contains(playlist.mediaKey),
        )
        .map(
          (Playlist playlist) => ExtendedPlaylist.fromAudioPlaylist(
            playlist,
            isMoodPlaylist: true,
          ),
        )
        .toList();
  }

  /// Парсит список из аудио миксов.
  List<ExtendedPlaylist> parseAudioMixPlaylists(
    APICatalogGetAudioResponse response,
  ) {
    final List<ExtendedPlaylist> playlists = [];

    // Проходимся по списку аудио миксов, создавая из них плейлисты.
    for (AudioMix mix in response.response!.audioStreamMixes) {
      playlists.add(
        ExtendedPlaylist(
          id: -fastHash(mix.id),
          ownerID: user.id!,
          title: mix.title,
          description: mix.description,
          backgroundAnimationUrl: mix.backgroundAnimationUrl,
          mixID: mix.id,
          count: 0,
          isAudioMixPlaylist: true,
        ),
      );
    }

    return playlists;
  }

  /// Парсит список из плейлистов, возвращая только список из рекомендуемых плейлистов ("Для вас" и подобные).
  List<ExtendedPlaylist> parseRecommendedPlaylists(
    APICatalogGetAudioResponse response,
  ) {
    final Section mainSection = response.response!.catalog.sections[0];

    // Ищем блок с рекомендуемыми плейлистами.
    SectionBlock recommendedPlaylistsBlock = mainSection.blocks!.firstWhere(
      (SectionBlock block) => block.dataType == "music_playlists",
      orElse: () => throw AssertionError(
        "Блок с рекомендуемыми плейлистами не был найден",
      ),
    );

    // Извлекаем список ID плейлистов из этого блока.
    final List<String> recommendedPlaylistIDs =
        recommendedPlaylistsBlock.playlistIDs!;

    // Достаём те плейлисты, которые рекомендуются нами ВКонтакте.
    // Превращаем объекты типа AudioPlaylist в ExtendedPlaylist.
    return response.response!.playlists
        .where(
          (Playlist playlist) =>
              recommendedPlaylistIDs.contains(playlist.mediaKey),
        )
        .map(
          (Playlist playlist) => ExtendedPlaylist.fromAudioPlaylist(playlist),
        )
        .toList();
  }

  /// Парсит список из плейлистов, возвращая только список из плейлистов раздела "Совпадения по вкусам".
  List<ExtendedPlaylist> parseSimillarPlaylists(
    APICatalogGetAudioResponse response,
  ) {
    final List<ExtendedPlaylist> playlists = [];

    // Проходимся по списку рекомендуемых плейлистов.
    for (SimillarPlaylist playlist in response.response!.recommendedPlaylists) {
      final fullPlaylist = response.response!.playlists.firstWhere(
        (Playlist fullPlaylist) {
          return fullPlaylist.mediaKey == playlist.mediaKey;
        },
      );

      playlists.add(
        ExtendedPlaylist.fromAudioPlaylist(
          fullPlaylist,
          simillarity: playlist.percentage,
          color: playlist.color,
          isLiveData: false,
          knownTracks: response.response!.audios
              .where(
                (Audio audio) => playlist.audios.contains(audio.mediaKey),
              )
              .map(
                (Audio audio) => ExtendedAudio.fromAPIAudio(audio),
              )
              .toList(),
        ),
      );
    }

    return playlists;
  }

  /// Парсит список из плейлистов, возвращая только список из плейлистов раздела "Собрано редакцией".
  List<ExtendedPlaylist> parseMadeByVKPlaylists(
    APICatalogGetAudioResponse response,
  ) {
    final Section mainSection = response.response!.catalog.sections[0];

    // Ищем блок с плейлистами "Собрано редакцией". Данный блок имеет [SectionBlock.dataType] == "music_playlists", но он расположен в конце.
    SectionBlock recommendedPlaylistsBlock = mainSection.blocks!.lastWhere(
      (SectionBlock block) => block.dataType == "music_playlists",
      orElse: () => throw AssertionError(
        "Блок с разделом 'собрано редакцией' не был найден",
      ),
    );

    // Извлекаем список ID плейлистов из этого блока.
    final List<String> recommendedPlaylistIDs =
        recommendedPlaylistsBlock.playlistIDs!;

    // Достаём те плейлисты, которые рекомендуются нами ВКонтакте.
    // Превращаем объекты типа AudioPlaylist в ExtendedPlaylist.
    return response.response!.playlists
        .where(
          (Playlist playlist) =>
              recommendedPlaylistIDs.contains(playlist.mediaKey),
        )
        .map(
          (Playlist playlist) => ExtendedPlaylist.fromAudioPlaylist(playlist),
        )
        .toList();
  }

  // Если информация уже загружена, то ничего не делаем.
  final ExtendedPlaylist? playlist = user.recommendationPlaylists.firstOrNull;
  if (!forceUpdate && playlist != null && playlist.isLiveData) {
    return;
  }

  // Если у пользователя нет второго токена, то ничего не делаем.
  if (user.recommendationsToken == null) return;

  logger.d("Loading music recommendations (force: $forceUpdate)");

  try {
    final APICatalogGetAudioResponse response = await user.catalogGetAudio();
    raiseOnAPIError(response);

    // Создаём список из всех рекомендуемых плейлистов, а так же добавляем их в память.
    user.updatePlaylists(
      [
        ...parseMoodPlaylists(response),
        ...parseAudioMixPlaylists(response),
        ...parseRecommendedPlaylists(response),
        ...parseSimillarPlaylists(response),
        ...parseMadeByVKPlaylists(response),
      ],
      saveToDB: saveToDB,
    );

    user.markUpdated(false);
  } catch (e, stackTrace) {
    logger.e(
      "Ошибка при загрузке рекомендованной музыки: ",
      error: e,
      stackTrace: stackTrace,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.music_recommendationsDataLoadError(
              e.toString(),
            ),
          ),
        ),
      );
    }
  }
}

/// Загружает полную информацию по всем плейлистам, у которых ранее было включено кэширование, загружая список их треков, и после чего запускает процесс кэширования.
Future<void> loadCachedTracksInformation(
  BuildContext context, {
  bool saveToDB = true,
  bool forceUpdate = false,
}) async {
  final UserProvider user = Provider.of<UserProvider>(context, listen: false);
  final AppLogger logger = getLogger("loadCachedTracksInformation");

  // Извлекаем список треков у тех плейлистов, у которых включено кэширование.
  for (ExtendedPlaylist playlist in user.allPlaylists.values) {
    // Плейлисты, у которых уже загружен список треков должны быть пропущены.
    if (playlist.areTracksLive) continue;

    // Плейлисты с отключенным кэшированием пропускаем.
    if (!(playlist.cacheTracks ?? false)) continue;

    logger.d("Found $playlist with enabled caching, downloading full data");

    // Загружаем информацию по данному плейлисту.
    final ExtendedPlaylist newPlaylist = await loadPlaylistData(
      playlist,
      user,
    );

    user.updatePlaylist(
      newPlaylist,
      saveToDB: saveToDB,
    );

    // Запускаем задачу по кэшированию этого плейлиста.
    downloadManager.cachePlaylist(user: user, newPlaylist);

    user.markUpdated(false);
  }
}

/// Виджет, олицетворяющий отдельный трек в списке треков.
class AudioTrackTile extends StatefulWidget {
  /// Объект типа [ExtendedAudio], олицетворяющий данный трек.
  final ExtendedAudio audio;

  /// Указывает, что этот трек сейчас выбран.
  ///
  /// Поле [currentlyPlaying] указывает, что плеер включён.
  final bool selected;

  /// Указывает, что плеер в данный момент включён.
  final bool currentlyPlaying;

  /// Указывает, что данный трек загружается перед тем, как начать его воспроизведение.
  final bool isLoading;

  /// Указывает, что в случае, если [selected] равен true, то у данного виджета будет эффект "свечения".
  final bool glowIfSelected;

  /// Указывает, что в случае, если трек кэширован ([ExtendedAudio.isCached]), то будет показана соответствующая иконка.
  final bool showCachedIcon;

  /// Если true, то данный виджет будет не будет иметь эффект прозрачности даже если [ExtendedAudio.canPlay] равен false.
  final bool forceAvailable;

  /// Действие, вызываемое при переключения паузы/возобновления при нажатии по иконке трека.
  ///
  /// В отличии от [onPlay], данный метод просто переключает то, находится трек на паузе или нет. Данный метод вызывается лишь в случае, если поле [selected] правдиво, в ином случае при нажатии на данный виджет будет вызываться событие [onPlay].
  final Function(bool)? onPlayToggle;

  /// Действие, вызываемое при "выборе" данного трека.
  ///
  /// В отличии от [onPlayToggle], данный метод должен "перезапустить" трек, если он в данный момент играет.
  final VoidCallback? onPlay;

  /// Действие, вызываемое при переключении состояния "лайка" данного трека.
  ///
  /// Если не указано, то кнопка лайка не будет показана.
  final Function(bool)? onLikeToggle;

  /// Действие, вызываемое при выборе ПКМ (или зажатии) по данном элементу.
  ///
  /// Чаще всего используется для открытия контекстного меню.
  final VoidCallback? onSecondaryAction;

  /// Действие, вызываемое при добавлении данного трека в очередь (свайп вправо).
  final VoidCallback? onAddToQueue;

  const AudioTrackTile({
    super.key,
    this.selected = false,
    this.isLoading = false,
    this.currentlyPlaying = false,
    this.glowIfSelected = false,
    this.showCachedIcon = true,
    this.forceAvailable = false,
    required this.audio,
    this.onPlay,
    this.onPlayToggle,
    this.onLikeToggle,
    this.onSecondaryAction,
    this.onAddToQueue,
  });

  @override
  State<AudioTrackTile> createState() => _AudioTrackTileState();
}

class _AudioTrackTileState extends State<AudioTrackTile> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool selectedAndPlaying = widget.selected && widget.currentlyPlaying;

    /// Url на изображение данного трека.
    final String? imageUrl = widget.audio.smallestThumbnail;

    return Dismissible(
      key: ValueKey(
        widget.audio.mediaKey,
      ),
      direction: (widget.onAddToQueue != null && isMobile)
          ? DismissDirection.startToEnd
          : DismissDirection.none,
      confirmDismiss: (_) async {
        widget.onAddToQueue?.call();

        return false;
      },
      background: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(
            globalBorderRadius,
          ),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Icon(
              Icons.queue_music,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPlay,
          onHover: widget.onPlay != null
              ? (bool value) => setState(() => isHovered = value)
              : null,
          borderRadius: BorderRadius.circular(
            globalBorderRadius,
          ),
          onLongPress: isMobile ? widget.onSecondaryAction : null,
          onSecondaryTap: widget.onSecondaryAction,
          child: AnimatedContainer(
            duration: const Duration(
              milliseconds: 500,
            ),
            curve: Curves.ease,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                globalBorderRadius,
              ),
              gradient: widget.selected && widget.glowIfSelected
                  ? LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(
                              0.075,
                            ),
                        Colors.transparent,
                      ],
                    )
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity:
                      widget.forceAvailable || widget.audio.canPlay ? 1.0 : 0.5,
                  child: InkWell(
                    onTap: widget.onPlayToggle != null || widget.onPlay != null
                        ? () {
                            // Если в данный момент играет именно этот трек, то вызываем onPlayToggle.
                            if (widget.selected) {
                              widget.onPlayToggle?.call(
                                !selectedAndPlaying,
                              );

                              return;
                            }

                            // В ином случае запускаем проигрывание этого трека.
                            widget.onPlay?.call();
                          }
                        : null,
                    borderRadius: BorderRadius.circular(
                      globalBorderRadius,
                    ),
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: Stack(
                        children: [
                          // Изображение трека.
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              globalBorderRadius,
                            ),
                            child: imageUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    cacheKey: "${widget.audio.mediaKey}small",
                                    width: 50,
                                    height: 50,
                                    placeholder:
                                        (BuildContext context, String url) =>
                                            const FallbackAudioAvatar(),
                                    cacheManager:
                                        CachedAlbumImagesManager.instance,
                                  )
                                : const FallbackAudioAvatar(),
                          ),
                          if (isHovered || widget.selected)
                            Center(
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .background
                                      .withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(
                                    globalBorderRadius,
                                  ),
                                ),
                                child: !isHovered && selectedAndPlaying
                                    ? Center(
                                        child: widget.isLoading
                                            ? const SizedBox(
                                                height: 25,
                                                width: 25,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                ),
                                              )
                                            : RepaintBoundary(
                                                child: Image.asset(
                                                  "assets/images/audioEqualizer.gif",
                                                  width: 18,
                                                  height: 18,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                ),
                                              ),
                                      )
                                    : Icon(
                                        selectedAndPlaying
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Название и исполнитель трека.
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 8,
                    ),
                    child: Opacity(
                      opacity: widget.forceAvailable || widget.audio.canPlay
                          ? 1.0
                          : 0.5,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Ряд с названием трека, плашки Explicit и иконки кэша, и subtitle, при наличии.
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Название трека.
                              Flexible(
                                child: Text(
                                  widget.audio.title,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: widget.selected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .onBackground,
                                  ),
                                ),
                              ),

                              // Плашка Explicit.
                              if (widget.audio.isExplicit)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 4,
                                  ),
                                  child: Icon(
                                    Icons.explicit,
                                    size: 16,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onBackground
                                        .withOpacity(0.5),
                                  ),
                                ),

                              // Иконка кэшированного трека.
                              if (widget.showCachedIcon &&
                                  (widget.audio.isCached ?? false))
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 4,
                                  ),
                                  child: Icon(
                                    Icons.arrow_downward,
                                    size: 16,
                                    color: widget.selected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .onBackground
                                            .withOpacity(0.5),
                                  ),
                                ),

                              // Прогресс загрузки трека.
                              if (widget.showCachedIcon &&
                                  !(widget.audio.isCached ?? false) &&
                                  widget.audio.downloadProgress.value > 0.0)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 4,
                                  ),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: ValueListenableBuilder(
                                      valueListenable:
                                          widget.audio.downloadProgress,
                                      builder: (
                                        BuildContext context,
                                        double value,
                                        Widget? child,
                                      ) {
                                        return CircularProgressIndicator(
                                          value: value,
                                          strokeWidth: 2,
                                          color: widget.selected
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onBackground
                                                  .withOpacity(0.5),
                                        );
                                      },
                                    ),
                                  ),
                                ),

                              // Подпись трека.
                              if (widget.audio.subtitle != null)
                                Flexible(
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      left: 6,
                                    ),
                                    child: Text(
                                      widget.audio.subtitle!,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onBackground
                                            .withOpacity(0.5),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          // Исполнитель.
                          Text(
                            widget.audio.artist,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: widget.selected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onBackground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Длительность трека.
                Padding(
                  padding: const EdgeInsets.only(
                    left: 8,
                  ),
                  child: Text(
                    widget.audio.durationString,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.75),
                    ),
                  ),
                ),

                // Кнопка для лайка, если её нужно показывать.
                if (widget.onLikeToggle != null)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 8,
                    ),
                    child: IconButton(
                      onPressed: () => widget.onLikeToggle!(
                        !widget.audio.isLiked,
                      ),
                      icon: Icon(
                        widget.audio.isLiked
                            ? Icons.favorite
                            : Icons.favorite_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Виджет, отображающий плейлист, как обычный так и рекомендательный.
class AudioPlaylistWidget extends StatefulWidget {
  /// URL на изображение заднего фона.
  final String? backgroundUrl;

  /// Поле, спользуемое как ключ для кэширования [backgroundUrl].
  final String? cacheKey;

  /// Название данного плейлиста.
  final String name;

  /// Указывает, что надписи данного плейлиста должны располагаться поверх изображения плейлиста.
  ///
  /// Используется у плейлистов по типу "Плейлист дня 1".
  final bool useTextOnImageLayout;

  /// Описание плейлиста.
  final String? description;

  /// Указывает, что музыка играет из этого плейлиста.
  final bool selected;

  /// Указывает, что плеер сейчас воспроизводит музыку.
  final bool currentlyPlaying;

  /// Вызывается при открытии плейлиста во весь экран.
  ///
  /// Вызывается при нажатии не по центру плейлиста. При нажатии по центру плейлиста запускается воспроизведение музыки, либо же она ставится на паузу, если музыка играет из этого плейлиста.
  final VoidCallback? onOpen;

  /// Действие, вызываемое при переключения паузы/возобновления при нажатии по центру плейлиста.
  ///
  /// Если не указывать, то возможность нажать на центр плейлиста будет выключена.
  final Function(bool)? onPlayToggle;

  const AudioPlaylistWidget({
    super.key,
    this.backgroundUrl,
    this.cacheKey,
    required this.name,
    this.useTextOnImageLayout = false,
    this.description,
    this.selected = false,
    this.currentlyPlaying = false,
    this.onOpen,
    this.onPlayToggle,
  });

  @override
  State<AudioPlaylistWidget> createState() => _AudioPlaylistWidgetState();
}

class _AudioPlaylistWidgetState extends State<AudioPlaylistWidget> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool selectedAndPlaying = widget.selected && widget.currentlyPlaying;

    return Tooltip(
      message: widget.description ?? "",
      waitDuration: const Duration(
        seconds: 1,
      ),
      child: InkWell(
        onTap: widget.onOpen,
        onSecondaryTap: widget.onOpen,
        onHover: (bool value) => setState(
          () => isHovered = value,
        ),
        borderRadius: BorderRadius.circular(
          globalBorderRadius,
        ),
        child: SizedBox(
          width: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(
                  milliseconds: 500,
                ),
                curve: Curves.ease,
                height: 200,
                decoration: BoxDecoration(
                  boxShadow: [
                    if (widget.selected)
                      BoxShadow(
                        blurRadius: 15,
                        spreadRadius: -3,
                        color: Theme.of(context).colorScheme.tertiary,
                        blurStyle: BlurStyle.outer,
                      ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Изображение плейлиста.
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        globalBorderRadius,
                      ),
                      child: widget.backgroundUrl != null
                          ? CachedNetworkImage(
                              imageUrl: widget.backgroundUrl!,
                              cacheKey: widget.cacheKey,
                              memCacheHeight: 200,
                              memCacheWidth: 200,
                              placeholder: (BuildContext context, String url) =>
                                  const FallbackAudioPlaylistAvatar(),
                              cacheManager: CachedNetworkImagesManager.instance,
                            )
                          : const FallbackAudioPlaylistAvatar(),
                    ),

                    // Затемнение у тех плейлистов, текст которых расположен поверх плейлистов.
                    if (widget.useTextOnImageLayout)
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Colors.black38,
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          borderRadius: BorderRadius.circular(
                            globalBorderRadius,
                          ),
                        ),
                      ),

                    // Если это у нас рекомендательный плейлист, то текст должен находиться внутри изображения плейлиста.
                    if (widget.useTextOnImageLayout)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Название плейлиста.
                            Text(
                              widget.name,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge!
                                  .copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                            ),

                            // Описание плейлиста.
                            if (widget.description != null)
                              Text(
                                widget.description!,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 3,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge!
                                    .copyWith(
                                      color: Colors.white,
                                    ),
                              ),
                          ],
                        ),
                      ),

                    // Затемнение, а так же иконка поверх плейлиста.
                    if (isHovered || widget.selected)
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .background
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(
                            globalBorderRadius,
                          ),
                        ),
                        child: !isHovered && selectedAndPlaying
                            ? Center(
                                child: RepaintBoundary(
                                  child: Image.asset(
                                    "assets/images/audioEqualizer.gif",
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    width: 32,
                                    height: 32,
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              )
                            : SizedBox(
                                width: 50,
                                height: 50,
                                child: Center(
                                  child: InkWell(
                                    onTap:
                                        isDesktop && widget.onPlayToggle != null
                                            ? () => widget.onPlayToggle?.call(
                                                  !selectedAndPlaying,
                                                )
                                            : null,
                                    child: Icon(
                                      selectedAndPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      size: 56,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                  ],
                ),
              ),

              // Если это обычный плейлист, то нам нужно показать его содержимое под изображением.
              if (!widget.useTextOnImageLayout)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Название плейлиста.
                        Text(
                          widget.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall!
                              .copyWith(
                                fontWeight: FontWeight.w500,
                                color: widget.selected
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                        ),

                        // Описание плейлиста, при наличии.
                        if (widget.description != null)
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: 2,
                              ),
                              child: Text(
                                widget.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                      color: widget.selected
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : null,
                                    ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Виджет, показывающий кучку переключателей-фильтров класса [FilterChip] для включения различных разделов "музыки".
class ChipFilters extends StatelessWidget {
  /// Указывает, что над этим блоком будет надпись "Активные разделы".
  final bool showLabel;

  const ChipFilters({
    super.key,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final UserProvider user = Provider.of<UserProvider>(context);

    /// Указывают, включены ли рекомендации.
    final bool hasRecommendations = user.recommendationsToken != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "Активные разделы".
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(
              bottom: 14,
            ),
            child: Text(
              AppLocalizations.of(context)!.music_filterChipsLabel,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Подключение рекомендаций.
            if (!hasRecommendations)
              ActionChip(
                avatar: const Icon(
                  Icons.auto_fix_high,
                ),
                label: Text(
                  AppLocalizations.of(context)!
                      .music_connectRecommendationsChipTitle,
                ),
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => const ConnectRecommendationsDialog(),
                ),
              ),

            // "Моя музыка".
            FilterChip(
              onSelected: (bool value) {
                user.settings.myMusicChipEnabled = value;

                user.markUpdated();
              },
              selected: user.settings.myMusicChipEnabled,
              label: Text(
                AppLocalizations.of(context)!.music_myMusicChip,
              ),
            ),

            // "Ваши плейлисты".
            FilterChip(
              onSelected: (bool value) {
                user.settings.playlistsChipEnabled = value;

                user.markUpdated();
              },
              selected: user.settings.playlistsChipEnabled,
              label: Text(
                AppLocalizations.of(context)!.music_myPlaylistsChip,
              ),
            ),

            // "В реальном времени".
            FilterChip(
              onSelected: (bool value) {
                user.settings.realtimePlaylistsChipEnabled = value;

                user.markUpdated();
              },
              selected: user.settings.realtimePlaylistsChipEnabled,
              label: Text(
                AppLocalizations.of(context)!.music_realtimePlaylistsChip,
              ),
            ),

            // "Плейлисты для Вас".
            if (hasRecommendations)
              FilterChip(
                onSelected: (bool value) {
                  user.settings.recommendedPlaylistsChipEnabled = value;

                  user.markUpdated();
                },
                selected: user.settings.recommendedPlaylistsChipEnabled,
                label: Text(
                  AppLocalizations.of(context)!.music_recommendedPlaylistsChip,
                ),
              ),

            // "Совпадения по вкусам".
            if (hasRecommendations)
              FilterChip(
                onSelected: (bool value) {
                  user.settings.similarMusicChipEnabled = value;

                  user.markUpdated();
                },
                selected: user.settings.similarMusicChipEnabled,
                label: Text(
                  AppLocalizations.of(context)!.music_similarMusicChip,
                ),
              ),

            // "Собрано редакцией".
            if (hasRecommendations)
              FilterChip(
                onSelected: (bool value) {
                  user.settings.byVKChipEnabled = value;

                  user.markUpdated();
                },
                selected: user.settings.byVKChipEnabled,
                label: Text(
                  AppLocalizations.of(context)!.music_byVKChip,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Виджет, показывающий надпись в случае, если пользователь отключил все разделы музыки.
class EverythingIsDisabledBlock extends StatelessWidget {
  const EverythingIsDisabledBlock({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // "Как пусто..."
        Padding(
          padding: const EdgeInsets.only(
            bottom: 4,
          ),
          child: Text(
            AppLocalizations.of(context)!.music_allBlocksDisabledTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        // "Соскучились по музыке? ..."
        Text(
          AppLocalizations.of(context)!.music_allBlocksDisabledDescription,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Страница для [HomeRoute] для управления музыкой.
class HomeMusicPage extends StatefulWidget {
  const HomeMusicPage({
    super.key,
  });

  @override
  State<HomeMusicPage> createState() => _HomeMusicPageState();
}

class _HomeMusicPageState extends State<HomeMusicPage> {
  /// Подписки на изменения состояния воспроизведения трека.
  late final List<StreamSubscription> subscriptions;

  /// Показывает [RefreshIndicator] во время загрузки данных с API ВКонтакте.
  void setLoading([bool value = true]) => setState(() => loadingData = value);

  /// Метод, который вызывается при нажатии на клавишу клавиатуры.
  void keyboardListener(
    RawKeyEvent key,
  ) async {
    if (!context.mounted) return;

    final UserProvider user = Provider.of<UserProvider>(context, listen: false);

    // Нажатие F5.
    if (user.favoritesPlaylist != null &&
        key.isKeyPressed(LogicalKeyboardKey.f5)) {
      setLoading();

      await ensureUserAudioAllInformation(
        context,
        forceUpdate: true,
      );
      setLoading(false);

      return;
    }

    // Нажатие комбинации CTRL+F.
    if (key.isControlPressed && key.isKeyPressed(LogicalKeyboardKey.keyF)) {
      Navigator.push(
        context,
        Material3PageRoute(
          builder: (context) => PlaylistInfoRoute(
            playlist: user.favoritesPlaylist!,
          ),
        ),
      );

      return;
    }
  }

  @override
  void initState() {
    super.initState();

    subscriptions = [
      // Изменения состояния воспроизведения.
      player.playingStream.listen(
        (bool playing) => setState(() {}),
      ),

      // Изменения плейлиста.
      player.sequenceStateStream.listen(
        (SequenceState? state) => setState(() {}),
      ),

      // Слушаем события подключения к интернету, что бы начать загрузку треков после появления интернета.
      connectivityManager.connectionChange.listen((bool isConnected) async {
        if (!isConnected) return;

        await ensureUserAudioAllInformation(
          context,
          forceUpdate: true,
        );
      }),
    ];

    // Загружаем информацию о плейлистах и треках.
    ensureUserAudioAllInformation(context);

    // Обработчик нажатия кнопок клавиатуры.
    RawKeyboard.instance.addListener(keyboardListener);
  }

  @override
  void dispose() {
    super.dispose();

    for (StreamSubscription subscription in subscriptions) {
      subscription.cancel();
    }

    RawKeyboard.instance.removeListener(keyboardListener);
  }

  /// Указывает, что в данный момент загружается информация.
  ///
  /// Данное поле равно `true` в первый момент захода на экран.
  bool loadingData = false;

  @override
  Widget build(BuildContext context) {
    final UserProvider user = Provider.of<UserProvider>(context);

    final bool isMobileLayout =
        getDeviceType(MediaQuery.of(context).size) == DeviceScreenType.mobile;

    /// Указывает, что у пользователя подключены рекомендации музыки от ВКонтакте.
    final bool hasRecommendations = user.recommendationsToken != null;

    final bool myMusic = user.settings.myMusicChipEnabled;
    final bool playlists = user.settings.playlistsChipEnabled;
    final bool realtimePlaylists =
        hasRecommendations && user.settings.realtimePlaylistsChipEnabled;
    final bool recommendedPlaylists =
        hasRecommendations && user.settings.recommendedPlaylistsChipEnabled;
    final bool similarMusic =
        hasRecommendations && user.settings.similarMusicChipEnabled;
    final bool byVK = hasRecommendations && user.settings.byVKChipEnabled;

    late bool everythingIsDisabled;

    // Если рекомендации включены, то мы должны учитывать и другие разделы.
    if (hasRecommendations) {
      everythingIsDisabled = (!(myMusic ||
          playlists ||
          realtimePlaylists ||
          recommendedPlaylists ||
          similarMusic ||
          byVK));
    } else {
      everythingIsDisabled = (!(myMusic || playlists));
    }

    /// [List], содержащий в себе список из виджетов/разделов на главном экране, которые доожны быть разделены [Divider]'ом.
    final List<Widget> activeBlocks = [
      // Раздел "Моя музыка".
      if (myMusic)
        MyMusicBlock(
          useTopButtons: isMobileLayout,
        ),

      // Раздел "Ваши плейлисты".
      if (playlists) const MyPlaylistsBlock(),

      // Раздел "В реальном времени".
      if (realtimePlaylists) const RealtimePlaylistsBlock(),

      // Раздел "Плейлисты для Вас".
      if (recommendedPlaylists) const RecommendedPlaylistsBlock(),

      // Раздел "Совпадения по вкусам".
      if (similarMusic) const SimillarMusicBlock(),

      // Раздел "Собрано редакцией".
      if (byVK) const ByVKPlaylistsBlock(),

      // Нижняя часть интерфейса с переключателями при Mobile Layout'е.
      if (isMobileLayout) const ChipFilters(),

      // Случай, если пользователь отключил все возможные разделы музыки.
      if (everythingIsDisabled) const EverythingIsDisabledBlock(),
    ];

    return Scaffold(
      appBar: isMobileLayout
          ? AppBar(
              title: StreamBuilder<bool>(
                stream: connectivityManager.connectionChange,
                builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                  final bool isConnected = connectivityManager.hasConnection;

                  return Text(
                    isConnected
                        ? AppLocalizations.of(context)!.music_label
                        : AppLocalizations.of(context)!.music_labelOffline,
                  );
                },
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  onPressed: () {
                    if (!networkRequiredDialog(context)) return;

                    showDialog(
                      context: context,
                      builder: (context) => const SearchDisplayDialog(),
                    );
                  },
                  icon: const Icon(
                    Icons.search,
                  ),
                ),
                const SizedBox(
                  width: 18,
                ),
              ],
            )
          : null,
      body: DeclarativeRefreshIndicator(
        onRefresh: () async {
          setLoading();

          if (networkRequiredDialog(context)) {
            await ensureUserAudioAllInformation(
              context,
              forceUpdate: true,
            );
          } else {
            await Future.delayed(Duration.zero);
          }
          setLoading(false);
        },
        refreshing: loadingData,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.only(
                  left: isMobileLayout ? 16 : 24,
                  right: isMobileLayout ? 16 : 24,
                  top: isMobileLayout ? 4 : 30,
                  bottom: isMobileLayout ? 20 : 30,
                ),
                children: [
                  // Часть интерфейса "Добро пожаловать", а так же кнопка поиска.
                  if (!isMobileLayout)
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: 36,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Текст "Добро пожаловать".
                          Flexible(
                            child: Text(
                              AppLocalizations.of(context)!.music_welcomeTitle(
                                user.firstName!,
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .displayMedium!
                                  .copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),

                          // Поиск.
                          IconButton.filledTonal(
                            onPressed: () {
                              if (!networkRequiredDialog(context)) return;

                              showDialog(
                                context: context,
                                builder: (context) =>
                                    const SearchDisplayDialog(),
                              );
                            },
                            icon: const Icon(
                              Icons.search,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Верхняя часть интерфейса с переключателями при Desktop Layout'е.
                  if (!isMobileLayout)
                    const ChipFilters(
                      showLabel: false,
                    ),
                  if (!isMobileLayout)
                    const Padding(
                      padding: EdgeInsets.only(
                        top: 8,
                        bottom: 2,
                      ),
                      child: Divider(),
                    ),

                  // Проходимся по всем активным разделам, создавая виджеты [Divider] и [SizedBox].
                  for (int i = 0; i < activeBlocks.length; i++) ...[
                    // Содержимое блока.
                    activeBlocks[i],

                    // Divider в случае, если это не последний элемент.
                    if (i < activeBlocks.length - 1)
                      const Padding(
                        padding: EdgeInsets.only(
                          top: 12,
                          bottom: 4,
                        ),
                        child: Divider(),
                      ),
                  ],

                  // Данный SizedBox нужен, что бы плеер снизу при Mobile Layout'е не закрывал ничего важного.
                  if (player.loaded && isMobileLayout)
                    const SizedBox(
                      height: 66,
                    ),
                ],
              ),
            ),

            // Данный SizedBox нужен, что бы плеер снизу при Desktop Layout'е не закрывал ничего важного.
            // Мы его располагаем после ListView, что бы ScrollBar не был закрыт плеером.
            if (player.loaded && !isMobileLayout)
              const SizedBox(
                height: 88,
              ),
          ],
        ),
      ),
    );
  }
}
