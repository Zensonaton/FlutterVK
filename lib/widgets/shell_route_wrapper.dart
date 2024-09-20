import "dart:async";

import "package:audio_service/audio_service.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:just_audio/just_audio.dart";

import "../api/vk/shared.dart";
import "../consts.dart";
import "../enums.dart";
import "../main.dart";
import "../provider/color.dart";
import "../provider/download_manager.dart";
import "../provider/l18n.dart";
import "../provider/player_events.dart";
import "../provider/playlists.dart";
import "../provider/preferences.dart";
import "../provider/updater.dart";
import "../provider/user.dart";
import "../provider/vk_api.dart";
import "../routes/fullscreen_player.dart";
import "../routes/home/music.dart";
import "../routes/home/music/categories/realtime_playlists.dart";
import "../services/cache_manager.dart";
import "../services/download_manager.dart";
import "../services/image_to_color_scheme.dart";
import "../services/logger.dart";
import "../utils.dart";
import "audio_player.dart";
import "dialogs.dart";
import "download_manager_icon.dart";
import "update_dialog.dart";

/// Класс для отображения Route'ов в [BottomNavigationBar], вместе с их названиями, а так же иконками.
class NavigationItem {
  /// Путь к данному элементу.
  final String path;

  /// Страница, которая будет отображена при выборе данного элемента. Если не будет указано, то Route будет отключён.
  final WidgetBuilder? body;

  /// Иконка, которая используется на [BottomNavigationBar].
  final IconData icon;

  /// Иконка, которая используется при выборе элемента в [BottomNavigationBar]. Если не указано, то будет использоваться [icon].
  final IconData? selectedIcon;

  /// Текст, используемый в [BottomNavigationBar].
  final String label;

  /// Указывает, что данная запись будет показана и в [BottomNavigationBar] при Mobile Layout'е.
  final bool showOnMobileLayout;

  /// Опциональный список из путей, которые могут быть использованы в [GoRouter].
  final List<RouteBase> routes;

  NavigationItem({
    required this.path,
    this.body,
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.showOnMobileLayout = true,
    this.routes = const [],
  });
}

/// Обёртка для [DownloadManagerIconWidget], добавляющая анимацию появления и исчезновения этого виджета.
class DownloadManagerWrapperWidget extends HookConsumerWidget {
  const DownloadManagerWrapperWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadManager = ref.watch(downloadManagerProvider);
    ref.watch(playerLoadedStateProvider);

    final downloadStarted = downloadManager.downloadStarted;
    final progressValue = useValueListenable(downloadManager.progress);
    final shown = useState(downloadStarted);
    final timer = useRef<Timer?>(null);
    useValueChanged(downloadStarted, (_, __) {
      timer.value?.cancel();

      if (downloadStarted) {
        shown.value = true;
      } else {
        // Прячем виджет, если прошло 5 секунд после полной загрузки.
        timer.value = Timer(
          const Duration(seconds: 5),
          () => shown.value = false,
        );
      }

      return true;
    });

    const double position = 40 - downloadManagerMinimizedSize / 2;

    return AnimatedPositioned(
      curve: Curves.ease,
      duration: const Duration(
        milliseconds: 500,
      ),
      left: position + 4,
      bottom: (player.loaded ? desktopMiniPlayerHeight : 0) + position,
      child: AnimatedSlide(
        offset: Offset(
          0,
          shown.value ? 0 : 2,
        ),
        curve: Curves.ease,
        duration: const Duration(
          milliseconds: 500,
        ),
        child: RepaintBoundary(
          child: DownloadManagerIconWidget(
            progress: progressValue,
            title: downloadManager.currentTask?.smallTitle ?? "",
            onTap: () => context.go("/profile/downloadManager"),
          ),
        ),
      ),
    );
  }
}

