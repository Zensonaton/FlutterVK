import "dart:async";

import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:gap/gap.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../../consts.dart";
import "../../main.dart";
import "../../provider/auth.dart";
import "../../provider/l18n.dart";
import "../../provider/playlists.dart";
import "../../provider/preferences.dart";
import "../../provider/user.dart";
import "../../services/cache_manager.dart";
import "../../utils.dart";
import "../../widgets/dialogs.dart";
import "../../widgets/fallback_audio_photo.dart";
import "music/categories/by_vk_playlists.dart";
import "music/categories/my_music.dart";
import "music/categories/my_playlists.dart";
import "music/categories/realtime_playlists.dart";
import "music/categories/recommended_playlists.dart";
import "music/categories/simillar_music.dart";
import "music/search.dart";
import "profile/dialogs.dart";

/// Загружает полную информацию по всем плейлистам, у которых ранее было включено кэширование, загружая список их треков, и после чего запускает процесс кэширования.
Future<void> loadCachedTracksInformation(
  BuildContext context, {
  bool saveToDB = true,
  bool forceUpdate = false,
}) async {
  // TODO

  // final UserProvider user = Provider.of<UserProvider>(context, listen: false);
  // final AppLogger logger = getLogger("loadCachedTracksInformation");

  // // Извлекаем список треков у тех плейлистов, у которых включено кэширование.
  // for (ExtendedPlaylist playlist in user.allPlaylists.values) {
  //   // Плейлисты, у которых уже загружен список треков должны быть пропущены.
  //   if (playlist.areTracksLive) continue;

  //   // Плейлисты с отключенным кэшированием пропускаем.
  //   if (!(playlist.cacheTracks ?? false)) continue;

  //   logger.d("Found $playlist with enabled caching, downloading full data");

  //   // Загружаем информацию по данному плейлисту.
  //   final ExtendedPlaylist newPlaylist = await loadPlaylistData(
  //     playlist,
  //     user,
  //   );

  //   user.updatePlaylist(
  //     newPlaylist,
  //     saveToDB: saveToDB,
  //   );

  //   // Запускаем задачу по кэшированию этого плейлиста.
  //   downloadManager.cachePlaylist(user: user, newPlaylist);

  //   user.markUpdated(false);
  // }
}

/// Виджет, олицетворяющий отдельный трек в списке треков.
class AudioTrackTile extends HookConsumerWidget {
  /// Объект типа [ExtendedAudio], олицетворяющий данный трек.
  final ExtendedAudio audio;

  /// Указывает, что этот трек сейчас выбран.
  ///
  /// Поле [currentlyPlaying] указывает, что плеер включён.
  final bool selected;

  /// Указывает, что плеер в данный момент включён.
  final bool currentlyPlaying;

  /// Указывает, что данный трек загружается перед тем, как начать его воспроизведение.
  final bool isLoading;

  /// Указывает, что в случае, если [selected] равен true, то у данного виджета будет эффект "свечения".
  final bool glowIfSelected;

  /// Указывает, что в случае, если трек кэширован ([ExtendedAudio.isCached]), то будет показана соответствующая иконка.
  final bool showCachedIcon;

  /// Если true, то данный виджет будет не будет иметь эффект прозрачности даже если [ExtendedAudio.canPlay] равен false.
  final bool forceAvailable;

  /// Указывает, что будет показана длительность этого трека.
  final bool showDuration;

  /// Действие, вызываемое при переключения паузы/возобновления при нажатии по иконке трека.
  ///
  /// В отличии от [onPlay], данный метод просто переключает то, находится трек на паузе или нет. Данный метод вызывается лишь в случае, если поле [selected] правдиво, в ином случае при нажатии на данный виджет будет вызываться событие [onPlay].
  final Function(bool)? onPlayToggle;

  /// Действие, вызываемое при "выборе" данного трека.
  ///
  /// В отличии от [onPlayToggle], данный метод должен "перезапустить" трек, если он в данный момент играет.
  final VoidCallback? onPlay;

  /// Действие, вызываемое при переключении состояния "лайка" данного трека.
  ///
  /// Если не указано, то кнопка лайка не будет показана.
  final Function(bool)? onLikeToggle;

  /// Действие, вызываемое при выборе ПКМ (или зажатии) по данном элементу.
  ///
  /// Чаще всего используется для открытия контекстного меню.
  final VoidCallback? onSecondaryAction;

