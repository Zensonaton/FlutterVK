import "dart:async";

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
import "package:share_plus/share_plus.dart";
import "package:skeletonizer/skeletonizer.dart";
import "package:styled_text/styled_text.dart";

import "../../api/audio/edit.dart";
import "../../api/audio/search.dart";
import "../../api/catalog/get_audio.dart";
import "../../api/executeScripts/mass_audio_get.dart";
import "../../api/shared.dart";
import "../../consts.dart";
import "../../main.dart";
import "../../provider/user.dart";
import "../../services/cache_manager.dart";
import "../../services/logger.dart";
import "../../utils.dart";
import "../../widgets/adaptive_dialog.dart";
import "../../widgets/dialogs.dart";
import "../../widgets/fallback_audio_photo.dart";
import "../../widgets/loading_overlay.dart";
import "../home.dart";
import "profile.dart";

/// Загружает всю информацию пользователя (плейлисты, треки, рекомендации) для раздела «музыка», присваивая её в объект [UserProvider]. Если таковая информация уже присутствует, то данный вызов будет проигнорирован.
///
/// Если [forceUpdate] = true, то данный метод загрузит информацию для раздела музыки даже если в [UserProvider] таковая информация уже есть.
Future<void> ensureUserAudioAllInformation(
  BuildContext context, {
  bool forceUpdate = false,
}) async {
  await Future.wait([
    ensureUserAudioBasicInfo(
      context,
      forceUpdate: forceUpdate,
    ),
    ensureUserAudioRecommendations(
      context,
      forceUpdate: forceUpdate,
    )
  ]);

  return;
}

