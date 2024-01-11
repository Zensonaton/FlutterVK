import "dart:async";
import "dart:math";

import "package:cached_network_image/cached_network_image.dart";
import "package:declarative_refresh_indicator/declarative_refresh_indicator.dart";
import "package:diacritic/diacritic.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:provider/provider.dart";
import "package:responsive_builder/responsive_builder.dart";
import "package:share_plus/share_plus.dart";
import "package:skeletonizer/skeletonizer.dart";
import "package:styled_text/styled_text.dart";

import "../../api/audio/edit.dart";
import "../../api/catalog/get_audio.dart";
import "../../api/executeScripts/mass_audio_get.dart";
import "../../api/shared.dart";
import "../../consts.dart";
import "../../main.dart";
import "../../provider/user.dart";
import "../../services/logger.dart";
import "../../utils.dart";
import "../../widgets/adaptive_dialog.dart";
import "../../widgets/error_dialog.dart";
import "../../widgets/fallback_audio_photo.dart";
import "../../widgets/loading_overlay.dart";
import "../../widgets/wip_dialog.dart";
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
      audios: response.response!.audios,
    );

    // Создаём объекты плейлистов у пользователя.
    user.allPlaylists.addAll(
      {
        for (var playlist in response.response!.playlists)
          playlist.id: ExtendedVKPlaylist.fromAudioPlaylist(playlist)
      },
    );

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
      orElse: () =>
          throw AssertionError("Блок с лайкнутыми треками не был найден"),
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

    user.allPlaylists.addAll(
      {
        for (var playlist in parseRecommendedPlaylists(response))
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
List<Audio> filterByName(
  List<Audio> audios,
  String query,
) {
  // Избавляемся от всех пробелов в запросе, а так же диакритические знаки.
  query = removeDiacritics(
    query.toLowerCase().replaceAll(
          r" ",
          "",
        ),
  );

  // Если запрос пустой, то просто возвращаем исходный массив.
  if (query.isEmpty) return audios;

  // Возвращаем список тех треков, у которых совпадает название или исполнитель.
  return audios
      .where(
        (Audio audio) => removeDiacritics(
          (("${audio.title}${audio.artist}").toLowerCase().replaceAll(
                r" ",
                "",
              )),
        ).contains(query),
      )
      .toList();
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
  ///
  /// Если информация не передаётся, то информация о плейлисте не будет показана (как это происходит на экране с показом 'любимых треков').
  final AudioPlaylist? playlist;

  /// Список треков в данном плейлисте.
  final List<Audio> audios;

  /// Если true, то сразу после открытия данного диалога фокус будет на [SearchBar].
  final bool focusSearchBarOnOpen;

  const PlaylistDisplayDialog({
    super.key,
    this.playlist,
    required this.audios,
    this.focusSearchBarOnOpen = true,
  });

  @override
  State<PlaylistDisplayDialog> createState() => _PlaylistDisplayDialogState();
}

class _PlaylistDisplayDialogState extends State<PlaylistDisplayDialog> {
  /// Контроллер, используемый для управления введённым в поле поиска текстом.
  final TextEditingController controller = TextEditingController();

  /// Подписка на изменения работы плеера.
  late final StreamSubscription<bool> subscription;

  /// FocusNode для фокуса поля поиска сразу после открытия данного диалога.
  final FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    subscription = player.stream.playing.listen((state) => setState(() {}));

    // Если у пользователя ПК, то тогда устанавливаем фокус на поле поиска.
    if (isDesktop && widget.focusSearchBarOnOpen) focusNode.requestFocus();

    // TODO: Если у пользователя играет что-то, то мы можем "отметить" трек в списке треков.
    // if (user.audioPlaybackStarted && user.player.currentTrack != null) {
    //   final int index = widget.audios.indexOf(
    //     user.player.currentTrack!,
    //   );

    //   if (index == -1) return;

    //   // Здесь должен отмечаться трек.
    // }
  }

  @override
  void dispose() {
    super.dispose();

    subscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final String searchText = controller.text;
    final List<Audio> filteredAudios = filterByName(
      widget.audios,
      searchText,
    );
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
                  if (isMobileLayout)
                    IconButton(
                      icon: Icon(
                        Icons.adaptive.arrow_back,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  Expanded(
                    child: SearchBar(
                      focusNode: focusNode,
                      controller: controller,
                      hintText: AppLocalizations.of(context)!
                          .music_searchText(widget.audios.length),
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
            if (widget.audios.isEmpty)
              Text(
                AppLocalizations.of(context)!.music_playlistEmpty,
              ),

            // У пользователя есть треки, но поиск ничего не выдал.
            if (widget.audios.isNotEmpty && filteredAudios.isEmpty)
              StyledText(
                text: AppLocalizations.of(context)!
                    .music_playlistZeroSearchResults,
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
                    final Audio audio = filteredAudios[index];

                    return Padding(
                      key: ValueKey(audio.accessKey),
                      padding: const EdgeInsets.only(
                        bottom: 8,
                      ),
                      child: AudioTrackTile(
                        selected: audio == player.currentAudio,
                        currentlyPlaying: player.state.playing,
                        audio: audio,
                        dragIndex: index,
                        onPlay: audio.isRestricted
                            ? () {
                                showErrorDialog(
                                  context,
                                  title: AppLocalizations.of(context)!
                                      .music_trackUnavailableTitle,
                                  description: AppLocalizations.of(context)!
                                      .music_trackUnavailableDescription,
                                );
                              }
                            : () async => await player.openAudioList(
                                  widget.audios,
                                  index: widget.audios.indexWhere(
                                    (Audio widgetAudio) => widgetAudio == audio,
                                  ),
                                ),
                        onPlayToggle: (bool enabled) async =>
                            await player.setPlaying(enabled),
                        onLikeToggle: () => showWipDialog(
                          context,
                          title: "Удаление лайка",
                        ),
                        onSecondaryAction: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (BuildContext context) =>
                              BottomAudioOptionsDialog(
                            audio: audio,
                          ),
                        ),
                      ),
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
  final Audio audio;

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

  @override
  void initState() {
    super.initState();

    titleController.text = widget.audio.title;
    artistController.text = widget.audio.artist;
  }

  @override
  Widget build(BuildContext context) {
    final UserProvider user = Provider.of<UserProvider>(context);

    // Создаём копию трека, засовывая в неё новые значения с новым именем трека и прочим.
    final Audio audio = Audio(
      title: titleController.text,
      artist: artistController.text,
      id: widget.audio.id,
      ownerID: widget.audio.ownerID,
      duration: widget.audio.duration,
      accessKey: widget.audio.accessKey,
      url: widget.audio.url,
      date: widget.audio.date,
      album: widget.audio.album,
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
              currentlyPlaying: player.state.playing,
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
            // TODO: Редактирование жанра. Оно уже почти реализовано, просто мне *сейчас* лень.
            // const SizedBox(height: 28),
            // DropdownMenu(
            //   label: const Text("Жанр"),
            //   onSelected: (_) => showWipDialog(
            //     context,
            //   ),
            //   initialSelection: 18, // Значение "Other".
            //   width:
            //       500 - 24 * 2, // Не очень красивое решение. Спасибо, Flutter.
            //   dropdownMenuEntries: [
            //     for (MapEntry<int, String> genre in musicGenres.entries)
            //       DropdownMenuEntry(
            //         value: genre.key,
            //         label: genre.value,
            //       ),
            //   ],
            // ),
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
                    );

                    // Проверяем, что в ответе нет ошибок.
                    if (response.error != null) {
                      throw Exception(
                        "API error ${response.error!.errorCode}: ${response.error!.errorMessage}",
                      );
                    }

                    // TODO: Обновить данные о треке у пользователя.
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
  /// Трек, над которым производится манипуляция.
  final Audio audio;

  const BottomAudioOptionsDialog({
    super.key,
    required this.audio,
  });

  @override
  State<BottomAudioOptionsDialog> createState() =>
      _BottomAudioOptionsDialogState();
}

class _BottomAudioOptionsDialogState extends State<BottomAudioOptionsDialog> {
  /// Подписка на изменения работы плеера.
  late final StreamSubscription<bool> subscription;

  @override
  void initState() {
    super.initState();

    subscription = player.stream.playing.listen((state) => setState(() {}));
  }

  @override
  void dispose() {
    super.dispose();

    subscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 500,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AudioTrackTile(
            audio: widget.audio,
            showLikeButton: false,
            selected: widget.audio == player.currentAudio,
            currentlyPlaying: player.state.playing,
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          ListTile(
            enabled: (widget.audio.album == null),
            onTap: (widget.audio.album == null)
                ? () {
                    Navigator.of(context).pop();

                    showDialog(
                      context: context,
                      builder: (BuildContext context) => TrackInfoEditDialog(
                        audio: widget.audio,
                      ),
                    );
                  }
                : null,
            leading: const Icon(
              Icons.edit,
            ),
            title: Text(
              AppLocalizations.of(context)!.music_detailsEditTitle,
            ),
          ),
          ListTile(
            onTap: () => showWipDialog(context),
            leading: const Icon(
              Icons.playlist_remove,
            ),
            title: Text(
              AppLocalizations.of(context)!.music_detailsDeleteTrackTitle,
            ),
          ),
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
          ListTile(
            onTap: () => showWipDialog(context),
            leading: const Icon(
              Icons.queue_music,
            ),
            title: Text(
              AppLocalizations.of(context)!.music_detailsPlayNextTitle,
            ),
          ),
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
  /// Объект типа [Audio], олицетворяющий данный трек.
  final Audio audio;

  /// Указывает, что этот трек сейчас выбран.
  ///
  /// Поле [currentlyPlaying] указывает, что плеер включён.
  final bool selected;

  /// Указывает, что плеер в данный момент включён.
  final bool currentlyPlaying;

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

  /// Действие, вызываемое при нажатии на кнопку "нравится" данного трека.
  final VoidCallback? onLikeToggle;

  /// Действие, вызываемое при выборе ПКМ (или зажатии) по данном элементу.
  ///
  /// Чаще всего используется для открытия контекстного меню.
  final VoidCallback? onSecondaryAction;

  const AudioTrackTile({
    super.key,
    this.selected = false,
    this.currentlyPlaying = false,
    this.showLikeButton = true,
    this.dragIndex,
    required this.audio,
    this.onPlay,
    this.onPlayToggle,
    this.onLikeToggle,
    this.onSecondaryAction,
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

    return ReorderableDragStartListener(
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
                  onTap: () {
                    // Если в данный момент играет именно этот трек, то вызываем onPlayToggle.
                    if (widget.selected) {
                      widget.onPlayToggle?.call(
                        !selectedAndPlaying,
                      );

                      return;
                    }

                    // В ином случае запускаем проигрывание этого трека.
                    widget.onPlay?.call();
                  },
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
                                    cacheKey: widget.audio.mediaKey,
                                    width: 50,
                                    height: 50,
                                    placeholder:
                                        (BuildContext context, String url) =>
                                            const FallbackAudioAvatar(),
                                  )
                                : const FallbackAudioAvatar(),
                          ),
                          if (isHovered || widget.selected)
                            Center(
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius:
                                      BorderRadius.circular(globalBorderRadius),
                                ),
                                child: Animate(
                                  onComplete: !isHovered && selectedAndPlaying
                                      ? (AnimationController controller) {
                                          controller.repeat(
                                            reverse: true,
                                          );
                                        }
                                      : null,
                                  effects: !isHovered && selectedAndPlaying
                                      ? [
                                          const FadeEffect(
                                            begin: 0.75,
                                            duration: Duration(
                                              seconds: 1,
                                            ),
                                          ),
                                          const ScaleEffect(
                                            begin: Offset(0.9, 0.9),
                                            end: Offset(1.25, 1.25),
                                            duration: Duration(
                                              seconds: 1,
                                            ),
                                          ),
                                          const ShakeEffect(
                                            duration: Duration(
                                              seconds: 1,
                                            ),
                                          ),
                                        ]
                                      : null,
                                  child: Icon(
                                    isHovered
                                        ? (selectedAndPlaying
                                            ? Icons.pause
                                            : Icons.play_arrow)
                                        : Icons.music_note,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
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
                  onPressed: widget.onLikeToggle,
                  icon: Icon(
                    Icons.favorite,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
            ],
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

  /// Указывает, что данный плейлист является рекомендательным, т.е., плейлистом по типу "Плейлист дня 1" и прочие.
  final bool isRecommendationPlaylist;

  /// Описание плейлиста.
  final String? description;

  /// Указывает, что музыка играет из этого плейлиста.
  final bool currentlyPlaying;

  /// Вызывается при открытии плейлиста во весь экран.
  final VoidCallback? onOpen;

  const AudioPlaylistWidget({
    super.key,
    this.backgroundUrl,
    required this.name,
    this.isRecommendationPlaylist = false,
    this.description,
    this.currentlyPlaying = false,
    this.onOpen,
  });

  @override
  State<AudioPlaylistWidget> createState() => _AudioPlaylistWidgetState();
}

class _AudioPlaylistWidgetState extends State<AudioPlaylistWidget> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onOpen,
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
                            placeholder: (BuildContext context, String url) =>
                                const FallbackAudioPlaylistAvatar(),
                          )
                        : const FallbackAudioPlaylistAvatar(),
                  ),

                  // Если это у нас рекомендательный плейлист, то текст должен находиться внутри изображения плейлиста.
                  if (widget.isRecommendationPlaylist)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.name,
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge!
                                .copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          if (widget.description != null)
                            Text(
                              widget.description!,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                        ],
                      ),
                    ),
                  if (isHovered || widget.currentlyPlaying)
                    Center(
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius:
                              BorderRadius.circular(globalBorderRadius),
                        ),
                        child: Icon(
                          isHovered
                              ? (widget.currentlyPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow)
                              : Icons.music_note,
                          color: Theme.of(context).colorScheme.primary,
                          size: 50,
                        ),
                      ),
                    )
                ],
              ),
            ),

            // Если это обычный плейлист, то нам нужно показать его содержимое под изображением.
            if (!widget.isRecommendationPlaylist) const SizedBox(height: 2),
            if (!widget.isRecommendationPlaylist)
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
          onSelected: (bool value) => setState(() {
            user.settings.myMusicChipEnabled = value;
            user.markUpdated();
          }),
          selected: user.settings.myMusicChipEnabled,
          label: Text(
            AppLocalizations.of(context)!.music_myMusicChip,
          ),
        ),
        FilterChip(
          onSelected: (bool value) => setState(() {
            user.settings.playlistsChipEnabled = value;
            user.markUpdated();
          }),
          selected: user.settings.playlistsChipEnabled,
          label: Text(
            AppLocalizations.of(context)!.music_myPlaylistsChip,
          ),
        ),
        if (hasRecommendations)
          FilterChip(
            onSelected: (bool value) => setState(() {
              user.settings.recommendedPlaylistsChipEnabled = value;
              user.markUpdated();
            }),
            selected: user.settings.recommendedPlaylistsChipEnabled,
            label: Text(
              AppLocalizations.of(context)!.music_recommendedPlaylistsChip,
            ),
          ),
        if (hasRecommendations)
          FilterChip(
            onSelected: (bool value) => setState(() {
              user.settings.similarMusicChipEnabled = value;
              user.markUpdated();
            }),
            selected: user.settings.similarMusicChipEnabled,
            label: Text(
              AppLocalizations.of(context)!.music_similarMusicChip,
            ),
          ),
        if (hasRecommendations)
          FilterChip(
            onSelected: (bool value) => setState(() {
              user.settings.byVKChipEnabled = value;
              user.markUpdated();
            }),
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
  const MyMusicBlock({
    super.key,
  });

  @override
  State<MyMusicBlock> createState() => _MyMusicBlockState();
}

class _MyMusicBlockState extends State<MyMusicBlock> {
  /// Подписки на изменения работы плеера.
  final List<StreamSubscription> subscriptions = [];

  @override
  void initState() {
    super.initState();

    // Если поменялось состояние паузы.
    subscriptions.add(
      player.stream.playing.listen((bool _) => setState(() {})),
    );

    // Если поменялся текущий трек.
    subscriptions.add(
      player.stream.duration.listen((Duration _) => setState(() {})),
    );
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.music_myMusicChip,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (musicCount > 0)
              const SizedBox(
                width: 8,
              ),
            if (musicCount > 0)
              Text(
                musicCount.toString(),
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onBackground
                      .withOpacity(0.75),
                ),
              ),
          ],
        ),
        const SizedBox(
          height: 14,
        ),

        // Настоящие данные.
        if (user.favoritesPlaylist?.audios != null)
          for (int index = 0; index < clampedMusicCount; index++)
            Padding(
              padding: EdgeInsets.only(
                bottom: index + 1 != clampedMusicCount ? 8 : 0,
              ),
              child: AudioTrackTile(
                audio: user.favoritesPlaylist!.audios![index],
                selected: user.favoritesPlaylist!.audios![index] ==
                    player.currentAudio,
                currentlyPlaying: player.isLoaded && player.state.playing,
                onPlay: user.favoritesPlaylist!.audios![index].isRestricted
                    ? () => showErrorDialog(
                          context,
                          title: AppLocalizations.of(context)!
                              .music_trackUnavailableTitle,
                          description: AppLocalizations.of(context)!
                              .music_trackUnavailableDescription,
                        )
                    : () async => await player.openAudioList(
                          user.favoritesPlaylist!.audios!,
                          index: index,
                        ),
                onPlayToggle: (bool enabled) async =>
                    await player.setPlaying(enabled),
                onLikeToggle: () => showWipDialog(
                  context,
                  title: "Удаление лайка",
                ),
                onSecondaryAction: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (BuildContext context) => BottomAudioOptionsDialog(
                    audio: user.favoritesPlaylist!.audios![index],
                  ),
                ),
              ),
            ),

        // Skeleton loader.
        if (user.favoritesPlaylist?.audios == null)
          for (int i = 0; i < 10; i++)
            Skeletonizer(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: i + 1 != 10 ? 8 : 0,
                ),
                child: AudioTrackTile(
                    audio: Audio(
                  id: -1,
                  ownerID: -1,
                  artist: "Artist name",
                  title: "Track name",
                  duration: 60 * 3,
                  accessKey: "",
                  url: "",
                  date: 0,
                )),
              ),
            ),

        const SizedBox(
          height: 12,
        ),

        Wrap(
          spacing: 8,
          children: [
            FilledButton.icon(
              onPressed: user.favoritesPlaylist?.audios != null
                  ? () async {
                      await player.setShuffle(true);

                      await player.openAudioList(
                        user.favoritesPlaylist!.audios!,
                        index: Random().nextInt(
                          user.favoritesPlaylist!.audios!.length,
                        ),
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
                          audios: user.favoritesPlaylist!.audios!,
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
        ),
      ],
    );
  }
}

