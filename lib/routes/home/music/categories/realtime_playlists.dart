import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_cache_manager/flutter_cache_manager.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:gap/gap.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:lottie/lottie.dart";
import "package:skeletonizer/skeletonizer.dart";

import "../../../../consts.dart";
import "../../../../main.dart";
import "../../../../provider/l18n.dart";
import "../../../../provider/player_events.dart";
import "../../../../provider/playlists.dart";
import "../../../../provider/preferences.dart";
import "../../../../provider/user.dart";
import "../../../../services/cache_manager.dart";
import "../../../../services/logger.dart";
import "../../../../utils.dart";
import "../../../../widgets/music_category.dart";
import "../../../../widgets/play_pause_animated_icon.dart";
import "../playlist.dart";

/// Указывает минимальное треков из аудио микса, которое обязано быть в очереди плеера. Если очередь плейлиста состоит из меньшего количества треков, то очередь будет восполнена этим значением.
const int minMixAudiosCount = 3;

/// Fallback-виджет, отображаемый вместо аудио миксов по типу VK Mix.
class FallbackMixPlaylistWidget extends StatelessWidget {
  const FallbackMixPlaylistWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 250,
      color: Theme.of(context)
          .colorScheme
          .primaryContainer
          .withValues(alpha: 0.25),
    );
  }
}

/// Виджет, отображающий плейлист типа "VK Mix" или подобный.
class LivePlaylistWidget extends HookWidget {
  static final AppLogger logger = getLogger("LivePlaylistWidget");

  /// Название плейлиста.
  final String title;

  /// Описание плейлиста.
  final String? description;

  /// URL на Lottie-анимацию, которая используется для фона.
  ///
  /// Для кэширования и повтороного использования анимации, рекомендуется использовать [lottieCacheKey].
  final String? lottieUrl;

  /// Ключ для кэширования Lottie-анимации. Обязан быть указан, если [lottieUrl] задан.
  final String? lottieCacheKey;

  /// Указывает, что будет использоваться большой размер данного плейлиста.
  final bool bigLayout;

  /// Указывает, что музыка играет из этого плейлиста.
  final bool selected;

  /// Указывает, что плеер сейчас воспроизводит музыку.
  final bool currentlyPlaying;

  /// Действие, вызываемое при переключения паузы/возобновления при нажатии по центру плейлиста.
  ///
  /// Указывая async-метод, можно сделать анимацию загрузки, пока плеер загружает треки.
  ///
  /// Если не указывать, то возможность нажать на центр плейлиста будет выключена.
  final AsyncCallback? onPlayToggle;

