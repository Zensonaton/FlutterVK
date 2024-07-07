import "dart:ui";

import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:gap/gap.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:styled_text/widgets/styled_text.dart";

import "../consts.dart";
import "../main.dart";
import "../provider/color.dart";
import "../provider/l18n.dart";
import "../provider/user.dart";
import "../routes/home.dart";
import "../routes/home/music/bottom_audio_options.dart";
import "../services/cache_manager.dart";
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
}) {
  final l18n = ref.watch(l18nProvider);
  final bool isSelected = audio == player.currentAudio;

  return AudioTrackTile(
    key: ValueKey(
      audio.id,
    ),
    isSelected: isSelected,
    isPlaying: player.loaded && player.playing,
    isLoading: isSelected && player.buffering,
    audio: audio,
    glowIfSelected: true,
    showCachedIcon: showCachedIcon,
    onPlayToggle: () async {
      // Если этот трек уже играет, то просто делаем toggle воспроизведения.
      if (isSelected) {
        await player.togglePlay();

        return;
      }

      // Если мы не можем начать воспроизведение этого трека, то выдаём ошибку.
      if (!audio.canPlay) {
        showErrorDialog(
          context,
          title: l18n.music_trackUnavailableTitle,
          description: l18n.music_trackUnavailableDescription,
        );

        return;
      }

      // Запускаем воспроизведение.
      await player.setPlaylist(
        playlist,
        audio: audio,
      );
    },
    onLikeTap: () async {
      if (!networkRequiredDialog(ref, context)) return;

      await toggleTrackLike(
        ref,
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
          child: isLoading || isSelected || isHovered
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

/// Виджет, являющийся частью [AudioTrackTitle], который либо использует [Text], либо [StyledText] в зависимости от того, указан [subtitle] или нет.
class TrackTitleWithSubtitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color color;

  const TrackTitleWithSubtitle({
    super.key,
    required this.title,
    this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle = TextStyle(
      fontWeight: FontWeight.w500,
      color: color,
    );

    // Если есть subtitle, то делаем RichText.
    if (subtitle != null) {
      return RichText(
        text: TextSpan(
          text: title,
          style: titleStyle,
          children: [
            TextSpan(
              text: " ($subtitle)",
              style: TextStyle(
                fontWeight: FontWeight.w300,
                color: color.withOpacity(0.75),
              ),
            ),
          ],
        ),
        overflow: TextOverflow.ellipsis,
      );
    }

    return Text(
      title,
      overflow: TextOverflow.ellipsis,
      style: titleStyle,
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
                color: primaryTextColor,
              ),
            ),

            // Explicit.
            if (isExplicit) ...[
              const Gap(4),
              Icon(
                Icons.explicit,
                size: 18,
                color: primaryIconColor,
              ),
            ],
          ],
        ),

        // Исполнитель.
        Text(
          artist,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: primaryTextColor.withOpacity(0.9),
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
    this.onLikeTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color color = isSelected ? scheme.primary : scheme.onSurface;

    return Row(
      children: [
        // Иконка кэша, при наличии.
        if (isCached)
          Icon(
            Icons.arrow_downward,
            size: 18,
            color: color.withOpacity(0.75),
          ),
        const Gap(14),

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
              color: color,
            ),
            onPressed: onLikeTap,
            color: color,
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

  // TODO: Использовать кэширование?

  const AudioTrackTile({
    super.key,
    required this.audio,
    this.isSelected = false,
    this.isLoading = false,
    this.isPlaying = false,
    this.glowIfSelected = false,
    this.showCachedIcon = true,
    this.forceAvailable = false,
    this.showDuration = true,
    this.onPlayToggle,
    this.onLikeTap,
    this.onSecondaryAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHovered = useState(false);

    final ColorScheme scheme = ((isSelected
            ? ref
                .watch(trackSchemeInfoProvider)
                ?.colorScheme(Theme.of(context).brightness)
            : null) ??
        Theme.of(context).colorScheme);

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
                  cacheKey: "${audio.mediaKey}small",
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
                    isAvailable: audio.canPlay,
                    isExplicit: audio.isExplicit,
                    isSelected: isSelected,
                  ),
                ),
                const Gap(12),

                // Прочая информация по треку. (справа)
                // Данный блок можно не отображать, если ничего не было передано.
                if (showDuration || onLikeTap != null)
                  AudioTrackOtherInfo(
                    duration: audio.durationString,
                    isFavorite: audio.isLiked,
                    isSelected: isSelected,
                    isCached: audio.isCached ?? false,
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
