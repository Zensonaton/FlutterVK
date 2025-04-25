import "dart:ui";

import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:gap/gap.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../consts.dart";
import "../extensions.dart";
import "../provider/color.dart";
import "../provider/l18n.dart";
import "../provider/player.dart";
import "../provider/preferences.dart";
import "../provider/user.dart";
import "../routes/music/bottom_audio_options.dart";
import "../services/cache_manager.dart";
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
  bool? isAvailable,
  bool showStatusIcons = false,
  bool showDuration = true,
  bool allowImageCache = true,
  bool replaceLikeWithMore = false,
  bool dense = false,
  EdgeInsets? padding,
  bool roundedCorners = true,
}) {
  final preferences = ref.read(preferencesProvider);
  final player = ref.read(playerProvider);
  final l18n = ref.watch(l18nProvider);

  final isPlaying = player.isPlaying;
  final isBuffering = player.isBuffering;
  final canPlay = audio.canPlay;
  final isSelected = audio.id == player.audio?.id;

  Future<void> onPlayToggle() async {
    if (!audio.canPlay) {
      showErrorDialog(
        context,
        title: audio.isRestricted
            ? l18n.track_restricted_title
            : l18n.track_unavailable_offline_title,
        description: audio.isRestricted
            ? l18n.track_restricted_desc
            : l18n.track_unavailable_offline_desc,
      );

      return;
    }

    FocusScope.of(context).unfocus();
    HapticFeedback.selectionClick();

    if (isSelected) {
      await player.togglePlay();

      return;
    }

    if (preferences.shuffleOnPlay) {
      await player.setShuffle(true);
    }
    await player.setPlaylist(
      playlist,
      initialAudio: audio,
    );
  }

  Future<void> onLikeTap() async {
    if (!networkRequiredDialog(ref, context)) return;

    if (!audio.isLiked && ref.read(preferencesProvider).checkBeforeFavorite) {
      if (!await audio.checkForDuplicates(ref, context)) return;
    }
    if (!context.mounted) return;

    HapticFeedback.lightImpact();

    await audio.likeDislikeRestoreSafe(
      context,
      player.ref,
      sourcePlaylist: playlist,
    );
  }

  void showMore([bool viaLongPress = false]) {
    FocusScope.of(context).unfocus();

    if (!viaLongPress) {
      HapticFeedback.selectionClick();
    }

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
  }

  return AudioTrackTile(
    audio: audio,
    isSelected: isSelected,
    isPlaying: isPlaying,
    isLoading: isSelected && isBuffering,
    isAvailable: isAvailable ?? canPlay,
    glowIfSelected: true,
    showTrackImage: preferences.showTrackThumbnails,
    showStatusIcons: showStatusIcons,
    showDuration: showDuration,
    allowImageCache: allowImageCache,
    dense: dense,
    padding: padding,
    roundedCorners: roundedCorners,
    onPlayToggle: onPlayToggle,
    onLikeTap: !replaceLikeWithMore ? onLikeTap : null,
    onSecondaryAction: () => showMore(true),
    onMoreTap: replaceLikeWithMore ? showMore : null,
  );
}

/// Виджет, являющийся частью [MusicPlayerWidget] и [AudioTrackTile], который отображает название трека ([title]) и подпись ([subtitle]), если таковая имеется.
class TrackTitleWithSubtitle extends StatelessWidget {
  /// Название трека.
  final String title;

  /// Подпись трека. Может отсутствовать.
  final String? subtitle;

  /// Цвет текста для [title] и [subtitle].
  final Color textColor;

  /// Размер шрифта.
  final double? fontSize;

  /// Указывает, что это Explicit-трек.
  final bool isExplicit;

  /// Если [isExplicit] правдив, то указывает цвет для иконки Explicit.
  final Color? explicitColor;

  /// Управляет возможностью выделить и скопировать название трека.
  final bool allowTextSelection;

  const TrackTitleWithSubtitle({
    super.key,
    required this.title,
    this.subtitle,
    required this.textColor,
    this.fontSize,
    this.isExplicit = false,
    this.explicitColor,
    this.allowTextSelection = false,
  });

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle = TextStyle(
      fontWeight: FontWeight.w500,
      color: textColor,
      fontSize: fontSize,
    );

