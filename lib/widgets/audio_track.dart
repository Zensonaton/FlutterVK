import "dart:ui";

import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:gap/gap.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../api/vk/shared.dart";
import "../consts.dart";
import "../main.dart";
import "../provider/color.dart";
import "../provider/l18n.dart";
import "../provider/preferences.dart";
import "../provider/user.dart";
import "../routes/home/music.dart";
import "../routes/home/music/bottom_audio_options.dart";
import "../services/cache_manager.dart";
import "../services/logger.dart";
import "../utils.dart";
import "audio_player.dart";
import "dialogs.dart";
import "fallback_audio_photo.dart";
import "loading_button.dart";

/// Создаёт виджет типа [AudioTrackTile] для отображения в [ListView.builder] или подобном.
///
/// [playlist] указывает, из какого [ExtendedPlaylist] должно запуститься воспроизведение треков при нажатии по созданному виджету трека.
Widget buildListTrackWidget(
  WidgetRef ref,
  BuildContext context,
  ExtendedAudio audio,
  ExtendedPlaylist playlist, {
  bool showCachedIcon = false,
  bool showDuration = true,
  bool allowImageCache = true,
}) {
  final logger = getLogger("buildListTrackWidget");
  final l18n = ref.watch(l18nProvider);
  final bool isSelected = audio.ownerID == player.currentAudio?.ownerID &&
      audio.id == player.currentAudio?.id;

  return AudioTrackTile(
    isSelected: isSelected && player.loaded,
    isPlaying: player.loaded && player.playing,
    isLoading: isSelected && player.buffering,
    audio: audio,
    glowIfSelected: true,
    showCachedIcon: showCachedIcon,
    showDuration: showDuration,
    allowImageCache: allowImageCache,
    onPlayToggle: () async {
      // Если мы не можем начать воспроизведение этого трека, то выдаём ошибку.
      if (!audio.canPlay) {
        showErrorDialog(
          context,
          title: l18n.music_trackUnavailableTitle,
          description: l18n.music_trackUnavailableDescription,
        );

        return;
      }

      // Убираем фокус с поля ввода, если оно есть.
      FocusScope.of(context).unfocus();

      // Если этот трек уже играет, то просто делаем toggle воспроизведения.
      if (isSelected) {
        await player.togglePlay();

        return;
      }

      // Запускаем воспроизведение.
      await player.setPlaylist(playlist, selectedTrack: audio);
    },
    onLikeTap: () async {
      if (!networkRequiredDialog(ref, context)) return;

      if (!audio.isLiked && ref.read(preferencesProvider).checkBeforeFavorite) {
        if (!await checkForDuplicates(ref, context, audio)) return;
      }

      try {
        await toggleTrackLike(
          player.ref,
          audio,
          !audio.isLiked,
          sourcePlaylist: playlist,
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
    },
    onSecondaryAction: () {
      FocusScope.of(context).unfocus();

      showModalBottomSheet(
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
      );
    },
  );
}

/// Часть [AudioTrackTile], используемая для отображения изображения трека, при его наличии.
class AudioTrackImage extends HookWidget {
  /// Размер для изображения трека.
  static const double imageSize = 50;

  /// Url на изображение трека.
  ///
  /// Если отсутствует, то вместо изображения трека будет использоваться [FallbackAudioAvatar].
  final String? imageUrl;

  /// Ключ кэша изображения трека.
  ///
  /// Если отсутствует, то использоваться кэш не будет.
  final String? cacheKey;

  /// Доступен ли трек.
  ///
  /// Если false, то текст становится серым.
  final bool isAvailable;

  /// Указывает, что этот трек сейчас выбран.
  ///
  /// Не стоит путать с полем [isPlaying]: оно указывает, что плеер включён.
  final bool isSelected;

  /// Указывает, что данный трек загружается перед тем, как начать его воспроизведение.
  final bool isLoading;

  /// Указывает, что плеер в данный момент включён.
  final bool isPlaying;

  /// Указывает, что на данный виджет навели.
  final bool isHovered;

  const AudioTrackImage({
    super.key,
    this.imageUrl,
    this.cacheKey,
    this.isAvailable = true,
    this.isSelected = false,
    this.isLoading = false,
    this.isPlaying = false,
    this.isHovered = false,
  });

  @override
  Widget build(BuildContext context) {
    const Widget placeholder = FallbackAudioAvatar();
    final int memorySize =
        (MediaQuery.of(context).devicePixelRatio * imageSize).toInt();
    final bool selectedAndPlaying = isSelected && isPlaying;

    Widget getImageWidget() {
      // Возвращаем fallbackAvatar, если изображения трека нету.
      if (imageUrl == null) return placeholder;

      // Если у нас не дан ключ для кэширования, то используем Image.network.
      if (cacheKey == null) {
        return Image.network(
          imageUrl!,
          width: imageSize,
          height: imageSize,
          cacheWidth: memorySize,
          cacheHeight: memorySize,
          frameBuilder: (_, Widget child, int? frame, bool loaded) {
            if (loaded || frame != null) return child;

            return placeholder;
          },
        );
      }

      return CachedNetworkImage(
        imageUrl: imageUrl!,
        cacheKey: cacheKey,
        width: imageSize,
        height: imageSize,
        memCacheWidth: memorySize,
        memCacheHeight: memorySize,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholderFadeInDuration: Duration.zero,
        placeholder: (BuildContext context, String url) => placeholder,
        cacheManager: CachedAlbumImagesManager.instance,
      );
    }

    final Widget imageWidget = getImageWidget();

    return Stack(
      alignment: Alignment.center,
      children: [
        // Обрезанное изображение трека.
        ClipRRect(
          borderRadius: BorderRadius.circular(
            globalBorderRadius,
          ),
          child: isLoading || isSelected || isHovered || !isAvailable
              ? Container(
                  foregroundDecoration: const BoxDecoration(
                    color: Colors.black54,
                  ),
                  child: (isLoading && isSelected)
                      ? ImageFiltered(
                          imageFilter: ImageFilter.blur(
                            sigmaX: 3,
                            sigmaY: 3,
                            tileMode: TileMode.decal,
                          ),
                          child: imageWidget,
                        )
                      : imageWidget,
                )
              : imageWidget,
        ),

        // Анимация загрузки/проигрывания, иконка паузы/воспроизведения.
        if (isHovered || isSelected)
          !isHovered && selectedAndPlaying
              ? RepaintBoundary(
                  child: isLoading
                      ? const SizedBox(
                          height: 25,
                          width: 25,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                          ),
                        )
                      : Image.asset(
                          "assets/images/audioEqualizer.gif",
                          width: 18,
                          height: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                )
              : Icon(
                  selectedAndPlaying ? Icons.pause : Icons.play_arrow,
                  color: Theme.of(context).colorScheme.primary,
                ),
      ],
    );
  }
}

/// Часть [AudioTrackTile], используемая для отображения основной информации трека: названия ([ExtendedAudio.title]), исполнителя ([ExtendedAudio.artist]) и подобные, а так же различные иконки кэширования, explicit и подобные.
class AudioTrackTitle extends ConsumerWidget {
  /// Название трека.
  final String title;

  /// Исполнитель трека.
  final String artist;

  /// Подпись трека. Может отсутствовать.
  final String? subtitle;

  /// Доступен ли трек.
  ///
  /// Если false, то текст становится серым.
  final bool isAvailable;

  /// Является ли трек explicit.
  final bool isExplicit;

  /// Указывает, что этот трек играет в данный момент.
  final bool isSelected;

  const AudioTrackTitle({
    super.key,
    required this.title,
    required this.artist,
    this.subtitle,
    this.isAvailable = true,
    this.isExplicit = true,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color primaryTextColor =
        isSelected ? scheme.primary : scheme.onSurface;
    final Color primaryIconColor = primaryTextColor.withOpacity(0.75);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ряд с названием, subtitle, иконкой explicit.
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Название, а так же subtitle.
            Flexible(
              child: TrackTitleWithSubtitle(
                title: title,
                subtitle: subtitle,
                color: primaryTextColor.withOpacity(isAvailable ? 1.0 : 0.5),
              ),
            ),

            // Explicit.
            if (isExplicit) ...[
              const Gap(4),
              Icon(
                Icons.explicit,
                size: 18,
                color: primaryIconColor.withOpacity(isAvailable ? 0.75 : 0.3),
              ),
            ],
          ],
        ),

        // Исполнитель.
        Text(
          artist,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: primaryTextColor.withOpacity(isAvailable ? 0.9 : 0.5),
          ),
        ),
      ],
    );
  }
}

