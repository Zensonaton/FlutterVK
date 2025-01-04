import "dart:async";

import "package:audio_service/audio_service.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../api/vk/shared.dart";
import "../consts.dart";
import "../enums.dart";
import "../intents.dart";
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
import "../routes/home/music/categories/realtime_playlists.dart";
import "../services/cache_manager.dart";
import "../services/download_manager.dart";
import "../services/image_to_color_scheme.dart";
import "../services/logger.dart";
import "../utils.dart";
import "audio_player.dart";
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

  /// Указывает, что данная запись будет видна только в Mobile Layout'е.
  final bool mobileOnly;

  /// Опциональный список из путей, которые могут быть использованы в [GoRouter].
  final List<RouteBase> routes;

  NavigationItem({
    required this.path,
    this.body,
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.mobileOnly = false,
    this.routes = const [],
  });
}

/// Обёртка для [DownloadManagerIconWidget], добавляющая анимацию появления и исчезновения этого виджета.
class DownloadManagerWrapperWidget extends HookConsumerWidget {
  /// Длительность анимации появления/исчезновения иконки менеджера загрузок.
  static const Duration slideAnimationDuration = Duration(milliseconds: 500);

  const DownloadManagerWrapperWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadManager = ref.watch(downloadManagerProvider);
    ref.watch(playerLoadedStateProvider);

    final isLoaded = player.loaded;
    final downloadStarted = downloadManager.downloadStarted;

    final progressValue = useValueListenable(downloadManager.progress);
    final showAnimation = useAnimationController(
      duration: slideAnimationDuration,
      initialValue: downloadStarted ? 1.0 : 0.0,
    );
    useValueListenable(showAnimation);

    final timer = useRef<Timer?>(null);
    useEffect(
      () {
        timer.value?.cancel();

        if (downloadStarted) {
          showAnimation.animateTo(
            1.0,
            curve: Easing.emphasizedDecelerate,
          );
        } else {
          // Прячем виджет, если прошло 5 секунд после полной загрузки.
          timer.value = Timer(
            const Duration(seconds: 5),
            () {
              if (!context.mounted) return;

              showAnimation.animateTo(
                0.0,
                curve: Easing.emphasizedAccelerate,
              );
            },
          );
        }

        return null;
      },
      [downloadStarted],
    );

    if (showAnimation.value == 0.0) return const SizedBox();

    const double position = 40 - downloadManagerMinimizedSize / 2;
    const double left = position + 4;
    final double bottom = (isLoaded
            ? MusicPlayerWidget.desktopMiniPlayerHeightWithSafeArea(context)
            : 0) +
        position;