/// Виджет с разделом "Ваши плейлисты"
class MyPlaylistsBlock extends StatelessWidget {
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
                  color: Theme.of(context)
                      .colorScheme
                      .onBackground
                      .withOpacity(0.75),
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
                  for (AudioPlaylist playlist in user.regularPlaylists)
                    AudioPlaylistWidget(
                      backgroundUrl: playlist.photo?.photo600,
                      name: playlist.title!,
                      description: playlist.subtitle,
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
                  for (int i = 0; i < 10; i++)
                    const AudioPlaylistWidget(
                      name: "Playlist",
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
                      backgroundUrl: playlist.photo!.photo600!,
                      name: playlist.title!,
                      description: playlist.subtitle,
                      isRecommendationPlaylist: true,
                      onOpen: () async {
                        // Если информация по данному плейлисту не загружена, то загружаем её.
                        if (playlist.audios == null) {
                          LoadingOverlay.of(context).show();

                          try {
                            final APIMassAudioGetResponse response =
                                await user.scriptMassAudioGetWithAlbums(
                              user.id!,
                              albumID: playlist.id,
                            );

                            // Проверяем, что в ответе нет ошибок.
                            if (response.error != null) {
                              throw Exception(
                                "API error ${response.error!.errorCode}: ${response.error!.errorMessage}",
                              );
                            }

                            playlist.audios = response.response!.audios;
                            playlist.count = response.response!.audioCount;
                          } catch (e, stackTrace) {
                            logger.e(
                              "Ошибка при открытии плейлиста: ",
                              error: e,
                              stackTrace: stackTrace,
                            );

                            if (context.mounted) {
                              showErrorDialog(context,
                                  description: e.toString());
                            }
                          } finally {
                            if (context.mounted) {
                              LoadingOverlay.of(context).hide();
                            }
                          }
                        }

                        // Убеждаемся, что данные у плейлисты и вправду загружены.
                        if (playlist.audios == null) return;
                        if (!context.mounted) return;

                        showDialog(
                          context: context,
                          builder: (BuildContext context) =>
                              PlaylistDisplayDialog(
                            audios: playlist.audios!,
                          ),
                        );
                      },
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
                          for (int i = 0; i < 9; i++)
                            const AudioPlaylistWidget(
                              name: "Playlist",
                              description: "Playlist description here",
                              isRecommendationPlaylist: true,
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
class SimillarMusicBlock extends StatefulWidget {
  const SimillarMusicBlock({
    super.key,
  });

  @override
  State<SimillarMusicBlock> createState() => _SimillarMusicBlockState();
}

class _SimillarMusicBlockState extends State<SimillarMusicBlock> {
  final ScrollController scrollController = ScrollController();

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
                  color: Theme.of(context)
                      .colorScheme
                      .onBackground
                      .withOpacity(0.75),
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
            controller: scrollController,
            child: Wrap(
              spacing: 8,
              children: [
                for (ExtendedVKPlaylist playlist
                    in user.recommendationPlaylists)
                  AudioPlaylistWidget(
                    backgroundUrl: playlist.photo!.photo600!,
                    name: playlist.title!,
                    description: playlist.subtitle,
                    isRecommendationPlaylist: true,
                    onOpen: () => showWipDialog(context),
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
class ByVKPlaylistsBlock extends StatefulWidget {
  const ByVKPlaylistsBlock({
    super.key,
  });

  @override
  State<ByVKPlaylistsBlock> createState() => _ByVKPlaylistsBlockState();
}

class _ByVKPlaylistsBlockState extends State<ByVKPlaylistsBlock> {
  final ScrollController scrollController = ScrollController();

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
              AppLocalizations.of(context)!.music_byVKChip,
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
                  color: Theme.of(context)
                      .colorScheme
                      .onBackground
                      .withOpacity(0.75),
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
            controller: scrollController,
            child: Wrap(
              spacing: 8,
              children: [
                for (ExtendedVKPlaylist playlist
                    in user.recommendationPlaylists)
                  AudioPlaylistWidget(
                    backgroundUrl: playlist.photo!.photo600!,
                    name: playlist.title!,
                    description: playlist.subtitle,
                    isRecommendationPlaylist: true,
                    onOpen: () => showWipDialog(context),
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
  @override
  void initState() {
    super.initState();

    ensureUserAudioAllInformation(context);
  }

  /// Указывает, что в данный момент загружается информация.
  ///
  /// Данное поле равно `false` в первый момент захода на экран.
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
          ): () => showDialog(
                context: context,
                builder: (context) => PlaylistDisplayDialog(
                  audios: user.favoritesPlaylist!.audios!,
                ),
              ),
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(isMobileLayout ? 16 : 24),
                children: [
                  // Часть интерфейса "Добро пожаловать".
                  if (!isMobileLayout)
                    Text(
                      AppLocalizations.of(context)!.music_welcomeTitle(
                        user.firstName!,
                      ),
                      style:
                          Theme.of(context).textTheme.displayMedium!.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                    ),
                  if (!isMobileLayout) const SizedBox(height: 36),

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
                  if (myMusicEnabled) const MyMusicBlock(),
                  if (myMusicEnabled) const SizedBox(height: 12),
                  if (myMusicEnabled) const Divider(),
                  if (myMusicEnabled) const SizedBox(height: 4),

                  // Раздел "Плейлисты".
                  if (playlistsEnabled) const MyPlaylistsBlock(),
                  if (playlistsEnabled) const SizedBox(height: 12),
                  if (playlistsEnabled) const Divider(),
                  if (playlistsEnabled) const SizedBox(height: 4),

                  // Раздел "Плейлисты для Вас".
                  if (recommendedPlaylistsEnabled) RecommendedPlaylistsBlock(),
                  if (recommendedPlaylistsEnabled) const SizedBox(height: 12),
                  if (recommendedPlaylistsEnabled) const Divider(),
                  if (recommendedPlaylistsEnabled) const SizedBox(height: 4),

                  // Раздел "Совпадения по вкусам".
                  if (similarMusicChipEnabled) const SimillarMusicBlock(),
                  if (similarMusicChipEnabled) const SizedBox(height: 12),
                  if (similarMusicChipEnabled) const Divider(),
                  if (similarMusicChipEnabled) const SizedBox(height: 4),

                  // Раздел "Собрано редакцией".
                  if (byVKChipEnabled) const ByVKPlaylistsBlock(),
                  if (byVKChipEnabled) const SizedBox(height: 12),
                  if (byVKChipEnabled) const Divider(),
                  if (byVKChipEnabled) const SizedBox(height: 4),

                  // Случай, если пользователь отключил все возможные разделы музыки.
                  if (everythingIsDisabled) const EverythingIsDisabledBlock(),

                  // Данный SizedBox нужен, что бы плеер снизу при мобильном layout'е не закрывал ничего важного.
                  if (player.isLoaded && isMobileLayout)
                    const SizedBox(
                      height: 70,
                    ),
                ],
              ),
            ),

            // Данный SizedBox нужен, что бы плеер снизу при desktop layout'е не закрывал ничего важного.
            // Мы его располагаем после ListView, что бы ScrollBar не был закрыт плеером.
            if (player.isLoaded && !isMobileLayout)
              const SizedBox(
                height: 90,
              ),
          ],
        ),
      ),
    );
  }
}