  const AudioTrackTile({
    super.key,
    this.selected = false,
    this.isLoading = false,
    this.currentlyPlaying = false,
    this.glowIfSelected = false,
    this.showCachedIcon = true,
    this.forceAvailable = false,
    this.showDuration = true,
    required this.audio,
    this.onPlay,
    this.onPlayToggle,
    this.onLikeToggle,
    this.onSecondaryAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHovered = useState(false);

    final bool selectedAndPlaying = selected && currentlyPlaying;

    /// Url на изображение данного трека.
    final String? imageUrl = audio.smallestThumbnail;

    /// Цвет для текста и прочих иконок.
    final Color color = selected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPlay,
        onHover:
            onPlay != null ? (bool value) => isHovered.value = value : null,
        borderRadius: BorderRadius.circular(
          globalBorderRadius,
        ),
        onLongPress: isMobile ? onSecondaryAction : null,
        onSecondaryTap: onSecondaryAction,
        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 500,
          ),
          curve: Curves.ease,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              globalBorderRadius,
            ),
            gradient: selected && glowIfSelected
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
                opacity: forceAvailable || audio.canPlay ? 1.0 : 0.5,
                child: InkWell(
                  onTap: onPlayToggle != null || onPlay != null
                      ? () {
                          // Если в данный момент играет именно этот трек, то вызываем onPlayToggle.
                          if (selected) {
                            onPlayToggle?.call(
                              !selectedAndPlaying,
                            );

                            return;
                          }

                          // В ином случае запускаем проигрывание этого трека.
                          onPlay?.call();
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
                                  cacheKey: "${audio.mediaKey}small",
                                  width: 50,
                                  height: 50,
                                  memCacheWidth: (50 *
                                          MediaQuery.of(context)
                                              .devicePixelRatio)
                                      .round(),
                                  memCacheHeight: (50 *
                                          MediaQuery.of(context)
                                              .devicePixelRatio)
                                      .round(),
                                  placeholder:
                                      (BuildContext context, String url) =>
                                          const FallbackAudioAvatar(),
                                  cacheManager:
                                      CachedAlbumImagesManager.instance,
                                )
                              : const FallbackAudioAvatar(),
                        ),
                        if (isHovered.value || selected)
                          Center(
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surface
                                    .withOpacity(0.5),
                                borderRadius: BorderRadius.circular(
                                  globalBorderRadius,
                                ),
                              ),
                              child: !isHovered.value && selectedAndPlaying
                                  ? Center(
                                      child: isLoading
                                          ? const SizedBox(
                                              height: 25,
                                              width: 25,
                                              child: CircularProgressIndicator(
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
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const Gap(8),

              // Название и исполнитель трека.
              Expanded(
                child: Opacity(
                  opacity: forceAvailable || audio.canPlay ? 1.0 : 0.5,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ряд с названием трека, плашки Explicit и иконки кэша, и subtitle, при наличии.
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Название трека.
                          Flexible(
                            child: Text(
                              audio.title,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: color,
                              ),
                            ),
                          ),

                          // Плашка Explicit.
                          if (audio.isExplicit)
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 4,
                              ),
                              child: Icon(
                                Icons.explicit,
                                size: 16,
                                color: color.withOpacity(0.5),
                              ),
                            ),

                          // Иконка кэшированного трека.
                          if (showCachedIcon && (audio.isCached ?? false))
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 4,
                              ),
                              child: Icon(
                                Icons.arrow_downward,
                                size: 16,
                                color: color.withOpacity(0.5),
                              ),
                            ),