    return AnimatedBuilder(
      animation: showAnimation,
      builder: (context, child) {
        return Positioned(
          left: left,
          bottom: bottom,
          child: FractionalTranslation(
            translation: Offset(
              0,
              1 - showAnimation.value,
            ),
            child: Opacity(
              opacity: showAnimation.value,
              child: RepaintBoundary(
                child: DownloadManagerIconWidget(
                  progress: progressValue,
                  title: downloadManager.currentTask?.smallTitle ?? "",
                  onTap: () => context.go("/profile/download_manager"),
                ),
              ),
            ),
          ),
        );
      },
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
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        preferencesNotifier.setPreReleaseWarningShown(true);
        await showDialog(
          context: context,
          builder: (context) => const PreReleaseInstalledDialog(),
        );

        // Обновляем настройки.
        updateBranch = UpdateBranch.preReleases;
        preferencesNotifier.setUpdateBranch(updateBranch);
      });
    }

    // Проверяем, есть ли разрешение на обновления, а так же работу интернета.
    if (preferences.updatePolicy == UpdatePolicy.disabled ||
        !connectivityManager.hasConnection) {
      return;
    }

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
    final trackImageInfoNotifier = ref.watch(trackSchemeInfoProvider.notifier);
    final playlistsNotifier = ref.watch(playlistsProvider.notifier);

    final bool mobileLayout = isMobileLayout(context);

    /// Метод, загружающий данные по треку (обложки, цвета, ...) и сохраняющий их в БД.
    Future<void> loadAudioData(
      ExtendedAudio audio, {
      required bool current,
    }) async {
      final preferences = ref.read(preferencesProvider);
      final playlist = player.currentPlaylist!.copyWith();

      Future<ImageSchemeExtractor?> getColorScheme(
        ExtendedAudio audio, {
        bool setColorScheme = false,
      }) async {
        if (audio.thumbnail == null) return null;

        // Если цвета обложки уже были получены, и они хранятся в БД, то просто возвращаем их.
        if (audio.colorCount != null) {
          final extractor = ImageSchemeExtractor(
            colorInts: audio.colorInts!,
            scoredColorInts: audio.scoredColorInts!,
            frequentColorInt: audio.frequentColorInt!,
            colorCount: audio.colorCount!,
          );
          if (setColorScheme) {
            trackImageInfoNotifier.fromExtractor(extractor);
          }

          return extractor;
        }

        // Заставляем плеер извлекать цветовую схему из обложки трека.
        final extractor = await ImageSchemeExtractor.fromImageProvider(
          CachedNetworkImageProvider(
            audio.smallestThumbnail!,
            cacheKey: "${audio.mediaKey}small",
            cacheManager: CachedAlbumImagesManager.instance,
          ),
        );
        if (setColorScheme) {
          trackImageInfoNotifier.fromExtractor(extractor);
        }

        return extractor;
      }

      // Пытаемся получить цвета обложки трека.
      // Здесь мы можем получить null, если обложки у трека нет.
      ImageSchemeExtractor? extractedColors = await getColorScheme(
        audio,
        setColorScheme: current,
      );

      // Загружаем метаданные трека (его обложки, текст песни, ...)
      final newAudio = await PlaylistCacheDownloadItem.downloadWithMetadata(
        playlistsNotifier.ref,
        playlist,
        audio,
        downloadAudio: false,
        deezerThumbnails: preferences.deezerThumbnails,
        lrcLibLyricsEnabled: preferences.lrcLibEnabled,
      );
      if (newAudio == null) return;

      // Повторно пытаемся получить цвета обложек трека, если они не были загружены ранее.
      extractedColors ??= await getColorScheme(
        newAudio,
        setColorScheme: current,
      );

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
    }

    useEffect(
      () {
        // Проверяем на наличие обновлений, если мы не в debug-режиме.
        if (!kDebugMode) checkForUpdates(ref, context);

        final List<StreamSubscription> subscriptions = [
          // Обрабатываем события изменения состояния интернет-соединения.
          connectivityManager.connectionChange.listen(
            (bool isConnected) {
              logger.d("Network connectivity state: $isConnected");

              if (isConnected || !context.mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration: Duration(
                    seconds: isConnected ? 2 : 6,
                  ),
                  content: Text(
                    l18n.noInternetConnectionDescription,
                  ),
                ),
              );
            },
          ),

          // Слушаем события нажатия на медиа-уведомление.
          AudioService.notificationClicked.listen((tapped) {
            // AudioService иногда создаёт это событие при запуске плеера. Такой случай мы игнорируем.
            // Если плеер не загружен, то ничего не делаем.
            if (!tapped || !player.loaded) return;

            openFullscreenPlayer(context);
          }),

          // Слушаем события изменения текущего трека в плеере, что бы загружать метадананные трека (обложки, тексты, ...) для текущего, а потом ещё и для следующего трека.
          player.currentIndexStream.listen((int? index) async {
            if (index == null || !player.loaded) return;

            // Текущий трек.
            await loadAudioData(
              player.currentAudio!,
              current: true,
            );

            // Следующий.
            if (player.smartNextAudio != null) {
              await loadAudioData(
                player.smartNextAudio!,
                current: false,
              );
            }
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
            } catch (error, stackTrace) {
              logger.w(
                "Couldn't notify VK about track listening state: ",
                error: error,
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
                player.currentPlaylist?.type != PlaylistType.audioMix) {
              return;
            }

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
              if (response.length != remainingTracksToAdd) {
                throw Exception(
                  "Invalid response length, expected $remainingTracksToAdd, got ${response.length} instead",
                );
              }

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
            } catch (error, stackTrace) {
              logger.e(
                "Couldn't load audio mix tracks: ",
                error: error,
                stackTrace: stackTrace,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l18n.musicMixAudiosAddError(error.toString()),
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

    final List<NavigationItem> navigationItems = useMemoized(
      () => this.navigationItems.where(
        (item) {
          return !item.mobileOnly || (item.mobileOnly && mobileLayout);
        },
      ).toList(),
      [mobileLayout],
    );
    int currentIndex = clampInt(
      navigationItems.indexWhere(
        (item) => currentPath.startsWith(item.path),
      ),
      0,
      navigationItems.length,
    );

    /// Обработчик выбора элемента в [NavigationRail] либо [BottomNavigationBar].
    void onDestinationSelected(int index) {
      if (index == currentIndex) return;

      context.go(navigationItems[index].path);
      HapticFeedback.selectionClick();
    }

    final Widget wrappedChild = useMemoized(
      () {
        if (mobileLayout) {
          return Stack(
            children: [
              // Содержимое страницы, которое может меняться.
              child,

              // Плеер.
              const BottomMusicPlayerWrapper(),
            ],
          );
        }

        return Stack(
          children: [
            Column(
              children: [
                // Содержимое страницы, вместе с [NavigationRail].
                Expanded(
                  child: Row(
                    children: [
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
                ),

                // Плеер.
                const BottomMusicPlayerWrapper(),
              ],
            ),

            // Иконка загрузки.
            const DownloadManagerWrapperWidget(),
          ],
        );
      },
      [mobileLayout, currentIndex, child],
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Actions(
        actions: {
          FullscreenPlayerIntent: CallbackAction(
            onInvoke: (intent) {
              return toggleFullscreenPlayer(context);
            },
          ),
        },
        child: wrappedChild,
      ),
      bottomNavigationBar: mobileLayout
          ? NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: (int index) {
                onDestinationSelected(
                  index,
                );
              },
              destinations: [
                for (final item in navigationItems)
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

/// Виджет, являющийся wrapper'ом для [MusicPlayerWidget], который добавляет анимацию появления и исчезновения мини-плеера.
class BottomMusicPlayerWrapper extends HookConsumerWidget {
  static final AppLogger logger = getLogger("BottomMusicPlayerWrapper");

  /// Длительность анимации появления/исчезновения мини-плеера.
  static const Duration playerAnimationDuration = Duration(milliseconds: 500);

  const BottomMusicPlayerWrapper({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(playerLoadedStateProvider);

    final bool isLoaded = player.loaded;
    final animation = useAnimationController(
      duration: playerAnimationDuration,
      initialValue: isLoaded ? 1.0 : 0.0,
    );
    useValueListenable(animation);
    useEffect(
      () {
        animation.animateTo(
          isLoaded ? 1.0 : 0.0,
          curve: isLoaded
              ? Easing.emphasizedDecelerate
              : Easing.emphasizedAccelerate,
        );

        return null;
      },
      [isLoaded],
    );

    // Если плеер не загружен, то ничего не показываем.
    if (animation.value == 0.0) return const SizedBox();

    return Align(
      alignment: Alignment.bottomCenter,
      child: Opacity(
        opacity: animation.value,
        child: FractionalTranslation(
          translation: Offset(
            0.0,
            1.0 - animation.value,
          ),
          child: const MusicPlayerWidget(),
        ),
      ),
    );
  }
}