    return Text.rich(
      TextSpan(
        style: titleStyle,
        children: [
          // Название трека.
          TextSpan(
            text: title,
            style: titleStyle.copyWith(
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Подпись трека, если таковая имеется.
          if (subtitle != null)
            TextSpan(
              text: " ($subtitle)",
              style: TextStyle(
                fontWeight: FontWeight.w300,
                color: textColor.withValues(alpha: 0.75),
              ),
            ),

          // Explicit.
          if (isExplicit)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 4,
                ),
                child: Icon(
                  Icons.explicit,
                  color: explicitColor,
                  size: 18,
                ),
              ),
            ),

          // Дополнительный пробел, что бы при выделении текста был пробел.
          if (allowTextSelection)
            const TextSpan(
              text: " ",
            ),
        ],
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Часть [AudioTrackTile], используемая для отображения изображения трека, при его наличии.
class AudioTrackImage extends HookWidget {
  /// Размер для изображения трека.
  final double imageSize;

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
    this.imageSize = AudioTrackTile.height,
    this.isAvailable = true,
    this.isSelected = false,
    this.isLoading = false,
    this.isPlaying = false,
    this.isHovered = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget placeholder = FallbackAudioAvatar(size: imageSize);
    final memorySize =
        (MediaQuery.of(context).devicePixelRatio * imageSize).toInt();
    final selectedAndPlaying = isSelected && isPlaying;
    final scheme = Theme.of(context).colorScheme;

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
          fit: BoxFit.cover,
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
        fit: BoxFit.cover,
        placeholder: (BuildContext context, String string) {
          return placeholder;
        },
        cacheManager: CachedAlbumImagesManager.instance,
      );
    }

    final imageWidget = getImageWidget();

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
                  foregroundDecoration: BoxDecoration(
                    color: scheme.surface.withValues(
                      alpha: 0.5,
                    ),
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
                          color: scheme.primary,
                        ),
                )
              : Icon(
                  selectedAndPlaying ? Icons.pause : Icons.play_arrow,
                  color: scheme.primary,
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

  /// Название альбома. Может отсутствовать.
  final String? album;

  /// Доступен ли трек.
  ///
  /// Если false, то текст становится серым.
  final bool isAvailable;

  /// Является ли трек explicit.
  final bool isExplicit;

  /// Указывает, что этот трек играет в данный момент.
  final bool isSelected;

  /// Управляет возможностью выделить и скопировать название трека.
  final bool allowTextSelection;

  const AudioTrackTitle({
    super.key,
    required this.title,
    required this.artist,
    this.subtitle,
    this.album,
    this.isAvailable = true,
    this.isExplicit = true,
    this.isSelected = false,
    this.allowTextSelection = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color primaryTextColor =
        isSelected ? scheme.primary : scheme.onSurface;
    final Color primaryIconColor = primaryTextColor.withValues(alpha: 0.75);

    final widget = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ряд с названием, subtitle, иконкой explicit.
        TrackTitleWithSubtitle(
          title: title,
          subtitle: subtitle,
          textColor:
              primaryTextColor.withValues(alpha: isAvailable ? 1.0 : 0.5),
          isExplicit: isExplicit,
          explicitColor:
              primaryIconColor.withValues(alpha: isAvailable ? 0.75 : 0.3),
          allowTextSelection: allowTextSelection,
        ),

        // Исполнитель.
        Text(
          artist,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: primaryTextColor.withValues(alpha: isAvailable ? 0.9 : 0.5),
          ),
        ),

        // Название альбома, если это разрешено и альбом есть.
        if (album != null)
          Text(
            album!,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color:
                  primaryTextColor.withValues(alpha: isAvailable ? 0.75 : 0.5),
            ),
          ),
      ],
    );

    if (allowTextSelection) {
      return SelectionArea(
        child: widget,
      );
    }

    return widget;
  }
}

/// Часть [AudioTrackOtherInfo], отображающая [Column] из иконок, символизирующих состояние кэширования и прочей информации.
class AudioTrackOtherInfoIcons extends ConsumerWidget {
  /// Цвет для иконок.
  final Color color;

  /// Указывает, что будет отображена более плотная версия иконок.
  final bool dense;

  /// Указывает, что будет показана иконка кэша.
  final bool isCached;

