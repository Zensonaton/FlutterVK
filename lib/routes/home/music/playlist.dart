import "dart:async";
import "dart:math";
import "dart:ui";

import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter/services.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:gap/gap.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:relative_time/relative_time.dart";
import "package:scroll_to_index/scroll_to_index.dart";
import "package:skeletonizer/skeletonizer.dart";
import "package:styled_text/tags/styled_text_tag_action.dart";
import "package:styled_text/widgets/styled_text.dart";

import "../../../api/vk/shared.dart";
import "../../../consts.dart";
import "../../../main.dart";
import "../../../provider/l18n.dart";
import "../../../provider/player_events.dart";
import "../../../provider/playlists.dart";
import "../../../provider/user.dart";
import "../../../services/cache_manager.dart";
import "../../../services/logger.dart";
import "../../../utils.dart";
import "../../../widgets/audio_track.dart";
import "../../../widgets/dialogs.dart";
import "../../../widgets/fallback_audio_photo.dart";
import "../../../widgets/loading_overlay.dart";

/// Возвращает только те [Audio], которые совпадают по названию [query].
List<ExtendedAudio> filterAudiosByName(
  List<ExtendedAudio> audios,
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
      .toList();
}

/// Метод, вызываемый при нажатии по центру плейлиста. Данный метод либо ставит плейлист на паузу, либо загружает его информацию.
Future<void> onPlaylistPlayToggle(
  WidgetRef ref,
  BuildContext context,
  ExtendedPlaylist playlist,
  bool playing,
) async {
  // Если у нас играет этот же плейлист, то тогда мы попросту должны поставить на паузу/убрать паузу.
  if (player.currentPlaylist == playlist) {
    return await player.togglePlay();
  }

  // Если информация по плейлисту не загружена, то мы должны её загрузить.
  await ref.read(playlistsProvider.notifier).loadPlaylist(playlist);

  // Всё ок, запускаем воспроизведение.
  await player.setPlaylist(playlist, randomTrack: true);
}

/// Диалог, спрашивающий у пользователя разрешения на запуск кэширования плейлиста.
class EnableCacheDialog extends ConsumerWidget {
  /// Плейлист, кэширование треков в котором пытаются включить.
  final ExtendedPlaylist playlist;

  const EnableCacheDialog({
    super.key,
    required this.playlist,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);

    final int aproxSizeMB =
        ((playlist.duration ?? Duration.zero).inMinutes * trackSizePerMin)
            .round();

    final aproxSizeString = aproxSizeMB >= 500
        ? l18n.trackSizeGB(aproxSizeMB / 500)
        : l18n.trackSizeMB(aproxSizeMB);

    return MaterialDialog(
      icon: Icons.file_download,
      title: l18n.music_enableTrackCachingTitle,
      text: l18n.music_enableTrackCachingDescription(
        playlist.count,
        aproxSizeString,
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(false),
          child: Text(
            l18n.general_no,
          ),
        ),
        FilledButton(
          onPressed: () => context.pop(true),
          child: Text(
            l18n.music_enableTrackCachingButton,
          ),
        ),
      ],
    );
  }
}

/// Диалог, предупреждающий пользователя о том, что при отключении кэширования треков будет полностью удалёно всё содержимое плейлиста с памяти устройства.
class CacheDisableWarningDialog extends ConsumerWidget {
  /// Плейлист, кэш которого пытаются отключить.
  final ExtendedPlaylist playlist;

