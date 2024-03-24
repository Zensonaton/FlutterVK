import "dart:async";
import "dart:math";
import "dart:ui";

import "package:cached_network_image/cached_network_image.dart";
import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter/services.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:just_audio/just_audio.dart";
import "package:provider/provider.dart";
import "package:relative_time/relative_time.dart";
import "package:responsive_builder/responsive_builder.dart";
import "package:scroll_to_index/scroll_to_index.dart";
import "package:skeletonizer/skeletonizer.dart";
import "package:styled_text/tags/styled_text_tag_action.dart";
import "package:styled_text/widgets/styled_text.dart";

import "../../../api/vk/api.dart";
import "../../../api/vk/executeScripts/mass_audio_get.dart";
import "../../../api/vk/shared.dart";
import "../../../consts.dart";
import "../../../extensions.dart";
import "../../../main.dart";
import "../../../provider/user.dart";
import "../../../services/cache_manager.dart";
import "../../../services/logger.dart";
import "../../../utils.dart";
import "../../../widgets/dialogs.dart";
import "../../../widgets/fallback_audio_photo.dart";
import "../../../widgets/loading_overlay.dart";
import "../../home.dart";
import "../music.dart";
import "bottom_audio_options.dart";

/// Загружает информацию по указанному [playlist], возвращая новую копию плейлиста с заполненными значениями.
Future<ExtendedPlaylist> loadPlaylistData(
  ExtendedPlaylist playlist,
  UserProvider user, {
  bool forceUpdate = false,
}) async {
  // Если информация уже загружена, то ничего не делаем.
  if (!forceUpdate &&
      (playlist.audios != null &&
          playlist.isLiveData &&
          playlist.areTracksLive)) {
    return playlist;
  }

  final ExtendedPlaylist newPlaylist = ExtendedPlaylist(
    id: playlist.id,
    ownerID: playlist.ownerID,
    title: playlist.title,
    description: playlist.description,
    count: playlist.count,
    accessKey: playlist.accessKey,
    followers: playlist.followers,
    plays: playlist.plays,
    createTime: playlist.createTime,
    updateTime: playlist.updateTime,
    isFollowing: playlist.isFollowing,
    subtitle: playlist.subtitle,
    photo: playlist.photo,
    audios: playlist.audios,
    simillarity: playlist.simillarity,
    color: playlist.color,
    knownTracks: playlist.knownTracks,
    isLiveData: true,
    areTracksLive: true,
    cacheTracks: playlist.cacheTracks,
  );

  final APIMassAudioGetResponse response =
      await user.scriptMassAudioGetWithAlbums(
    playlist.ownerID,
    albumID: playlist.id,
    accessKey: playlist.accessKey,
  );
  raiseOnAPIError(response);

  newPlaylist.audios = response.response!.audios
      .map(
        (Audio audio) => ExtendedAudio.fromAPIAudio(audio),
      )
      .toSet();
  newPlaylist.count = response.response!.audioCount;
  newPlaylist.photo ??= response.response!.playlists
      .firstWhereOrNull(
        (item) => item.mediaKey == newPlaylist.mediaKey,
      )
      ?.photo;

  return newPlaylist;
}

/// Возвращает только те [Audio], которые совпадают по названию [query].
Set<ExtendedAudio> filterAudiosByName(
  Set<ExtendedAudio> audios,
  String query,
) {
  // Избавляемся от всех пробелов в запросе, а так же диакритические знаки.
  query = cleanString(query);

  // Если запрос пустой, то просто возвращаем исходный массив.
  if (query.isEmpty) return audios;

  // Возвращаем список тех треков, у которых совпадает название или исполнитель.
  return audios
      .where(
        (ExtendedAudio audio) => audio.normalizedName.contains(query),
      )
      .toSet();
}