                          // Прогресс загрузки трека.
                          if (showCachedIcon &&
                              !(audio.isCached ?? false) &&
                              audio.downloadProgress.value > 0.0)
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 4,
                              ),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: ValueListenableBuilder(
                                  valueListenable: audio.downloadProgress,
                                  builder: (
                                    BuildContext context,
                                    double value,
                                    Widget? child,
                                  ) {
                                    return CircularProgressIndicator(
                                      value: value,
                                      strokeWidth: 2,
                                      color: color.withOpacity(0.5),
                                    );
                                  },
                                ),
                              ),
                            ),

                          // Подпись трека.
                          if (audio.subtitle != null)
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 6,
                                ),
                                child: Text(
                                  audio.subtitle!,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: color.withOpacity(0.5),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                      // Исполнитель.
                      Text(
                        audio.artist,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Длительность трека, если включена.
              if (showDuration)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 8,
                  ),
                  child: Text(
                    audio.durationString,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.75),
                    ),
                  ),
                ),

              // Кнопка для лайка, если её нужно показывать.
              if (onLikeToggle != null)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 8,
                  ),
                  child: IconButton(
                    onPressed: () => onLikeToggle!(
                      !audio.isLiked,
                    ),
                    icon: Icon(
                      audio.isLiked ? Icons.favorite : Icons.favorite_outline,
                      color: Theme.of(context).colorScheme.primary,
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

/// Виджет, отображающий плейлист, как обычный так и рекомендательный.
class AudioPlaylistWidget extends StatefulWidget {
  /// URL на изображение заднего фона.
  final String? backgroundUrl;

  /// Поле, спользуемое как ключ для кэширования [backgroundUrl].
  final String? cacheKey;

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
    this.cacheKey,
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

    return Tooltip(
      message: widget.description ?? "",
      waitDuration: const Duration(
        seconds: 1,
      ),
      child: InkWell(
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
              AnimatedContainer(
                duration: const Duration(
                  milliseconds: 500,
                ),
                curve: Curves.ease,
                height: 200,
                decoration: BoxDecoration(
                  boxShadow: [
                    if (widget.selected)
                      BoxShadow(
                        blurRadius: 15,
                        spreadRadius: -3,
                        color: Theme.of(context).colorScheme.tertiary,
                        blurStyle: BlurStyle.outer,
                      ),
                  ],
                ),
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
                              cacheKey: widget.cacheKey,
                              memCacheHeight:
                                  (200 * MediaQuery.devicePixelRatioOf(context))
                                      .round(),
                              memCacheWidth:
                                  (200 * MediaQuery.devicePixelRatioOf(context))
                                      .round(),
                              placeholder: (BuildContext context, String url) =>
                                  const FallbackAudioPlaylistAvatar(),
                              cacheManager: CachedNetworkImagesManager.instance,
                            )
                          : const FallbackAudioPlaylistAvatar(),
                    ),

                    // Затемнение у тех плейлистов, текст которых расположен поверх плейлистов.
                    if (widget.useTextOnImageLayout)
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Colors.black38,
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          borderRadius: BorderRadius.circular(
                            globalBorderRadius,
                          ),
                        ),
                      ),

                    // Если это у нас рекомендательный плейлист, то текст должен находиться внутри изображения плейлиста.
                    if (widget.useTextOnImageLayout)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Название плейлиста.
                            Text(
                              widget.name,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge!
                                  .copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                            ),

                            // Описание плейлиста.
                            if (widget.description != null)
                              Text(
                                widget.description!,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 3,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge!
                                    .copyWith(
                                      color: Colors.white,
                                    ),
                              ),
                          ],
                        ),
                      ),

                    // Затемнение, а так же иконка поверх плейлиста.
                    if (isHovered || widget.selected)
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surface
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(
                            globalBorderRadius,
                          ),
                        ),
                        child: !isHovered && selectedAndPlaying
                            ? Center(
                                child: RepaintBoundary(
                                  child: Image.asset(
                                    "assets/images/audioEqualizer.gif",
                                    color:
                                        Theme.of(context).colorScheme.primary,
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
                      ),
                  ],
                ),
              ),

              // Если это обычный плейлист, то нам нужно показать его содержимое под изображением.
              if (!widget.useTextOnImageLayout)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Название плейлиста.
                        Text(
                          widget.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall!
                              .copyWith(
                                fontWeight: FontWeight.w500,
                                color: widget.selected
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                        ),

                        // Описание плейлиста, при наличии.
                        if (widget.description != null)
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: 2,
                              ),
                              child: Text(
                                widget.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                      color: widget.selected
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : null,
                                    ),
                              ),
                            ),
                          ),
                      ],
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

/// Виджет, показывающий кучку переключателей-фильтров класса [FilterChip] для включения различных разделов "музыки".
class ChipFilters extends ConsumerWidget {
  /// Указывает, что над этим блоком будет надпись "Активные разделы".
  final bool showLabel;