  const CacheDisableWarningDialog({
    super.key,
    required this.playlist,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);

    return MaterialDialog(
      icon: Icons.file_download_off,
      title: l18n.music_disableTrackCachingTitle,
      text: l18n.music_disableTrackCachingDescription,
      actions: [
        // "Нет".
        TextButton(
          onPressed: () => context.pop(),
          child: Text(
            l18n.general_no,
          ),
        ),

        // "Остановить".
        if (downloadManager.isTaskRunningFor(playlist))
          TextButton(
            onPressed: () => context.pop(false),
            child: Text(
              l18n.music_stopTrackCachingButton,
            ),
          ),

        // "Удалить".
        FilledButton(
          onPressed: () => context.pop(true),
          child: Text(
            l18n.music_disableTrackCachingButton,
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
  final Function(BuildContext context, double shrinkOffset) builder;

  SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.builder,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => max(maxHeight, minHeight);

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
  bool shouldRebuild(SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        builder != oldDelegate.builder;
  }
}

/// Route, отображающий информацию о плейлисте: его название, треки, и прочую информацию.
class PlaylistInfoRoute extends HookConsumerWidget {
  static final AppLogger logger = getLogger("PlaylistInfoRoute");

  /// ID владельца плейлиста.
  final int ownerID;

  /// ID плейлиста.
  final int id;

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
    required this.ownerID,
    required this.id,
    this.audio,
    this.focusSearchBarOnOpen,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlist = ref.watch(getPlaylistProvider(ownerID, id))!;
    final user = ref.watch(userProvider);
    final l18n = ref.watch(l18nProvider);
    ref.watch(playerLoadedStateProvider);
    ref.watch(playerStateProvider);

    final scrollController = useMemoized(() => AutoScrollController());
    final searchController = useTextEditingController();
    final focusNode = useFocusNode();
    useValueListenable(searchController);

    useEffect(
      () {
        logger.d("Open $playlist");

        final playlistsNotifier = ref.read(playlistsProvider.notifier);
        Future<void> loadPlaylist() => playlistsNotifier.loadPlaylist(playlist);

        // Загружаем данные о плейлисте, если есть доступ к интернету.
        StreamSubscription? subscription;
        if (connectivityManager.hasConnection) {
          loadPlaylist();
        } else {
          // Если доступа к интернету нет, то ничего не делаем.
          subscription = connectivityManager.connectionChange
              .listen((bool isConnected) async {
            if (!isConnected) return;

            await loadPlaylist();
          });
        }

        // Если нам это разрешено, то устанавливаем фокус на поле поиска.
        if (focusSearchBarOnOpen ?? isDesktop) focusNode.requestFocus();

        // Если у нас указан трек, то скроллим до него.
        if (audio != null) {
          final int index = (playlist.audios ?? []).indexOf(audio!);

          if (index != -1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              scrollController.jumpTo(
                (50 + 8).toDouble() * index,
              );
            });
          }
        }

        return subscription?.cancel;
      },
      [],
    );

    final List<ExtendedAudio> playlistAudios = playlist.audios ?? [];
    final List<ExtendedAudio> filteredAudios = useMemoized(
      () => filterAudiosByName(playlistAudios, searchController.text),
      [searchController.text, playlistAudios],
    );

    final bool mobileLayout = isMobileLayout(context);

    final double horizontalPadding = mobileLayout ? 16 : 24;
    final double verticalPadding = mobileLayout ? 0 : 30;

    final bool loading = !playlist.areTracksLive;

    final String playlistType = playlist.isRecommendationsPlaylist
        ? l18n.music_recommendationPlaylistTitle
        : (playlist.isFavoritesPlaylist ||
                (playlist.ownerID == user.id && !playlist.isFollowing))
            ? l18n.music_ownedPlaylistTitle
            : l18n.music_savedPlaylistTitle;

    final bool hasTracksLoaded = !playlist.isEmpty && !loading;

    void onCacheTap() async {
      bool cacheTracks = playlist.cacheTracks ?? false;

      // Пользователь пытается включить кэширование с выключенным интернетом, запрещаем ему такое.
      if (!cacheTracks &&
          !networkRequiredDialog(
            ref,
            context,
          )) return;

      // Пользователь пытается включить кэширование, спрашиваем, уверен ли он в своих намерениях.
      if (!cacheTracks) {
        final bool dialogResult = await showDialog(
              context: context,
              builder: (
                BuildContext context,
              ) {
                return EnableCacheDialog(
                  playlist: playlist,
                );
              },
            ) ??
            false;

        // Если пользователь нажал на "нет", то выходим.
        if (!dialogResult || !context.mounted) return;
      }

      // Если кэширование уже включено, то спрашиваем у пользователя, хочет ли он отменить его и удалить треки.
      bool removeTracksFromCache = false;
      if (cacheTracks) {
        // Если плеер воспроизводит этот же плейлист, то мы не должны позволить пользователю удалить кэш.
        if (player.currentPlaylist == playlist) {
          showErrorDialog(
            context,
            title: l18n.music_disableTrackCachingUnavailableTitle,
            description: AppLocalizations.of(context)!
                .music_disableTrackCachingUnavailableDescription,
          );

          return;
        }

        // Спрашимаем у пользователя, хочет ли он отключить кэширование.
        //  true - да, отключаем с удалением.
        //  false - да, отключаем без удаления треков.
        //  null - нет.
        final bool? dialogResult = await showDialog(
          context: context,
          builder: (
            BuildContext context,
          ) {
            return CacheDisableWarningDialog(
              playlist: playlist,
            );
          },
        );

        if (dialogResult == null) {
          return;
        }

        removeTracksFromCache = dialogResult;
      }

      // Включаем или отключаем кэширование.
      cacheTracks = !cacheTracks;
      // playlist.cacheTracks = cacheTracks;

      // user.markUpdated(false);
      await appStorage.savePlaylist(
        playlist.asDBPlaylist,
      );

      // Запускаем задачу по кэшированию плейлиста.
      if (!cacheTracks && context.mounted) {
        LoadingOverlay.of(context).show();
      }

      // Если пользователь просто попросил остановить загрузку, то помечаем, что у плейлиста нет кэша, а так же останавливаем задачу.
      if (!cacheTracks && !removeTracksFromCache) {
        await downloadManager
            .getCacheTask(
              playlist,
            )
            ?.cancelCaching();

        return;
      }

      try {
        await downloadManager.cachePlaylist(
          playlist,
          // user: user,
          cache: playlist.cacheTracks ?? false,
          onTrackCached: (ExtendedAudio audio) {
            if (!context.mounted) {
              return;
            }

            // user.markUpdated(false);
          },
        );
      } catch (e, stackTrace) {
        logger.e(
          "Playlist caching error: ",
          error: e,
          stackTrace: stackTrace,
        );
      } finally {
        if (!cacheTracks && context.mounted) {
          LoadingOverlay.of(context).hide();
        }
      }
    }

    void onPlayTapped() async {
      // Если у нас уже запущен этот же плейлист, то переключаем паузу/воспроизведение.
      if (player.currentPlaylist == playlist) {
        await player.togglePlay();

        return;
      }

      await player.setShuffle(true);

      await player.setPlaylist(playlist, randomTrack: true);
    }

    void onSearchClear() => searchController.clear();

    void onSearchSubmitted(String? value) async {
      // Если у нас уже запущен этот же трек, то переключаем паузу/воспроизведение.
      if (player.currentAudio == filteredAudios.first) {
        await player.togglePlay();

        return;
      }

      await player.setPlaylist(
        playlist,
        index: playlist.audios!.indexOf(filteredAudios.first),
      );
    }

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
                          constraints.scrollOffset < 280 && !mobileLayout;

                      return SliverAppBar(
                        pinned: true,
                        expandedHeight: mobileLayout ? null : 260,
                        elevation: 0,
                        title: isExpanded
                            ? null
                            : Text(
                                playlist.title ??
                                    l18n.music_fullscreenFavoritePlaylistName,
                              ),
                        centerTitle: true,
                        flexibleSpace: mobileLayout
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
                                            child: playlist.photo != null
                                                ? CachedNetworkImage(
                                                    imageUrl: playlist
                                                        .photo!.photo270!,
                                                    cacheKey:
                                                        "${playlist.mediaKey}270",
                                                    memCacheHeight: (200 *
                                                            MediaQuery
                                                                .devicePixelRatioOf(
                                                              context,
                                                            ))
                                                        .round(),
                                                    memCacheWidth: (200 *
                                                            MediaQuery
                                                                .devicePixelRatioOf(
                                                              context,
                                                            ))
                                                        .round(),
                                                    placeholder: (
                                                      BuildContext context,
                                                      String url,
                                                    ) {
                                                      return const FallbackAudioPlaylistAvatar();
                                                    },
                                                    cacheManager:
                                                        CachedNetworkImagesManager
                                                            .instance,
                                                  )
                                                : FallbackAudioPlaylistAvatar(
                                                    favoritesPlaylist: playlist
                                                        .isFavoritesPlaylist,
                                                  ),
                                          ),
                                          const Gap(24),

                                          // Название плейлиста, количество треков в нём.
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Название плейлиста.
                                                SelectableText(
                                                  playlist.title ??
                                                      l18n.music_fullscreenFavoritePlaylistName,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .displayLarge!
                                                      .copyWith(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                ),
                                                const Gap(4),

                                                // Описание плейлиста, при наличии.
                                                if (playlist.description !=
                                                    null)
                                                  SelectableText(
                                                    playlist.description!,
                                                    style: TextStyle(
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurface
                                                          .withOpacity(0.9),
                                                    ),
                                                  ),
                                                if (playlist.description !=
                                                    null)
                                                  const Gap(4),

                                                // Строка вида "100 треков • Ваш плейлист, 25 часов".
                                                // TODO: Написать свою функцию для форматирования времени.
                                                Skeletonizer(
                                                  enabled: loading,
                                                  child: Text(
                                                    l18n.music_bottomPlaylistInfo(
                                                      playlist.count,
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
                                                          playlist.duration ??
                                                              Duration.zero,
                                                        ),
                                                      ),
                                                    ),
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurface
                                                          .withOpacity(0.8),
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
                            color: Theme.of(context).colorScheme.surface,
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
                                      onPressed: !playlist.isEmpty && !loading
                                          ? onPlayTapped
                                          : null,
                                      iconSize: 38,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      icon: Icon(
                                        player.currentPlaylist == playlist &&
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
                                    const Gap(6),

                                    // Кнопка для загрузки треков в кэш.
                                    IconButton(
                                      iconSize: 38,
                                      icon: downloadManager
                                              .isTaskRunningFor(playlist)
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
                                                  ? ((playlist.cacheTracks ??
                                                          false)
                                                      ? Theme.of(context)
                                                          .colorScheme
                                                          .primary
                                                      : Theme.of(context)
                                                          .colorScheme
                                                          .onSurface)
                                                  : null,
                                            ),
                                      onPressed:
                                          hasTracksLoaded ? onCacheTap : null,
                                    ),
                                    const Gap(6),
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
                                        ): onSearchClear,
                                      },
                                      child: TextField(
                                        controller: searchController,
                                        focusNode: focusNode,
                                        enabled: hasTracksLoaded,
                                        onSubmitted: onSearchSubmitted,
                                        decoration: InputDecoration(
                                          hintText:
                                              l18n.music_searchTextInPlaylist(
                                            playlistAudios.length,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              globalBorderRadius,
                                            ),
                                          ),
                                          prefixIconColor: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(
                                                hasTracksLoaded ? 1.0 : 0.5,
                                              ),
                                          prefixIcon: const Icon(
                                            Icons.search,
                                          ),
                                          suffixIcon: searchController
                                                  .text.isNotEmpty
                                              ? Padding(
                                                  padding:
                                                      const EdgeInsetsDirectional
                                                          .only(end: 12),
                                                  child: IconButton(
                                                    icon: const Icon(
                                                      Icons.close,
                                                    ),
                                                    onPressed: onSearchClear,
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
                  if (playlistAudios.isEmpty && !loading)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                        child: Text(
                          l18n.music_playlistEmpty,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                  // У пользователя есть треки, но поиск ничего не выдал.
                  if (playlistAudios.isNotEmpty &&
                      filteredAudios.isEmpty &&
                      !loading)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                        ),
                        child: StyledText(
                          text: l18n.music_zeroSearchResults,
                          textAlign: TextAlign.center,
                          tags: {
                            "click": StyledTextActionTag(
                              (String? text, Map<String?, String?> attrs) =>
                                  onSearchClear(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          },
                        ),
                      ),
                    ),

                  // Содержимое плейлиста.
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    sliver: SliverList.separated(
                      itemCount:
                          loading ? playlist.count : filteredAudios.length,
                      separatorBuilder: (BuildContext context, int index) {
                        return const Gap(8);
                      },
                      itemBuilder: (BuildContext context, int index) {
                        // Если ничего не загружено, то отображаем Skeleton Loader вместо реального трека.
                        if (loading) {
                          return Skeletonizer(
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
                          );
                        }

                        return buildListTrackWidget(
                          ref,
                          context,
                          filteredAudios.elementAt(index),
                          playlist,
                          showCachedIcon: true,
                        );
                      },
                    ),
                  ),

                  // Данный Gap нужен, что бы плеер снизу при Mobile Layout'е не закрывал ничего важного.
                  if (player.loaded && mobileLayout)
                    const SliverGap(mobileMiniPlayerHeight),

                  // Небольшой Gap, что бы интерфейс был не слишком сжат.
                  const SliverGap(8),
                ],
              ),

              // FAB, располагаемый поверх всего интерфейса при Mobile Layout'е, если играет не этот плейлист.
              if (mobileLayout && player.currentPlaylist != playlist)
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
                      label: Text(
                        l18n.music_shuffleAndPlay,
                      ),
                      icon: const Icon(
                        Icons.shuffle,
                      ),
                      onPressed: onPlayTapped,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Данный Gap нужен, что бы плеер снизу при Desktop Layout'е не закрывал ничего важного.
        // Мы его располагаем после ListView, что бы ScrollBar не был закрыт плеером.
        if (player.loaded && !mobileLayout) const Gap(desktopMiniPlayerHeight),
      ],
    );
  }
}
