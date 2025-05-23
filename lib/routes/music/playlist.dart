import "dart:async";
import "dart:math";
import "dart:ui";

import "package:cached_network_image/cached_network_image.dart";
import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:gap/gap.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:humanize_duration/humanize_duration.dart";
import "package:skeletonizer/skeletonizer.dart";
import "package:styled_text/tags/styled_text_tag_action.dart";
import "package:styled_text/widgets/styled_text.dart";

import "../../api/vk/shared.dart";
import "../../consts.dart";
import "../../enums.dart";
import "../../extensions.dart";
import "../../main.dart";
import "../../provider/color.dart";
import "../../provider/download_manager.dart";
import "../../provider/l18n.dart";
import "../../provider/player.dart";
import "../../provider/playlists.dart";
import "../../provider/preferences.dart";
import "../../provider/user.dart";
import "../../provider/vk_api.dart";
import "../../services/cache_manager.dart";
import "../../services/download_manager.dart";
import "../../services/logger.dart";
import "../../services/player/subscribers/audio_mix.dart";
import "../../utils.dart";
import "../../widgets/audio_player.dart";
import "../../widgets/audio_track.dart";
import "../../widgets/dialogs.dart";
import "../../widgets/fallback_audio_photo.dart";
import "../../widgets/loading_button.dart";
import "../../widgets/play_pause_animated.dart";
import "../../widgets/shortcuts_propagator.dart";

/// Проверяет, подходит ли [Audio] под запрос [query].
///
/// Учтите, что данный метод не делает нормализацию [query] (т.е., [cleanString])
bool isAudioMatchesQuery(ExtendedAudio audio, String query) {
  if (query.isEmpty) return true;

  return audio.normalizedName.contains(query);
}

/// Возвращает только те [Audio], которые совпадают по названию [query].
///
/// Для сверки названия используется метод [isAudioMatchesQuery].
List<ExtendedAudio> filterAudiosByName(
  List<ExtendedAudio> audios,
  String query,
) {
  query = cleanString(query);

  if (query.isEmpty) return audios;

  // Возвращаем список тех треков, у которых совпадает название или исполнитель.
  return audios
      .where(
        (ExtendedAudio audio) => isAudioMatchesQuery(audio, query),
      )
      .toList();
}

/// Метод, вызываемый при нажатии по центру плейлиста.
///
/// Данный метод либо ставит плейлист на паузу, либо загружает его информацию.
Future<void> onPlaylistPlayToggle(
  WidgetRef ref,
  BuildContext context,
  ExtendedPlaylist playlist,
  bool playing,
) async {
  final player = ref.read(playerProvider);
  final playlists = ref.read(playlistsProvider.notifier);
  final preferences = ref.read(preferencesProvider);

  // Переключение паузы, если тот же плейлист.
  if (player.playlist?.mediaKey == playlist.mediaKey) {
    return await player.togglePlay();
  }

  // Если информация по плейлисту не загружена, то мы должны её загрузить.
  final newPlaylist = await playlists.loadPlaylist(playlist);

  // Всё ок, запускаем воспроизведение.
  if (preferences.shuffleOnPlay) {
    await player.setShuffle(true);
  }
  await player.setPlaylist(
    newPlaylist,
    randomAudio: true,
  );
}

/// Метод, вызываемый при нажатии нажатии по аудио микс-плейлисту (VK Mix).
///
/// Данный метод либо ставит плейлист на паузу, либо возобновляет воспроизведение.
Future<void> onMixPlayToggle(
  WidgetRef ref,
  ExtendedPlaylist playlist,
) async {
  final player = ref.read(playerProvider);
  final api = ref.read(vkAPIProvider);
  final playlists = ref.read(playlistsProvider.notifier);

  if (playlist.type != PlaylistType.audioMix) {
    throw Exception(
      "onMixPlayToggle can only be called for audio mix playlists",
    );
  }

  // Переключение паузы, если тот же плейлист.
  if (player.playlist?.mediaKey == playlist.mediaKey) {
    return player.togglePlay();
  }

  final List<Audio> response = await api.audio.getStreamMixAudiosWithAlbums(
    count: AudioMixPlayerSubscriber.requiredMixAudiosCount,
  );

  final update = await playlists.updatePlaylist(
    playlist.basicCopyWith(
      audios: response
          .map(
            (audio) => ExtendedAudio.fromAPIAudio(audio),
          )
          .toList(),
      count: response.length,
    ),
  );

  // Всё ок, запускаем воспроизведение.
  await player.setShuffle(false);
  await player.setPlaylist(update.playlist);
}

/// Диалог, предупреждающий пользователя о том, что при отключении кэширования треков будет полностью удалёно всё содержимое плейлиста с памяти устройства.
///
/// Возвращает:
/// - `true`, если пользователь согласился на удаление.
/// - `false`, если пользователь остановил загрузку.
/// - `null`, если пользователь передумал.
class DeleteCacheDialog extends ConsumerWidget {
  /// Плейлист, кэш которого пытаются удалить.
  final ExtendedPlaylist playlist;

  const DeleteCacheDialog({
    super.key,
    required this.playlist,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);

    final int count = playlist.audios!
        .where(
          (audio) => audio.isCached ?? false,
        )
        .length;
    final int sizeBytes = playlist.audios!
        .where(
          (audio) => (audio.isCached ?? false) && (audio.cachedSize ?? 0) > 0,
        )
        .fold(
          0,
          (prev, audio) => prev + audio.cachedSize!,
        );
    final int sizeMB = sizeBytes ~/ 1024 ~/ 1024;
    final size = sizeMB >= 500
        ? l18n.general_filesize_gb(
            value: sizeMB / 500,
          )
        : l18n.general_filesize_mb(
            value: sizeMB,
          );

    return MaterialDialog(
      icon: Icons.file_download_off,
      title: l18n.disable_download_title,
      text: l18n.disable_download_desc(
        count: count,
        size: size,
      ),
      actions: [
        // "Нет".
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            l18n.general_no,
          ),
        ),

        // TODO: "Остановить".
        // if (downloadManager.isTaskRunningFor(playlist))
        //   TextButton(
        //     onPressed: () => context.pop(false),
        //     child: Text(
        //       l18n.stop_downloading_button,
        //     ),
        //   ),

        // "Удалить".
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            l18n.delete_downloaded_button,
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
    return SizedBox.expand(
      child: builder(
        context,
        shrinkOffset,
      ),
    );
  }

  @override
  bool shouldRebuild(SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        builder != oldDelegate.builder;
  }
}

