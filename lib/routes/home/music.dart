import "dart:async";

import "package:cached_network_image/cached_network_image.dart";
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

import "../../api/vk/api.dart";
import "../../api/vk/audio/edit.dart";
import "../../api/vk/audio/search.dart";
import "../../api/vk/catalog/get_audio.dart";
import "../../api/vk/consts.dart";
import "../../api/vk/executeScripts/mass_audio_get.dart";
import "../../api/vk/shared.dart";
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
    raiseOnAPIError(response);

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
    raiseOnAPIError(response);

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
                builder: (BuildContext context,
                    AsyncSnapshot<APIAudioSearchResponse> snapshot) {
                  final List<ExtendedVKAudio>? audios =
                      snapshot.data?.response?.items
                          .map(
                            (audio) => ExtendedVKAudio.fromAudio(audio),
                          )
                          .toList();

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
                    itemCount: audios!.length,
                    itemBuilder: (BuildContext context, int index) {
                      return buildListTrackWidget(
                        context,
                        audios[index],
                        ExtendedVKPlaylist(
                          id: -1,
                          ownerID: user.id!,
                          audios: audios,
                          count: audios.length,
                          title: AppLocalizations.of(context)!
                              .music_searchPlaylistTitle,
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
  final ExtendedVKAudio audio;

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
            // Открытый трек.
            AudioTrackTile(
              audio: audio,
              showLikeButton: false,
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
                  showLikeButton: false,
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
          ),
        );
      },
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

  /// Указывает, что данный трек загружается перед тем, как начать его воспроизведение.
  final bool isLoading;

  /// Указывает, что этот трек лайкнут.
  final bool isLiked;

  /// Указывает, что кнопка для лайка должна быть показана.
  final bool showLikeButton;

  /// Указывает, что в случае, если [selected] равен true, то у данного виджета будет эффект "свечения".
  final bool glowIfSelected;

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
    this.isLoading = false,
    this.currentlyPlaying = false,
    this.isLiked = false,
    this.showLikeButton = true,
    this.glowIfSelected = false,
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
                            )
                        ],
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

  /// [ExtendedVKPlaylist.mediaKey], используемый как ключ для кэширования, а так же для [Hero]-анимации..
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

    return InkWell(
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
            SizedBox(
              height: 200,
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
                        borderRadius: BorderRadius.circular(
                          globalBorderRadius,
                        ),
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
              user.favoritesPlaylist!.audios![index],
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
  static AppLogger logger = getLogger("MyPlaylistsBlock");

  const MyPlaylistsBlock({
    super.key,
  });

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
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            physics: user.regularPlaylists.isEmpty
                ? const NeverScrollableScrollPhysics()
                : null,
            child: Wrap(
              spacing: 8,
              children: [
                // Настоящие данные.
                if (user.regularPlaylists.isNotEmpty)
                  for (ExtendedVKPlaylist playlist in user.regularPlaylists)
                    AudioPlaylistWidget(
                      backgroundUrl: playlist.photo?.photo270,
                      mediaKey: playlist.mediaKey,
                      name: playlist.title!,
                      description: playlist.subtitle,
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

                // Skeleton loader.
                if (user.regularPlaylists.isEmpty)
                  for (int index = 0; index < 10; index++)
                    Skeletonizer(
                      child: AudioPlaylistWidget(
                        name:
                            fakePlaylistNames[index % fakePlaylistNames.length],
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

/// Виджет, показывающий раздел "Плейлисты для Вас".
class RecommendedPlaylistsBlock extends StatelessWidget {
  static AppLogger logger = getLogger("RecommendedPlaylistsBlock");

  const RecommendedPlaylistsBlock({
    super.key,
  });

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
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            physics: user.recommendationPlaylists.isEmpty
                ? const NeverScrollableScrollPhysics()
                : null,
            child: Wrap(
              spacing: 8,
              children: [
                // Настоящие данные.
                if (user.recommendationPlaylists.isNotEmpty)
                  for (ExtendedVKPlaylist playlist
                      in user.recommendationPlaylists)
                    AudioPlaylistWidget(
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

                // Skeleton loader.
                if (user.recommendationPlaylists.isEmpty)
                  for (int index = 0; index < 9; index++)
                    Skeletonizer(
                      child: AudioPlaylistWidget(
                        name:
                            fakePlaylistNames[index % fakePlaylistNames.length],
                        description: "Playlist description here",
                        useTextOnImageLayout: true,
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
  static AppLogger logger = getLogger("SimillarMusicBlock");

  const SimillarMusicBlock({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: Skeleton loader.
    // TODO: Доделать этот раздел.
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
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Wrap(
              spacing: 8,
              children: [
                for (ExtendedVKPlaylist playlist
                    in user.recommendationPlaylists)
                  AudioPlaylistWidget(
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
  static AppLogger logger = getLogger("ByVKPlaylistsBlock");

  const ByVKPlaylistsBlock({
    super.key,
  });

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
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            physics: user.madeByVKPlaylists.isEmpty
                ? const NeverScrollableScrollPhysics()
                : null,
            child: Wrap(
              spacing: 8,
              children: [
                // Настоящие данные.
                if (user.madeByVKPlaylists.isNotEmpty)
                  for (ExtendedVKPlaylist playlist in user.madeByVKPlaylists)
                    AudioPlaylistWidget(
                      backgroundUrl: playlist.photo!.photo270!,
                      mediaKey: playlist.mediaKey,
                      name: playlist.title!,
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

                // Skeleton loader.
                if (user.madeByVKPlaylists.isEmpty)
                  for (int index = 0; index < 10; index++)
                    Skeletonizer(
                      child: AudioPlaylistWidget(
                        name:
                            fakePlaylistNames[index % fakePlaylistNames.length],
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

    /// Показывает [RefreshIndicator] во время загрузки данных с API ВКонтакте.
    void setLoading([bool value = true]) => setState(() => loadingData = value);

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
        child: CallbackShortcuts(
          bindings: {
            if (user.favoritesPlaylist != null)
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
            if (user.favoritesPlaylist != null)
              const SingleActivator(
                LogicalKeyboardKey.keyF,
                control: true,
              ): () => Navigator.push(
                    context,
                    Material3PageRoute(
                      builder: (context) => PlaylistInfoRoute(
                        playlist: user.favoritesPlaylist!,
                      ),
                    ),
                  )
          },
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
                                AppLocalizations.of(context)!
                                    .music_welcomeTitle(
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
                                builder: (context) =>
                                    const SearchDisplayDialog(),
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
                      const Focus(
                        autofocus: true,
                        skipTraversal: true,
                        canRequestFocus: true,
                        child: ChipFilters(
                          showLabel: false,
                        ),
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
      ),
    );
  }
}