/// Виджет, который содержит в себе [Scaffold] с [NavigationRail] или [BottomNavigationBar] в зависимости от того, какой используется Layout: Desktop ([isDesktopLayout]) или Mobile ([isMobileLayout]), а так же мини-плеер снизу ([BottomMusicPlayerWrapper]).
///
/// Данный виджет так же подписывается на некоторые события, по типу проверки на наличия новых обновлений.
class ShellRouteWrapper extends HookConsumerWidget {
  static final AppLogger logger = getLogger("ShellRouteWrapper");

  final Widget child;
  final String currentPath;
  final List<NavigationItem> navigationItems;

  const ShellRouteWrapper({
    super.key,
    required this.child,
    required this.currentPath,
    required this.navigationItems,
  });

  /// Проверяет на наличие обновлений, и дальше предлагает пользователю обновиться, если есть новое обновление.
  void checkForUpdates(WidgetRef ref, BuildContext context) async {
    final preferences = ref.read(preferencesProvider);
    final preferencesNotifier = ref.read(preferencesProvider.notifier);
    UpdateBranch updateBranch = preferences.updateBranch;

    // Отображаем уведомление о бета-обновлении, если мы находимся на бета-версии.
    if (isPrerelease && !preferences.preReleaseWarningShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (context) => const PreReleaseInstalledDialog(),
        );

        // Обновляем настройки.
        updateBranch = UpdateBranch.preReleases;
        preferencesNotifier.setUpdateBranch(updateBranch);
        preferencesNotifier.setPreReleaseWarningShown(true);
      });
    }

    // Проверяем, есть ли разрешение на обновления, а так же работу интернета.
    if (preferences.updatePolicy == UpdatePolicy.disabled ||
        !connectivityManager.hasConnection) return;

    // Проверяем на наличие обновлений.
    if (context.mounted) {
      ref.read(updaterProvider).checkForUpdates(
            context,
            allowPre: updateBranch == UpdateBranch.preReleases,
            useSnackbarOnUpdate: preferences.updatePolicy == UpdatePolicy.popup,
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);

    useEffect(
      () {
        // Проверяем на наличие обновлений, если мы не в debug-режиме.
        if (!kDebugMode) checkForUpdates(ref, context);

        // Слушаем события подключения к интернету.
        final subscription =
            connectivityManager.connectionChange.listen((bool isConnected) {
          logger.d("Network connectivity state: $isConnected");

          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: Duration(
                seconds: isConnected ? 2 : 6,
              ),
              content: Text(
                isConnected
                    ? l18n.internetConnectionRestoredDescription
                    : l18n.noInternetConnectionDescription,
              ),
            ),
          );
        });

        return subscription.cancel;
      },
      [],
    );

    final List<NavigationItem> mobileNavigationItems = useMemoized(
      () => navigationItems.where((item) => item.showOnMobileLayout).toList(),
    );

    final bool mobileLayout = isMobileLayout(context);
    final int currentIndex =
        navigationItems.indexWhere((item) => currentPath.startsWith(item.path));
    final int mobileCurrentIndex = mobileNavigationItems
        .indexWhere((item) => currentPath.startsWith(item.path));

    /// TODO: Проверка на то, что мы попали на недопустимую страницу.

    /// Обработчик выбора элемента в [NavigationRail].
    void onDestinationSelected(int index) {
      if (index == currentIndex) return;

      context.go(navigationItems[index].path);
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // NavigationRail и содержимое экрана на Desktop Layout.
          if (!mobileLayout)
            Row(
              children: [
                // NavigationRail с иконкой загрузки.
                if (!mobileLayout)
                  RepaintBoundary(
                    child: NavigationRail(
                      selectedIndex: currentIndex,
                      onDestinationSelected: onDestinationSelected,
                      labelType: NavigationRailLabelType.all,
                      destinations: [
                        for (final item in navigationItems)
                          NavigationRailDestination(
                            icon: Icon(
                              item.icon,
                            ),
                            selectedIcon: Icon(
                              item.selectedIcon ?? item.icon,
                            ),
                            label: Text(
                              item.label,
                            ),
                            disabled: item.body == null,
                          ),
                      ],
                    ),
                  ),

                // Само содержимое страницы.
                Expanded(
                  child: child,
                ),
              ],
            ),

          // Содержимое экрана на Mobile Layout.
          if (mobileLayout) child,

          // Иконка загрузки.
          if (!mobileLayout) const DownloadManagerWrapperWidget(),

          // Мини-плеер снизу.
          const RepaintBoundary(
            child: BottomMusicPlayerWrapper(),
          ),
        ],
      ),
      bottomNavigationBar: mobileLayout
          ? NavigationBar(
              selectedIndex: mobileCurrentIndex >= 0 ? mobileCurrentIndex : 2,
              onDestinationSelected: (int index) {
                final List<NavigationItem> realNavigationItems = [
                  ...mobileNavigationItems,
                ];

                // Учитываем, что у нас появляется элемент в [NavigationBar] на 2 индексе,
                // если мы находимся на странице, которая не показывается в [NavigationBar].
                if (navigationItems.any(
                  (item) =>
                      item.path == currentPath && !item.showOnMobileLayout,
                )) {
                  realNavigationItems.insert(
                    2,
                    navigationItems.firstWhere(
                      (item) => item.path == currentPath,
                    ),
                  );
                }

                // Поскольку мы используем [mobileNavigationItems] вместо [navigationItems],
                // мы должны найти реальный индекс относительно [navigationItems].
                final NavigationItem mobilePage = realNavigationItems[index];

                onDestinationSelected(
                  navigationItems.indexWhere(
                    (page) => page == mobilePage,
                  ),
                );
              },
              destinations: [
                for (final item in navigationItems)
                  if (item.showOnMobileLayout || item.path == currentPath)
                    NavigationDestination(
                      icon: Icon(
                        item.icon,
                      ),
                      selectedIcon: Icon(
                        item.selectedIcon ?? item.icon,
                      ),
                      label: item.label,
                      enabled: item.body != null,
                    ),
              ],
            )
          : null,
    );
  }
}