/// Виджет, отображающий кнопку для кэширования плейлиста.
class CachePlaylistButtonWidget extends HookConsumerWidget {
  /// Плейлист, для которого изображена эта иконка.
  final ExtendedPlaylist playlist;

  /// Размер иконки.
  final double size;

  /// Ключ, используемый у [DownloadTask], по которому может быть извлечена информация о загрузке.
  final String? taskKey;

  /// Метод, вызываемый при нажатии на кнопку.
  final VoidCallback onTap;

  const CachePlaylistButtonWidget({
    super.key,
    this.size = 38,
    required this.playlist,
    this.taskKey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task =
        taskKey != null ? ref.watch(downloadTaskByIDProvider(taskKey!)) : null;

    // Если задача не была найдена, то ничего не делаем.
    if (task == null) {
      return IconButton(
        iconSize: size,
        icon: Icon(
          playlist.cacheTracks ?? false
              ? Icons.offline_pin
              : Icons.arrow_circle_down,
          color: playlist.cacheTracks ?? false
              ? ColorScheme.of(context).secondary
              : ColorScheme.of(context).onSurface,
        ),
        onPressed: onTap,
      );
    }

    final progress = useValueListenable(task.progress);

    final scheme = ColorScheme.of(context);

    // FIXME: Данный виджет стоит переписать, поскольку тут происходит какие-то странные, не имеющие смысла вещи.
    return SizedBox(
      width: size * 1.5,
      height: size * 1.5,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(
            milliseconds: 250,
          ),
          child: Stack(
            key: const ValueKey(
              false,
            ),
            alignment: Alignment.center,
            children: [
              // Анимация загрузки.
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: progress,
                )
                    .animate(
                      onComplete: (controller) => controller.loop(),
                    )
                    .rotate(
                      duration: const Duration(
                        seconds: 2,
                      ),
                      begin: 0,
                      end: 1,
                    ),
              ),

              // Прогресс загрузки.
              AnimatedOpacity(
                curve: Curves.easeInOutCubicEmphasized,
                duration: const Duration(
                  milliseconds: 500,
                ),
                opacity: progress > 0.0 ? 1.0 : 0.0,
                child: Text(
                  "${(progress * 100).round()}%",
                  style: TextStyle(
                    color: scheme.primary,
                    fontSize: 12,
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

/// Виджет, отображающий информацию о данном плейлисте (его название, ...) для [PlaylistRoute].
class MobilePlaylistInfoWidget extends ConsumerWidget {
  /// [ExtendedPlaylist], данные которого будут показаны.
  final ExtendedPlaylist playlist;

  /// Цветовая схема, извлечённая из цветов плейлиста.
  final ColorScheme? scheme;

  /// Высота блока с информацией.
  final double infoBoxHeight;

  const MobilePlaylistInfoWidget({
    super.key,
    required this.playlist,
    this.scheme,
    required this.infoBoxHeight,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);

    final safeScheme = scheme ?? ColorScheme.of(context);

    final String playlistName =
        playlist.title ?? l18n.general_favorites_playlist;

    return SliverToBoxAdapter(
      child: SizedBox(
        height: infoBoxHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
          ),
          child: Column(
            children: [
              // Название плейлиста.
              Text(
                playlistName,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: safeScheme.onSurface,
                ),
              ),

              // Описание плейлиста, если таковое есть.
              if (playlist.description != null) ...[
                Text(
                  playlist.description!,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: TextStyle(
                    color: safeScheme.onSurface.withValues(alpha: 0.9),
                  ),
                ),
                const Gap(4),
              ],

              // Пояснение того, что это за плейлист.
              PlaylistTypeDescriptionWidget(
                playlist: playlist,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ряд из кнопок управления плейлиста для [PlaylistRoute].
class MobileControlButtonsWidget extends HookConsumerWidget {
  /// Размер иконки, используемой у кнопок.
  static const double buttonSize = 56;

  /// [ExtendedPlaylist], для которого отображаются кнопки.
  final ExtendedPlaylist playlist;

  /// [ScrollController], используемый для отслеживания прокрутки.
  final ScrollController scrollController;

  /// Максимальный размер для данного [AppBar], когда он полностью раскрыт.
  final double maxAppBarHeight;

  /// Минимальный размер для данного [AppBar], когда он полностью свёрнут.
  final double minAppBarHeight;

  /// Высота блока с информацией.
  final double infoBoxHeight;

  /// Указывает то, лайкнут ли этот плейлист.
  final bool isLiked;

  /// Метод, вызываемый при нажатии на кнопку "лайка" плейлиста слева.
  ///
  /// Если не указано, то кнопка не будет отображена.
  ///
  /// Поле [isLiked] указывает, какая иконка будет отображена.
  final AsyncCallback? onLikePressed;

  /// Метод, вызываемый при нажатии на кнопку воспроизведения.
  final VoidCallback? onPlayPausePressed;

  /// Метод, вызываемый при нажатии на кнопку кэширования плейлиста справа.
  ///
  /// Если не указано, то кнопка не будет отображена.
  final VoidCallback? onCachePressed;

  const MobileControlButtonsWidget({
    super.key,
    required this.playlist,
    required this.scrollController,
    required this.maxAppBarHeight,
    required this.minAppBarHeight,
    required this.infoBoxHeight,
    this.isLiked = false,
    this.onLikePressed,
    this.onPlayPausePressed,
    this.onCachePressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(playerProvider);
    final preferences = ref.watch(preferencesProvider);
    ref.watch(playerIsPlayingProvider);

    useListenable(scrollController.position);

    final scheme = ColorScheme.of(context);

    final double finalPosition = minAppBarHeight - buttonSize / 2;
    double positionFromTop = maxAppBarHeight;
    double otherButtonOpacity = 1.0;

    // Если по какой-то причине у нас нет клиента, то возвращаем стандартную позицию.
    if (scrollController.hasClients) {
      final double offset = scrollController.offset;

      final double buttonCenterPosition = infoBoxHeight - buttonSize / 2;

      // Другие кнопки должны становиться прозрачными после скроллинга большого AppBar'а.
      otherButtonOpacity =
          (1.0 + (maxAppBarHeight - minAppBarHeight - offset) / infoBoxHeight)
              .clamp(0.0, 1.0);

      // Если пользователь прокрутил плейлист, закрыв AppBar, то ставим кнопку на статичную позицию.
      positionFromTop =
          offset > (maxAppBarHeight - finalPosition + buttonCenterPosition)
              ? finalPosition
              : maxAppBarHeight - offset + buttonCenterPosition;
    }

    const double realButtonSize = buttonSize - 8 * 2;

    final bool isSelected = player.playlist?.ownerID == playlist.ownerID &&
        player.playlist?.id == playlist.id;

    return Positioned(
      top: positionFromTop,
      child: SizedBox(
        width: 300,
        child: RepaintBoundary(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Кнопка для лайка плейлиста, при наличии.
              SizedBox(
                width: buttonSize,
                height: buttonSize,
                child: (otherButtonOpacity > 0 && onLikePressed != null)
                    ? Opacity(
                        opacity: otherButtonOpacity,
                        child: LoadingIconButton(
                          icon: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_outline,
                            color: isLiked ? scheme.primary : null,
                          ),
                          iconSize: realButtonSize,
                          onPressed: onLikePressed,
                        ),
                      )
                    : null,
              ),

              // Кнопка для воспроизведения/паузы.
              IconButton.filled(
                icon: isSelected
                    ? PlayPauseAnimatedIcon(
                        color: scheme.onPrimary,
                      )
                    : Icon(
                        preferences.shuffleOnPlay
                            ? Icons.shuffle
                            : Icons.play_arrow,
                        color: scheme.onPrimary,
                      ),
                iconSize: realButtonSize,
                onPressed: onPlayPausePressed,
                color: scheme.primary,
              ),

              // Кнопка для кэширования плейлиста.
              SizedBox(
                width: buttonSize,
                height: buttonSize,
                child: (otherButtonOpacity > 0 && onCachePressed != null)
                    ? Opacity(
                        opacity: otherButtonOpacity,
                        child: CachePlaylistButtonWidget(
                          size: realButtonSize,
                          playlist: playlist,
                          taskKey: playlist.mediaKey,
                          onTap: onCachePressed!,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Виджет, отображающий список из треков для [PlaylistRoute].
class PlaylistAudiosListWidget extends HookConsumerWidget {
  /// Расстояние между треками.
  static const double tracksSpacing = 8.0;

  /// [ExtendedPlaylist], треки которого будут отображены.
  final ExtendedPlaylist playlist;

  /// [TextEditingController] для поля поиска.
  final TextEditingController searchController;

  /// Значение, используемое как горизонтальный Padding.
  final double horizontalPadding;

  const PlaylistAudiosListWidget({
    super.key,
    required this.playlist,
    required this.searchController,
    this.horizontalPadding = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);
    ref.watch(playerIsPlayingProvider);
    ref.watch(playerIsBufferingProvider);
    ref.watch(playerIsLoadedProvider);

    useValueListenable(searchController);

    final List<ExtendedAudio> playlistAudios = playlist.audios ?? [];

    final String searchText = searchController.text;
    final List<ExtendedAudio> filteredAudios = useMemoized(
      () => filterAudiosByName(playlistAudios, searchText),
      [searchText, playlistAudios],
    );

    final bool isFavoritesPlaylist = playlist.type == PlaylistType.favorites;
    final bool hasTracksList = playlist.audios != null;

    final bool mobileLayout = isMobileLayout(context);

    // У пользователя нет треков в данном плейлисте.
    if (hasTracksList && playlistAudios.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
          ),
          child: Text(
            l18n.playlist_is_empty,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // У пользователя есть треки, но поиск ничего не выдал.
    if (hasTracksList && playlistAudios.isNotEmpty && filteredAudios.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
          ),
          child: StyledText(
            text: l18n.playlist_search_zero_results,
            textAlign: TextAlign.center,
            tags: {
              "click": StyledTextActionTag(
                (_, __) => searchController.clear(),
                style: TextStyle(
                  color: ColorScheme.of(context).primary,
                ),
              ),
            },
          ),
        ),
      );
    }

    // Содержимое плейлиста.
    return SliverSafeArea(
      top: false,
      bottom: false,
      sliver: SliverFixedExtentList.builder(
        itemCount: hasTracksList ? filteredAudios.length : playlist.count,
        itemExtent: 50 + tracksSpacing,
        itemBuilder: (BuildContext context, int index) {
          // Skeleton loader.
          if (!hasTracksList) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: tracksSpacing,
                left: mobileLayout ? 0 : horizontalPadding,
                right: mobileLayout ? 0 : horizontalPadding,
              ),
              child: Skeletonizer(
                child: AudioTrackTile(
                  audio: ExtendedAudio.fake(index),
                  dense: mobileLayout,
                  roundedCorners: !mobileLayout,
                  padding: mobileLayout
                      ? EdgeInsets.symmetric(horizontal: horizontalPadding)
                      : null,
                ),
              ),
            );
          }

          final audio = filteredAudios[index];

          return Padding(
            padding: EdgeInsets.only(
              bottom: tracksSpacing,
              left: mobileLayout ? 0 : horizontalPadding,
              right: mobileLayout ? 0 : horizontalPadding,
            ),
            child: buildListTrackWidget(
              ref,
              context,
              audio,
              playlist,
              isAvailable:
                  audio.canPlay && (!isFavoritesPlaylist || audio.isLiked),
              showStatusIcons: true,
              showDuration: !mobileLayout,
              replaceLikeWithMore: mobileLayout,
              dense: mobileLayout,
              roundedCorners: !mobileLayout,
              padding: mobileLayout
                  ? EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}

/// Виджет, отображающий изображение плейлиста для [AppBarWidget].
class AppBarPlaylistImageWidget extends StatelessWidget {
  /// Плейлист, изображение которого будет получено.
  final ExtendedPlaylist playlist;

  /// Значение, используемое как ширина и высота для данного виджета.
  final double size;

  const AppBarPlaylistImageWidget({
    super.key,
    required this.playlist,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = playlist.photo?.photo1200;
    final fallbackWidget = FallbackAudioPlaylistAvatar(
      favoritesPlaylist: playlist.type == PlaylistType.favorites,
      size: size,
    );

    final int cacheSize =
        (size * MediaQuery.devicePixelRatioOf(context)).round();

    final scheme = ColorScheme.of(context);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: scheme.surface,
            spreadRadius: 1,
            blurRadius: 50,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          globalBorderRadius,
        ),
        child: imageUrl != null
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                cacheKey: "${playlist.mediaKey}1200",
                fit: BoxFit.cover,
                width: size,
                height: size,
                memCacheHeight: cacheSize,
                memCacheWidth: cacheSize,
                placeholder: (BuildContext context, String string) {
                  return fallbackWidget;
                },
                cacheManager: CachedNetworkImagesManager.instance,
              )
            : fallbackWidget,
      ),
    );
  }
}

/// [AppBar] для [AppBarWidget], показывающий настоящее содержимое [AppBar]'а: кнопку назад, поиска и дополнительных действий.
class AppBarRealAppBarWidget extends HookConsumerWidget {
  /// [TextEditingController] для поля поиска.
  final TextEditingController? controller;

  /// [FocusNode] для поля поиска.
  final FocusNode? focusNode;

  /// Заголовок для данного [AppBar].
  final String title;

  /// Количество треков в данном плейлисте.
  final int count;

  /// Указывает, открыто ли поле для поиска.
  ///
  /// Если правдиво, то будет показано поле для поиска, а кнопки "поиска" и "дополнительных действий" не будут отображены.
  final bool isSearchOpen;

  /// Значение от `0.0` до `1.0`, отображающее прозрачность заголовка.
  final double titleOpacity;

  /// Метод, вызываемый при нажатии на кнопку "поиска" справа.
  ///
  /// Если не указано, то кнопка не будет отображена.
  final VoidCallback? onSearchPressed;

  /// Метод, вызываемый при нажатии на кнопку "дополнительных действий" справа.
  ///
  /// Если не указано, то кнопка не будет отображена.
  final VoidCallback? onMorePressed;

  /// Метод, возвращающий текст для поиска.
  ///
  /// Не может вызываться, если [isSearchOpen] не правдив.
  final ValueChanged<String>? onSearchInput;

  /// Метод, вызываемый при нажатии кнопки Enter на клавиатуре при вводе текста поля поиска.
  ///
  /// Не может вызываться, если [isSearchOpen] не правдив.
  final void Function(String)? onSearchSubmitted;

  const AppBarRealAppBarWidget({
    super.key,
    this.controller,
    this.focusNode,
    required this.title,
    this.count = 0,
    this.isSearchOpen = false,
    this.titleOpacity = 1.0,
    this.onSearchPressed,
    this.onMorePressed,
    this.onSearchInput,
    this.onSearchSubmitted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);

    useListenable(controller);

    final bool showSearchButton = onSearchPressed != null && !isSearchOpen;
    final bool showMoreButton = onMorePressed != null && !isSearchOpen;

    void onSearchClear() => controller?.clear();

    return AppBar(
      title: isSearchOpen
          ? ShortcutsPropagator(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: onSearchInput,
                onSubmitted: onSearchSubmitted,
                style: const TextStyle(
                  color: Colors.white,
                ),
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: l18n.search_tracks_in_playlist(
                    count: count,
                  ),
                  filled: true,
                  contentPadding: const EdgeInsets.all(
                    16,
                  ),
                  suffixIcon: controller != null && controller!.text.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsetsDirectional.only(
                            end: 12,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                            ),
                            onPressed: onSearchClear,
                          ),
                        )
                      : null,
                ),
              ),
            )
          : AnimatedOpacity(
              opacity: titleOpacity.clamp(
                0.0,
                1.0,
              ),
              duration: const Duration(
                milliseconds: 150,
              ),
              child: Text(
                title,
              ),
            ),
      leading: isSearchOpen ? const BackButton() : null,
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: Colors.white,
      actions: [
        // Кнопка для поиска.
        if (showSearchButton)
          IconButton(
            onPressed: onSearchPressed,
            icon: const Icon(
              Icons.search,
            ),
          ),

        // Кнопка для открытия дополнительных действий.
        if (showMoreButton)
          IconButton(
            onPressed: onMorePressed,
            icon: Icon(
              Icons.adaptive.more,
            ),
          ),

        // Небольшое расстояние.
        if (showSearchButton || showMoreButton) const Gap(12),
      ],
    );
  }
}

/// [AppBar] для [PlaylistRoute] Mobile Layout'а.
///
/// Не стоит путать с [AppBarRealAppBarWidget].
class AppBarWidget extends HookConsumerWidget {
  /// Плейлист, для которого отображается данный [AppBar].
  final ExtendedPlaylist playlist;

  /// Указывает, что будет использоваться Mobile Layout.
  final bool mobileLayout;

  /// [TextEditingController] для поля поиска.
  final TextEditingController? searchController;

  /// [FocusNode] для поля поиска.
  final FocusNode? searchFocusNode;

  /// Максимальный размер для данного [AppBar], когда он полностью раскрыт.
  final double maxAppBarHeight;

  /// Минимальный размер для данного [AppBar], когда он полностью свёрнут.
  final double minAppBarHeight;

  /// Указывает, открыто ли поле для поиска.
  ///
  /// Если правдиво, то будет показано поле для поиска, а кнопки "поиска" и "дополнительных действий" не будут отображены.
  final bool isSearchOpen;

  /// Метод, вызываемый при нажатии на кнопку "поиска" справа.
  ///
  /// Если не указано, то кнопка не будет отображена.
  final VoidCallback? onSearchPressed;

  /// Метод, вызываемый при нажатии на кнопку "дополнительных действий" справа.
  ///
  /// Если не указано, то кнопка не будет отображена.
  final VoidCallback? onMorePressed;

  /// Метод, возвращающий текст для поиска.
  ///
  /// Не может вызываться, если [isSearchOpen] не правдив.
  final ValueChanged<String>? onSearchInput;

  /// Метод, вызываемый при нажатии кнопки Enter на клавиатуре при вводе текста поля поиска.
  ///
  /// Не может вызываться, если [isSearchOpen] не правдив.
  final void Function(String)? onSearchSubmitted;

  const AppBarWidget({
    super.key,
    required this.playlist,
    this.mobileLayout = false,
    this.searchController,
    this.searchFocusNode,
    required this.maxAppBarHeight,
    required this.minAppBarHeight,
    this.isSearchOpen = false,
    this.onSearchPressed,
    this.onMorePressed,
    this.onSearchInput,
    this.onSearchSubmitted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);

    final scheme = ColorScheme.of(context);

    final String title = playlist.title ?? l18n.general_favorites_playlist;

    return SliverPersistentHeader(
      pinned: true,
      delegate: SliverAppBarDelegate(
        maxHeight: maxAppBarHeight,
        minHeight: minAppBarHeight,
        builder: (BuildContext context, double offset) {
          const double albumPadding = 50;
          final double albumImageSize =
              (MediaQuery.sizeOf(context).width - albumPadding * 2)
                  .clamp(50, 300);
          final double albumImageSizeWithPadding =
              albumImageSize + albumPadding * 2;

          final double scrollToHeightRatio = offset / maxAppBarHeight;

          // Изображение альбома должно становиться меньше, если пользовать проскроллил
          //  изображение, а так же его padding сверху и снизу.
          final double freeSpace = maxAppBarHeight - albumImageSizeWithPadding;
          final bool shouldScaleDownAlbumImage = offset > freeSpace;
          final double albumScaleDiff = shouldScaleDownAlbumImage
              ? (offset - freeSpace) / (maxAppBarHeight - freeSpace)
              : 0.0;
          final double albumScale = 1.0 - albumScaleDiff;

          // Если размер альбома уменьшился на 50%, то начинаем анимировать его прозрачность.
          final double albumOpacity =
              (1.0 - (albumScaleDiff - 0.5) / 0.7).clamp(0.0, 1.0);

          // Вычисляем позицию для изображения. Оно должно находиться по центру AppBar'а,
          // Однако, если пользователь проскроллил много, то оно должно "уезжать" наверх.
          final double albumBasePosition =
              maxAppBarHeight / 2 - albumImageSize / 2;
          final double albumAnimatedPosition = albumBasePosition -
              scrollToHeightRatio * maxAppBarHeight / 2 -
              (albumImageSize / 2 * (1.0 - albumOpacity));

          // Вычисляем прозрачность названия плейлиста в AppBar'е сверху.
          final bool showAppBarTitle = scrollToHeightRatio > 0.7;
          final double titleOpacity = showAppBarTitle
              ? 1.0 - (maxAppBarHeight - offset) / minAppBarHeight
              : 0.0;

          return Stack(
            alignment: Alignment.center,
            children: [
              // Изображение альбома для Mobile Layout'а, которое двигается с анимацией.
              if (mobileLayout && albumOpacity > 0)
                Positioned(
                  top: albumAnimatedPosition,
                  child: Opacity(
                    opacity: albumOpacity,
                    child: Transform.scale(
                      scale: albumScale,
                      child: AppBarPlaylistImageWidget(
                        playlist: playlist,
                        size: albumImageSize,
                      ),
                    ),
                  ),
                ),

              // AppBar сверху, title и градиент которого меняется в зависимости от того, сколько наскроллено.
              AnimatedContainer(
                duration: const Duration(
                  milliseconds: 150,
                ),
                decoration: BoxDecoration(
                  gradient: showAppBarTitle
                      ? LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            scheme.primary.darken(0.5).withValues(alpha: 0.75),
                            scheme.primary.darken(0.5).withValues(alpha: 0.3),
                          ],
                        )
                      : null,
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: titleOpacity * 25,
                    sigmaY: titleOpacity * 25,
                  ),
                  child: AppBarRealAppBarWidget(
                    controller: searchController,
                    focusNode: searchFocusNode,
                    title: title,
                    count: playlist.count ?? 0,
                    isSearchOpen: isSearchOpen,
                    titleOpacity: titleOpacity,
                    onSearchPressed: mobileLayout ? onSearchPressed : null,
                    onMorePressed: mobileLayout ? onMorePressed : null,
                    onSearchInput: onSearchInput,
                    onSearchSubmitted: onSearchSubmitted,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Виджет, отображающий фоновый градиент для [PlaylistRoute].
class BackgroundGradientWidget extends HookConsumerWidget {
  /// Цветовая схема, извлечённая из цветов плейлиста.
  final ColorScheme? scheme;

  /// [ScrollController], используемый для отслеживания прокрутки.
  final ScrollController scrollController;

  /// Максимальный размер для градиента.
  final double maxHeight;

  const BackgroundGradientWidget({
    super.key,
    this.scheme,
    required this.scrollController,
    required this.maxHeight,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useListenable(scrollController);

    final double offset =
        scrollController.hasClients ? scrollController.position.pixels : 0.0;

    // Если проскроллено больше, чем размер AppBar'а + блок с информацией, то ничего не отображаем.
    if (offset > maxHeight) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: -offset,
      child: SizedBox(
        width: MediaQuery.sizeOf(context).width,
        height: maxHeight,
        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 1500,
          ),
          curve: Curves.easeInOutCubicEmphasized,
          decoration: BoxDecoration(
            gradient: scheme != null
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      scheme!.primary,
                      Colors.transparent,
                    ],
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

/// Виджет, используемый для [DesktopAppBarWidget] и [MobilePlaylistInfoWidget], отображающий описание плейлиста вида "рекомендуемый плейлист - 50 треков - 3 часа".
class PlaylistTypeDescriptionWidget extends HookConsumerWidget {
  /// [ExtendedPlaylist], данные которого будут показаны.
  final ExtendedPlaylist playlist;

  const PlaylistTypeDescriptionWidget({
    super.key,
    required this.playlist,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.read(l18nProvider);

    final String playlistType = useMemoized(
      () => getPlaylistTypeString(l18n, playlist),
    );
    final String durationString = useMemoized(
      () => humanizeDuration(
        playlist.duration ??
            const Duration(
              hours: 1,
              minutes: 30,
            ),
        language: getLanguageByLocale(
          l18n.localeName,
        ),
        options: const HumanizeOptions(
          units: [
            Units.hour,
            Units.minute,
          ],
        ),
      ),
      [
        playlist.duration,
      ],
    );

    final hasInfo =
        playlist.isLiveData || playlist.type == PlaylistType.favorites;
    final areTracksLoaded = playlist.audios != null;

    final scheme = ColorScheme.of(context);

    return Skeletonizer(
      enabled: !hasInfo,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text.rich(
          TextSpan(
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.8),
            ),
            children: [
              // Тип плейлиста.
              TextSpan(
                text: playlistType,
              ),
              const TextSpan(
                text: " • ",
              ),

              // Количество треков.
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Skeletonizer(
                  enabled: !areTracksLoaded,
                  child: Text(
                    l18n.general_audios_count(
                      count: playlist.count ?? 50,
                    ),
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),
              const TextSpan(
                text: " • ",
              ),

              // Длительность.
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Skeletonizer(
                  enabled: !areTracksLoaded,
                  child: Text(
                    durationString,
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.8),
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

/// [AppBar] для [PlaylistRoute] Desktop Layout'а.
class DesktopAppBarWidget extends HookConsumerWidget {
  /// Плейлист, для которого отображается данный [AppBar].
  final ExtendedPlaylist playlist;

  /// Значение, используемое как горизонтальный Padding.
  final double horizontalPadding;

  /// Максимальный размер для данного [AppBar], когда он полностью раскрыт.
  final double maxAppBarHeight;

  /// Минимальный размер для данного [AppBar], когда он полностью свёрнут.
  final double minAppBarHeight;

  const DesktopAppBarWidget({
    super.key,
    required this.playlist,
    this.horizontalPadding = 0,
    required this.maxAppBarHeight,
    required this.minAppBarHeight,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);

    final scheme = ColorScheme.of(context);

    return SliverLayoutBuilder(
      builder: (
        BuildContext context,
        SliverConstraints constraints,
      ) {
        final double offset = constraints.scrollOffset;

        final isExpanded = maxAppBarHeight > offset;

        return SliverAppBar(
          pinned: true,
          expandedHeight: maxAppBarHeight,
          backgroundColor: isExpanded ? Colors.transparent : scheme.surface,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          foregroundColor: Colors.white,
          title: AnimatedOpacity(
            opacity: isExpanded ? 0.0 : 1.0,
            duration: const Duration(
              milliseconds: 150,
            ),
            child: Text(
              playlist.title ?? l18n.general_favorites_playlist,
            ),
          ),
          centerTitle: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Padding(
              padding: EdgeInsets.only(
                left: horizontalPadding,
                right: horizontalPadding,
                top: 60,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Информация о плейлисте в Desktop Layout'е.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Изображение плейлиста.
                      AppBarPlaylistImageWidget(
                        playlist: playlist,
                        size: 200,
                      ),
                      const Gap(24),

                      // Название плейлиста, количество треков в нём.
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Название плейлиста.
                            SelectableText(
                              playlist.title ?? l18n.general_favorites_playlist,
                              style: Theme.of(context)
                                  .textTheme
                                  .displayLarge!
                                  .copyWith(
                                    fontWeight: FontWeight.w500,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                            ),
                            const Gap(4),

                            // Описание плейлиста, при наличии.
                            if (playlist.description != null)
                              SelectableText(
                                playlist.description!,
                                style: TextStyle(
                                  overflow: TextOverflow.ellipsis,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.9),
                                ),
                              ),
                            if (playlist.description != null) const Gap(4),

                            // Пояснение того, что это за плейлист.
                            PlaylistTypeDescriptionWidget(
                              playlist: playlist,
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
    );
  }
}

/// Виджет для [PlaylistRoute] Desktop Layout'а, отображающий кнопки управления плейлистом.
class DesktopPlaylistControlsWidget extends HookConsumerWidget {
  /// [ExtendedPlaylist], для которого отображаются кнопки.
  final ExtendedPlaylist playlist;

  /// Цветовая схема, извлечённая из цветов плейлиста.
  final ColorScheme? scheme;

  /// [TextEditingController] для поля поиска.
  final TextEditingController? searchController;

  /// [FocusNode] для поля поиска.
  final FocusNode? searchFocusNode;

  /// Значение, используемое как горизонтальный Padding.
  final double horizontalPadding;

  /// Указывает, лайкнут ли плейлист.
  final bool isLiked;

  /// Метод, вызываемый при нажатии на кнопку воспроизведения.
  ///
  /// Если не указано, то кнопка не будет отображена.
  final VoidCallback? onPlayPressed;

  /// Метод, вызываемый при нажатии на кнопку "лайка" плейлиста.
  ///
  /// Если не указано, то кнопка не будет отображена.
  final AsyncCallback? onLikePressed;

  /// Метод, вызываемый при нажатии на кнопку кэширования плейлиста.
  ///
  /// Если не указано, то кнопка не будет отображена.
  final VoidCallback? onCacheTap;

  /// Метод, возвращающий текст для поиска.
  final ValueChanged<String>? onSearchInput;

  /// Метод, вызываемый при нажатии кнопки Enter на клавиатуре при вводе текста поля поиска.
  final void Function(String)? onSearchSubmitted;

  const DesktopPlaylistControlsWidget({
    super.key,
    required this.playlist,
    this.scheme,
    this.searchController,
    this.searchFocusNode,
    this.horizontalPadding = 0,
    this.isLiked = false,
    this.onPlayPressed,
    this.onLikePressed,
    this.onCacheTap,
    this.onSearchInput,
    this.onSearchSubmitted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);
    final player = ref.read(playerProvider);
    final preferences = ref.watch(preferencesProvider);
    ref.watch(playerIsPlayingProvider);

    useListenable(searchController);

    final hasTracksLoaded = playlist.audios != null;
    final isSelected = player.playlist?.ownerID == playlist.ownerID &&
        player.playlist?.id == playlist.id;
    final safeScheme = scheme ?? ColorScheme.of(context);

    void onSearchClear() => searchController?.clear();

    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
      ),
      sliver: SliverPersistentHeader(
        pinned: true,
        delegate: SliverAppBarDelegate(
          minHeight: 54 + 8 * 2,
          maxHeight: 54 + 8 * 2,
          builder: (BuildContext context, double offset) {
            return Container(
              color: ColorScheme.of(context).surface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Кнопки управления.
                  Theme(
                    data: ThemeData(
                      colorScheme: safeScheme,
                    ),
                    child: Row(
                      children: [
                        // Кнопка запуска воспроизведения треков из плейлиста.
                        if (onPlayPressed != null)
                          IconButton.filled(
                            onPressed: onPlayPressed,
                            iconSize: 38,
                            icon: isSelected
                                ? PlayPauseAnimatedIcon(
                                    color: scheme?.onPrimary,
                                  )
                                : Icon(
                                    preferences.shuffleOnPlay
                                        ? Icons.shuffle
                                        : Icons.play_arrow,
                                    color: scheme?.onPrimary,
                                  ),
                          ),
                        const Gap(12),

                        // Кнопка для лайка плейлиста.
                        if (onLikePressed != null)
                          LoadingIconButton(
                            onPressed: onLikePressed,
                            iconSize: 38,
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_outline,
                              color: isLiked
                                  ? safeScheme.primary
                                  : safeScheme.onSurface,
                            ),
                          ),
                        const Gap(6),

                        // Кнопка для загрузки треков в кэш.
                        if (onCacheTap != null)
                          CachePlaylistButtonWidget(
                            playlist: playlist,
                            taskKey: playlist.mediaKey,
                            onTap: onCacheTap!,
                          ),
                        const Gap(6),
                      ],
                    ),
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
                        child: ShortcutsPropagator(
                          child: TextField(
                            controller: searchController,
                            focusNode: searchFocusNode,
                            enabled: hasTracksLoaded,
                            onSubmitted: onSearchSubmitted,
                            decoration: InputDecoration(
                              hintText: l18n.search_tracks_in_playlist(
                                count: playlist.count ?? 0,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  globalBorderRadius,
                                ),
                              ),
                              prefixIconColor: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(
                                    alpha: hasTracksLoaded ? 1.0 : 0.5,
                                  ),
                              prefixIcon: const Icon(
                                Icons.search,
                              ),
                              suffixIcon: searchController != null &&
                                      searchController!.text.isNotEmpty
                                  ? Padding(
                                      padding: const EdgeInsetsDirectional.only(
                                        end: 12,
                                      ),
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
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Route, отображающий информацию о [ExtendedPlaylist] по передаваемым параметрам.
///
/// Данный Route показывает базовую информацию о плейлисте, его треки, и позволяет управлять ими.
///
/// go_route: `/music/playlist/:ownerID/:id`.
class PlaylistRoute extends HookConsumerWidget {
  static final AppLogger logger = getLogger("PlaylistRoute");

  /// ID владельца плейлиста. [ExtendedPlaylist.ownerID]
  final int ownerID;

  /// ID плейлиста. [ExtendedPlaylist.id]
  final int id;

  const PlaylistRoute({
    super.key,
    required this.ownerID,
    required this.id,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);
    final player = ref.read(playerProvider);
    final playlist = ref.watch(getPlaylistProvider(ownerID, id))!;
    ref.watch(playerIsLoadedProvider);

    // Если поменялось изображение плейлиста, то нужно обновить цветовую схему.
    useEffect(
      () {
        ref.invalidate(colorInfoFromPlaylistProvider(ownerID, id));

        return null;
      },
      [playlist.photo?.photo34],
    );
    final playlistColorInfo =
        ref.watch(colorInfoFromPlaylistProvider(ownerID, id));

    final scrollController = useScrollController();
    final searchController = useTextEditingController();
    final searchFocusNode = useFocusNode();
    final isSearchOpen = useState(false);

    useEffect(
      () {
        Future<void> loadPlaylist() =>
            ref.read(playlistsProvider.notifier).loadPlaylist(playlist);

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

        // Делаем фокус на поле поиска на Desktop-платформах.
        if (isDesktop) {
          searchFocusNode.requestFocus();
        }

        return subscription?.cancel;
      },
      [],
    );

    final bool mobileLayout = isMobileLayout(context);

    final theme = Theme.of(context);
    final oldScheme = theme.colorScheme;
    final brightness = theme.brightness;

    final ColorScheme? scheme = useMemoized(
      () {
        // Если у плейлиста нет фотографии, то возвращаем стандартную цветовую схему.
        if (playlist.photo == null) return oldScheme;

        // Если у нас есть информация о цвете плейлиста, то возвращаем цветовую схему из него.
        if (playlistColorInfo.value != null) {
          return ColorScheme.fromSeed(
            seedColor: Color(
              playlistColorInfo.value!.scoredColorInts.first,
            ),
            brightness: brightness,
          );
        }

        return null;
      },
      [brightness, playlistColorInfo.value, oldScheme.primary],
    );

    final double screenHeight = MediaQuery.sizeOf(context).height;
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double infoBoxHeight = mobileLayout
        ? playlist.description != null
            ? 150
            : 100
        : 0;
    final double maxAppBarHeight = (mobileLayout
            ? (screenHeight / 2).roundToDouble().clamp(0, 500) - infoBoxHeight
            : 272) +
        statusBarHeight;
    final double minAppBarHeight = 70 + statusBarHeight;
    final double horizontalPadding = mobileLayout ? 12 : 18;

    Future<void> onLikePlaylistTap() async {
      HapticFeedback.lightImpact();

      showWipDialog(context);
    }

    void onCacheTap() async {
      final downloadManager = ref.read(downloadManagerProvider.notifier);
      final playlistsManager = ref.read(playlistsProvider.notifier);
      final playlistName = playlist.title ?? l18n.general_favorites_playlist;
      final playlistCached = playlist.cacheTracks ?? false;

      HapticFeedback.lightImpact();

      // Не даём что либо делать с кэшированием в демо-версии.
      if (!demoModeDialog(ref, context)) return;

      // Если плейлист уже кэширован, то значит, что нам нужно его удалить.
      // Сначала нужно спросить у пользователя то, хочет ли он удалить кэш.
      if (playlistCached) {
        final bool dialogResult = await showDialog(
              context: context,
              builder: (BuildContext context) {
                return DeleteCacheDialog(
                  playlist: playlist,
                );
              },
            ) ??
            false;

        // Если пользователь нажал на "нет", то выходим.
        if (!dialogResult || !context.mounted) return;

        // Пользователь разрешил удаление кэша плейлиста.
        // Если у нас запущено воспроизведение этого плейлиста, то останавливаем её.
        if (player.playlist?.mediaKey == playlist.mediaKey) {
          await player.stop();
        }

        // Запоминаем, что плейлист больше не кэширован.
        final newPlaylist = await playlistsManager.updatePlaylist(
          playlist.basicCopyWith(
            cacheTracks: false,
          ),
          saveInDB: true,
        );

        // Создаём задачу по удалению кэша.
        await downloadManager.newTask(
          PlaylistCacheDownloadTask(
            ref: downloadManager.ref,
            id: playlist.mediaKey,
            playlist: newPlaylist.playlist,
            longTitle: l18n.playlist_download_removal(
              title: playlistName,
            ),
            smallTitle: playlistName,
            tasks: playlist.audios!
                .map(
                  (audio) => PlaylistCacheDeleteDownloadItem(
                    ref: downloadManager.ref,
                    playlist: newPlaylist.playlist,
                    audio: audio,
                    removeThumbnails: true,
                  ),
                )
                .toList(),
          ),
        );

        return;
      }

      // Если мы попали сюда, то значит, что плейлист не кэширован, и пользователь пытается включить кэширование.

      // Проверяем наличие интернета.
      if (!networkRequiredDialog(ref, context)) return;

      // Вычисляем примерный размер плейлиста.
      final int approxSize =
          ((playlist.duration ?? Duration.zero).inMinutes * trackSizePerMin)
              .round();
      final size = approxSize >= 500
          ? l18n.general_filesize_gb(
              value: approxSize / 500,
            )
          : l18n.general_filesize_mb(
              value: approxSize,
            );

      // Спрашиваем, уверен ли он в своих намерениях.
      final result = await showYesNoDialog(
        context,
        icon: Icons.file_download,
        title: l18n.enable_download_title,
        description: l18n.enable_download_desc(
          count: playlist.count ?? 0,
          downloadSize: size,
        ),
        yesText: l18n.general_enable,
      );

      // Если пользователь нажал на "нет", то выходим.
      if (result != true || !context.mounted) return;

      // Запоминаем, что плейлист теперь кэширован.
      final newPlaylist = await playlistsManager.updatePlaylist(
        playlist.basicCopyWith(
          cacheTracks: true,
        ),
        saveInDB: true,
      );

      createPlaylistCacheTask(
        downloadManager.ref,
        newPlaylist.playlist,
      );
    }

    void onPlayTapped() async {
      final preferences = ref.read(preferencesProvider);

      HapticFeedback.mediumImpact();

      // Если у нас уже запущен этот же плейлист, то переключаем паузу/воспроизведение.
      if (player.playlist?.mediaKey == playlist.mediaKey) {
        await player.togglePlay();

        return;
      }

      if (preferences.shuffleOnPlay) {
        await player.setShuffle(true);
      }
      await player.setPlaylist(
        playlist,
        randomAudio: preferences.shuffleOnPlay,
      );
    }

    void onSearchSubmitted(String? value) async {
      final preferences = ref.read(preferencesProvider);

      final String query = cleanString(value ?? "");
      if (query.isEmpty) return;

      final ExtendedAudio? foundAudio = playlist.audios!.firstWhereOrNull(
        (item) => isAudioMatchesQuery(item, query),
      );
      if (foundAudio == null || !foundAudio.canPlay) return;

      searchFocusNode.unfocus();
      HapticFeedback.mediumImpact();

      // Если у нас уже запущен этот же трек, то переключаем паузу/воспроизведение.
      if (player.audio?.mediaKey == foundAudio.mediaKey) {
        await player.togglePlay();

        return;
      }

      if (preferences.shuffleOnPlay) {
        await player.setShuffle(true);
      }
      await player.setPlaylist(
        playlist,
        initialAudio: foundAudio,
      );
    }

    /// Скроллит экран таким образом, что бы он он показывал место, где начинают отображаться сами треки.
    void scrollPastAppBar() => scrollController.animateTo(
          maxAppBarHeight + infoBoxHeight - statusBarHeight - 46,
          duration: const Duration(
            milliseconds: 300,
          ),
          curve: Curves.easeInOutCubicEmphasized,
        );

    void onSearchPressed() {
      isSearchOpen.value = true;
      searchFocusNode.requestFocus();

      scrollPastAppBar();
    }

    void onSearchInput() {
      // TODO: Вызвать событие скроллинга, что бы показать результаты поиска.

      scrollPastAppBar();
    }

    void onMorePressed() => showWipDialog(context);

    final List<Widget> customScrollViewSlivers = useMemoized(
      () => [
        // AppBar, в котором есть кнопки для управления (назад, ...),
        //  а так же анимированное изображение плейлиста.
        if (mobileLayout)
          AppBarWidget(
            playlist: playlist,
            mobileLayout: mobileLayout,
            searchController: searchController,
            searchFocusNode: searchFocusNode,
            maxAppBarHeight: maxAppBarHeight,
            minAppBarHeight: minAppBarHeight,
            isSearchOpen: isSearchOpen.value,
            onSearchPressed: onSearchPressed,
            onMorePressed: onMorePressed,
            onSearchInput: (_) => onSearchInput(),
            onSearchSubmitted: onSearchSubmitted,
          )
        else
          DesktopAppBarWidget(
            playlist: playlist,
            maxAppBarHeight: maxAppBarHeight,
            minAppBarHeight: minAppBarHeight,
            horizontalPadding: horizontalPadding,
          ),

        // Информация о данном плейлисте для Mobile Layout'а.
        if (mobileLayout) ...[
          MobilePlaylistInfoWidget(
            playlist: playlist,
            scheme: scheme,
            infoBoxHeight: infoBoxHeight,
          ),
          const SliverGap(36),
        ] else ...[
          Theme(
            data: ThemeData(
              colorScheme: oldScheme,
            ),
            child: DesktopPlaylistControlsWidget(
              playlist: playlist,
              scheme: scheme,
              searchController: searchController,
              searchFocusNode: searchFocusNode,
              horizontalPadding: horizontalPadding,
              onPlayPressed: onPlayTapped,
              onLikePressed: playlist.type == PlaylistType.favorites
                  ? null
                  : () async => showWipDialog(context),
              onCacheTap: onCacheTap,
              onSearchSubmitted: onSearchSubmitted,
            ),
          ),
          const SliverGap(8),
        ],

        // Треки в плейлисте.
        Theme(
          data: ThemeData(
            colorScheme: oldScheme,
          ),
          child: PlaylistAudiosListWidget(
            playlist: playlist,
            searchController: searchController,
            horizontalPadding: horizontalPadding,
          ),
        ),

        // Данный Gap нужен, что бы плеер снизу при Mobile Layout'е не закрывал ничего важного.
        if (player.isLoaded && mobileLayout)
          const SliverGap(MusicPlayerWidget.mobileHeightWithPadding),
      ],
      [
        mobileLayout,
        maxAppBarHeight,
        isSearchOpen.value,
        oldScheme,
        scheme,
        playlist,
      ],
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Theme(
        data: ThemeData(
          colorScheme: scheme ?? oldScheme,
        ),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Градиент на фоне, который будет меняться в зависимости от прокрутки.
            BackgroundGradientWidget(
              scheme: scheme,
              scrollController: scrollController,
              maxHeight: maxAppBarHeight + infoBoxHeight,
            ),

            // Содержимое.
            ScrollConfiguration(
              behavior: AlwaysScrollableScrollBehavior().copyWith(
                overscroll: !isSearchOpen.value,
              ),
              child: CustomScrollView(
                controller: scrollController,
                slivers: customScrollViewSlivers,
              ),
            ),

            // Ряд из кнопок управления плейлистом: кнопка лайка/дизлайка, воспроизведения/паузы, кэширования.
            if (mobileLayout && !isSearchOpen.value)
              MobileControlButtonsWidget(
                playlist: playlist,
                scrollController: scrollController,
                maxAppBarHeight: maxAppBarHeight,
                minAppBarHeight: minAppBarHeight,
                infoBoxHeight: infoBoxHeight,
                onLikePressed: playlist.type == PlaylistType.favorites
                    ? null
                    : onLikePlaylistTap,
                onPlayPausePressed: onPlayTapped,
                onCachePressed: onCacheTap,
              ),
          ],
        ),
      ),
    );
  }
}