/// Метод, вызываемый при нажатии по центру плейлиста. Данный метод либо ставит плейлист на паузу, либо загружает его информацию.
Future<void> onPlaylistPlayToggle(
  BuildContext context,
  ExtendedPlaylist playlist,
  bool playing,
) async {
  final UserProvider user = Provider.of<UserProvider>(context, listen: false);
  final AppLogger logger = getLogger("onPlaylistPlayToggle");

  // Если у нас играет этот же плейлист, то тогда мы попросту должны поставить на паузу/убрать паузу.
  if (player.currentPlaylist == playlist) {
    return await player.playOrPause(playing);
  }

  // Если информация по плейлисту не загружена, то мы должны её загрузить.
  if (playlist.audios == null ||
      playlist.isDataCached ||
      playlist.areTracksCached) {
    LoadingOverlay.of(context).show();

    try {
      final ExtendedPlaylist newPlaylist = await loadPlaylistData(
        playlist,
        user,
      );

      user.updatePlaylist(newPlaylist);
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

/// Создаёт виджет типа [AudioTrackTile] для отображения в [ListView.builder] или подобном.
///
/// [playlist] указывает, из какого [ExtendedPlaylist] должно запуститься воспроизведение треков при нажатии по созданному виджету трека.
Widget buildListTrackWidget(
  BuildContext context,
  ExtendedAudio audio,
  ExtendedPlaylist playlist, {
  bool addBottomPadding = true,
  bool showCachedIcon = false,
}) {
  return Padding(
    key: ValueKey(
      audio.mediaKey,
    ),
    padding: EdgeInsets.only(
      bottom: addBottomPadding ? 8 : 0,
    ),
    child: AudioTrackTile(
      selected: audio == player.currentAudio,
      currentlyPlaying: player.loaded && player.playing,
      isLoading: player.buffering,
      audio: audio,
      glowIfSelected: true,
      showCachedIcon: showCachedIcon,
      onAddToQueue: false
          // ignore: dead_code
          ? () async {
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
            }
          : null,
      onPlay: !audio.canPlay
          ? () => showErrorDialog(
                context,
                title:
                    AppLocalizations.of(context)!.music_trackUnavailableTitle,
                description: AppLocalizations.of(context)!
                    .music_trackUnavailableDescription,
              )
          : () => player.setPlaylist(
                playlist,
                audio: audio,
              ),
      onPlayToggle: (bool enabled) => player.playOrPause(enabled),
      onLikeToggle: (bool liked) {
        if (!networkRequiredDialog(context)) return false;

        return toggleTrackLikeState(
          context,
          audio,
          !audio.isLiked,
        );
      },
      onSecondaryAction: () => showModalBottomSheet(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (BuildContext context) {
          return BottomAudioOptionsDialog(
            audio: audio,
            playlist: playlist,
          );
        },
      ),
    ),
  );
}

/// Диалог, спрашивающий у пользователя разрешения на запуск кэширования плейлиста.
class EnableCacheDialog extends StatelessWidget {
  /// Плейлист, кэширование треков в котором пытаются включить.
  final ExtendedPlaylist playlist;

  const EnableCacheDialog({
    super.key,
    required this.playlist,
  });

  @override
  Widget build(BuildContext context) {
    final int aproxSizeMB =
        ((playlist.duration ?? Duration.zero).inMinutes * trackSizePerMin)
            .round();

    final aproxSizeString = aproxSizeMB >= 500
        ? AppLocalizations.of(context)!.trackSizeGB(aproxSizeMB / 500)
        : AppLocalizations.of(context)!.trackSizeMB(aproxSizeMB);

    return MaterialDialog(
      icon: Icons.file_download,
      title: AppLocalizations.of(context)!.music_enableTrackCachingTitle,
      text: AppLocalizations.of(context)!
          .music_enableTrackCachingDescription(playlist.count, aproxSizeString),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            AppLocalizations.of(context)!.general_no,
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            AppLocalizations.of(context)!.music_enableTrackCachingButton,
          ),
        ),
      ],
    );
  }
}

/// Диалог, предупреждающий пользователя о том, что при отключении кэширования треков будет полностью удалёно всё содержимое плейлиста с памяти устройства.
class CacheDisableWarningDialog extends StatelessWidget {
  /// Плейлист, кэш которого пытаются отключить.
  final ExtendedPlaylist playlist;