  const ChipFilters({
    super.key,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsNotifier = ref.read(preferencesProvider.notifier);
    final preferences = ref.watch(preferencesProvider);
    final l18n = ref.watch(l18nProvider);

    /// Указывают, включены ли рекомендации.
    final bool hasRecommendations = ref.read(secondaryTokenProvider) != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "Активные разделы".
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(
              bottom: 14,
            ),
            child: Text(
              l18n.music_filterChipsLabel,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
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
                  l18n.music_connectRecommendationsChipTitle,
                ),
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => const ConnectRecommendationsDialog(),
                ),
              ),

            // "Моя музыка".
            FilterChip(
              onSelected: (bool value) =>
                  prefsNotifier.setMyMusicChipEnabled(value),
              selected: preferences.myMusicChipEnabled,
              label: Text(
                l18n.music_myMusicChip,
              ),
            ),

            // "Ваши плейлисты".
            FilterChip(
              onSelected: (bool value) =>
                  prefsNotifier.setPlaylistsChipEnabled(value),
              selected: preferences.playlistsChipEnabled,
              label: Text(
                l18n.music_myPlaylistsChip,
              ),
            ),

            // "В реальном времени".
            if (hasRecommendations)
              FilterChip(
                onSelected: (bool value) =>
                    prefsNotifier.setRealtimePlaylistsChipEnabled(value),
                selected: preferences.realtimePlaylistsChipEnabled,
                label: Text(
                  l18n.music_realtimePlaylistsChip,
                ),
              ),

            // "Плейлисты для Вас".
            if (hasRecommendations)
              FilterChip(
                onSelected: (bool value) =>
                    prefsNotifier.setRecommendedPlaylistsChipEnabled(value),
                selected: preferences.recommendedPlaylistsChipEnabled,
                label: Text(
                  l18n.music_recommendedPlaylistsChip,
                ),
              ),

            // "Совпадения по вкусам".
            if (hasRecommendations)
              FilterChip(
                onSelected: (bool value) =>
                    prefsNotifier.setSimilarMusicChipEnabled(value),
                selected: preferences.similarMusicChipEnabled,
                label: Text(
                  l18n.music_similarMusicChip,
                ),
              ),