/// Виджет, являющийся wrapper'ом для [BottomMusicPlayer], который добавляет обработку для различных событий.
///
/// Данный виджет так же регистрирует listener'ы для некоторых событий плеера, благодаря чему появляется поддержка кэширования, получения цветов обложек и прочего.
class BottomMusicPlayerWrapper extends HookConsumerWidget {
  static final AppLogger logger = getLogger("BottomMusicPlayerWrapper");

  const BottomMusicPlayerWrapper({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackImageInfoNotifier = ref.watch(trackSchemeInfoProvider.notifier);
    final trackImageInfo = ref.watch(trackSchemeInfoProvider);
    final preferences = ref.watch(preferencesProvider);
    final playlistsNotifier = ref.watch(playlistsProvider.notifier);
    final preferencesNotifier = ref.watch(preferencesProvider.notifier);
    final l18n = ref.watch(l18nProvider);
    ref.watch(playerPlaylistModificationsProvider);
    ref.watch(playerShuffleModeEnabledProvider);
    ref.watch(playerCurrentIndexProvider);
    ref.watch(playerLoadedStateProvider);
    ref.watch(playerLoopModeProvider);
    ref.watch(playerVolumeProvider);
    ref.watch(playerStateProvider);

    /// Метод, создающий цветовую схему из обложки трека [audio], если таковая имеется, и возвращающий [ImageSchemeExtractor] в случае успеха.
    Future<ImageSchemeExtractor?> getColorScheme(ExtendedAudio audio) async {
      if (audio.thumbnail == null) return null;

      // Если цвета обложки уже были получены, и они хранятся в БД, то просто загружаем их.
      if (audio.colorCount != null) {
        logger.d("Image colors are loaded from DB");

        return trackImageInfoNotifier.fromColors(
          colorInts: audio.colorInts!,
          scoredColorInts: audio.scoredColorInts!,
          frequentColorInt: audio.frequentColorInt!,
          colorCount: audio.colorCount!,
        );
      }

      // Заставляем плеер извлекать цветовую схему из обложки трека.
      logger.d("Extracting image colors from network");

      return await trackImageInfoNotifier.fromImageProvider(
        CachedNetworkImageProvider(
          audio.smallestThumbnail!,
          cacheKey: "${audio.mediaKey}small",
          cacheManager: CachedAlbumImagesManager.instance,
        ),
      );
    }

    useEffect(
      () {
        final List<StreamSubscription> subscriptions = [
          // Слушаем события нажатия на медиа-уведомление.
          AudioService.notificationClicked.listen((tapped) {
            // logger.d("Handling player notification clicked event");

            // AudioService иногда создаёт это событие при запуске плеера. Такой случай мы игнорируем.
            // Если плеер не загружен, то ничего не делаем.
            if (!tapped || !player.loaded) return;

            openFullscreenPlayer(context);
          }),

          // Слушаем события изменения текущего трека в плеере, что бы загружать обложку, текст песни, а так же создание цветовой схемы.
          player.currentIndexStream.listen((int? index) async {
            if (index == null || !player.loaded) return;

            final preferences = ref.read(preferencesProvider);

            final playlist = player.currentPlaylist!.copyWith();
            final audio = player.currentAudio!.copyWith();

            // Пытаемся получить цвета обложки трека.
            // Здесь мы можем получить null, если обложки у трека нет.
            ImageSchemeExtractor? extractedColors = await getColorScheme(audio);

            // Загружаем метаданные трека (его обложки, текст песни, ...)
            final newAudio =
                await PlaylistCacheDownloadItem.downloadWithMetadata(
              playlistsNotifier.ref,
              playlist,
              audio,
              downloadAudio: false,
              deezerThumbnails: preferences.deezerThumbnails,
              lrcLibLyricsEnabled: preferences.lrcLibEnabled,
            );
            if (newAudio == null) return;

            // Повторно пытаемся получить цвета обложек трека, если они не были загружены ранее.
            extractedColors ??= await getColorScheme(newAudio);

            // Сохраняем новую версию трека.
            await playlistsNotifier.updatePlaylist(
              playlist.basicCopyWith(
                audiosToUpdate: [
                  newAudio.basicCopyWith(
                    colorInts: extractedColors?.colorInts,
                    scoredColorInts: extractedColors?.scoredColorInts,
                    frequentColorInt: extractedColors?.frequentColorInt,
                    colorCount: extractedColors?.colorCount,

                    // Повторяем следующие поля, поскольку они могли быть загружены в downloadWithMetadata,
                    // а .basicCopyWith проигнорирует их (превратит их в null), поэтому их нужно продублировать.
                    vkLyrics: newAudio.vkLyrics,
                    lrcLibLyrics: newAudio.lrcLibLyrics,
                    deezerThumbs: newAudio.deezerThumbs,
                  ),
                ],
              ),
              saveInDB: true,
            );
          }),

          // Слушаем события изменения текущего трека, что бы в случае, если запущен рекомендательный плейлист, мы передавали информацию об этом ВКонтакте.
          player.currentIndexStream.listen((int? index) async {
            final api = ref.read(vkAPIProvider);

            if (index == null) return;

            // Если нет доступа к интернету, то ничего не делаем.
            if (!connectivityManager.hasConnection) return;

            // Если это не рекомендуемый плейлист, то ничего не делаем.
            if (!(player.currentPlaylist?.isRecommendationTypePlaylist ??
                false)) {
              return;
            }

            // Делаем API-запрос, передавая информацию серверам ВКонтакте.
            try {
              await api.audio.sendStartEvent(player.currentAudio!.mediaKey);
            } catch (e, stackTrace) {
              logger.w(
                "Couldn't notify VK about track listening state: ",
                error: e,
                stackTrace: stackTrace,
              );
            }
          }),

          // Отдельно слушаем события изменения индекса текущего трека, что бы добавлять треки в реальном времени, если это аудио микс.
          player.currentIndexStream.listen((int? index) async {
            final AppLogger logger = getLogger("VK Mix");
            final api = ref.read(vkAPIProvider);

            if (index == null ||
                !player.loaded ||
                player.currentPlaylist?.type != PlaylistType.audioMix) return;

            final int playlistItemCount = player.currentPlaylist!.count ?? 0;
            final int remainingTracks = playlistItemCount - index;
            final int remainingTracksToAdd = clampInt(
              minMixAudiosCount - remainingTracks,
              0,
              minMixAudiosCount,
            );

            logger.d(
              "Mix index: $index/$playlistItemCount, should add $remainingTracksToAdd tracks",
            );

            // Если у нас достаточно треков в очереди, то ничего не делаем.
            if (remainingTracksToAdd <= 0) return;

            try {
              final List<Audio> response =
                  await api.audio.getStreamMixAudiosWithAlbums(
                count: remainingTracksToAdd,
              );
              assert(
                response.length == remainingTracksToAdd,
                "Invalid response length, expected $remainingTracksToAdd, got ${response.length} instead",
              );

              final List<ExtendedAudio> newAudios = response
                  .map(
                    (audio) => ExtendedAudio.fromAPIAudio(audio),
                  )
                  .toList();

              // Добавляем треки в объект плейлиста.
              await playlistsNotifier.updatePlaylist(
                player.currentPlaylist!.copyWith(
                  audiosToUpdate: newAudios,
                  count: playlistItemCount + remainingTracksToAdd,
                ),
                saveInDB: true,
              );

              // Добавляем треки в очередь воспроизведения плеера.
              for (ExtendedAudio audio in newAudios) {
                await player.addToQueueEnd(audio);
              }
            } catch (e, stackTrace) {
              logger.e(
                "Couldn't load audio mix tracks: ",
                error: e,
                stackTrace: stackTrace,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l18n.musicMixAudiosAddError(e.toString()),
                    ),
                  ),
                );
              }

              return;
            }

            logger.d(
              "Successfully added $remainingTracksToAdd tracks to mix queue (current: ${player.currentPlaylist!.count})",
            );
          }),
        ];

        return () {
          for (StreamSubscription subscription in subscriptions) {
            subscription.cancel();
          }
        };
      },
      [],
    );

    final brightness = Theme.of(context).brightness;
    final ColorScheme? scheme = useMemoized(
      () => trackImageInfo?.createScheme(
        brightness,
        schemeVariant: preferences.dynamicSchemeType,
      ),
      [brightness, trackImageInfo, preferences.dynamicSchemeType],
    );

    final bool mobileLayout = isMobileLayout(context);

    const Alignment alignment =
        Alignment.bottomLeft; // TODO: navigationPage.audioPlayerAlign,
    const bool allowBigPlayer =
        true; // TODO: navigationPage.allowBigAudioPlayer
    final double? width = mobileLayout
        ? null
        : (allowBigPlayer
            ? MediaQuery.sizeOf(context).width.clamp(500, double.infinity)
            // ignore: dead_code
            : 360);

    final bool isLoaded = player.loaded;
    final bool isRepeatEnabled = player.loopMode == LoopMode.one;
    final bool isLiked = player.smartCurrentAudio?.isLiked ?? false;
    final bool isRecommendation =
        player.currentPlaylist?.isRecommendationTypePlaylist ?? false;
    final isMixPlaylist = player.currentPlaylist?.type == PlaylistType.audioMix;

    Future<void> onLikeTap() async {
      if (!networkRequiredDialog(ref, context)) return;

      if (!player.currentAudio!.isLiked && preferences.checkBeforeFavorite) {
        if (!await checkForDuplicates(
          ref,
          context,
          player.currentAudio!,
        )) return;
      }

      try {
        await toggleTrackLike(
          player.ref,
          player.currentAudio!,
          !player.currentAudio!.isLiked,
          sourcePlaylist: player.currentPlaylist,
        );
      } on VKAPIException catch (error, stackTrace) {
        if (!context.mounted) return;

        if (error.errorCode == 15) {
          showErrorDialog(
            context,
            description: l18n.music_likeRestoreTooLate,
          );

          return;
        }

        showLogErrorDialog(
          "Error while restoring audio:",
          error,
          stackTrace,
          logger,
          context,
        );
      }
    }

    Future<void> onDislike() async {
      if (!networkRequiredDialog(ref, context)) return;

      await dislikeTrack(
        player.ref,
        player.currentAudio!,
      );

      await player.next();
    }

    void onPlayToggle() => player.togglePlay();

    void onSeek(double progress) => player.seekNormalized(progress);

    void onVolumeChange(double volume) => player.setVolume(volume);

    void onDismiss() => player.stop();

    void onFullscreen(bool viaSwipeUp) async {
      final bool fullscreenOnDesktop =
          !mobileLayout && !HardwareKeyboard.instance.isShiftPressed;

      await openFullscreenPlayer(
        context,
        fullscreenOnDesktop: fullscreenOnDesktop,
      );
    }

    void onMiniplayer() => openMiniPlayer(context);

    void onShuffleToggle() async {
      await player.toggleShuffle();

      preferencesNotifier.setShuffleEnabled(player.shuffleModeEnabled);
    }

    void onRepeatToggle() async {
      await player.toggleLoopMode();

      preferencesNotifier.setLoopModeEnabled(player.loopMode == LoopMode.one);
    }

    void onNextTrack(bool viaSwipe) => player.next();

    void onPreviousTrack(bool viaSwipe) {
      if (viaSwipe) {
        player.previous(allowSeekToBeginning: !viaSwipe);

        return;
      }

      player.smartPrevious();
    }

    return AnimatedAlign(
      duration: const Duration(
        milliseconds: 500,
      ),
      alignment: alignment,
      child: StreamBuilder<Duration>(
        stream: player.positionStream,
        builder: (BuildContext context, AsyncSnapshot<Duration> snapshot) {
          return AnimatedOpacity(
            opacity: isLoaded ? 1.0 : 0.0,
            curve: Curves.ease,
            duration: const Duration(
              milliseconds: 500,
            ),
            child: AnimatedSlide(
              offset: Offset(
                0,
                player.loaded ? 0.0 : 1.0,
              ),
              duration: const Duration(
                milliseconds: 500,
              ),
              curve: Curves.ease,
              child: Container(
                width: width,
                padding: EdgeInsets.all(
                  mobileLayout ? 8 : 0,
                ),
                child: BottomMusicPlayer(
                  audio: player.smartCurrentAudio,
                  nextAudio: player.smartNextAudio,
                  previousAudio: player.smartPreviousAudio,
                  scheme: scheme ?? Theme.of(context).colorScheme,
                  progress: player.progress,
                  volume: player.volume,
                  position: player.position,
                  duration: player.duration ?? Duration.zero,
                  isPlaying: player.playing,
                  isBuffering: player.buffering,
                  isShuffleEnabled: player.shuffleModeEnabled,
                  isRepeatEnabled: isRepeatEnabled,
                  spoilerNextTrackEnabled: preferences.spoilerNextTrack,
                  isLiked: isLiked,
                  useBigLayout: !mobileLayout,
                  onLikeTap: onLikeTap,
                  onDislike: isRecommendation ? onDislike : null,
                  onPlayToggle: onPlayToggle,
                  onSeek: onSeek,
                  onVolumeChange: onVolumeChange,
                  onDismiss: onDismiss,
                  onFullscreen: onFullscreen,
                  onMiniplayer: onMiniplayer,
                  onShuffleToggle: isMixPlaylist ? null : onShuffleToggle,
                  onRepeatToggle: onRepeatToggle,
                  onNextTrack: onNextTrack,
                  onPreviousTrack: onPreviousTrack,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