  const CacheDisableWarningDialog({
    super.key,
    required this.playlist,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialDialog(
      icon: Icons.file_download_off,
      title: AppLocalizations.of(context)!.music_disableTrackCachingTitle,
      text: AppLocalizations.of(context)!.music_disableTrackCachingDescription,
      actions: [
        // "Нет".
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(
            AppLocalizations.of(context)!.general_no,
          ),
        ),

        // "Остановить".
        if (downloadManager.isTaskRunningFor(playlist))
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              AppLocalizations.of(context)!.music_stopTrackCachingButton,
            ),
          ),

        // "Удалить".
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            AppLocalizations.of(context)!.music_disableTrackCachingButton,
          ),
        ),
      ],
    );
  }
}

/// Расширение для [SliverPersistentHeaderDelegate], предоставляющий возможность указать минимальную и максимальную высоту для Sliver'ов.
class SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  /// Минимальная высота для этого [AppBar]'а.
  final double minHeight;

  /// Максимальная высота для этого [AppBar]'а.
  final double maxHeight;

  /// Builder, используемый для создания интерфейса.
  final Function(
    BuildContext context,
    double shrinkOffset,
  ) builder;

  SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.builder,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => max(
        maxHeight,
        minHeight,
      );

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return builder(
      context,
      shrinkOffset,
    );
  }

  @override
  bool shouldRebuild(
    SliverAppBarDelegate oldDelegate,
  ) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        builder != oldDelegate.builder;
  }
}

/// Route, отображающий информацию о плейлисте: его название, треки, и прочую информацию.
class PlaylistInfoRoute extends StatefulWidget {
  /// Плейлист, информация о котором будет отображена.
  final ExtendedPlaylist playlist;

  /// Указывает трек типа [ExtendedAudio], который будет иметь фокус после открытия данного плейлиста.
  ///
  /// Если не указывать, никакой из треков иметь фокус не будет.
  final ExtendedAudio? audio;

  /// Если true, то сразу после открытия данного диалога фокус будет на [SearchBar].
  ///
  /// Если значение не указано, то оно будет зависеть от [isDesktop].
  final bool? focusSearchBarOnOpen;

  const PlaylistInfoRoute({
    super.key,
    required this.playlist,
    this.audio,
    this.focusSearchBarOnOpen,
  });

  @override
  State<PlaylistInfoRoute> createState() => _PlaylistInfoRouteState();
}

class _PlaylistInfoRouteState extends State<PlaylistInfoRoute> {
  static AppLogger logger = getLogger("PlaylistInfoRoute");

  /// Подписки на изменения состояния воспроизведения трека.
  late final List<StreamSubscription> subscriptions;

  /// Контроллер, используемый для скроллинга для определённого трека в этом плейлисте, указанного в переменной [widget.audio].
  final AutoScrollController scrollController = AutoScrollController();

  /// Контроллер, используемый для управления введённым в поле поиска текстом.
  final TextEditingController controller = TextEditingController();

  /// FocusNode для фокуса поля поиска сразу после открытия данного диалога.
  final FocusNode focusNode = FocusNode();

  /// Указывает, что в данный момент данные о плейлисте загружаются.
  bool _loading = false;

  /// Показывает [RefreshIndicator] во время загрузки данных с API ВКонтакте.
  void setLoading([bool value = true]) => setState(() => _loading = value);