  /// Указывает, что трек был заменён локально.
  final bool isReplacedLocally;

  /// Указывает, что трек ограничен.
  final bool isRestricted;

  const AudioTrackOtherInfoIcons({
    super.key,
    required this.color,
    this.dense = false,
    this.isCached = false,
    this.isReplacedLocally = false,
    this.isRestricted = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);

    final List<IconData> icons = [
      // Кэширование.
      if (isCached) Icons.arrow_downward,

      // Локально заменённый трек.
      if (isReplacedLocally) Icons.sd_card,

      // Ограниченный трек.
      if (isRestricted) Icons.music_off,
    ];
    final List<String> tooltips = [
      // Кэширование.
      if (isCached) l18n.icon_tooltip_downloaded,

      // Локально заменённый трек.
      if (isReplacedLocally) l18n.icon_tooltip_replaced_locally,

      // Ограниченный трек.
      if (isRestricted)
        (isReplacedLocally || isCached)
            ? l18n.icon_tooltip_restricted_playable
            : l18n.icon_tooltip_restricted,
    ];
    final tooltip = tooltips.join(", ");

    return Tooltip(
      message: tooltip,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: AudioTrackTile.height,
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            iconTheme: IconThemeData(
              size: dense ? 16 : 18,
              color: color.withValues(alpha: 0.75),
            ),
          ),
          child: Wrap(
            direction: Axis.vertical,
            spacing: 4,
            runSpacing: dense ? 4 : 8,
            alignment: WrapAlignment.center,
            children: icons.map(
              (iconData) {
                return Icon(
                  iconData,
                );
              },
            ).toList(),
          ),
        ),
      ),
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

  /// Указывает, что будут указаны иконки состояния справа (кэширования, локальной замены, недоступности, ...).
  final bool showStatusIcons;

  /// Кэширован ли трек.
  final bool isCached;

  /// Указывает, что трек был заменён локально.
  final bool isReplacedLocally;

  /// Указывает, что трек ограничен.
  final bool isRestricted;

  /// Делает расположение кнопок справа более плотным (сжатым).
  final bool dense;

  /// Callback-метод, вызываемый при нажатии на кнопку "лайка" трека.
  ///
  /// Если не указан, то кнопки лайка не будет.
  final AsyncCallback? onLikeTap;

  /// Действие, вызываемое при нажатии на `...` справа.
  ///
  /// Если не указано, то кнопка `...` не будет показана.
  final VoidCallback? onMoreTap;

  const AudioTrackOtherInfo({
    super.key,
    this.duration,
    this.isSelected = false,
    this.isFavorite = false,
    this.isCached = false,
    this.showStatusIcons = true,
    this.isReplacedLocally = false,
    this.isRestricted = false,
    this.dense = false,
    this.onLikeTap,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color color = isSelected ? scheme.primary : scheme.onSurface;

    return Row(
      children: [
        // Множество иконок, отображающих состояние трека.
        if (showStatusIcons) ...[
          AudioTrackOtherInfoIcons(
            color: color,
            dense: dense,
            isCached: isCached,
            isReplacedLocally: isReplacedLocally,
            isRestricted: isRestricted,
          ),
          Gap(dense ? 4 : 14),
        ],

        // Блок с длительностью трека, а так же иконкой кэша.
        // Длительность трека.
        if (duration != null)
          Text(
            duration!,
            style: TextStyle(
              color: color.withValues(alpha: 0.75),
            ),
          ),

        // Кнопка для лайка.
        if (onLikeTap != null) ...[
          if (!dense) const Gap(8),
          LoadingIconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_outline,
              color: scheme.primary,
            ),
            onPressed: onLikeTap,
            color: scheme.primary,
          ),
        ],

        // Кнопка `...`.
        if (onMoreTap != null) ...[
          if (!dense) const Gap(8),
          IconButton(
            icon: Icon(
              Icons.adaptive.more,
              color: scheme.primary,
            ),
            onPressed: onMoreTap,
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
  /// Высота этого виджета.
  static const double height = 50;

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

  /// Указывает, что данный трек доступен для воспроизведения.
  final bool isAvailable;

  /// Указывает, что в случае, если [isSelected] равен true, то у данного виджета будет эффект "свечения".
  final bool glowIfSelected;

  /// Указывает, будет ли отображаться обложка альбома (если он присутствует).
  final bool showTrackImage;

  /// Указывает, что под именем исполнителя будет отображаться название альбома (если он присутствует).
  final bool showAlbumName;

  /// Указывает, что будут указаны иконки состояния справа (кэширования, локальной замены, недоступности, ...).
  final bool showStatusIcons;

  /// Указывает, разрешено ли использование кэшированного изображения трека.
  final bool allowImageCache;

  /// Указывает, что будет показана длительность этого трека.
  final bool showDuration;

  /// Делает расположение кнопок справа более плотным (сжатым).
  final bool dense;

  /// Внутренний Padding.
  final EdgeInsetsGeometry? padding;

  /// Указывает, что данный виджет будет иметь скруглённые углы.
  final bool roundedCorners;

  /// Управляет возможностью выделить и скопировать название трека.
  final bool allowTextSelection;

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

  /// Действие, вызываемое при нажатии на `...` справа.
  ///
  /// Если не указано, то кнопка `...` не будет показана.
  final VoidCallback? onMoreTap;

  const AudioTrackTile({
    super.key,
    required this.audio,
    this.isSelected = false,
    this.isLoading = false,
    this.isPlaying = false,
    this.isAvailable = true,
    this.glowIfSelected = false,
    this.showTrackImage = true,
    this.showAlbumName = false,
    this.showStatusIcons = true,
    this.allowImageCache = true,
    this.showDuration = true,
    this.dense = false,
    this.padding,
    this.roundedCorners = true,
    this.allowTextSelection = false,
    this.onPlayToggle,
    this.onLikeTap,
    this.onSecondaryAction,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schemeInfo = ref.watch(trackSchemeInfoProvider);
    final preferences = ref.watch(preferencesProvider);

    final brightness = Theme.of(context).brightness;

    final isHovered = useState(false);

    final ColorScheme scheme = useMemoized(
      () {
        if (!isSelected || schemeInfo == null) {
          return Theme.of(context).colorScheme;
        }

        return schemeInfo.createScheme(
          brightness,
          schemeVariant: preferences.dynamicSchemeType,
        );
      },
      [
        isSelected,
        preferences.dynamicSchemeType,
        brightness,
        schemeInfo,
        Theme.of(context).colorScheme,
      ],
    );

    final isExplicit = audio.isExplicit;
    final durationString = audio.durationString;
    final isCached = audio.isCached ?? false;
    final isReplacedLocally = audio.replacedLocally ?? false;

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
          borderRadius: roundedCorners
              ? BorderRadius.circular(
                  globalBorderRadius,
                )
              : null,
          child: Padding(
            padding: padding ?? EdgeInsets.zero,
            child: Container(
              decoration: BoxDecoration(
                gradient: isSelected && glowIfSelected
                    ? LinearGradient(
                        colors: [
                          scheme.primary.withValues(
                            alpha: 0.1,
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
                spacing: 12,
                children: [
                  if (showTrackImage)
                    AudioTrackImage(
                      imageUrl: audio.smallestThumbnail,
                      cacheKey:
                          allowImageCache ? "${audio.mediaKey}small" : null,
                      isAvailable: isAvailable,
                      isSelected: isSelected,
                      isPlaying: isPlaying,
                      isLoading: isLoading,
                      isHovered: isHovered.value,
                    )
                  else
                    const SizedBox(height: height),
                  Expanded(
                    child: AudioTrackTitle(
                      title: audio.title,
                      artist: audio.artist,
                      subtitle: audio.subtitle,
                      album: showAlbumName ? audio.album?.title : null,
                      isAvailable: isAvailable,
                      isExplicit: isExplicit,
                      isSelected: isSelected,
                      allowTextSelection: allowTextSelection,
                    ),
                  ),
                  if (showDuration || onLikeTap != null || onMoreTap != null)
                    AudioTrackOtherInfo(
                      duration: showDuration ? durationString : null,
                      isFavorite: audio.isLiked,
                      isSelected: isSelected,
                      showStatusIcons: showStatusIcons,
                      isCached: isCached,
                      isReplacedLocally: isReplacedLocally,
                      isRestricted: audio.isRestricted,
                      dense: dense,
                      onLikeTap: onLikeTap,
                      onMoreTap: onMoreTap,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
