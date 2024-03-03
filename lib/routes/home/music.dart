import "dart:async";
import "dart:io";

import "package:cached_network_image/cached_network_image.dart";
import "package:collection/collection.dart";
import "package:debounce_throttle/debounce_throttle.dart";
import "package:declarative_refresh_indicator/declarative_refresh_indicator.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:just_audio/just_audio.dart";
import "package:provider/provider.dart";
import "package:responsive_builder/responsive_builder.dart";
import "package:skeletonizer/skeletonizer.dart";
import "package:styled_text/styled_text.dart";

import "../../api/vk/api.dart";
import "../../api/vk/audio/edit.dart";
import "../../api/vk/audio/search.dart";
import "../../api/vk/catalog/get_audio.dart";
import "../../api/vk/consts.dart";
import "../../api/vk/executeScripts/mass_audio_get.dart";
import "../../api/vk/shared.dart";
import "../../consts.dart";
import "../../db/schemas/playlists.dart";
import "../../extensions.dart";
import "../../main.dart";
import "../../provider/user.dart";
import "../../services/audio_player.dart";
import "../../services/cache_manager.dart";
import "../../services/logger.dart";
import "../../utils.dart";
import "../../widgets/adaptive_dialog.dart";
import "../../widgets/dialogs.dart";
import "../../widgets/fallback_audio_photo.dart";
import "../../widgets/loading_overlay.dart";
import "../../widgets/page_route_builders.dart";
import "../home.dart";
import "music/playlist.dart";
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

  // Делаем API-запросы, получаем список плейлистов из ВКонтакте.
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

  if (!context.mounted) return;

  // После полной загрузки, делаем загрузку остальных данных.
  await loadCachedTracksInformation(
    context,
    forceUpdate: forceUpdate,
  );

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
                (Audio audio) => ExtendedAudio.fromAudio(
                  audio,
                  isLiked: true,
                ),
              )
              .toSet(),
          isLiveData: true,
          areTracksLive: true,
        ),

        // Все остальные плейлисты пользователя.
        // Мы помечаем что плейлисты являются кэшированными.
        ...response.response!.playlists
            .map(
              (playlist) => ExtendedPlaylist.fromAudioPlaylist(
                playlist,
              ),
            )
            .toSet(),
      ],
      saveToDB: saveToDB,
    );

    // Запускаем задачу по кэшированию плейлиста с фаворитными треками.
    //
    // Запуск кэширования у других плейлистов происходит в ином месте:
    // Данный метод НЕ загружает содержимое у других плейлистов.
    if (user.favoritesPlaylist!.cacheTracks ?? false) {
      downloadManager.cachePlaylist(user.favoritesPlaylist!);
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
                (Audio audio) => ExtendedAudio.fromAudio(audio),
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

  final UserProvider user = Provider.of<UserProvider>(context, listen: false);
  final AppLogger logger = getLogger("ensureUserAudioRecommendations");

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
        ...parseRecommendedPlaylists(response),
        ...parseSimillarPlaylists(response),
        ...parseMadeByVKPlaylists(response),
      ],
      saveToDB: saveToDB,
    );

    user.markUpdated(false);
  } catch (e, stackTrace) {
    logger.e(
      "Ошибка при загрузке информации для раздела музыки: ",
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
    // Уже загруженные плейлисты должны быть пропущены.
    if (playlist.isLiveData) continue;

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
    downloadManager.cachePlaylist(newPlaylist);

    user.markUpdated(false);
  }
}

/// Диалог, показывающий поле для глобального поиска через API ВКонтакте, а так же сами результаты поиска.
class SearchDisplayDialog extends StatefulWidget {
  /// Если true, то сразу после открытия данного диалога фокус будет на [SearchBar].
  final bool focusSearchBarOnOpen;

  const SearchDisplayDialog({
    super.key,
    this.focusSearchBarOnOpen = true,
  });

  @override
  State<SearchDisplayDialog> createState() => _SearchDisplayDialogState();
}

class _SearchDisplayDialogState extends State<SearchDisplayDialog> {
  /// Контроллер, используемый для управления введённым в поле поиска текстом.
  final TextEditingController controller = TextEditingController();

  /// FocusNode для фокуса поля поиска сразу после открытия данного диалога.
  final FocusNode focusNode = FocusNode();

  /// Подписки на изменения состояния воспроизведения трека.
  late final List<StreamSubscription> subscriptions;

  /// Debouncer для поиска.
  final debouncer = Debouncer<String>(
    const Duration(
      seconds: 1,
    ),
    initialValue: "",
  );

  /// Текущий Future по поиску через API ВКонтакте. Может отсутствовать, если ничего не было введено в поиск.
  Future<APIAudioSearchResponse>? searchFuture;

  /// Метод, который вызывается при печати в поле поиска.
  ///
  /// Данный метод вызывается с учётом debouncing'а.
  void onDebounce(String query) {
    // Если мы вышли из текущего Route, то ничего не делаем.
    if (!mounted) return;

    final UserProvider user = Provider.of<UserProvider>(context, listen: false);

    // Если ничего не введено, то делаем пустой Future.
    if (query.isEmpty) {
      if (searchFuture != null) {
        setState(
          () => searchFuture = null,
        );
      }

      return;
    }

    searchFuture = user.audioSearchWithAlbums(query);
    setState(() {});
  }