  const LivePlaylistWidget({
    super.key,
    required this.title,
    this.description,
    this.lottieUrl,
    this.lottieCacheKey,
    this.bigLayout = false,
    this.selected = false,
    this.currentlyPlaying = false,
    this.onPlayToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (lottieUrl != null) {
      if (lottieCacheKey == null) {
        throw ArgumentError("Expected lottieCacheKey to be set");
      }
    }

    final lottieComposition = useState<LottieComposition?>(null);

    useEffect(
      () {
        if (lottieUrl == null) {
          return null;
        }

        Future<void> loadLottieComposition() async {
          final manager = CachedLottieAnimationsManager.instance;

          final FileInfo? info =
              await manager.getFileFromCache(lottieCacheKey!);
          final bool shouldDownload =
              info == null || info.validTill.isBefore(DateTime.now());

          if (!shouldDownload) {
            final Uint8List bytes = await info.file.readAsBytes();
            final composition = await LottieComposition.fromBytes(bytes);

            if (context.mounted) {
              lottieComposition.value = composition;
            }

            return;
          }

          final FileInfo downloadedInfo =
              await manager.downloadFile(lottieUrl!, key: lottieCacheKey);

          final Uint8List bytes = await downloadedInfo.file.readAsBytes();
          final composition = await LottieComposition.fromBytes(bytes);

          if (context.mounted) {
            lottieComposition.value = composition;
          }
        }

        loadLottieComposition();

        return null;
      },
      [lottieUrl, lottieCacheKey],
    );

    final isLoading = useState(false);

    Future<void> onPlayToggleWrapper() async {
      isLoading.value = true;

      try {
        await onPlayToggle!();
      } catch (e) {
        rethrow;
      } finally {
        if (context.mounted) isLoading.value = false;
      }
    }

    return AnimatedContainer(
      height: bigLayout ? 250 : 200,
      width: double.infinity,
      duration: const Duration(
        milliseconds: 500,
      ),
      curve: Curves.easeInOutCubicEmphasized,
      child: InkWell(
        onTap: isLoading.value ? null : onPlayToggleWrapper,
        borderRadius: BorderRadius.circular(
          globalBorderRadius,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            globalBorderRadius,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Фоновая анимация, если задана ссылка на это.
              if (lottieUrl != null)
                SizedBox(
                  width: 1200,
                  child: Lottie(
                    composition: lottieComposition.value,
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.fill,
                    addRepaintBoundary: true,
                    repeat: true,
                    animate: currentlyPlaying && selected,
                  ),
                ),

              // Заменяющий фоновый анимацию контейнер.
              if (lottieUrl == null)
                const Skeleton.keep(
                  child: FallbackMixPlaylistWidget(),
                ),

              // Текст, а так же кнопка запуска.
              SizedBox(
                width: bigLayout ? 500 : 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Запуск воспроизведения.
                    IconButton.filledTonal(
                      icon: SizedBox(
                        width: 36,
                        height: 36,
                        child: isLoading.value
                            ? Center(
                                child: SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: CircularProgressIndicator.adaptive(
                                    strokeWidth: 3.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              )
                            : selected
                                ? PlayPauseAnimatedIcon(
                                    size: 36,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  )
                                : Icon(
                                    Icons.shuffle,
                                    size: 36,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                      ),
                      onPressed: isLoading.value ? null : onPlayToggleWrapper,
                    ),
                    const Gap(12),

                    // "Слушать VK Mix".
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Gap(2),

                    // Описание плейлиста, при наличии.
                    if (description != null)
                      Text(
                        description!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Виджет, отображающий "плоский" плейлист из раздела "Какой сейчас вайб?" ВКонтакте.
class MoodPlaylistWidget extends StatelessWidget {
  /// Название плейлиста.
  final String title;

  /// Описание плейлиста. Отображается при наведении.
  final String? description;

  /// URL на изображение плейлиста.
  final String? backgroundUrl;

  /// Поле, спользуемое как ключ для кэширования [backgroundUrl].
  final String? cacheKey;

  /// Указывает, что музыка играет из этого плейлиста.
  final bool selected;

  /// Указывает, что плеер сейчас воспроизводит музыку.
  final bool currentlyPlaying;

  /// Действие, вызываемое при переключения паузы/возобновления при нажатии по центру плейлиста.
  ///
  /// Если не указывать, то возможность нажать на центр плейлиста будет выключена.
  final VoidCallback? onPlayToggle;

  const MoodPlaylistWidget({
    super.key,
    required this.title,
    this.description,
    this.backgroundUrl,
    this.cacheKey,
    this.selected = false,
    this.currentlyPlaying = false,
    this.onPlayToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (backgroundUrl != null) {
      if (cacheKey == null) {
        throw ArgumentError("Expected cacheKey to be set");
      }
    }

    final bool selectedAndPlaying = selected && currentlyPlaying;
    final int cacheWidth = MediaQuery.devicePixelRatioOf(context).round() * 200;
    final int cacheHeight = MediaQuery.devicePixelRatioOf(context).round() * 50;

    return AnimatedContainer(
      width: 200,
      height: 50,
      duration: const Duration(
        milliseconds: 500,
      ),
      curve: Curves.easeInOutCubicEmphasized,
      decoration: BoxDecoration(
        boxShadow: [
          if (selected)
            BoxShadow(
              blurRadius: 15,
              spreadRadius: -3,
              color: Theme.of(context).colorScheme.tertiary,
              blurStyle: BlurStyle.outer,
            ),
        ],
      ),
      child: InkWell(
        onTap: onPlayToggle,
        borderRadius: BorderRadius.circular(
          globalBorderRadius,
        ),
        child: Container(
          width: 200,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              globalBorderRadius,
            ),
          ),
          child: Stack(
            children: [
              // Фоновое изображение.
              ClipRRect(
                borderRadius: BorderRadius.circular(
                  globalBorderRadius,
                ),
                child: backgroundUrl != null
                    ? CachedNetworkImage(
                        imageUrl: backgroundUrl!,
                        cacheKey: cacheKey,
                        fit: BoxFit.fill,
                        width: 200,
                        height: 50,
                        memCacheWidth: cacheWidth,
                        memCacheHeight: cacheHeight,
                      )
                    : const SizedBox(
                        width: 200,
                        height: 50,
                      ),
              ),

              // Название, а так же кнопка запуска.
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 6,
                  ),
                  child: Theme(
                    data: ThemeData(
                      brightness: Brightness.dark,
                    ),
                    child: Row(
                      children: [
                        // Название плейлиста.
                        Expanded(
                          child: Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                        ),

                        // Кнопка для запуска.
                        Icon(
                          selectedAndPlaying ? Icons.pause : Icons.play_arrow,
                        ),
                      ],
                    ),
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

/// Виджет, показывающий раздел "В реальном времени".
class RealtimePlaylistsBlock extends HookConsumerWidget {
  static final AppLogger logger = getLogger("RealtimePlaylistsBlock");

  const RealtimePlaylistsBlock({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mixPlaylists = ref.watch(mixPlaylistsProvider);
    final moodPlaylists = ref.watch(moodPlaylistsProvider);
    final l18n = ref.watch(l18nProvider);
    ref.watch(playerStateProvider);
    ref.watch(playerLoadedStateProvider);

    final bool mobileLayout = isMobileLayout(context);

    return MusicCategory(
      title: l18n.realtime_playlists_chip,
      onDismiss: () {
        final preferences = ref.read(preferencesProvider.notifier);

        preferences.setRealtimePlaylistsChipEnabled(false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l18n.category_closed(
                category: l18n.realtime_playlists_chip,
              ),
            ),
            duration: const Duration(
              seconds: 5,
            ),
            action: SnackBarAction(
              label: l18n.general_restore,
              onPressed: () =>
                  preferences.setRealtimePlaylistsChipEnabled(true),
            ),
          ),
        );
      },
      children: [
        // Skeleton loader.
        if (mixPlaylists == null) ...[
          Skeletonizer(
            child: LivePlaylistWidget(
              title: "Mix playlist",
              description:
                  "Mix playlist that plays tracks adapting to your mood",
              bigLayout: !mobileLayout,
            ),
          ),
          const Gap(8),
        ],

        // Настоящие данные.
        if (mixPlaylists != null)
          for (ExtendedPlaylist playlist in mixPlaylists) ...[
            LivePlaylistWidget(
              title: playlist.title!,
              description: playlist.description,
              lottieUrl: playlist.backgroundAnimationUrl!,
              lottieCacheKey: "${playlist.mediaKey}animation",
              bigLayout: !isMobile,
              selected: player.currentPlaylist?.mediaKey == playlist.mediaKey,
              currentlyPlaying: player.playing,
              onPlayToggle: () => onMixPlayToggle(ref, playlist),
            ),
          ],

        // Содержимое плейлистов из раздела "Какой сейчас вайб?".
        if (moodPlaylists?.isNotEmpty ?? false) ...[
          const Gap(8),
          ScrollConfiguration(
            behavior: AlwaysScrollableScrollBehavior(),
            child: SizedBox(
              height: 50,
              child: ListView.separated(
                padding: EdgeInsets.zero,
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                physics: moodPlaylists == null
                    ? const NeverScrollableScrollPhysics()
                    : null,
                itemCount: moodPlaylists?.length ?? 0,
                separatorBuilder: (BuildContext context, int index) {
                  return const Gap(8);
                },
                itemBuilder: (BuildContext context, int index) {
                  // Skeleton loader.
                  if (moodPlaylists == null) {
                    return Skeletonizer(
                      child: MoodPlaylistWidget(
                        title:
                            fakePlaylistNames[index % fakePlaylistNames.length],
                      ),
                    );
                  }

                  // Настоящие данные.
                  final ExtendedPlaylist playlist = moodPlaylists[index];

                  return MoodPlaylistWidget(
                    title: playlist.title!,
                    description: playlist.description ?? playlist.subtitle,
                    backgroundUrl: playlist.photo!.photo600,
                    cacheKey: "${playlist.mediaKey}600",
                    selected:
                        player.currentPlaylist?.mediaKey == playlist.mediaKey,
                    currentlyPlaying: player.playing,
                    onPlayToggle: () => onPlaylistPlayToggle(
                      ref,
                      context,
                      playlist,
                      player.playing,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}