            // "Собрано редакцией".
            if (hasRecommendations)
              FilterChip(
                onSelected: (bool value) =>
                    prefsNotifier.setByVKChipEnabled(value),
                selected: preferences.byVKChipEnabled,
                label: Text(
                  l18n.music_byVKChip,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Виджет, показывающий надпись в случае, если пользователь отключил все разделы музыки.
class EverythingIsDisabledBlock extends ConsumerWidget {
  const EverythingIsDisabledBlock({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);

    return Column(
      children: [
        // "Как пусто..."
        Text(
          l18n.music_allBlocksDisabledTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
          textAlign: TextAlign.center,
        ),
        const Gap(8),

        // "Соскучились по музыке? ..."
        Text(
          l18n.music_allBlocksDisabledDescription,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Страница для управления музыкой.
class HomeMusicPage extends HookConsumerWidget {
  const HomeMusicPage({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final preferences = ref.watch(preferencesProvider);
    final l18n = ref.watch(l18nProvider);

    final bool isMobile = isMobileLayout(context);

    /// Указывает, что у пользователя подключены рекомендации музыки от ВКонтакте.
    final bool hasRecommendations = ref.read(secondaryTokenProvider) != null;

    final bool myMusic = preferences.myMusicChipEnabled;
    final bool playlists = preferences.playlistsChipEnabled;
    final bool realtimePlaylists =
        hasRecommendations && preferences.realtimePlaylistsChipEnabled;
    final bool recommendedPlaylists =
        hasRecommendations && preferences.recommendedPlaylistsChipEnabled;
    final bool similarMusic =
        hasRecommendations && preferences.similarMusicChipEnabled;
    final bool byVK = hasRecommendations && preferences.byVKChipEnabled;

    bool everythingIsDisabled;

    // Если рекомендации включены, то мы должны учитывать и другие разделы.
    if (hasRecommendations) {
      everythingIsDisabled = (!(myMusic ||
          playlists ||
          realtimePlaylists ||
          recommendedPlaylists ||
          similarMusic ||
          byVK));
    } else {
      everythingIsDisabled = (!(myMusic || playlists));
    }

    /// [List], содержащий в себе список из виджетов/разделов на главном экране, которые доожны быть разделены [Divider]'ом.
    final List<Widget> activeBlocks = useMemoized(
        () => [
              // Раздел "Моя музыка".
              if (myMusic)
                MyMusicBlock(
                  useTopButtons: isMobile,
                ),

              // Раздел "Ваши плейлисты".
              if (playlists) const MyPlaylistsBlock(),

              // Раздел "В реальном времени".
              if (realtimePlaylists) const RealtimePlaylistsBlock(),

              // Раздел "Плейлисты для Вас".
              if (recommendedPlaylists) const RecommendedPlaylistsBlock(),

              // Раздел "Совпадения по вкусам".
              if (similarMusic) const SimillarMusicBlock(),

              // Раздел "Собрано редакцией".
              if (byVK) const ByVKPlaylistsBlock(),

              // Нижняя часть интерфейса с переключателями при Mobile Layout'е.
              if (isMobile) const ChipFilters(),

              // Случай, если пользователь отключил все возможные разделы музыки.
              if (everythingIsDisabled) const EverythingIsDisabledBlock(),
            ],
        [
          myMusic,
          playlists,
          realtimePlaylists,
          recommendedPlaylists,
          similarMusic,
          byVK,
          everythingIsDisabled,
        ]);

    return Scaffold(
      appBar: isMobile
          ? AppBar(
              title: StreamBuilder<bool>(
                stream: connectivityManager.connectionChange,
                builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                  final bool isConnected = connectivityManager.hasConnection;

                  return Text(
                    isConnected ? l18n.music_label : l18n.music_labelOffline,
                  );
                },
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  onPressed: () {
                    if (!networkRequiredDialog(ref, context)) return;

                    showDialog(
                      context: context,
                      builder: (context) => const SearchDisplayDialog(),
                    );
                  },
                  icon: const Icon(
                    Icons.search,
                  ),
                ),
                const Gap(18),
              ],
            )
          : null,
      body: ScrollConfiguration(
        behavior: AlwaysScrollableScrollBehavior(),
        child: RefreshIndicator.adaptive(
          onRefresh: () => ref.refresh(playlistsProvider.future),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.only(
                    left: isMobile ? 16 : 24,
                    right: isMobile ? 16 : 24,
                    top: isMobile ? 4 : 30,
                    bottom: isMobile ? 20 : 30,
                  ),
                  children: [
                    // Часть интерфейса "Добро пожаловать", а так же кнопка поиска.
                    if (!isMobile)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: 36,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Аватарка пользователя.
                                // TODO: Избавиться от анимации изменения размера плеера.
                                if (user.photoMaxUrl != null)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      right: 18,
                                    ),
                                    child: CachedNetworkImage(
                                      imageUrl: user.photoMaxUrl!,
                                      cacheKey: "${user.id}400",
                                      imageBuilder: (
                                        BuildContext context,
                                        ImageProvider imageProvider,
                                      ) {
                                        return Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            image: DecorationImage(
                                              image: imageProvider,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        );
                                      },
                                      cacheManager:
                                          CachedNetworkImagesManager.instance,
                                    ),
                                  ),

                                // Текст "Добро пожаловать".
                                Flexible(
                                  child: Text(
                                    l18n.music_welcomeTitle(
                                      user.firstName,
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .displayMedium!
                                        .copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ),
                              ],
                            ),

                            // Поиск.
                            IconButton.filledTonal(
                              onPressed: () {
                                if (!networkRequiredDialog(ref, context)) {
                                  return;
                                }

                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return const SearchDisplayDialog();
                                  },
                                );
                              },
                              icon: const Icon(
                                Icons.search,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Верхняя часть интерфейса с переключателями при Desktop Layout'е.
                    if (!isMobile)
                      const ChipFilters(
                        showLabel: false,
                      ),
                    if (!isMobile)
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

                    // Данный Gap нужен, что бы плеер снизу при Mobile Layout'е не закрывал ничего важного.
                    if (player.loaded && isMobile) const Gap(66),
                  ],
                ),
              ),

              // Данный Gap нужен, что бы плеер снизу при Desktop Layout'е не закрывал ничего важного.
              // Мы его располагаем после ListView, что бы ScrollBar не был закрыт плеером.
              if (player.loaded && !isMobile) const Gap(88),
            ],
          ),
        ),
      ),
    );
  }
}