/// Часть [AudioTrackTile], используемая для отображения информации по длительности трека, а так же кнопки для лайка трека, при необходимости.
class AudioTrackOtherInfo extends ConsumerWidget {
  /// Длительность трека.
  ///
  /// Если не указано, то надписи с длительностью трека не будет.
  final String? duration;

  /// Указывает, лайкнут ли этот трек.
  final bool isFavorite;

  /// Указывает, что этот трек играет в данный момент.
  final bool isSelected;

  /// Кэширован ли трек.
  final bool isCached;

  /// Указывает, что в случае, если трек кэширован ([ExtendedAudio.isCached]), то будет показана соответствующая иконка.
  final bool showCachedIcon;

  /// Callback-метод, вызываемый при нажатии на кнопку "лайка" трека.
  ///
  /// Если не указан, то кнопки лайка не будет.
  final AsyncCallback? onLikeTap;

  const AudioTrackOtherInfo({
    super.key,
    this.duration,
    this.isSelected = false,
    this.isFavorite = false,
    this.isCached = false,
    this.showCachedIcon = true,
    this.onLikeTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color color = isSelected ? scheme.primary : scheme.onSurface;

    return Row(
      children: [
        // Иконка кэша, при наличии.
        if (isCached && showCachedIcon) ...[
          Icon(
            Icons.arrow_downward,
            size: 18,
            color: color.withOpacity(0.75),
          ),
          const Gap(14),
        ],

        // Блок с длительностью трека, а так же иконкой кэша.
        // Длительность трека.
        if (duration != null)
          Text(
            duration!,
            style: TextStyle(
              color: color.withOpacity(0.75),
            ),
          ),

        // Кнопка для лайка.
        if (onLikeTap != null) ...[
          const Gap(8),
          LoadingIconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_outline,
              color: scheme.primary,
            ),
            onPressed: onLikeTap,
            color: scheme.primary,
          ),
        ],
      ],
    );
  }
}

