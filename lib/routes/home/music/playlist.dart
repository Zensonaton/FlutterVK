import "dart:async";
import "dart:math";
import "dart:ui";

import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:just_audio/just_audio.dart";
import "package:provider/provider.dart";
import "package:responsive_builder/responsive_builder.dart";
import "package:skeletonizer/skeletonizer.dart";
import "package:styled_text/tags/styled_text_tag_action.dart";
import "package:styled_text/widgets/styled_text.dart";

import "../../../api/vk/api.dart";
import "../../../api/vk/executeScripts/mass_audio_get.dart";
import "../../../api/vk/shared.dart";
import "../../../consts.dart";
import "../../../main.dart";
import "../../../provider/user.dart";
import "../../../services/cache_manager.dart";
import "../../../services/logger.dart";
import "../../../utils.dart";
import "../../../widgets/dialogs.dart";
import "../../../widgets/fallback_audio_photo.dart";
import "../../home.dart";
import "../music.dart";

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
  raiseOnAPIError(response);

  playlist.audios = response.response!.audios
      .map(
        (Audio audio) => ExtendedVKAudio.fromAudio(audio),
      )
      .toList();
  playlist.count = response.response!.audioCount;
}

/// Возвращает только те [Audio], которые совпадают по названию [query].
List<ExtendedVKAudio> filterAudiosByName(
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

/// Создаёт виджет типа [AudioTrackTile] для отображения в [ListView.builder] или подобном.
///
/// [playlist] указывает, из какого [ExtendedVKPlaylist] должно запуститься воспроизведение треков при нажатии по созданному виджету трека.
Widget buildListTrackWidget(
  BuildContext context,
  ExtendedVKAudio audio,
  ExtendedVKPlaylist playlist, {
  bool addBottomPadding = true,
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
      isLiked: audio.isLiked,
      audio: audio,
      glowIfSelected: true,
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
                playlist,
                audio: audio,
              ),
      onPlayToggle: (bool enabled) => player.playOrPause(enabled),
      onLikeToggle: (bool liked) => toggleTrackLikeState(
        context,
        audio,
        !audio.isLiked,
      ),
      onSecondaryAction: () => showModalBottomSheet(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (BuildContext context) {
          return BottomAudioOptionsDialog(
            audio: audio,
          );
        },
      ),
    ),
  );
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
  final ExtendedVKPlaylist playlist;

  /// Если true, то сразу после открытия данного диалога фокус будет на [SearchBar].
  ///
  /// Если значение не указано, то оно будет зависеть от [isDesktop].
  final bool? focusSearchBarOnOpen;

  const PlaylistInfoRoute({
    super.key,
    required this.playlist,
    this.focusSearchBarOnOpen,
  });

  @override
  State<PlaylistInfoRoute> createState() => _PlaylistInfoRouteState();
}

class _PlaylistInfoRouteState extends State<PlaylistInfoRoute> {
  static AppLogger logger = getLogger("PlaylistInfoRoute");

  /// Подписки на изменения состояния воспроизведения трека.
  late final List<StreamSubscription> subscriptions;

  /// Контроллер, используемый для управления введённым в поле поиска текстом.
  final TextEditingController controller = TextEditingController();

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
      // Изменения запуска плеера.
      player.loadedStateStream.listen(
        (bool loaded) => setState(() {}),
      ),

      // Изменения состояния воспроизведения.
      player.playerStateStream.listen(
        (PlayerState state) => setState(() {}),
      ),

      // Изменения плейлиста.
      player.sequenceStateStream.listen(
        (SequenceState? state) => setState(() {}),
      ),
    ];

    // Если нам это разрешено, то устанавливаем фокус на поле поиска.
    if (widget.focusSearchBarOnOpen ?? isDesktop) focusNode.requestFocus();
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

    return Column(
      children: [
        // Внутреннее содержимое.
        Expanded(
          child: CustomScrollView(
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Информация о плейлисте в Desktop Layout'е.
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      // Изображение плейлиста.
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          globalBorderRadius,
                                        ),
                                        child: widget.playlist.photo != null
                                            ? CachedNetworkImage(
                                                imageUrl: widget
                                                    .playlist.photo!.photo270!,
                                                cacheKey:
                                                    "${widget.playlist.mediaKey}270",
                                                memCacheHeight: 200,
                                                memCacheWidth: 200,
                                                placeholder: (BuildContext
                                                            context,
                                                        String url) =>
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
                                                  AppLocalizations.of(context)!
                                                      .music_fullscreenFavoritePlaylistName,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .displayLarge!
                                                  .copyWith(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(
                                              height: 4,
                                            ),

                                            // Строка вида "100 треков • Ваш плейлист".
                                            Skeletonizer(
                                              enabled: _loading,
                                              child: Text(
                                                AppLocalizations.of(context)!
                                                    .music_playlistTracksCount(
                                                  widget.playlist.count,
                                                  playlistType,
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
                                  onPressed:
                                      !widget.playlist.isEmpty && !_loading
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
                                  color: Theme.of(context).colorScheme.primary,
                                  icon: Icon(
                                    player.currentPlaylist == widget.playlist &&
                                            player.playing
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: !widget.playlist.isEmpty && !_loading
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
                                  onPressed:
                                      !widget.playlist.isEmpty && !_loading
                                          ? () => showWipDialog(
                                                context,
                                                title: "Кэширование треков",
                                              )
                                          : null,
                                  iconSize: 38,
                                  icon: Icon(
                                    Icons.arrow_circle_down,
                                    color: !widget.playlist.isEmpty && !_loading
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onBackground
                                        : null,
                                  ),
                                ),
                              ],
                            ),

                            // Поиск.
                            Flexible(
                              child: SizedBox(
                                width: 300,
                                child: SearchBar(
                                  focusNode: focusNode,
                                  controller: controller,
                                  hintText: AppLocalizations.of(context)!
                                      .music_searchTextInPlaylist(
                                    playlistAudios.length,
                                  ),
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
                                        onPressed: () =>
                                            setState(() => controller.clear()),
                                      )
                                  ],
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
                    text: AppLocalizations.of(context)!.music_zeroSearchResults,
                    textAlign: TextAlign.center,
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
                        filteredAudios[index],
                        widget.playlist,
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