  /// Метод, который вызывается при нажатии на клавишу клавиатуры.
  void keyboardListener(
    RawKeyEvent key,
  ) {
    // Нажатие кнопки ESC.
    if (key.isKeyPressed(LogicalKeyboardKey.escape)) {
      // Если в поле поиска есть текст, и это поле находится в фокусе, то ничего не делаем.
      // "Стирание" текста находится в TextField'е.
      if (controller.text.isNotEmpty && focusNode.hasFocus || !mounted) return;

      Navigator.of(context).pop();

      return;
    }

    // Нажатие комбинации CTRL+F.
    if (key.isControlPressed && key.isKeyPressed(LogicalKeyboardKey.keyF)) {
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: controller.text.length,
      );
      focusNode.requestFocus();

      return;
    }
  }

  @override
  void initState() {
    super.initState();

    subscriptions = [
      // Изменения состояния воспроизведения.
      player.playerStateStream.listen(
        (PlayerState state) => setState(() {}),
      ),

      // Изменения плейлиста.
      player.sequenceStateStream.listen(
        (SequenceState? state) => setState(() {}),
      ),
    ];

    // Обработчик печати.
    controller.addListener(
      () => debouncer.value = controller.text,
    );

    // Обработчик событий поиска, испускаемых Debouncer'ом, если пользователь остановил печать.
    debouncer.values.listen(onDebounce);

    // Если у пользователя ПК, то тогда устанавливаем фокус на поле поиска.
    if (isDesktop && widget.focusSearchBarOnOpen) focusNode.requestFocus();

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

  @override
  Widget build(BuildContext context) {
    final UserProvider user = Provider.of<UserProvider>(context);

    final bool isMobileLayout =
        getDeviceType(MediaQuery.of(context).size) == DeviceScreenType.mobile;

    return AdaptiveDialog(
      child: Container(
        padding: isMobileLayout
            ? const EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
              )
            : const EdgeInsets.all(
                24,
              ),
        width: 650,
        child: Column(
          children: [
            Padding(
              padding: isMobileLayout
                  ? EdgeInsets.zero
                  : const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Кнопка "Назад".
                  if (isMobileLayout)
                    IconButton(
                      icon: Icon(
                        Icons.adaptive.arrow_back,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  if (isMobileLayout)
                    const SizedBox(
                      width: 12,
                    ),

                  // Поиск.
                  Expanded(
                    child: CallbackShortcuts(
                      bindings: {
                        const SingleActivator(
                          LogicalKeyboardKey.escape,
                        ): () => controller.clear(),
                      },
                      child: TextField(
                        focusNode: focusNode,
                        controller: controller,
                        onChanged: (String query) => setState(() {}),
                        decoration: InputDecoration(
                          hintText:
                              AppLocalizations.of(context)!.music_searchText,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              globalBorderRadius,
                            ),
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                          ),
                          suffixIcon: controller.text.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                    end: 12,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                    ),
                                    onPressed: () => setState(
                                      () => controller.clear(),
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            Expanded(
              child: FutureBuilder(
                future: searchFuture,
                builder: (
                  BuildContext context,
                  AsyncSnapshot<APIAudioSearchResponse> snapshot,
                ) {
                  final Set<ExtendedAudio>? audios =
                      snapshot.data?.response?.items
                          .map(
                            (audio) => ExtendedAudio.fromAudio(audio),
                          )
                          .toSet();

                  // Пользователь ещё ничего не ввёл.
                  if (snapshot.connectionState == ConnectionState.none) {
                    return Text(
                      AppLocalizations.of(context)!.music_typeToSearchText,
                    );
                  }

                  // Информация по данному плейлисту ещё не была загружена.
                  if (snapshot.connectionState == ConnectionState.waiting ||
                      snapshot.hasError ||
                      !(snapshot.hasData && snapshot.data!.error == null)) {
                    return ListView.builder(
                      itemCount: 50,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (BuildContext context, int index) {
                        return Skeletonizer(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              bottom: 8,
                            ),
                            child: AudioTrackTile(
                              audio: ExtendedAudio(
                                id: -1,
                                ownerID: -1,
                                title: fakeTrackNames[
                                    index % fakeTrackNames.length],
                                artist: fakeTrackNames[
                                    (index + 1) % fakeTrackNames.length],
                                duration: 60 * 3,
                                accessKey: "",
                                url: "",
                                date: 0,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }

                  // Ничего не найдено.
                  if (snapshot.hasData &&
                      snapshot.data!.response!.items.isEmpty) {
                    return StyledText(
                      text:
                          AppLocalizations.of(context)!.music_zeroSearchResults,
                      tags: {
                        "click": StyledTextActionTag(
                          (String? text, Map<String?, String?> attrs) =>
                              setState(
                            () => controller.clear(),
                          ),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      },
                    );
                  }

                  // Отображаем данные.
                  return ListView.builder(
                    itemCount: audios!.length,
                    itemBuilder: (BuildContext context, int index) {
                      return buildListTrackWidget(
                        context,
                        audios.elementAt(index),
                        ExtendedPlaylist(
                          id: -1,
                          ownerID: user.id!,
                          audios: audios,
                          count: audios.length,
                          title: AppLocalizations.of(context)!
                              .music_searchPlaylistTitle,
                          isLiveData: true,
                          areTracksLive: true,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Диалог, который позволяет пользователю отредактировать данные о треке.
///
/// Пример использования:
/// ```dart
/// openDialog(
///   context: context,
///   builder: (BuildContext context) => const TrackInfoEditDialog(...),
/// ),
/// ```
class TrackInfoEditDialog extends StatefulWidget {
  /// Трек, данные которого будут изменяться.
  final ExtendedAudio audio;

  const TrackInfoEditDialog({
    super.key,
    required this.audio,
  });

  @override
  State<TrackInfoEditDialog> createState() => _TrackInfoEditDialogState();
}

class _TrackInfoEditDialogState extends State<TrackInfoEditDialog> {
  static AppLogger logger = getLogger("TrackInfoEditDialog");

  /// [TextEditingController] для поля ввода названия трека.
  final TextEditingController titleController = TextEditingController();

  /// [TextEditingController] для поля ввода артиста трека.
  final TextEditingController artistController = TextEditingController();

  /// Выбранный жанр у трека.
  late int trackGenre;

  @override
  void initState() {
    super.initState();

    titleController.text = widget.audio.title;
    artistController.text = widget.audio.artist;
    trackGenre = widget.audio.genreID ?? 18; // Жанр "Other".
  }

  @override
  Widget build(BuildContext context) {
    final UserProvider user = Provider.of<UserProvider>(context);

    // Создаём копию трека, засовывая в неё новые значения с новым именем трека и прочим.
    final ExtendedAudio audio = ExtendedAudio(
      title: titleController.text,
      artist: artistController.text,
      id: widget.audio.id,
      ownerID: widget.audio.ownerID,
      duration: widget.audio.duration,
      accessKey: widget.audio.accessKey,
      url: widget.audio.url,
      date: widget.audio.date,
      album: widget.audio.album,
      isLiked: widget.audio.isLiked,
    );

    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Открытый трек.
            AudioTrackTile(
              audio: audio,
              selected: audio == player.currentAudio,
              currentlyPlaying: player.loaded && player.playing,
            ),
            const SizedBox(height: 8),
            const Divider(),

            // Текстовое поле для изменения названия.
            TextField(
              controller: titleController,
              onChanged: (String _) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Padding(
                  padding: EdgeInsetsDirectional.only(
                    end: 12,
                  ),
                  child: Icon(
                    Icons.music_note,
                  ),
                ),
                label: Text(
                  AppLocalizations.of(context)!.music_trackTitle,
                ),
              ),
            ),

            // Текстовое поле для изменения исполнителя.
            TextField(
              controller: artistController,
              onChanged: (String _) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Padding(
                  padding: EdgeInsetsDirectional.only(
                    end: 12,
                  ),
                  child: Icon(
                    Icons.album,
                  ),
                ),
                label: Text(
                  AppLocalizations.of(context)!.music_trackArtist,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Выпадающее меню с жанром.
            DropdownMenu(
              label: Text(
                AppLocalizations.of(context)!.music_trackGenre,
              ),
              onSelected: (int? genreID) {
                if (genreID == null) return;

                setState(() => trackGenre = genreID);
              },
              initialSelection: widget.audio.genreID ?? 18, // Жанр "Other".
              dropdownMenuEntries: [
                for (MapEntry<int, String> genre in musicGenres.entries)
                  DropdownMenuEntry(
                    value: genre.key,
                    label: genre.value,
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Кнопка для сохранения.
            Align(
              alignment: Alignment.bottomRight,
              child: FilledButton.icon(
                onPressed: () async {
                  final LoadingOverlay overlay = LoadingOverlay.of(context);

                  Navigator.of(context).pop();
                  overlay.show();

                  try {
                    final APIAudioEditResponse response = await user.audioEdit(
                      widget.audio.ownerID,
                      widget.audio.id,
                      titleController.text,
                      artistController.text,
                      trackGenre,
                    );
                    raiseOnAPIError(response);

                    // Обновляем данные о треке у пользователя.
                    widget.audio.title = titleController.text;
                    widget.audio.artist = artistController.text;
                    widget.audio.genreID = trackGenre;

                    user.markUpdated(false);
                  } catch (e, stackTrace) {
                    logger.e(
                      "Ошибка при редактировании данных трека: ",
                      error: e,
                      stackTrace: stackTrace,
                    );

                    if (mounted) {
                      showErrorDialog(
                        context,
                        description: e.toString(),
                      );
                    }
                  } finally {
                    overlay.hide();
                  }
                },
                icon: const Icon(Icons.edit),
                label: Text(
                  AppLocalizations.of(context)!.general_save,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Диалог, появляющийся снизу экрана, дающий пользователю действия над выбранным треком.
///
/// Пример использования:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   builder: (BuildContext context) => const BottomAudioOptionsDialog(...),
/// ),
/// ```
class BottomAudioOptionsDialog extends StatefulWidget {
  /// Трек типа [ExtendedAudio], над которым производится манипуляция.
  final ExtendedAudio audio;

  const BottomAudioOptionsDialog({
    super.key,
    required this.audio,
  });

  @override
  State<BottomAudioOptionsDialog> createState() =>
      _BottomAudioOptionsDialogState();
}

class _BottomAudioOptionsDialogState extends State<BottomAudioOptionsDialog> {
  /// Подписки на изменения состояния воспроизведения трека.
  late final List<StreamSubscription> subscriptions;

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
    ];
  }

  @override
  void dispose() {
    super.dispose();

    for (StreamSubscription subscription in subscriptions) {
      subscription.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final UserProvider user = Provider.of<UserProvider>(context);

    return DraggableScrollableSheet(
      expand: false,
      builder: (BuildContext context, ScrollController controller) {
        return Container(
          width: 500,
          height: 300,
          padding: const EdgeInsets.all(24),
          child: SizedBox.expand(
            child: ListView(
              controller: controller,
              children: [
                AudioTrackTile(
                  audio: widget.audio,
                  selected: widget.audio == player.currentAudio,
                  currentlyPlaying: player.loaded && player.playing,
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),

                // Редактировать данные трека.
                ListTile(
                  enabled: widget.audio.album == null &&
                      widget.audio.ownerID == user.id!,
                  onTap: () {
                    Navigator.of(context).pop();

                    showDialog(
                      context: context,
                      builder: (BuildContext context) => TrackInfoEditDialog(
                        audio: widget.audio,
                      ),
                    );
                  },
                  leading: const Icon(
                    Icons.edit,
                  ),
                  title: Text(
                    AppLocalizations.of(context)!.music_detailsEditTitle,
                  ),
                ),

                // Удалить из текущего плейлиста.
                ListTile(
                  onTap: () => showWipDialog(context),
                  leading: const Icon(
                    Icons.playlist_remove,
                  ),
                  title: Text(
                    AppLocalizations.of(context)!.music_detailsDeleteTrackTitle,
                  ),
                ),

                // Добавить в другой плейлист.
                ListTile(
                  onTap: () => showWipDialog(context),
                  leading: const Icon(
                    Icons.playlist_add,
                  ),
                  title: Text(
                    AppLocalizations.of(context)!
                        .music_detailsAddToOtherPlaylistTitle,
                  ),
                ),

                // Добавить в очередь.
                ListTile(
                  onTap: () async {
                    await player.addNextToQueue(
                      widget.audio,
                    );

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.general_addedToQueue,
                        ),
                        duration: const Duration(
                          seconds: 3,
                        ),
                      ),
                    );

                    Navigator.of(context).pop();
                  },
                  enabled: !widget.audio.isRestricted,
                  leading: const Icon(
                    Icons.queue_music,
                  ),
                  title: Text(
                    AppLocalizations.of(context)!.music_detailsPlayNextTitle,
                  ),
                ),

                // Установить обложку.
                ListTile(
                  onTap: () => showWipDialog(context),
                  leading: const Icon(
                    Icons.photo_library,
                  ),
                  title: Text(
                    AppLocalizations.of(context)!
                        .music_detailsSetThumbnailTitle,
                  ),
                  subtitle: Text(
                    AppLocalizations.of(context)!
                        .music_detailsSetThumbnailDescription,
                  ),
                ),

                // Перезалить с Youtube.
                ListTile(
                  onTap: () => showWipDialog(context),
                  leading: const Icon(
                    Icons.rotate_left,
                  ),
                  title: Text(
                    AppLocalizations.of(context)!
                        .music_detailsReuploadFromYoutubeTitle,
                  ),
                  subtitle: Text(
                    AppLocalizations.of(context)!
                        .music_detailsReuploadFromYoutubeDescription,
                  ),
                ),

                // Debug-опции.
                if (kDebugMode) ...[
                  ListTile(
                    onTap: () {
                      Clipboard.setData(
                        ClipboardData(
                          text: widget.audio.mediaKey,
                        ),
                      );

                      Navigator.of(context).pop();
                    },
                    leading: const Icon(
                      Icons.link,
                    ),
                    title: const Text(
                      "Скопировать ID трека",
                    ),
                    subtitle: const Text(
                      "Debug-режим",
                    ),
                  ),
                  if (Platform.isWindows)
                    ListTile(
                      onTap: () async {
                        Navigator.of(context).pop();

                        final File path =
                            await CachedStreamedAudio.getCachedAudioByKey(
                          widget.audio.mediaKey,
                        );
                        await Process.run(
                          "explorer.exe",
                          ["/select,", path.path],
                        );
                      },
                      enabled: widget.audio.isCached ?? false,
                      leading: const Icon(
                        Icons.folder_open,
                      ),
                      title: const Text(
                        "Открыть папку с треком",
                      ),
                      subtitle: const Text(
                        "Debug-режим",
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
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
    final String? imageUrl = widget.audio.album?.thumbnails?.photo68;

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
                  opacity: widget.audio.isRestricted ? 0.5 : 1.0,
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
                                    cacheKey: "${widget.audio.album!.id}68",
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
                      opacity: widget.audio.isRestricted ? 0.5 : 1,
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

  /// [ExtendedPlaylist.mediaKey], используемый как ключ для кэширования, а так же для [Hero]-анимации..
  final String? mediaKey;

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
    this.mediaKey,
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
                              cacheKey: widget.mediaKey,
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

/// Виджет, отображающий несколько треков из плейлиста раздела "Совпадения по вкусам".
class SimillarMusicPlaylistWidget extends StatefulWidget {
  /// Название плейлиста.
  final String name;

  /// Число от `0.0` до `1.0`, показывающий процент того, насколько плейлист схож с музыкальным вкусом текущего пользователя.
  final double simillarity;

  /// Список со строго первыми тремя треками из этого плейлиста, которые будут отображены.
  final List<ExtendedAudio> tracks;

  /// Цвет данного блока.
  ///
  /// Если не указан, то будет использоваться значение [ColorScheme.primaryContainer].
  final Color? color;

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

  const SimillarMusicPlaylistWidget({
    super.key,
    required this.name,
    required this.simillarity,
    required this.tracks,
    this.color,
    this.selected = false,
    this.currentlyPlaying = false,
    this.onOpen,
    this.onPlayToggle,
  });

  @override
  State<SimillarMusicPlaylistWidget> createState() =>
      _SimillarMusicPlaylistWidgetState();
}

class _SimillarMusicPlaylistWidgetState
    extends State<SimillarMusicPlaylistWidget> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    assert(
      widget.tracks.length == 3,
      "Expected tracks amount to be 3, but got ${widget.tracks.length} instead",
    );

    final Color topColor =
        widget.color ?? Theme.of(context).colorScheme.primaryContainer;
    final bool selectedAndPlaying = widget.selected && widget.currentlyPlaying;

    return Container(
      width: 250,
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(
          globalBorderRadius * 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Верхняя часть такового плейлиста, в которой отображается название плейлиста, а так же его "схожесть".
          Tooltip(
            message: widget.name,
            waitDuration: const Duration(
              seconds: 1,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(
                globalBorderRadius * 2,
              ),
              onTap: widget.onOpen,
              onSecondaryTap: widget.onOpen,
              onHover: (bool value) => setState(
                () => isHovered = value,
              ),
              child: Stack(
                children: [
                  // Название и прочая информация.
                  Container(
                    height: 90,
                    padding: const EdgeInsets.all(
                      10,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          topColor,
                          topColor.withOpacity(0.8),
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      borderRadius: BorderRadius.circular(
                        globalBorderRadius * 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // "80% совпадения".
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Процент.
                            Text(
                              "${(widget.simillarity * 100).truncate()}%",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(
                              width: 4,
                            ),

                            // "совпадения".
                            Text(
                              AppLocalizations.of(context)!
                                  .music_simillarityPercentTitle,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),

                        // Название плейлиста.
                        Flexible(
                          child: Text(
                            widget.name,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.fade,
                            maxLines: 2,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Кнопки для совершения действий над этим плейлистом при наведении.
                  AnimatedOpacity(
                    opacity: isHovered ? 1.0 : 0.0,
                    duration: const Duration(
                      milliseconds: 300,
                    ),
                    curve: Curves.ease,
                    child: Container(
                      height: 90,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(
                          globalBorderRadius * 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Запуск воспроизведения.
                          IconButton(
                            icon: Icon(
                              selectedAndPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              size: 32,
                              color: Colors.white,
                            ),
                            onPressed: isHovered
                                ? () => widget.onPlayToggle?.call(
                                      !selectedAndPlaying,
                                    )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 12,
          ),

          // Отображение треков в этом плейлисте.
          for (ExtendedAudio audio in widget.tracks)
            Padding(
              padding: const EdgeInsets.only(
                left: 12,
                right: 12,
                bottom: 8,
              ),
              child: AudioTrackTile(
                audio: audio,
                selected: audio == player.currentAudio,
                currentlyPlaying: player.loaded && player.playing,
                isLoading: player.buffering,
                glowIfSelected: true,
              ),
            ),
          const SizedBox(
            height: 4,
          ),
        ],
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
          Text(
            AppLocalizations.of(context)!.music_filterChipsLabel,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        if (showLabel)
          const SizedBox(
            height: 14,
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

/// Виджет с разделом "Моя музыка"
class MyMusicBlock extends StatefulWidget {
  /// Указывает, что ряд из кнопок по типу "Перемешать", "Все треки" будет располагаться сверху.
  final bool useTopButtons;

  const MyMusicBlock({
    super.key,
    this.useTopButtons = false,
  });

  @override
  State<MyMusicBlock> createState() => _MyMusicBlockState();
}

class _MyMusicBlockState extends State<MyMusicBlock> {
  /// Подписки на изменения состояния воспроизведения трека.
  late final List<StreamSubscription> subscriptions;

  @override
  void initState() {
    super.initState();

    subscriptions = [
      // Изменения состояния воспроизведения.
      player.playerStateStream.listen(
        (PlayerState state) => setState(() {}),
      ),

      // Изменения состояния остановки/запуска плеера.
      player.loadedStateStream.listen(
        (bool loaded) => setState(() {}),
      ),

      // Изменения плейлиста.
      player.sequenceStateStream.listen(
        (SequenceState? state) => setState(() {}),
      ),
    ];
  }

  @override
  void dispose() {
    super.dispose();

    for (StreamSubscription subscription in subscriptions) {
      subscription.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final UserProvider user = Provider.of<UserProvider>(context);

    final bool selected = player.currentPlaylist == user.favoritesPlaylist;
    final bool selectedAndPlaying = selected && player.playing;
    final int musicCount = user.favoritesPlaylist?.count ?? 0;
    final int clampedMusicCount = clampInt(
      musicCount,
      0,
      10,
    );
    final Widget controlButtonsRow = Wrap(
      spacing: 8,
      children: [
        // "Перемешать".
        FilledButton.icon(
          onPressed: user.favoritesPlaylist?.audios != null
              ? () async {
                  // Если данный плейлист уже играет, то просто ставим на паузу/воспроизведение.
                  if (player.currentPlaylist == user.favoritesPlaylist) {
                    await player.togglePlay();

                    return;
                  }

                  await player.setShuffle(true);

                  await player.setPlaylist(
                    user.favoritesPlaylist!,
                    audio: user.favoritesPlaylist!.audios!.randomItem(),
                  );
                }
              : null,
          icon: Icon(
            selectedAndPlaying ? Icons.pause : Icons.play_arrow,
          ),
          label: Text(
            selected
                ? player.playing
                    ? AppLocalizations.of(context)!.music_shuffleAndPlayPause
                    : AppLocalizations.of(context)!.music_shuffleAndPlayResume
                : AppLocalizations.of(context)!.music_shuffleAndPlay,
          ),
        ),

        // "Все треки".
        FilledButton.tonalIcon(
          onPressed: user.favoritesPlaylist?.audios != null
              ? () => Navigator.push(
                    context,
                    Material3PageRoute(
                      builder: (context) => PlaylistInfoRoute(
                        playlist: user.favoritesPlaylist!,
                      ),
                    ),
                  )
              : null,
          icon: const Icon(
            Icons.queue_music,
          ),
          label: Text(
            AppLocalizations.of(context)!.music_showAllFavoriteTracks,
          ),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: [
            Text(
              AppLocalizations.of(context)!.music_myMusicChip,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (musicCount > 0)
              Text(
                musicCount.toString(),
                style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.secondary.withOpacity(0.75),
                ),
              ),
          ],
        ),
        SizedBox(
          height: widget.useTopButtons ? 10 : 14,
        ),

        // Кнопки для управления (сверху, если useTopButtons = true).
        if (widget.useTopButtons) controlButtonsRow,
        if (widget.useTopButtons)
          const SizedBox(
            height: 10,
          ),

        // Настоящие данные.
        if (user.favoritesPlaylist?.audios != null)
          for (int index = 0; index < clampedMusicCount; index++)
            buildListTrackWidget(
              context,
              user.favoritesPlaylist!.audios!.elementAt(index),
              user.favoritesPlaylist!,
              addBottomPadding: index < clampedMusicCount - 1,
            ),

        // Skeleton loader.
        if (user.favoritesPlaylist?.audios == null)
          for (int index = 0; index < 10; index++)
            Skeletonizer(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: index + 1 != 10 ? 8 : 0,
                ),
                child: AudioTrackTile(
                  audio: ExtendedAudio(
                    id: -1,
                    ownerID: -1,
                    title: fakeTrackNames[index % fakeTrackNames.length],
                    artist: fakeTrackNames[(index + 1) % fakeTrackNames.length],
                    duration: 60 * 3,
                    accessKey: "",
                    date: 0,
                  ),
                ),
              ),
            ),

        // Кнопки для управления (снизу, если useTopButtons = false).
        if (!widget.useTopButtons)
          const SizedBox(
            height: 12,
          ),

        if (!widget.useTopButtons) controlButtonsRow,
      ],
    );
  }
}

/// Виджет с разделом "Ваши плейлисты"
class MyPlaylistsBlock extends StatefulWidget {
  static AppLogger logger = getLogger("MyPlaylistsBlock");

  const MyPlaylistsBlock({
    super.key,
  });

  @override
  State<MyPlaylistsBlock> createState() => _MyPlaylistsBlockState();
}

class _MyPlaylistsBlockState extends State<MyPlaylistsBlock> {
  /// Подписки на изменения состояния воспроизведения трека.
  late final List<StreamSubscription> subscriptions;

  @override
  void initState() {
    super.initState();

    subscriptions = [
      // Изменения состояния воспроизведения.
      player.playerStateStream.listen(
        (PlayerState state) => setState(() {}),
      ),

      // Изменения состояния остановки/запуска плеера.
      player.loadedStateStream.listen(
        (bool loaded) => setState(() {}),
      ),
    ];
  }

  @override
  void dispose() {
    super.dispose();

    for (StreamSubscription subscription in subscriptions) {
      subscription.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final UserProvider user = Provider.of<UserProvider>(context);

    final int playlistsCount = user.playlistsCount ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "Ваши плейлисты".
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.music_myPlaylistsChip,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (playlistsCount > 0)
              const SizedBox(
                width: 8,
              ),
            if (playlistsCount > 0)
              Text(
                playlistsCount.toString(),
                style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.secondary.withOpacity(0.75),
                ),
              ),
          ],
        ),
        const SizedBox(
          height: 14,
        ),

        // Содержимое.
        ScrollConfiguration(
          behavior: AlwaysScrollableScrollBehavior(),
          child: SizedBox(
            height: 310,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              physics: user.regularPlaylists.isEmpty
                  ? const NeverScrollableScrollPhysics()
                  : null,
              itemCount: user.regularPlaylists.isNotEmpty
                  ? user.regularPlaylists.length
                  : null,
              itemBuilder: (BuildContext context, int index) {
                // Skeleton loader.
                if (user.regularPlaylists.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      right: 8,
                    ),
                    child: Skeletonizer(
                      child: AudioPlaylistWidget(
                        name:
                            fakePlaylistNames[index % fakePlaylistNames.length],
                      ),
                    ),
                  );
                }

                // Настоящие данные.
                final ExtendedPlaylist playlist = user.regularPlaylists[index];

                return Padding(
                  padding: const EdgeInsets.only(
                    right: 8,
                  ),
                  child: AudioPlaylistWidget(
                    backgroundUrl: playlist.photo?.photo270,
                    mediaKey: playlist.mediaKey,
                    name: playlist.title!,
                    description: playlist.description,
                    selected: player.currentPlaylist == playlist,
                    currentlyPlaying: player.playing && player.loaded,
                    onOpen: () => Navigator.push(
                      context,
                      Material3PageRoute(
                        builder: (context) => PlaylistInfoRoute(
                          playlist: playlist,
                        ),
                      ),
                    ),
                    onPlayToggle: (bool playing) => onPlaylistPlayToggle(
                      context,
                      playlist,
                      playing,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Виджет, показывающий раздел "Плейлисты для Вас".
class RecommendedPlaylistsBlock extends StatefulWidget {
  static AppLogger logger = getLogger("RecommendedPlaylistsBlock");

  const RecommendedPlaylistsBlock({
    super.key,
  });

  @override
  State<RecommendedPlaylistsBlock> createState() =>
      _RecommendedPlaylistsBlockState();
}

class _RecommendedPlaylistsBlockState extends State<RecommendedPlaylistsBlock> {
  /// Подписки на изменения состояния воспроизведения трека.
  late final List<StreamSubscription> subscriptions;

  @override
  void initState() {
    super.initState();

    subscriptions = [
      // Изменения состояния воспроизведения.
      player.playerStateStream.listen(
        (PlayerState state) => setState(() {}),
      ),

      // Изменения состояния остановки/запуска плеера.
      player.loadedStateStream.listen(
        (bool loaded) => setState(() {}),
      ),
    ];
  }

  @override
  void dispose() {
    super.dispose();

    for (StreamSubscription subscription in subscriptions) {
      subscription.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final UserProvider user = Provider.of<UserProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "Плейлисты для Вас".
        Text(
          AppLocalizations.of(context)!.music_recommendedPlaylistsChip,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(
          height: 14,
        ),

        // Содержимое.
        ScrollConfiguration(
          behavior: AlwaysScrollableScrollBehavior(),
          child: SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              physics: user.recommendationPlaylists.isEmpty
                  ? const NeverScrollableScrollPhysics()
                  : null,
              itemCount: user.recommendationPlaylists.isNotEmpty
                  ? user.recommendationPlaylists.length
                  : null,
              itemBuilder: (BuildContext context, int index) {
                final List<ExtendedPlaylist> recommendationPlaylists = user
                    .recommendationPlaylists
                    .sorted((a, b) => b.id.compareTo(a.id));

                // Skeleton loader.
                if (recommendationPlaylists.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      right: 8,
                    ),
                    child: Skeletonizer(
                      child: AudioPlaylistWidget(
                        name:
                            fakePlaylistNames[index % fakePlaylistNames.length],
                        description: "Playlist description here",
                        useTextOnImageLayout: true,
                      ),
                    ),
                  );
                }

                // Настоящие данные.
                final ExtendedPlaylist playlist =
                    recommendationPlaylists[index];

                return Padding(
                  padding: const EdgeInsets.only(
                    right: 8,
                  ),
                  child: AudioPlaylistWidget(
                    backgroundUrl: playlist.photo!.photo270!,
                    mediaKey: playlist.mediaKey,
                    name: playlist.title!,
                    description: playlist.subtitle,
                    useTextOnImageLayout: true,
                    selected: player.currentPlaylist == playlist,
                    currentlyPlaying: player.playing && player.loaded,
                    onOpen: () => Navigator.push(
                      context,
                      Material3PageRoute(
                        builder: (context) => PlaylistInfoRoute(
                          playlist: playlist,
                        ),
                      ),
                    ),
                    onPlayToggle: (bool playing) => onPlaylistPlayToggle(
                      context,
                      playlist,
                      playing,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Виджет, показывающий раздел "Совпадения по вкусам".
class SimillarMusicBlock extends StatefulWidget {
  static AppLogger logger = getLogger("SimillarMusicBlock");

  const SimillarMusicBlock({
    super.key,
  });

  @override
  State<SimillarMusicBlock> createState() => _SimillarMusicBlockState();
}

class _SimillarMusicBlockState extends State<SimillarMusicBlock> {
  /// Подписки на изменения состояния воспроизведения трека.
  late final List<StreamSubscription> subscriptions;

  @override
  void initState() {
    super.initState();

    subscriptions = [
      // Изменения состояния воспроизведения.
      player.playerStateStream.listen(
        (PlayerState state) => setState(() {}),
      ),

      // Изменения состояния остановки/запуска плеера.
      player.loadedStateStream.listen(
        (bool loaded) => setState(() {}),
      ),
    ];
  }

  @override
  void dispose() {
    super.dispose();

    for (StreamSubscription subscription in subscriptions) {
      subscription.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final UserProvider user = Provider.of<UserProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "Совпадения по вкусам".
        Text(
          AppLocalizations.of(context)!.music_similarMusicChip,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(
          height: 14,
        ),

        // Содержимое.
        ScrollConfiguration(
          behavior: AlwaysScrollableScrollBehavior(),
          child: SizedBox(
            height: 282,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              physics: user.simillarPlaylists.isEmpty
                  ? const NeverScrollableScrollPhysics()
                  : null,
              itemCount: user.simillarPlaylists.isNotEmpty
                  ? user.recommendationPlaylists.length
                  : null,
              itemBuilder: (BuildContext context, int index) {
                final List<ExtendedPlaylist> simillarPlaylists = user
                    .simillarPlaylists
                    .sorted((a, b) => b.simillarity!.compareTo(a.simillarity!));

                // Skeleton loader.
                if (simillarPlaylists.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      right: 8,
                    ),
                    child: Skeletonizer(
                      child: SimillarMusicPlaylistWidget(
                        name:
                            fakePlaylistNames[index % fakePlaylistNames.length],
                        simillarity: 0.9,
                        tracks: List.generate(
                          3,
                          (int index) => ExtendedAudio(
                            id: -1,
                            ownerID: -1,
                            title:
                                fakeTrackNames[index % fakeTrackNames.length],
                            artist: fakeTrackNames[
                                (index + 1) % fakeTrackNames.length],
                            duration: 60 * 3,
                            accessKey: "",
                            url: "",
                            date: 0,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                // Настоящие данные.
                final ExtendedPlaylist playlist = simillarPlaylists[index];

                return Padding(
                  padding: const EdgeInsets.only(
                    right: 8,
                  ),
                  child: SimillarMusicPlaylistWidget(
                    name: playlist.title!,
                    simillarity: playlist.simillarity!,
                    color: HexColor.fromHex(playlist.color!),
                    tracks: playlist.knownTracks!,
                    selected: player.currentPlaylist == playlist,
                    currentlyPlaying: player.playing && player.loaded,
                    onOpen: () => Navigator.push(
                      context,
                      Material3PageRoute(
                        builder: (context) => PlaylistInfoRoute(
                          playlist: playlist,
                        ),
                      ),
                    ),
                    onPlayToggle: (bool playing) => onPlaylistPlayToggle(
                      context,
                      playlist,
                      playing,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Виджет, показывающий раздел "Собрано редакцией".
class ByVKPlaylistsBlock extends StatefulWidget {
  static AppLogger logger = getLogger("ByVKPlaylistsBlock");

  const ByVKPlaylistsBlock({
    super.key,
  });

  @override
  State<ByVKPlaylistsBlock> createState() => _ByVKPlaylistsBlockState();
}

class _ByVKPlaylistsBlockState extends State<ByVKPlaylistsBlock> {
  /// Подписки на изменения состояния воспроизведения трека.
  late final List<StreamSubscription> subscriptions;

  @override
  void initState() {
    super.initState();

    subscriptions = [
      // Изменения состояния воспроизведения.
      player.playerStateStream.listen(
        (PlayerState state) => setState(() {}),
      ),

      // Изменения состояния остановки/запуска плеера.
      player.loadedStateStream.listen(
        (bool loaded) => setState(() {}),
      ),
    ];
  }

  @override
  void dispose() {
    super.dispose();

    for (StreamSubscription subscription in subscriptions) {
      subscription.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final UserProvider user = Provider.of<UserProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "Собрано редакцией".
        Text(
          AppLocalizations.of(context)!.music_byVKChip,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(
          height: 14,
        ),

        // Содержимое.
        ScrollConfiguration(
          behavior: AlwaysScrollableScrollBehavior(),
          child: SizedBox(
            height: 310,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              physics: user.madeByVKPlaylists.isEmpty
                  ? const NeverScrollableScrollPhysics()
                  : null,
              itemCount: user.madeByVKPlaylists.isNotEmpty
                  ? user.madeByVKPlaylists.length
                  : null,
              itemBuilder: (BuildContext context, int index) {
                // Skeleton loader.
                if (user.madeByVKPlaylists.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      right: 8,
                    ),
                    child: Skeletonizer(
                      child: AudioPlaylistWidget(
                        name:
                            fakePlaylistNames[index % fakePlaylistNames.length],
                      ),
                    ),
                  );
                }

                // Настоящие данные.
                final ExtendedPlaylist playlist = user.madeByVKPlaylists[index];

                return Padding(
                  padding: const EdgeInsets.only(
                    right: 8,
                  ),
                  child: AudioPlaylistWidget(
                    backgroundUrl: playlist.photo!.photo270!,
                    mediaKey: playlist.mediaKey,
                    name: playlist.title!,
                    description: playlist.description,
                    selected: player.currentPlaylist == playlist,
                    currentlyPlaying: player.playing && player.loaded,
                    onOpen: () => Navigator.push(
                      context,
                      Material3PageRoute(
                        builder: (context) => PlaylistInfoRoute(
                          playlist: playlist,
                        ),
                      ),
                    ),
                    onPlayToggle: (bool playing) => onPlaylistPlayToggle(
                      context,
                      playlist,
                      playing,
                    ),
                  ),
                );
              },
            ),
          ),
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
        Text(
          AppLocalizations.of(context)!.music_allBlocksDisabledTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(
          height: 2,
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
    ];

    // Загружаем информацию о пользователе.
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

    final bool myMusicEnabled = user.settings.myMusicChipEnabled;
    final bool playlistsEnabled = user.settings.playlistsChipEnabled;
    final bool recommendedPlaylistsEnabled =
        hasRecommendations && user.settings.recommendedPlaylistsChipEnabled;
    final bool similarMusicChipEnabled =
        hasRecommendations && user.settings.similarMusicChipEnabled;
    final bool byVKChipEnabled =
        hasRecommendations && user.settings.byVKChipEnabled;

    late bool everythingIsDisabled;

    // Если рекомендации включены, то мы должны учитывать и другие разделы.
    if (hasRecommendations) {
      everythingIsDisabled = (!(myMusicEnabled ||
          playlistsEnabled ||
          recommendedPlaylistsEnabled ||
          similarMusicChipEnabled ||
          byVKChipEnabled));
    } else {
      everythingIsDisabled = (!(myMusicEnabled || playlistsEnabled));
    }

    /// [List], содержащий в себе список из виджетов/разделов на главном экране, которые доожны быть разделены [Divider]'ом.
    final List<Widget> activeBlocks = [
      // Раздел "Моя музыка".
      if (myMusicEnabled)
        MyMusicBlock(
          useTopButtons: isMobileLayout,
        ),

      // Раздел "Ваши плейлисты".
      if (playlistsEnabled) const MyPlaylistsBlock(),

      // Раздел "Плейлисты для Вас".
      if (recommendedPlaylistsEnabled) const RecommendedPlaylistsBlock(),

      // Раздел "Совпадения по вкусам".
      if (similarMusicChipEnabled) const SimillarMusicBlock(),

      // Раздел "Собрано редакцией".
      if (byVKChipEnabled) const ByVKPlaylistsBlock(),

      // Нижняя часть интерфейса с переключателями при Mobile Layout'е.
      if (isMobileLayout) const ChipFilters(),

      // Случай, если пользователь отключил все возможные разделы музыки.
      if (everythingIsDisabled) const EverythingIsDisabledBlock(),
    ];

    return Scaffold(
      appBar: isMobileLayout
          ? AppBar(
              title: Text(
                AppLocalizations.of(context)!.music_label,
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => const SearchDisplayDialog(),
                  ),
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

          await ensureUserAudioAllInformation(
            context,
            forceUpdate: true,
          );
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
                            onPressed: () => showDialog(
                              context: context,
                              builder: (context) => const SearchDisplayDialog(),
                            ),
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