/// Загружает информацию (плейлисты, треки) для раздела «музыка», присваивая её в объект [UserProvider]. Если таковая информация уже присутствует, то данный вызов будет проигнорирован.
///
/// Если [forceUpdate] = true, то данный метод загрузит информацию для раздела музыки даже если в [UserProvider] таковая информация уже есть.
Future<void> ensureUserAudioBasicInfo(
  BuildContext context, {
  bool forceUpdate = false,
}) async {
  final UserProvider user = Provider.of<UserProvider>(context, listen: false);
  final AppLogger logger = getLogger("ensureUserAudioInfo");

  // Если информация уже загружена, то ничего не делаем.
  if (!forceUpdate && user.favoritesPlaylist?.audios != null) return;

  logger.d("Loading music information");

  // Сбрасываем информацию у "рекомендованных" плейлистов.
  user.allPlaylists.removeWhere(
    (int _, ExtendedVKPlaylist playlist) => playlist.isRecommendationsPlaylist,
  );

  // Получаем информацию по музыке, вместе с альбомами, если пользователь добавил токен от VK Admin.
  try {
    final APIMassAudioGetResponse response =
        await user.scriptMassAudioGetWithAlbums(user.id!);

    // Проверяем, что в ответе нет ошибок.
    if (response.error != null) {
      throw Exception(
        "API error ${response.error!.errorCode}: ${response.error!.errorMessage}",
      );
    }

    user.playlistsCount = response.response!.playlistsCount;

    // Создаём фейковый плейлист, где хранятся "любимые" треки пользователя.
    user.allPlaylists[0] = ExtendedVKPlaylist(
      id: 0,
      ownerID: user.id!,
      count: response.response!.audioCount,
      audios: response.response!.audios
          .map(
            (Audio audio) => ExtendedVKAudio.fromAudio(
              audio,
              isLiked: true,
            ),
          )
          .toList(),
    );

    // Создаём объекты плейлистов у пользователя.
    user.allPlaylists.addAll(
      {
        for (var playlist in response.response!.playlists)
          playlist.id: ExtendedVKPlaylist.fromAudioPlaylist(playlist)
      },
    );

    user.resetFavoriteMediaKeys();
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

/// Загружает информацию по рекомендациям для раздела «музыка», присваивая её в объект [UserProvider]. Если таковая информация уже присутствует, то данный вызов будет проигнорирован.
///
/// Данный метод работает лишь в том случае, если у пользователя есть присвоенный токен рекомендаций (т.е., токен приложения VK Admin). Если [UserProvider] не имеет данного токена, то вызов будет проигнорирован.
///
/// Если [forceUpdate] = true, то данный метод загрузит информацию для раздела музыки даже если в [UserProvider] таковая информация уже есть.
Future<void> ensureUserAudioRecommendations(
  BuildContext context, {
  bool forceUpdate = false,
}) async {
  /// Парсит список из плейлистов, возвращая только список из рекомендуемых плейлистов ("Для вас" и подобные).
  List<ExtendedVKPlaylist> parseRecommendedPlaylists(
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
    // Превращаем объекты типа AudioPlaylist в ExtendedVKPlaylist.
    return response.response!.playlists
        .where((AudioPlaylist playlist) => recommendedPlaylistIDs.contains(
              playlist.mediaKey,
            ))
        .map(
          (AudioPlaylist playlist) => ExtendedVKPlaylist.fromAudioPlaylist(
            playlist,
          ),
        )
        .toList();
  }

  /// Парсит список из плейлистов, возвращая только список из плейлистов раздела "Собрано редакцией".
  List<ExtendedVKPlaylist> parseMadeByVKPlaylists(
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
    // Превращаем объекты типа AudioPlaylist в ExtendedVKPlaylist.
    return response.response!.playlists
        .where((AudioPlaylist playlist) => recommendedPlaylistIDs.contains(
              playlist.mediaKey,
            ))
        .map(
          (AudioPlaylist playlist) => ExtendedVKPlaylist.fromAudioPlaylist(
            playlist,
          ),
        )
        .toList();
  }

  final UserProvider user = Provider.of<UserProvider>(context, listen: false);
  final AppLogger logger = getLogger("ensureUserAudioRecommendations");

  // Если информация уже загружена, то ничего не делаем.
  if (!forceUpdate && user.recommendationPlaylists.isNotEmpty) return;

  // Если у пользователя нет второго токена, то ничего не делаем.
  if (user.recommendationsToken == null) return;

  logger.d("Loading music recommendations");

  try {
    final APICatalogGetAudioResponse response = await user.catalogGetAudio();

    // Проверяем, что в ответе нет ошибок.
    if (response.error != null) {
      throw Exception(
        "API error ${response.error!.errorCode}: ${response.error!.errorMessage}",
      );
    }

    // Добавляем рекомендуемые плейлисты, а так же плейлисты из раздела "сделано редакцией ВКонтакте".
    user.allPlaylists.addAll(
      {
        for (ExtendedVKPlaylist playlist in {
          ...parseRecommendedPlaylists(response),
          ...parseMadeByVKPlaylists(response),
        })
          playlist.id: playlist
      },
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

/// Возвращает только те [Audio], которые совпадают по названию [query].
List<ExtendedVKAudio> filterByName(
  List<ExtendedVKAudio> audios,
  String query,
) {
  // Избавляемся от всех пробелов в запросе, а так же диакритические знаки.
  query = cleanString(query);

  // Если запрос пустой, то просто возвращаем исходный массив.
  if (query.isEmpty) return audios;

  // Возвращаем список тех треков, у которых совпадает название или исполнитель.
  return audios
      .where(
        (ExtendedVKAudio audio) => audio.normalizedName.contains(query),
      )
      .toList();
}

/// Создаёт виджет типа [AudioTrackTile] для отображения в [ListView.builder].
Padding buildListTrackWidget(
  BuildContext context,
  int index,
  List<ExtendedVKAudio> audios,
  UserProvider user, {
  ExtendedVKPlaylist? playlist,
}) {
  final ExtendedVKAudio audio = audios[index];

  return Padding(
    key: ValueKey(
      audio.mediaKey,
    ),
    padding: EdgeInsets.only(
      bottom: index < audios.length - 1
          ? 8
          : 0, // Делаем Padding только в том случае, если это не последний элемент.
    ),
    child: AudioTrackTile(
      selected: audio == player.currentAudio,
      currentlyPlaying: player.loaded && player.playing,
      isLiked: user.favoriteMediaKeys.contains(
        audio.mediaKey,
      ),
      audio: audio,
      dragIndex: index,
      onAddToQueue: () async {
        await player.addNextToQueue(audio);

        if (!context.mounted) return;
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
      },
      onPlay: audio.isRestricted
          ? () => showErrorDialog(
                context,
                title:
                    AppLocalizations.of(context)!.music_trackUnavailableTitle,
                description: AppLocalizations.of(context)!
                    .music_trackUnavailableDescription,
              )
          : () => player.setPlaylist(
                playlist ??
                    ExtendedVKPlaylist(
                      id: -1,
                      ownerID: user.id!,
                      count: 1,
                      audios: audios,
                      title: AppLocalizations.of(context)!
                          .music_searchPlaylistTitle,
                    ),
                audio: audio,
              ),
      onPlayToggle: (bool enabled) => player.playOrPause(enabled),
      onLikeToggle: (bool liked) => toggleTrackLikeState(
        context,
        audio,
        !user.favoriteMediaKeys.contains(
          audio.mediaKey,
        ),
      ),
      onSecondaryAction: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (BuildContext context) => BottomAudioOptionsDialog(
          audio: audio,
        ),
      ),
    ),
  );
}

/// Загружает информацию по указанному [playlist], заполняя его новыми значениями.
Future<void> loadPlaylistData(
  ExtendedVKPlaylist playlist,
  UserProvider user, {
  bool forceUpdate = false,
}) async {
  // Если информация уже загружена, то ничего не делаем.
  if (!forceUpdate && playlist.audios != null) return;

  final APIMassAudioGetResponse response =
      await user.scriptMassAudioGetWithAlbums(
    playlist.ownerID,
    albumID: playlist.id,
    accessKey: playlist.accessKey,
  );

  // Проверяем, что в ответе нет ошибок.
  if (response.error != null) {
    throw Exception(
      "API error ${response.error!.errorCode}: ${response.error!.errorMessage}",
    );
  }

  playlist.audios = response.response!.audios
      .map(
        (Audio audio) => ExtendedVKAudio.fromAudio(audio),
      )
      .toList();
  playlist.count = response.response!.audioCount;
}

/// Диалог, показывающий содержимое плейлиста.
///
/// Пример использования:
/// ```dart
/// showDialog(
/// 	context: context,
/// 	builder: (context) => const PlaylistDisplayDialog(...)
/// );
/// ```
class PlaylistDisplayDialog extends StatefulWidget {
  /// Информация об открываемом плейлисте.
  final ExtendedVKPlaylist playlist;

  /// Если true, то сразу после открытия данного диалога фокус будет на [SearchBar].
  final bool focusSearchBarOnOpen;

  const PlaylistDisplayDialog({
    super.key,
    required this.playlist,
    this.focusSearchBarOnOpen = true,
  });

  @override
  State<PlaylistDisplayDialog> createState() => _PlaylistDisplayDialogState();
}

class _PlaylistDisplayDialogState extends State<PlaylistDisplayDialog> {
  final AppLogger logger = getLogger("PlaylistDisplayDialog");

  /// Контроллер, используемый для управления введённым в поле поиска текстом.
  final TextEditingController controller = TextEditingController();

  /// Подписки на изменения состояния воспроизведения трека.
  late final List<StreamSubscription> subscriptions;

  /// FocusNode для фокуса поля поиска сразу после открытия данного диалога.
  final FocusNode focusNode = FocusNode();

  /// Указывает, что в данный момент данные о плейлисте загружаются.
  bool _loading = false;

  /// Загрузка данных данного плейлиста.
  Future<void> init() async {
    final UserProvider user = Provider.of<UserProvider>(context, listen: false);

    // Если информация по данному плейлисту не загружена, то загружаем её.
    if (widget.playlist.audios == null) {
      setState(() => _loading = true);

      try {
        await loadPlaylistData(
          widget.playlist,
          user,
        );
      } catch (e, stackTrace) {
        // ignore: use_build_context_synchronously
        showLogErrorDialog(
          "Ошибка при открытии плейлиста: ",
          e,
          stackTrace,
          logger,
          context,
        );
      } finally {
        if (context.mounted) setState(() => _loading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    init();

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

    // Если мы запущены на Desktop'е, то тогда устанавливаем фокус на поле поиска.
    if (isDesktop && widget.focusSearchBarOnOpen) focusNode.requestFocus();
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

    final List<ExtendedVKAudio> playlistAudios = widget.playlist.audios ?? [];
    final List<ExtendedVKAudio> filteredAudios =
        filterByName(playlistAudios, controller.text);
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
                    child: SearchBar(
                      focusNode: focusNode,
                      controller: controller,
                      hintText: AppLocalizations.of(context)!
                          .music_searchTextInPlaylist(playlistAudios.length),
                      elevation: MaterialStateProperty.all(
                        1, // TODO: Сделать нормальный вид у поиска при наведении.
                      ),
                      onChanged: (String query) => setState(() {}),
                      trailing: [
                        if (controller.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                            ),
                            onPressed: () => setState(() => controller.clear()),
                          )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 16,
            ),

            // У пользователя нет треков в данном плейлисте.
            if (playlistAudios.isEmpty && !_loading)
              Text(
                AppLocalizations.of(context)!.music_playlistEmpty,
              ),

            // У пользователя есть треки, но поиск ничего не выдал.
            if (playlistAudios.isNotEmpty &&
                filteredAudios.isEmpty &&
                !_loading)
              StyledText(
                text: AppLocalizations.of(context)!.music_zeroSearchResults,
                tags: {
                  "click": StyledTextActionTag(
                    (String? text, Map<String?, String?> attrs) => setState(
                      () => controller.clear(),
                    ),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                },
              ),

            // Информация по данному плейлисту ещё не была загружена.
            if (_loading)
              Expanded(
                child: ListView.builder(
                  itemCount: 50,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (BuildContext context, int index) {
                    return Skeletonizer(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          bottom: 8,
                        ),
                        child: AudioTrackTile(
                          audio: ExtendedVKAudio(
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
                    );
                  },
                ),
              ),

            // Результаты поиска/отображение всех элементов.
            if (filteredAudios.isNotEmpty)
              Expanded(
                child: ReorderableListView.builder(
                  onReorder: (int oldIndex, int newIndex) {
                    // Небольшие костыли ввиду странности работы метода onReorder у Flutter.
                    if (newIndex > filteredAudios.length) {
                      newIndex = filteredAudios.length;
                    }
                    if (oldIndex < newIndex) newIndex--;

                    // Если индекс не поменялся, то ничего не делаем.
                    if (oldIndex == newIndex) return;

                    showWipDialog(
                      context,
                      title: "Изменение порядка трека с $oldIndex до $newIndex",
                    );
                  },
                  buildDefaultDragHandles: false,
                  itemCount: filteredAudios.length,
                  itemBuilder: (BuildContext context, int index) {
                    return buildListTrackWidget(
                      context,
                      index,
                      filteredAudios,
                      user,
                      playlist: widget.playlist,
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
  final AppLogger logger = getLogger("SearchDisplayDialog");

  /// Контроллер, используемый для управления введённым в поле поиска текстом.
  final TextEditingController controller = TextEditingController();

  /// FocusNode для фокуса поля поиска сразу после открытия данного диалога.
  final FocusNode focusNode = FocusNode();

  /// Debouncer для поиска.
  final debouncer = Debouncer<String>(
    const Duration(
      seconds: 1,
    ),
    initialValue: "",
  );

  /// Текущий Future по поиску через API ВКонтакте. Может отсутствовать, если ничего не было введено в поиск.
  Future<APIAudioSearchResponse>? searchFuture;

  @override
  void initState() {
    super.initState();

    final UserProvider user = Provider.of<UserProvider>(context, listen: false);

    // Обработчик печати.
    controller.addListener(
      () => debouncer.value = controller.text,
    );

    // Обработчик событий поиска, испускаемых Debouncer'ом, если пользователь остановил печать.
    debouncer.values.listen(
      (String query) {
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
      },
    );

    // Если у пользователя ПК, то тогда устанавливаем фокус на поле поиска.
    if (isDesktop && widget.focusSearchBarOnOpen) focusNode.requestFocus();
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
                    child: SearchBar(
                      focusNode: focusNode,
                      controller: controller,
                      hintText: AppLocalizations.of(context)!.music_searchText,
                      elevation: MaterialStateProperty.all(
                        1, // TODO: Сделать нормальный вид у поиска при наведении.
                      ),
                      onChanged: (String query) => setState(() {}),
                      trailing: [
                        if (controller.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                            ),
                            onPressed: () => setState(
                              () => controller.clear(),
                            ),
                          )
                      ],
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
                builder: (BuildContext context,
                    AsyncSnapshot<APIAudioSearchResponse> snapshot) {
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
                              audio: ExtendedVKAudio(
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
                    itemCount: snapshot.data!.response!.items.length,
                    itemBuilder: (BuildContext context, int index) {
                      return buildListTrackWidget(
                        context,
                        index,
                        snapshot.data!.response!.items
                            .map(
                              (audio) => ExtendedVKAudio.fromAudio(audio),
                            )
                            .toList(),
                        user,
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
  final ExtendedVKAudio audio;

  const TrackInfoEditDialog({
    super.key,
    required this.audio,
  });

  @override
  State<TrackInfoEditDialog> createState() => _TrackInfoEditDialogState();
}

class _TrackInfoEditDialogState extends State<TrackInfoEditDialog> {
  final AppLogger logger = getLogger("TrackInfoEditDialog");

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
    final ExtendedVKAudio audio = ExtendedVKAudio(
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
            AudioTrackTile(
              audio: audio,
              showLikeButton: false,
              selected: audio == player.currentAudio,
              currentlyPlaying: player.loaded && player.playing,
            ),
            const SizedBox(height: 8),
            const Divider(),
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
            DropdownMenu(
              label: Text(
                AppLocalizations.of(context)!.music_trackGenre,
              ),
              onSelected: (int? genreID) {
                if (genreID == null) return;

                setState(() => trackGenre = genreID);
              },
              initialSelection: widget.audio.genreID ?? 18, // Жанр "Other".
              width:
                  500 - 24 * 2, // Не очень красивое решение. Спасибо, Flutter.
              dropdownMenuEntries: [
                for (MapEntry<int, String> genre in musicGenres.entries)
                  DropdownMenuEntry(
                    value: genre.key,
                    label: genre.value,
                  ),
              ],
            ),
            const SizedBox(height: 24),
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

                    // Проверяем, что в ответе нет ошибок.
                    if (response.error != null) {
                      throw Exception(
                        "API error ${response.error!.errorCode}: ${response.error!.errorMessage}",
                      );
                    }

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
/// showBottomSheet(
///   context: context,
///   builder: (BuildContext context) => const BottomAudioOptionsDialog(...),
/// ),
/// ```
class BottomAudioOptionsDialog extends StatefulWidget {
  /// Трек типа [ExtendedVKAudio], над которым производится манипуляция.
  final ExtendedVKAudio audio;

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

    return Container(
      width: 500,
      padding: const EdgeInsets.all(24),
      child: ListView(
        shrinkWrap: true,
        children: [
          AudioTrackTile(
            audio: widget.audio,
            showLikeButton: false,
            selected: widget.audio == player.currentAudio,
            currentlyPlaying: player.loaded && player.playing,
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),

          // Редактировать данные трека.
          ListTile(
            enabled:
                widget.audio.album == null && widget.audio.ownerID == user.id!,
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
              AppLocalizations.of(context)!.music_detailsSetThumbnailTitle,
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

          // Поделиться ссылкой на трек.
          ListTile(
            onTap: () {
              Navigator.of(context).pop();

              Share.share(
                widget.audio.trackUrl,
              );
            },
            leading: const Icon(
              Icons.share,
            ),
            title: Text(
              AppLocalizations.of(context)!.music_detailsShareTitle,
            ),
          ),

          // Debug-опции.
          if (kDebugMode)
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
        ],
      ),
    );
  }
}

/// Виджет, олицетворяющий отдельный трек в списке треков.
class AudioTrackTile extends StatefulWidget {
  /// Объект типа [ExtendedVKAudio], олицетворяющий данный трек.
  final ExtendedVKAudio audio;

  /// Указывает, что этот трек сейчас выбран.
  ///
  /// Поле [currentlyPlaying] указывает, что плеер включён.
  final bool selected;

  /// Указывает, что плеер в данный момент включён.
  final bool currentlyPlaying;

  /// Указывает, что этот трек лайкнут.
  final bool isLiked;

  /// Указывает, что кнопка для лайка должна быть показана.
  final bool showLikeButton;

  /// Указывает индекс данного элемента для перетаскивания. Если не указан, то перетаскивание работать не будет.
  ///
  /// Для перетаскивания данный виджет обязан находиться внутри [ReorderableListView].
  final int? dragIndex;

  /// Действие, вызываемое при переключения паузы/возобновления при нажатии по иконке трека.
  ///
  /// В отличии от [onPlay], данный метод просто переключает то, находится трек на паузе или нет. Данный метод вызывается лишь в случае, если поле [selected] правдиво, в ином случае при нажатии на данный виджет будет вызываться событие [onPlay].
  final Function(bool)? onPlayToggle;

  /// Действие, вызываемое при "выборе" данного трека.
  ///
  /// В отличии от [onPlayToggle], данный метод должен "перезапустить" трек, если он в данный момент играет.
  final VoidCallback? onPlay;

  /// Действие, вызываемое при переключении состояния "лайка" данного трека.
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
    this.currentlyPlaying = false,
    this.isLiked = false,
    this.showLikeButton = true,
    this.dragIndex,
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

  // TODO: Сделать показ того, что данный трек играет более заметным.

  @override
  Widget build(BuildContext context) {
    final bool selectedAndPlaying = widget.selected && widget.currentlyPlaying;

    /// Url на изображение данного трека.
    final String? imageUrl = widget.audio.album?.thumb?.photo68;

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
          borderRadius: BorderRadius.circular(globalBorderRadius),
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
      child: ReorderableDragStartListener(
        index: widget.dragIndex ?? 0,
        enabled: widget.dragIndex != null && isDesktop,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPlay,
            onHover: widget.onPlay != null
                ? (bool value) => setState(() => isHovered = value)
                : null,
            borderRadius: BorderRadius.circular(globalBorderRadius),
            onLongPress: isMobile ? widget.onSecondaryAction : null,
            onSecondaryTap: widget.onSecondaryAction,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: widget.audio.isRestricted ? 0.5 : 1,
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
                    borderRadius: BorderRadius.circular(globalBorderRadius),
                    child: ReorderableDragStartListener(
                      index: widget.dragIndex ?? 0,
                      enabled: widget.dragIndex != null && isMobile,
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(globalBorderRadius),
                              child: imageUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      cacheKey: "${widget.audio.mediaKey}68",
                                      width: 50,
                                      height: 50,
                                      placeholder:
                                          (BuildContext context, String url) =>
                                              const FallbackAudioAvatar(),
                                      cacheManager:
                                          CachedNetworkImagesManager.instance,
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
                                          child: RepaintBoundary(
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
                              )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 8,
                ),
                Expanded(
                  child: Opacity(
                    opacity: widget.audio.isRestricted ? 0.5 : 1,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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
                            if (widget.audio.isExplicit)
                              const SizedBox(
                                width: 2,
                              ),
                            if (widget.audio.isExplicit)
                              Icon(
                                Icons.explicit,
                                size: 16,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onBackground
                                    .withOpacity(0.5),
                              ),
                            if (widget.audio.subtitle != null)
                              const SizedBox(
                                width: 6,
                              ),
                            if (widget.audio.subtitle != null)
                              Flexible(
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
                          ],
                        ),
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
                const SizedBox(
                  width: 8,
                ),
                Text(
                  secondsAsString(widget.audio.duration),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onBackground
                        .withOpacity(0.75),
                  ),
                ),
                if (widget.showLikeButton)
                  const SizedBox(
                    width: 8,
                  ),
                if (widget.showLikeButton)
                  IconButton(
                    onPressed: () => widget.onLikeToggle?.call(
                      !widget.isLiked,
                    ),
                    icon: Icon(
                      widget.isLiked ? Icons.favorite : Icons.favorite_outline,
                      color: Theme.of(context).colorScheme.primary,
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

    return InkWell(
      onTap: widget.onOpen,
      onSecondaryTap: widget.onOpen,
      onHover: (bool value) => setState(() => isHovered = value),
      child: SizedBox(
        width: 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 200,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(globalBorderRadius),
                    child: widget.backgroundUrl != null
                        ? CachedNetworkImage(
                            imageUrl: widget.backgroundUrl!,
                            memCacheHeight: 200,
                            memCacheWidth: 200,
                            placeholder: (BuildContext context, String url) =>
                                const FallbackAudioPlaylistAvatar(),
                            cacheManager: CachedNetworkImagesManager.instance,
                          )
                        : const FallbackAudioPlaylistAvatar(),
                  ),

                  // Если это у нас рекомендательный плейлист, то текст должен находиться внутри изображения плейлиста.
                  if (widget.useTextOnImageLayout)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.name,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge!
                                .copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: widget.useTextOnImageLayout
                                      ? Colors.white
                                      : null,
                                ),
                          ),
                          if (widget.description != null)
                            Text(
                              widget.description!,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 3,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge!
                                  .copyWith(
                                    color: widget.useTextOnImageLayout
                                        ? Colors.white
                                        : null,
                                  ),
                            ),
                        ],
                      ),
                    ),
                  if (isHovered || widget.selected)
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .background
                            .withOpacity(0.5),
                        borderRadius: BorderRadius.circular(globalBorderRadius),
                      ),
                      child: !isHovered && selectedAndPlaying
                          ? Center(
                              child: RepaintBoundary(
                                child: Image.asset(
                                  "assets/images/audioEqualizer.gif",
                                  color: Theme.of(context).colorScheme.primary,
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
                    )
                ],
              ),
            ),

            // Если это обычный плейлист, то нам нужно показать его содержимое под изображением.
            if (!widget.useTextOnImageLayout)
              const SizedBox(
                height: 2,
              ),
            if (!widget.useTextOnImageLayout)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      widget.name,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style:
                          Theme.of(context).textTheme.headlineSmall!.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                    ),
                  ),
                  if (widget.description != null)
                    Flexible(
                      child: Text(
                        widget.description!,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.w400,
                            ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Виджет, показывающий кучку переключателей-фильтров класса [FilterChip] для включения различных разделов "музыки".
class ChipFilters extends StatefulWidget {
  const ChipFilters({
    super.key,
  });

  @override
  State<ChipFilters> createState() => _ChipFiltersState();
}

class _ChipFiltersState extends State<ChipFilters> {
  @override
  Widget build(BuildContext context) {
    final UserProvider user = Provider.of<UserProvider>(context);

    final bool hasRecommendations = user.recommendationsToken != null;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(
          onSelected: (bool value) => setState(
            () {
              user.settings.myMusicChipEnabled = value;
              user.markUpdated();
            },
          ),
          selected: user.settings.myMusicChipEnabled,
          label: Text(
            AppLocalizations.of(context)!.music_myMusicChip,
          ),
        ),
        FilterChip(
          onSelected: (bool value) => setState(
            () {
              user.settings.playlistsChipEnabled = value;
              user.markUpdated();
            },
          ),
          selected: user.settings.playlistsChipEnabled,
          label: Text(
            AppLocalizations.of(context)!.music_myPlaylistsChip,
          ),
        ),
        if (hasRecommendations)
          FilterChip(
            onSelected: (bool value) => setState(
              () {
                user.settings.recommendedPlaylistsChipEnabled = value;
                user.markUpdated();
              },
            ),
            selected: user.settings.recommendedPlaylistsChipEnabled,
            label: Text(
              AppLocalizations.of(context)!.music_recommendedPlaylistsChip,
            ),
          ),
        if (hasRecommendations)
          FilterChip(
            onSelected: (bool value) => setState(
              () {
                user.settings.similarMusicChipEnabled = value;
                user.markUpdated();
              },
            ),
            selected: user.settings.similarMusicChipEnabled,
            label: Text(
              AppLocalizations.of(context)!.music_similarMusicChip,
            ),
          ),
        if (hasRecommendations)
          FilterChip(
            onSelected: (bool value) => setState(
              () {
                user.settings.byVKChipEnabled = value;
                user.markUpdated();
              },
            ),
            selected: user.settings.byVKChipEnabled,
            label: Text(
              AppLocalizations.of(context)!.music_byVKChip,
            ),
          ),
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

    final int musicCount = user.favoritesPlaylist?.count ?? 0;
    final int clampedMusicCount = clampInt(
      musicCount,
      0,
      10,
    );
    final Widget controlButtonsRow = Wrap(
      spacing: 8,
      children: [
        FilledButton.icon(
          onPressed: user.favoritesPlaylist?.audios != null
              ? () async {
                  await player.setShuffle(true);

                  await player.setPlaylist(
                    user.favoritesPlaylist!,
                    audio: user.favoritesPlaylist!.audios!.randomItem(),
                  );
                }
              : null,
          icon: const Icon(
            Icons.play_arrow,
          ),
          label: Text(
            AppLocalizations.of(context)!.music_shuffleAndPlay,
          ),
        ),
        FilledButton.tonalIcon(
          onPressed: user.favoritesPlaylist?.audios != null
              ? () => showDialog(
                    context: context,
                    builder: (context) => PlaylistDisplayDialog(
                      playlist: user.favoritesPlaylist!,
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
              index,
              user.favoritesPlaylist!.audios!.slice(0, clampedMusicCount),
              user,
              playlist: user.favoritesPlaylist!,
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
                  audio: ExtendedVKAudio(
                    id: -1,
                    ownerID: -1,
                    title: fakeTrackNames[index % fakeTrackNames.length],
                    artist: fakeTrackNames[(index + 1) % fakeTrackNames.length],
                    duration: 60 * 3,
                    accessKey: "",
                    url: "",
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

/// Метод, вызываемый при нажатии по центру плейлиста. Данный метод либо ставит плейлист на паузу, либо загружает его информацию.
Future<void> onPlaylistPlayToggle(
  BuildContext context,
  ExtendedVKPlaylist playlist,
  bool playing,
) async {
  final UserProvider user = Provider.of<UserProvider>(context, listen: false);
  final AppLogger logger = getLogger("onPlaylistPlayToggle");

  // Если у нас играет этот же плейлист, то тогда мы попросту должны поставить на паузу/убрать паузу.
  if (player.currentPlaylist == playlist) {
    return await player.playOrPause(playing);
  }

  // Если информация по плейлисту не загружена, то мы должны её загрузить.
  if (playlist.audios == null) {
    LoadingOverlay.of(context).show();

    try {
      await loadPlaylistData(
        playlist,
        user,
      );
    } catch (e, stackTrace) {
      // ignore: use_build_context_synchronously
      showLogErrorDialog(
        "Ошибка при загрузке информации по плейлисту для запуска трека: ",
        e,
        stackTrace,
        logger,
        context,
      );

      return;
    } finally {
      if (context.mounted) {
        LoadingOverlay.of(context).hide();
      }
    }
  }

  // Всё ок, запускаем воспроизведение.
  await player.setPlaylist(
    playlist,
    audio: playlist.audios?.randomItem(),
  );
}

/// Виджет с разделом "Ваши плейлисты"
class MyPlaylistsBlock extends StatelessWidget {
  final AppLogger logger = getLogger("MyPlaylistsBlock");

  MyPlaylistsBlock({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final UserProvider user = Provider.of<UserProvider>(context);

    final int playlistsCount = user.playlistsCount ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

        // Настоящие данные.
        if (user.regularPlaylists.isNotEmpty)
          ScrollConfiguration(
            behavior: AlwaysScrollableScrollBehavior(),
            child: SingleChildScrollView(
              // TODO: ClipBehaviour.
              scrollDirection: Axis.horizontal,
              child: Wrap(
                spacing: 8,
                children: [
                  for (ExtendedVKPlaylist playlist in user.regularPlaylists)
                    AudioPlaylistWidget(
                      backgroundUrl: playlist.photo?.photo270,
                      name: playlist.title!,
                      description: playlist.subtitle,
                      selected: player.currentPlaylist == playlist,
                      currentlyPlaying: player.playing && player.loaded,
                      onOpen: () => showDialog(
                        context: context,
                        builder: (context) => PlaylistDisplayDialog(
                          playlist: playlist,
                        ),
                      ),
                      onPlayToggle: (bool playing) => onPlaylistPlayToggle(
                        context,
                        playlist,
                        playing,
                      ),
                    ),
                ],
              ),
            ),
          ),

        // Skeleton loader.
        if (user.regularPlaylists.isEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Skeletonizer(
              child: Wrap(
                spacing: 8,
                children: [
                  for (int index = 0; index < 10; index++)
                    AudioPlaylistWidget(
                      name: fakePlaylistNames[index % fakePlaylistNames.length],
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Виджет, показывающий раздел "Плейлисты для Вас".
class RecommendedPlaylistsBlock extends StatelessWidget {
  final AppLogger logger = getLogger("RecommendedPlaylistsBlock");

  RecommendedPlaylistsBlock({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final UserProvider user = Provider.of<UserProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        ScrollConfiguration(
          behavior: AlwaysScrollableScrollBehavior(),
          child: SingleChildScrollView(
            // TODO: ClipBehaviour.
            scrollDirection: Axis.horizontal,
            child: Wrap(
              spacing: 8,
              children: [
                // Настоящие данные.
                if (user.recommendationPlaylists.isNotEmpty)
                  for (ExtendedVKPlaylist playlist
                      in user.recommendationPlaylists)
                    AudioPlaylistWidget(
                      backgroundUrl: playlist.photo!.photo270!,
                      name: playlist.title!,
                      description: playlist.subtitle,
                      useTextOnImageLayout: true,
                      selected: player.currentPlaylist == playlist,
                      currentlyPlaying: player.playing && player.loaded,
                      onOpen: () async => showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return PlaylistDisplayDialog(
                            playlist: playlist,
                          );
                        },
                      ),
                      onPlayToggle: (bool playing) => onPlaylistPlayToggle(
                        context,
                        playlist,
                        playing,
                      ),
                    ),

                // Skeleton loader.
                if (user.recommendationPlaylists.isEmpty)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Skeletonizer(
                      child: Wrap(
                        spacing: 8,
                        children: [
                          for (int index = 0; index < 9; index++)
                            AudioPlaylistWidget(
                              name: fakePlaylistNames[
                                  index % fakePlaylistNames.length],
                              description: "Playlist description here",
                              useTextOnImageLayout: true,
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Виджет, показывающий раздел "Совпадения по вкусам".
class SimillarMusicBlock extends StatelessWidget {
  final AppLogger logger = getLogger("SimillarMusicBlock");

  SimillarMusicBlock({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: Skeleton loader.
    // TODO: Доделать этот раздел.
    final UserProvider user = Provider.of<UserProvider>(context);

    const int playlistsCount = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.music_similarMusicChip,
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
        ScrollConfiguration(
          behavior: AlwaysScrollableScrollBehavior(),
          child: SingleChildScrollView(
            // TODO: ClipBehaviour.
            scrollDirection: Axis.horizontal,
            child: Wrap(
              spacing: 8,
              children: [
                for (ExtendedVKPlaylist playlist
                    in user.recommendationPlaylists)
                  AudioPlaylistWidget(
                    backgroundUrl: playlist.photo!.photo270!,
                    name: playlist.title!,
                    description: playlist.subtitle,
                    useTextOnImageLayout: true,
                    selected: player.currentPlaylist == playlist,
                    currentlyPlaying: player.playing && player.loaded,
                    onOpen: () => showDialog(
                      context: context,
                      builder: (context) => PlaylistDisplayDialog(
                        playlist: playlist,
                      ),
                    ),
                    onPlayToggle: (bool playing) => onPlaylistPlayToggle(
                      context,
                      playlist,
                      playing,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Виджет, показывающий раздел "Собрано редакцией".
class ByVKPlaylistsBlock extends StatelessWidget {
  final AppLogger logger = getLogger("ByVKPlaylistsBlock");

  ByVKPlaylistsBlock({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final UserProvider user = Provider.of<UserProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

        // Настоящие данные.
        if (user.madeByVKPlaylists.isNotEmpty)
          ScrollConfiguration(
            behavior: AlwaysScrollableScrollBehavior(),
            child: SingleChildScrollView(
              // TODO: ClipBehaviour.
              scrollDirection: Axis.horizontal,
              child: Wrap(
                spacing: 8,
                children: [
                  for (ExtendedVKPlaylist playlist in user.madeByVKPlaylists)
                    AudioPlaylistWidget(
                      backgroundUrl: playlist.photo!.photo270!,
                      name: playlist.title!,
                      selected: player.currentPlaylist == playlist,
                      currentlyPlaying: player.playing && player.loaded,
                      onOpen: () => showDialog(
                        context: context,
                        builder: (context) => PlaylistDisplayDialog(
                          playlist: playlist,
                        ),
                      ),
                      onPlayToggle: (bool playing) => onPlaylistPlayToggle(
                        context,
                        playlist,
                        playing,
                      ),
                    ),
                ],
              ),
            ),
          ),

        // Skeleton loader.
        if (user.madeByVKPlaylists.isEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Skeletonizer(
              child: Wrap(
                spacing: 8,
                children: [
                  for (int index = 0; index < 10; index++)
                    AudioPlaylistWidget(
                      name: fakePlaylistNames[index % fakePlaylistNames.length],
                    ),
                ],
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
        Text(
          AppLocalizations.of(context)!.music_allBlocksDisabledTitle,
          style: Theme.of(context).textTheme.displayMedium!.copyWith(
                fontWeight: FontWeight.w500,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(
          height: 18,
        ),
        Text(
          AppLocalizations.of(context)!.music_allBlocksDisabledDescription,
          style: Theme.of(context).textTheme.headlineSmall,
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

    ensureUserAudioAllInformation(context);
  }

  @override
  void dispose() {
    super.dispose();

    for (StreamSubscription subscription in subscriptions) {
      subscription.cancel();
    }
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

    /// Показывает [RefreshIndicator] во время загрузки данных с API ВКонтакте.
    void setLoading([bool value = true]) => setState(() => loadingData = value);

    return DeclarativeRefreshIndicator(
      onRefresh: () async {
        setLoading();

        await ensureUserAudioAllInformation(
          context,
          forceUpdate: true,
        );
        setLoading(false);
      },
      refreshing: loadingData,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(
            LogicalKeyboardKey.f5,
          ): () async {
            setLoading();

            await ensureUserAudioAllInformation(
              context,
              forceUpdate: true,
            );
            setLoading(false);
          },
          const SingleActivator(
            LogicalKeyboardKey.keyF,
            control: true,
          ): user.favoritesPlaylist != null
              ? () => showDialog(
                    context: context,
                    builder: (context) => PlaylistDisplayDialog(
                      playlist: user.favoritesPlaylist!,
                    ),
                  )
              : () {},
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(
                  isMobileLayout ? 16 : 24,
                ),
                children: [
                  // Часть интерфейса "Добро пожаловать", а так же кнопка поиска.
                  if (!isMobileLayout)
                    Row(
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
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                          child: IconButton.filledTonal(
                            onPressed: () => showDialog(
                              context: context,
                              builder: (context) => const SearchDisplayDialog(),
                            ),
                            icon: const Icon(
                              Icons.search,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (!isMobileLayout)
                    const SizedBox(
                      height: 36,
                    ),

                  // Верхняя часть интерфейса с переключателями.
                  const Focus(
                    autofocus: true,
                    skipTraversal: true,
                    canRequestFocus: true,
                    child: ChipFilters(),
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 2),

                  // Раздел "Моя музыка".
                  if (myMusicEnabled)
                    MyMusicBlock(
                      useTopButtons: isMobileLayout,
                    ),
                  if (myMusicEnabled) const SizedBox(height: 12),
                  if (myMusicEnabled) const Divider(),
                  if (myMusicEnabled) const SizedBox(height: 4),

                  // Раздел "Плейлисты".
                  if (playlistsEnabled) MyPlaylistsBlock(),
                  if (playlistsEnabled) const SizedBox(height: 12),
                  if (playlistsEnabled) const Divider(),
                  if (playlistsEnabled) const SizedBox(height: 4),

                  // Раздел "Плейлисты для Вас".
                  if (recommendedPlaylistsEnabled) RecommendedPlaylistsBlock(),
                  if (recommendedPlaylistsEnabled) const SizedBox(height: 12),
                  if (recommendedPlaylistsEnabled) const Divider(),
                  if (recommendedPlaylistsEnabled) const SizedBox(height: 4),

                  // Раздел "Совпадения по вкусам".
                  if (similarMusicChipEnabled) SimillarMusicBlock(),
                  if (similarMusicChipEnabled) const SizedBox(height: 12),
                  if (similarMusicChipEnabled) const Divider(),
                  if (similarMusicChipEnabled) const SizedBox(height: 4),

                  // Раздел "Собрано редакцией".
                  if (byVKChipEnabled) ByVKPlaylistsBlock(),
                  if (byVKChipEnabled) const SizedBox(height: 12),
                  if (byVKChipEnabled) const Divider(),
                  if (byVKChipEnabled) const SizedBox(height: 4),

                  // Случай, если пользователь отключил все возможные разделы музыки.
                  if (everythingIsDisabled) const EverythingIsDisabledBlock(),

                  // Данный SizedBox нужен, что бы плеер снизу при Mobile Layout'е не закрывал ничего важного.
                  if (player.loaded && isMobileLayout)
                    const SizedBox(
                      height: 80,
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