  /// Загрузка данных данного плейлиста.
  Future<void> loadPlaylist() async {
    final UserProvider user = Provider.of<UserProvider>(context, listen: false);

    // Если информация по данному плейлисту не загружена, то загружаем её.
    if (widget.playlist.audios == null ||
        widget.playlist.isDataCached ||
        widget.playlist.areTracksCached && connectivityManager.hasConnection) {
      // Отображаем анимацию загрузки лишь в случае, если список треков пустой, т.е., он не был загружен с кэша.
      if (widget.playlist.audios == null) {
        setLoading();
      }

      try {
        final ExtendedPlaylist newPlaylist = await loadPlaylistData(
          widget.playlist,
          user,
        );

        user.updatePlaylist(newPlaylist);
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
        if (context.mounted) {
          setLoading(false);
        }
      }
    }
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
    logger.d("Open ${widget.playlist}");

    super.initState();

    // Загружаем данные о плейлисте, если есть доступ к интернету.
    if (connectivityManager.hasConnection) {
      loadPlaylist();
    }

    subscriptions = [
      // Изменения запуска плеера.
      player.loadedStateStream.listen(
        (bool loaded) => setState(() {}),
      ),

      // Изменения состояния воспроизведения.
      player.playerStateStream.listen(
        (PlayerState state) => setState(() {}),
      ),

      // Пауза/воспроизведение.
      player.playingStream.listen(
        (bool playing) => setState(() {}),
      ),

      // Изменения плейлиста.
      player.sequenceStateStream.listen(
        (SequenceState? state) => setState(() {}),
      ),

      // Слушаем события подключения к интернету, что бы начать загрузку треков после появления интернета.
      connectivityManager.connectionChange.listen((bool isConnected) async {
        // Если доступа к интернету нет, то ничего не делаем.
        if (!isConnected) return;

        // Если данный плейлист является плейлистом "лайкнутые треки", то его обновлять не нужно (он обновится в другом месте).
        if (widget.playlist.isFavoritesPlaylist) return;

        setLoading();

        await loadPlaylist();
        setLoading(false);
      }),
    ];

    // Если нам это разрешено, то устанавливаем фокус на поле поиска.
    if (widget.focusSearchBarOnOpen ?? isDesktop) focusNode.requestFocus();

    // Если у нас указан трек, то скроллим до него.
    if (widget.audio != null) {
      final int index =
          (widget.playlist.audios ?? {}).toList().indexOf(widget.audio!);

      if (index != -1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          scrollController.jumpTo(
            (50 + 8).toDouble() * index,
          );
        });
      }
    }

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

    final Set<ExtendedAudio> playlistAudios = widget.playlist.audios ?? {};
    final Set<ExtendedAudio> filteredAudios =
        filterAudiosByName(playlistAudios, controller.text);

    final bool isMobileLayout =
        getDeviceType(MediaQuery.of(context).size) == DeviceScreenType.mobile;

    final double horizontalPadding = isMobileLayout ? 16 : 24;
    final double verticalPadding = isMobileLayout ? 0 : 30;

    final String playlistType = widget.playlist.isRecommendationsPlaylist
        ? AppLocalizations.of(context)!.music_recommendationPlaylistTitle
        : (widget.playlist.isFavoritesPlaylist ||
                (widget.playlist.ownerID == user.id! &&
                    !widget.playlist.isFollowing))
            ? AppLocalizations.of(context)!.music_ownedPlaylistTitle
            : AppLocalizations.of(context)!.music_savedPlaylistTitle;

    final bool hasTracksLoaded = !widget.playlist.isEmpty && !_loading;

    return Column(
      children: [
        // Внутреннее содержимое.
        Expanded(
          child: Stack(
            children: [
              // Само содержимое плейлиста.
              CustomScrollView(
                controller: scrollController,
                slivers: [
                  // AppBar, дополнительно содержащий информацию о данном плейлисте.
                  SliverLayoutBuilder(
                    builder: (
                      BuildContext context,
                      SliverConstraints constraints,
                    ) {
                      final isExpanded =
                          constraints.scrollOffset < 280 && !isMobileLayout;

                      return SliverAppBar(
                        pinned: true,
                        expandedHeight: isMobileLayout ? null : 260,
                        elevation: 0,
                        title: isExpanded
                            ? null
                            : Text(
                                widget.playlist.title ??
                                    AppLocalizations.of(context)!
                                        .music_fullscreenFavoritePlaylistName,
                              ),
                        centerTitle: true,
                        flexibleSpace: isMobileLayout
                            ? null
                            : FlexibleSpaceBar(
                                background: Padding(
                                  padding: EdgeInsets.only(
                                    left: horizontalPadding,
                                    right: horizontalPadding,
                                    top: verticalPadding + 30,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Информация о плейлисте в Desktop Layout'е.
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          // Изображение плейлиста.
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              globalBorderRadius,
                                            ),
                                            child: widget.playlist.photo != null
                                                ? CachedNetworkImage(
                                                    imageUrl: widget.playlist
                                                        .photo!.photo270!,
                                                    cacheKey:
                                                        "${widget.playlist.mediaKey}270",
                                                    memCacheHeight: 200,
                                                    memCacheWidth: 200,
                                                    placeholder: (
                                                      BuildContext context,
                                                      String url,
                                                    ) =>
                                                        const FallbackAudioPlaylistAvatar(),
                                                    cacheManager:
                                                        CachedNetworkImagesManager
                                                            .instance,
                                                  )
                                                : FallbackAudioPlaylistAvatar(
                                                    favoritesPlaylist: widget
                                                        .playlist
                                                        .isFavoritesPlaylist,
                                                  ),
                                          ),
                                          const SizedBox(
                                            width: 24,
                                          ),

                                          // Название плейлиста, количество треков в нём.
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Название плейлиста.
                                                Text(
                                                  widget.playlist.title ??
                                                      AppLocalizations.of(
                                                        context,
                                                      )!
                                                          .music_fullscreenFavoritePlaylistName,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .displayLarge!
                                                      .copyWith(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(
                                                  height: 4,
                                                ),

                                                // Описание плейлиста, при наличии.
                                                if (widget
                                                        .playlist.description !=
                                                    null)
                                                  Text(
                                                    widget
                                                        .playlist.description!,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onBackground,
                                                    ),
                                                  ),
                                                if (widget
                                                        .playlist.description !=
                                                    null)
                                                  const SizedBox(
                                                    height: 4,
                                                  ),

                                                // Строка вида "100 треков • Ваш плейлист, 25 часов".
                                                // TODO: Написать свою функцию для форматирования времени.
                                                Skeletonizer(
                                                  enabled: _loading,
                                                  child: Text(
                                                    AppLocalizations.of(
                                                      context,
                                                    )!
                                                        .music_bottomPlaylistInfo(
                                                      widget.playlist.count,
                                                      playlistType,
                                                      RelativeTime.locale(
                                                        Localizations.localeOf(
                                                          context,
                                                        ),
                                                        timeUnits: [
                                                          TimeUnit.hour,
                                                          TimeUnit.minute,
                                                        ],
                                                        numeric: true,
                                                      ).format(
                                                        DateTime.now().add(
                                                          widget.playlist
                                                                  .duration ??
                                                              Duration.zero,
                                                        ),
                                                      ),
                                                    ),
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onBackground
                                                          .withOpacity(0.75),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      );
                    },
                  ),

                  // Row с действиями с данным плейлистом.
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: clampDouble(
                        verticalPadding - 8 * 2,
                        0,
                        100,
                      ),
                    ),
                    sliver: SliverPersistentHeader(
                      pinned: true,
                      delegate: SliverAppBarDelegate(
                        minHeight: 54 + 8 * 2,
                        maxHeight: 54 + 8 * 2,
                        builder: (BuildContext context, double shrinkOffset) {
                          return Container(
                            color: Theme.of(context).colorScheme.background,
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Кнопка запуска воспроизведения треков из плейлиста.
                                Row(
                                  children: [
                                    IconButton.filled(
                                      onPressed: !widget.playlist.isEmpty &&
                                              !_loading
                                          ? () async {
                                              // Если у нас уже запущен этот же плейлист, то переключаем паузу/воспроизведение.
                                              if (player.currentPlaylist ==
                                                  widget.playlist) {
                                                await player.togglePlay();

                                                return;
                                              }

                                              await player.setShuffle(true);

                                              await player.setPlaylist(
                                                widget.playlist,
                                                audio: widget.playlist.audios!
                                                    .randomItem(),
                                              );
                                            }
                                          : null,
                                      iconSize: 38,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      icon: Icon(
                                        player.currentPlaylist ==
                                                    widget.playlist &&
                                                player.playing
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        color: hasTracksLoaded
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onPrimary
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 6,
                                    ),

                                    // Кнопка для загрузки треков в кэш.
                                    IconButton(
                                      onPressed: hasTracksLoaded
                                          ? () async {
                                              bool cacheTracks =
                                                  widget.playlist.cacheTracks ??
                                                      false;

                                              // Пользователь пытается включить кэширование с выключенным интернетом, запрещаем ему такое.
                                              if (!cacheTracks &&
                                                  !networkRequiredDialog(
                                                    context,
                                                  )) return;

                                              // Пользователь пытается включить кэширование, спрашиваем, уверен ли он в своих намерениях.
                                              if (!cacheTracks) {
                                                final bool dialogResult =
                                                    await showDialog(
                                                          context: context,
                                                          builder: (
                                                            BuildContext
                                                                context,
                                                          ) {
                                                            return EnableCacheDialog(
                                                              playlist: widget
                                                                  .playlist,
                                                            );
                                                          },
                                                        ) ??
                                                        false;

                                                // Если пользователь нажал на "нет", то выходим.
                                                if (!dialogResult ||
                                                    !context.mounted) return;
                                              }

                                              // Если кэширование уже включено, то спрашиваем у пользователя, хочет ли он отменить его и удалить треки.
                                              bool removeTracksFromCache =
                                                  false;
                                              if (cacheTracks) {
                                                // Если плеер воспроизводит этот же плейлист, то мы не должны позволить пользователю удалить кэш.
                                                if (player.currentPlaylist ==
                                                    widget.playlist) {
                                                  showErrorDialog(
                                                    context,
                                                    title: AppLocalizations.of(
                                                      context,
                                                    )!
                                                        .music_disableTrackCachingUnavailableTitle,
                                                    description: AppLocalizations
                                                            .of(context)!
                                                        .music_disableTrackCachingUnavailableDescription,
                                                  );

                                                  return;
                                                }

                                                // Спрашимаем у пользователя, хочет ли он отключить кэширование.
                                                //  true - да, отключаем с удалением.
                                                //  false - да, отключаем без удаления треков.
                                                //  null - нет.
                                                final bool? dialogResult =
                                                    await showDialog(
                                                  context: context,
                                                  builder: (
                                                    BuildContext context,
                                                  ) {
                                                    return CacheDisableWarningDialog(
                                                      playlist: widget.playlist,
                                                    );
                                                  },
                                                );

                                                if (dialogResult == null) {
                                                  return;
                                                }

                                                removeTracksFromCache =
                                                    dialogResult;
                                              }

                                              // Включаем или отключаем кэширование.
                                              cacheTracks = !cacheTracks;
                                              widget.playlist.cacheTracks =
                                                  cacheTracks;

                                              user.markUpdated(false);
                                              await appStorage.savePlaylist(
                                                widget.playlist.asDBPlaylist,
                                              );

                                              // Запускаем задачу по кэшированию плейлиста.
                                              if (!cacheTracks &&
                                                  context.mounted) {
                                                LoadingOverlay.of(context)
                                                    .show();
                                              }

                                              // Если пользователь просто попросил остановить загрузку, то помечаем, что у плейлиста нет кэша, а так же останавливаем задачу.
                                              if (!cacheTracks &&
                                                  !removeTracksFromCache) {
                                                await downloadManager
                                                    .getCacheTask(
                                                      widget.playlist,
                                                    )
                                                    ?.cancelCaching();

                                                return;
                                              }

                                              try {
                                                await downloadManager
                                                    .cachePlaylist(
                                                  widget.playlist,
                                                  user: user,
                                                  cache: widget.playlist
                                                          .cacheTracks ??
                                                      false,
                                                  onTrackCached:
                                                      (ExtendedAudio audio) {
                                                    if (!context.mounted) {
                                                      return;
                                                    }

                                                    user.markUpdated(false);
                                                  },
                                                );
                                              } catch (e, stackTrace) {
                                                logger.e(
                                                  "Ошибка при кэшировании плейлиста: ",
                                                  error: e,
                                                  stackTrace: stackTrace,
                                                );
                                              } finally {
                                                if (!cacheTracks &&
                                                    context.mounted) {
                                                  LoadingOverlay.of(context)
                                                      .hide();
                                                }
                                              }

                                              setState(() {});
                                            }
                                          : null,
                                      iconSize: 38,
                                      icon: downloadManager
                                              .isTaskRunningFor(widget.playlist)
                                          ? const SizedBox(
                                              width: 28,
                                              height: 28,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 3.5,
                                              ),
                                            )
                                          : Icon(
                                              Icons.arrow_circle_down,
                                              color: hasTracksLoaded
                                                  ? ((widget.playlist
                                                              .cacheTracks ??
                                                          false)
                                                      ? Theme.of(context)
                                                          .colorScheme
                                                          .primary
                                                      : Theme.of(context)
                                                          .colorScheme
                                                          .onBackground)
                                                  : null,
                                            ),
                                    ),
                                    const SizedBox(
                                      width: 6,
                                    ),
                                  ],
                                ),

                                // Поиск.
                                Flexible(
                                  child: SizedBox(
                                    width: 300,
                                    child: CallbackShortcuts(
                                      bindings: {
                                        const SingleActivator(
                                          LogicalKeyboardKey.escape,
                                        ): () => controller.clear(),
                                        if (hasTracksLoaded)
                                          const SingleActivator(
                                            LogicalKeyboardKey.enter,
                                          ): () async {
                                            // Если у нас уже запущен этот же трек, то переключаем паузу/воспроизведение.
                                            if (player.currentAudio ==
                                                filteredAudios.first) {
                                              await player.togglePlay();

                                              return;
                                            }

                                            await player.setPlaylist(
                                              widget.playlist,
                                              audio: filteredAudios.first,
                                            );
                                          },
                                      },
                                      child: TextField(
                                        focusNode: focusNode,
                                        controller: controller,
                                        enabled: hasTracksLoaded,
                                        onChanged: (String query) =>
                                            setState(() {}),
                                        decoration: InputDecoration(
                                          hintText:
                                              AppLocalizations.of(context)!
                                                  .music_searchTextInPlaylist(
                                            playlistAudios.length,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              globalBorderRadius,
                                            ),
                                          ),
                                          prefixIconColor: Theme.of(context)
                                              .colorScheme
                                              .onBackground
                                              .withOpacity(
                                                hasTracksLoaded ? 1.0 : 0.5,
                                              ),
                                          prefixIcon: const Icon(
                                            Icons.search,
                                          ),
                                          suffixIcon: controller.text.isNotEmpty
                                              ? Padding(
                                                  padding:
                                                      const EdgeInsetsDirectional
                                                          .only(
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
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // У пользователя нет треков в данном плейлисте.
                  if (playlistAudios.isEmpty && !_loading)
                    SliverToBoxAdapter(
                      child: Text(
                        AppLocalizations.of(context)!.music_playlistEmpty,
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // У пользователя есть треки, но поиск ничего не выдал.
                  if (playlistAudios.isNotEmpty &&
                      filteredAudios.isEmpty &&
                      !_loading)
                    SliverToBoxAdapter(
                      child: StyledText(
                        text: AppLocalizations.of(context)!
                            .music_zeroSearchResults,
                        textAlign: TextAlign.center,
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
                      ),
                    ),

                  // Содержимое плейлиста.
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) {
                          // Если ничего не загружено, то отображаем Skeleton Loader вместо реального трека.
                          if (_loading) {
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
                          }

                          if (index == filteredAudios.length) {
                            // Данный SizedBox нужен, что бы плеер снизу при Mobile Layout'е не закрывал ничего важного.
                            return const SizedBox(
                              key: ValueKey(null),
                              height: 76,
                            );
                          }

                          return buildListTrackWidget(
                            context,
                            filteredAudios.elementAt(index),
                            widget.playlist,
                            showCachedIcon: true,
                          );
                        },
                        childCount: _loading
                            ? widget.playlist.count
                            : filteredAudios.length +
                                (isMobileLayout && player.loaded ? 1 : 0),
                      ),
                    ),
                  ),
                ],
              ),

              // FAB, располагаемый поверх всего интерфейса при Mobile Layout'е, если играет не этот плейлист.
              if (isMobileLayout && player.currentPlaylist != widget.playlist)
                Align(
                  alignment: Alignment.bottomRight,
                  child: AnimatedPadding(
                    padding: const EdgeInsets.all(8).copyWith(
                      bottom: player.loaded ? 84 : null,
                    ),
                    duration: const Duration(
                      milliseconds: 500,
                    ),
                    curve: Curves.ease,
                    child: FloatingActionButton.extended(
                      onPressed: () async {
                        await player.setShuffle(true);

                        await player.setPlaylist(
                          widget.playlist,
                          audio: widget.playlist.audios!.randomItem(),
                        );
                      },
                      label: Text(
                        AppLocalizations.of(context)!.music_shuffleAndPlay,
                      ),
                      icon: const Icon(
                        Icons.shuffle,
                      ),
                    ),
                  ),
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
    );
  }
}