/// Виджет, олицетворяющий отдельный трек среди списка треков.
///
/// У такового виджета есть изображение, название, а так же блок, в котором отображается его длительность.
class AudioTrackTile extends HookConsumerWidget {
  /// Объект типа [ExtendedAudio], олицетворяющий данный трек.
  final ExtendedAudio audio;

  /// Указывает, что этот трек сейчас выбран.
  ///
  /// Не стоит путать с полем [isPlaying]: оно указывает, что плеер включён.
  final bool isSelected;

  /// Указывает, что плеер в данный момент включён.
  final bool isPlaying;

  /// Указывает, что данный трек загружается перед тем, как начать его воспроизведение.
  final bool isLoading;

  /// Указывает, что в случае, если [isSelected] равен true, то у данного виджета будет эффект "свечения".
  final bool glowIfSelected;

  /// Указывает, что в случае, если трек кэширован ([ExtendedAudio.isCached]), то будет показана соответствующая иконка.
  final bool showCachedIcon;

  /// Если true, то данный виджет будет не будет иметь эффект прозрачности даже если [ExtendedAudio.canPlay] равен false.
  final bool forceAvailable;

  /// Указывает, разрешено ли использование кэшированного изображения трека.
  final bool allowImageCache;

  /// Указывает, что будет показана длительность этого трека.
  final bool showDuration;

  /// Действие, вызываемое при нажатии на этот виджет.
  ///
  /// Обычно, по нажатию на этот виджет должно запускаться воспроизведение этого трека, а если он уже играет, то он должен ставиться на паузу/возобновляться.
  final VoidCallback? onPlayToggle;

  /// Действие, вызываемое при переключении состояния "лайка" данного трека.
  ///
  /// Если не указано, то кнопка лайка не будет показана.
  final AsyncCallback? onLikeTap;

  /// Действие, вызываемое при выборе ПКМ (или зажатии) по данном элементу.
  ///
  /// Чаще всего используется для открытия контекстного меню.
  final VoidCallback? onSecondaryAction;

  const AudioTrackTile({
    super.key,
    required this.audio,
    this.isSelected = false,
    this.isLoading = false,
    this.isPlaying = false,
    this.glowIfSelected = false,
    this.showCachedIcon = true,
    this.forceAvailable = false,
    this.allowImageCache = true,
    this.showDuration = true,
    this.onPlayToggle,
    this.onLikeTap,
    this.onSecondaryAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHovered = useState(false);

    final schemeInfo = ref.watch(trackSchemeInfoProvider);
    final preferences = ref.watch(preferencesProvider);
    final brightness = Theme.of(context).brightness;

    // FIXME: Нужно каким-то образом оптимизировать это.
    final ColorScheme scheme = (!isSelected || schemeInfo == null)
        ? Theme.of(context).colorScheme
        : schemeInfo.createScheme(
            brightness,
            schemeVariant: preferences.dynamicSchemeType,
          );

    return Theme(
      data: ThemeData(
        colorScheme: scheme,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onHover: (bool value) => isHovered.value = value,
          onTap: onPlayToggle,
          onSecondaryTap: onSecondaryAction,
          onLongPress: isMobile ? onSecondaryAction : null,
          borderRadius: BorderRadius.circular(
            globalBorderRadius,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: isSelected && glowIfSelected
                  ? LinearGradient(
                      colors: [
                        scheme.primary.withOpacity(
                          0.1,
                        ),
                        Colors.transparent,
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(
                globalBorderRadius,
              ),
            ),
            child: Row(
              children: [
                // Изображение трека. (слева)
                AudioTrackImage(
                  imageUrl: audio.smallestThumbnail,
                  cacheKey: allowImageCache ? "${audio.mediaKey}small" : null,
                  isAvailable: forceAvailable || audio.canPlay,
                  isSelected: isSelected,
                  isPlaying: isPlaying,
                  isLoading: isLoading,
                  isHovered: isHovered.value,
                ),
                const Gap(12),

                // Название, и прочая информация по треку. (центр)
                Expanded(
                  child: AudioTrackTitle(
                    title: audio.title,
                    artist: audio.artist,
                    subtitle: audio.subtitle,
                    isAvailable: forceAvailable || audio.canPlay,
                    isExplicit: audio.isExplicit,
                    isSelected: isSelected,
                  ),
                ),
                const Gap(12),

                // Прочая информация по треку. (справа)
                // Данный блок можно не отображать, если ничего не было передано.
                if (showDuration || onLikeTap != null)
                  AudioTrackOtherInfo(
                    duration: showDuration ? audio.durationString : null,
                    isFavorite: audio.isLiked,
                    isSelected: isSelected,
                    isCached: audio.isCached ?? false,
                    showCachedIcon: showCachedIcon,
                    onLikeTap: onLikeTap,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
