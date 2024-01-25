import "dart:async";
import "dart:ui";

import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:fullscreen_window/fullscreen_window.dart";
import "package:just_audio/just_audio.dart";
import "package:provider/provider.dart";
import "package:responsive_builder/responsive_builder.dart";
import "package:scroll_to_index/scroll_to_index.dart";
import "package:skeletonizer/skeletonizer.dart";
import "package:styled_text/styled_text.dart";
import "package:visibility_detector/visibility_detector.dart";

import "../api/audio/get_lyrics.dart";
import "../consts.dart";
import "../main.dart";
import "../provider/color.dart";
import "../provider/user.dart";
import "../services/cache_manager.dart";
import "../services/logger.dart";
import "../utils.dart";
import "../widgets/fallback_audio_photo.dart";
import "../widgets/page_route.dart";
import "../widgets/scrollable_slider.dart";
import "home.dart";
import "home/music.dart";

/// Метод, который открывает музыкальный плеер на всё окно, либо на весь экран, если приложение запущено на Desktop-платформе. Если [fullscreenOnDesktop] правдив, и приложение запущено на Desktop ([isDesktop]), то тогда приложение перейдёт в полноэкранный режим.
///
/// Для закрытия воспользуйтесь методом [closeFullscreenPlayer].
Future<void> openFullscreenPlayer(
  BuildContext context, {
  bool fullscreenOnDesktop = true,
}) async {
  // Если приложение запущено на Desktop, то нужно отобразить окно на весь экран.
  if (isDesktop && fullscreenOnDesktop) {
    await FullScreenWindow.setFullScreen(true);
  }

  if (context.mounted) {
    Navigator.push(
      context,
      Material3PageRoute(
        builder: (context) => const FullscreenPlayerRoute(),
      ),
    );
  }
}

/// Метод, закрывающий ранее открытый при помощи метода [openFullscreenPlayer] полноэкранный плеер.
Future<void> closeFullscreenPlayer(
  BuildContext context,
) async {
  // Если приложение запущено на Desktop, то нужно закрыть полноэкранный режим.
  if (isDesktop) {
    await FullScreenWindow.setFullScreen(false);
  }

  if (context.mounted) {
    Navigator.of(context).pop();
  }
}

/// Виджет, отображающий отдельную строчку линии в тексте трека. По нажатию по данной линии, плеер перемотается на начало данной линии.
class TrackLyric extends StatelessWidget {
  /// Текст данной строчки. Если данное поле равно null, то вместо текста будет использоваться виджет [Icon], с иконкой ноты.
  final String? line;

  /// Указывает, что данная строчка была проиграна ранее, и теперь она неактивна.
  final bool isOld;

  /// Указывает, что данная строчка сейчас активна.
  final bool isActive;

  /// Указывает, что текст должен находиться по центру.
  final bool centerText;

  /// Действие, вызываемое при нажатии на данную строчку.
  final VoidCallback? onTap;

  const TrackLyric({
    super.key,
    this.line,
    this.isOld = false,
    required this.isActive,
    this.centerText = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color color = Theme.of(context).colorScheme.primary.withOpacity(
          isActive && !isOld
              ? 1.0
              : isOld
                  ? 0.75
                  : 0.5,
        );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
        globalBorderRadius,
      ),
      child: AnimatedDefaultTextStyle(
        duration: const Duration(
          milliseconds: 300,
        ),
        style: TextStyle(
          fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
          color: color,
          fontSize: 24,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 4,
          ),
          child: line != null
              ? Text(
                  line!,
                  textAlign: centerText ? TextAlign.center : null,
                )
              : Icon(
                  Icons.music_note,
                  color: color,
                ),
        ),
      ),
    );
  }
}

/// Виджет, отображающий текст трека.
class TrackLyricsBlock extends StatefulWidget {
  final AppLogger logger = getLogger("TrackLyricsBlock");

  /// Отображаемый текст песни.
  final Lyrics lyrics;

  TrackLyricsBlock({
    super.key,
    required this.lyrics,
  });

  @override
  State<TrackLyricsBlock> createState() => _TrackLyricsBlockState();
}

class _TrackLyricsBlockState extends State<TrackLyricsBlock> {
  /// [AutoScrollController] для [ListView.builder], необходимый для автоматического перемещения до определённой строчки.
  final AutoScrollController controller = AutoScrollController();

  /// Текст песни.
  late List<LyricTimestamp> lyrics;

  /// Указывает текущую активную строчку в тексте песни.
  int? currentLyricIndex;

  /// Указывает, что виджет с текстом песни видим внутри ListView.
  bool currentLyricIsVisible = false;

  @override
  void initState() {
    super.initState();

    // Если у нас несинхронизированный текст песни, то тогда нам нужно преобразовать все [String] в [LyricTimestamp].
    lyrics = (widget.lyrics.timestamps ?? widget.lyrics.text!).map(
      (dynamic item) {
        if (item is LyricTimestamp) return item;

        return LyricTimestamp(item as String);
      },
    ).toList();

    // Пытаемся найти текущий момент в тексте песни, если мы уже что-то воспроизвели.
    currentLyricIndex = getCurrentLyricIndex();

    // Скроллим до этого момента в треке.
    if (currentLyricIndex != null) {
      currentLyricIsVisible = true;

      scrollToIndex(
        currentLyricIndex!,
        checkVisibility: false,
      );
    }
  }

  /// Возвращает индекс текущей строчки в тексте песни.
  int? getCurrentLyricIndex() {
    final int playerPosition = player.position.inMilliseconds;

    // Узнаём индекс строчки в тексте песни.
    // Начинаем с конца, на случай, если по какой-то причине "поют" сразу две строчки песни.
    for (var i = lyrics.length - 1; i >= 0; i--) {
      LyricTimestamp lyric = lyrics[i];

      // Если нам не дано начало, то просто ничего не делаем.
      if (lyric.begin == null) return null;

      // Если у нас плеер находится в 'правильной' позиции, то тогда мы нашли активную строчку.
      if (playerPosition >= lyric.begin! && playerPosition <= lyric.end!) {
        return i;
      }
    }

    // Если ничего не найдено, то индекс должен отсутствовать.
    return currentLyricIndex;
  }

  /// Прокручивает [ListView] с текстом до указанного [index]. Если [checkVisibility] = true, то прокрутка произойдёт только в том случае, если виджет с текстом виден пользователю.
  Future<void> scrollToIndex(
    int index, {
    bool checkVisibility = true,
  }) async {
    // Проверяем на видимость.
    if (checkVisibility && !currentLyricIsVisible) return;

    controller.scrollToIndex(
      currentLyricIndex!,
      preferPosition: AutoScrollPosition.middle,
    );
  }

  /// Метод, вызываемый при изменении строчки песни.
  void onLyricLineChanged() {
    // Если индекс неизвестен, то ничего не делаем.
    if (currentLyricIndex == null) return;

    scrollToIndex(currentLyricIndex!);
  }

  @override
  Widget build(BuildContext context) {
    // Пытаемся найти индекс текущего момента в тексте песни.
    final int? newLyricIndex = getCurrentLyricIndex();

    // Если поменялась строчка песни, то скроллим до этой строчки.
    if (newLyricIndex != currentLyricIndex) {
      currentLyricIndex = newLyricIndex;

      onLyricLineChanged();
    }

    return ListView.builder(
      controller: controller,
      itemCount: lyrics.length,
      itemBuilder: (BuildContext context, int index) {
        final LyricTimestamp lyric = lyrics[index];
        final bool isSyncedLyric = lyric.begin != null;

        bool isActive = isSyncedLyric && currentLyricIndex != null
            ? currentLyricIndex! == index
            : false;
        bool isOld = isSyncedLyric && currentLyricIndex != null
            ? currentLyricIndex! > index
            : true;

        return AutoScrollTag(
          key: ValueKey(index),
          controller: controller,
          index: index,
          child: VisibilityDetector(
            key: ValueKey(index),
            onVisibilityChanged: (VisibilityInfo info) {
              if (index != currentLyricIndex) return;

              currentLyricIsVisible = info.visibleFraction > 0;
            },
            child: TrackLyric(
              line: lyric.line,
              isActive: isActive,
              isOld: isOld,
              centerText: isSyncedLyric,
              onTap: isSyncedLyric
                  ? () => player.seek(
                        Duration(
                          milliseconds: lyric.begin!,
                        ),
                        play: true,
                      )
                  : null,
            ),
          ),
        );
      },
    );
  }
}

/// Desktop layout для полноэкранного плеера.
class FullscreenPlayerDesktopRoute extends StatelessWidget {
  final AppLogger logger = getLogger("FullscreenPlayerDesktopRoute");

  FullscreenPlayerDesktopRoute({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final UserProvider user = Provider.of<UserProvider>(context);

    /// Определяет по оставшейся длине трека то, стоит ли показывать надпись со следующим треком.
    final bool displayNextTrack =
        (player.currentAudio != null && player.nextAudio != null)
            ? (player.progress >= nextPlayingTextProgress)
            : false;

    /// Размер Padding'а.
    const double padding = 56;

    /// Ширина блока текста песни.
    const double lyricsBlockWidth = 500;

    /// Указывает, сохранён ли этот трек в лайкнутых.
    final bool isFavorite =
        user.favoriteMediaKeys.contains(player.currentAudio!.mediaKey);

    /// Указывает, что используется более компактный интерфейс.
    final bool compactLayout = MediaQuery.of(context).size.width <= 900;

    return Padding(
      padding: const EdgeInsets.all(
        padding,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Надпись "Воспроизведение музыки".
          Align(
            alignment: Alignment.topLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!compactLayout)
                  player.playing
                      ? Image.asset(
                          "assets/images/audioEqualizer.gif",
                          color: Theme.of(context).colorScheme.primary,
                          width: 32,
                          height: 32,
                          fit: BoxFit.fill,
                        )
                      : Icon(
                          Icons.music_note,
                          color: Theme.of(context).colorScheme.primary,
                          size: 32,
                        ),
                const SizedBox(
                  width: 14,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!
                          .music_fullscreenPlaylistNameTitle,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onBackground
                            .withOpacity(0.75),
                      ),
                    ),
                    Text(
                      player.currentPlaylist?.title ??
                          AppLocalizations.of(context)!
                              .music_fullscreenFavoritePlaylistName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Надпись со следующим треком.
          if (player.nextAudio != null)
            AnimatedOpacity(
              opacity: displayNextTrack ? 1.0 : 0.0,
              duration: const Duration(
                milliseconds: 500,
              ),
              curve: Curves.ease,
              child: AnimatedSlide(
                duration: const Duration(
                  milliseconds: 500,
                ),
                curve: Curves.ease,
                offset: Offset(
                  displayNextTrack ? 0.0 : -0.1,
                  0.0,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: () => player.next(),
                    borderRadius: BorderRadius.circular(
                      globalBorderRadius,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            globalBorderRadius,
                          ),
                          child: player.nextAudio!.album?.thumb != null
                              ? CachedNetworkImage(
                                  imageUrl:
                                      player.nextAudio!.album!.thumb!.photo600!,
                                  cacheKey: "${player.nextAudio!.mediaKey}600",
                                  width: 32,
                                  height: 32,
                                  memCacheWidth: 32,
                                  memCacheHeight: 32,
                                  placeholder:
                                      (BuildContext context, String url) =>
                                          const FallbackAudioAvatar(),
                                  cacheManager:
                                      CachedNetworkImagesManager.instance,
                                )
                              : const FallbackAudioAvatar(
                                  width: 32,
                                  height: 32,
                                ),
                        ),
                        const SizedBox(
                          width: 14,
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppLocalizations.of(context)!
                                  .music_fullscreenNextTrackTitle,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onBackground
                                    .withOpacity(0.75),
                              ),
                            ),
                            Text(
                              "${player.nextAudio!.artist} • ${player.nextAudio!.title}",
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Текст песни, либо заглушка на случай, если текста нет.
          AnimatedOpacity(
            duration: const Duration(
              milliseconds: 500,
            ),
            curve: Curves.ease,
            opacity: user.settings.trackLyricsEnabled ? 1.0 : 0.0,
            child: Align(
              alignment: Alignment.topRight,
              child: SizedBox(
                width: lyricsBlockWidth,
                height: MediaQuery.of(context).size.height - padding * 2 - 100,
                child: AnimatedSwitcher(
                  duration: const Duration(
                    milliseconds: 500,
                  ),
                  child: player.currentAudio!.hasLyrics
                      ? player.currentAudio!.lyrics != null
                          ? TrackLyricsBlock(
                              key: ValueKey(
                                player.currentAudio!.mediaKey,
                              ),
                              lyrics: player.currentAudio!.lyrics!,
                            )
                          : ListView.builder(
                              key: const ValueKey(
                                "skeleton",
                              ),
                              itemCount: 50,
                              itemBuilder: (BuildContext context, int index) {
                                return Skeletonizer(
                                  child: TrackLyric(
                                    line: fakeTrackLyrics[
                                        index % fakeTrackLyrics.length],
                                    isActive: false,
                                  ),
                                );
                              },
                            )
                      : Column(
                          key: const ValueKey(
                            "nolyrics",
                          ),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              "assets/images/dog.gif",
                              width: 25 * 5,
                              height: 12 * 5,
                              fit: BoxFit.fill,
                            ),
                            const SizedBox(
                              height: 18,
                            ),
                            StyledText(
                              text: AppLocalizations.of(context)!
                                  .music_fullscreenTrackNoLyrics,
                              textAlign: TextAlign.center,
                              tags: {
                                "bold": StyledTextTag(
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                "toggle": StyledTextActionTag(
                                  (String? text, Map<String?, String?> attrs) {
                                    user.settings.trackLyricsEnabled =
                                        !user.settings.trackLyricsEnabled;

                                    user.markUpdated();
                                  },
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              },
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),

          // Информация по текущему треку и медиаплеер.
          Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Информация по текущему треку.
                  AnimatedSwitcher(
                    duration: const Duration(
                      milliseconds: 500,
                    ),
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 200,
                      ),
                      width: MediaQuery.of(context).size.width -
                          padding * 2 -
                          (player.currentAudio!.hasLyrics
                              ? lyricsBlockWidth
                              : 0) -
                          50,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.bottomLeft,
                        child: Row(
                          key: ValueKey(
                            player.currentAudio!.mediaKey,
                          ),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Изображение трека.
                            Hero(
                              tag: "image",
                              child: Container(
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      blurRadius: 20,
                                      spreadRadius: -1,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .tertiary,
                                      blurStyle: BlurStyle.outer,
                                    )
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    globalBorderRadius,
                                  ),
                                  child: player.currentAudio!.album?.thumb !=
                                          null
                                      ? CachedNetworkImage(
                                          imageUrl: player.currentAudio!.album!
                                              .thumb!.photo600!,
                                          cacheKey:
                                              "${player.currentAudio!.mediaKey}600",
                                          width: 130,
                                          height: 130,
                                          memCacheWidth: 260,
                                          memCacheHeight: 260,
                                          fit: BoxFit.fill,
                                          placeholder: (BuildContext context,
                                                  String url) =>
                                              const FallbackAudioAvatar(),
                                          cacheManager:
                                              CachedNetworkImagesManager
                                                  .instance,
                                        )
                                      : const FallbackAudioAvatar(
                                          width: 130,
                                          height: 130,
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 24,
                            ),

                            // Информация по названию трека и его исполнителю.
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      player.currentAudio!.title,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 36,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer,
                                      ),
                                    ),
                                    if (player.currentAudio!.isExplicit)
                                      const SizedBox(
                                        width: 4,
                                      ),
                                    if (player.currentAudio!.isExplicit)
                                      Icon(
                                        Icons.explicit,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onBackground
                                            .withOpacity(0.5),
                                      ),
                                  ],
                                ),
                                Text(
                                  player.currentAudio!.artist,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer
                                        .withOpacity(0.75),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 18,
                  ),

                  // Slider для отображения прогресса воспроизведения трека.
                  SliderTheme(
                    data: SliderThemeData(
                      trackShape: CustomTrackShape(),
                      overlayShape: SliderComponentShape.noOverlay,
                      inactiveTrackColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.5),
                    ),
                    child: Slider(
                      value: player.progress,
                      onChanged: (double value) {},
                      onChangeEnd: (double newProgress) =>
                          player.seekNormalized(newProgress),
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),

                  // Кнопки управления воспроизведением.
                  Stack(
                    children: [
                      // Кнопка для лайка/дизлайка трека. Если места мало (compactLayout), то кнопка находится в панели управления плеера (ниже).
                      if (!compactLayout)
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: SizedBox(
                            height: 70,
                            child: IconButton(
                              onPressed: () => toggleTrackLikeState(
                                context,
                                player.currentAudio!,
                                !isFavorite,
                              ),
                              icon: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),

                      // Кнопки управления плеера по центру, либо слева, если места мало (compactLayout).
                      Align(
                        alignment: compactLayout
                            ? Alignment.bottomLeft
                            : Alignment.bottomCenter,
                        child: SizedBox(
                          height: 70,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Если места мало, то кнопка для лайка/дизлайка.
                              if (compactLayout)
                                IconButton(
                                  onPressed: () => toggleTrackLikeState(
                                    context,
                                    player.currentAudio!,
                                    !isFavorite,
                                  ),
                                  icon: Icon(
                                    isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              if (compactLayout)
                                const SizedBox(
                                  width: 8,
                                ),

                              // Переключение shuffle.
                              IconButton(
                                onPressed: () => player.setShuffle(
                                  !player.shuffleModeEnabled,
                                ),
                                icon: Icon(
                                  player.shuffleModeEnabled
                                      ? Icons.shuffle_on_outlined
                                      : Icons.shuffle,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(
                                width: 8,
                              ),

                              // Предыдущий трек.
                              IconButton(
                                onPressed: () => player.previous(
                                  allowSeekToBeginning: true,
                                ),
                                icon: Icon(
                                  Icons.skip_previous,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(
                                width: 8,
                              ),

                              // Пауза/воспроизведение.
                              IconButton(
                                onPressed: () => player.togglePlay(),
                                icon: Icon(
                                  player.playing
                                      ? Icons.pause_circle
                                      : Icons.play_circle,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                                iconSize: 50,
                              ),
                              const SizedBox(
                                width: 8,
                              ),

                              // Следующий трек.
                              IconButton(
                                onPressed: () => player.next(),
                                icon: Icon(
                                  Icons.skip_next,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(
                                width: 8,
                              ),

                              // Повтор трека.
                              IconButton(
                                onPressed: () => player.setLoop(
                                  player.loopMode == LoopMode.one
                                      ? LoopMode.off
                                      : LoopMode.one,
                                ),
                                icon: Icon(
                                  player.loopMode == LoopMode.one
                                      ? Icons.repeat_on_outlined
                                      : Icons.repeat,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Остальные кнопки (выход из полноэкранного режима, ...) справа.
                      Align(
                        alignment: Alignment.bottomRight,
                        child: SizedBox(
                          height: 70,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Управление громкостью.
                              if (isDesktop)
                                ScrollableSlider(
                                  value: player.volume,
                                  onChanged: (double newVolume) async {
                                    await player.setVolume(newVolume);

                                    // Если пользователь установил минимальную громкость, а так же настройка "Пауза при отключении громкости" включена, то ставим плеер на паузу.
                                    if (newVolume == 0 &&
                                        user.settings.pauseOnMuteEnabled) {
                                      await player.pause();
                                    }
                                  },
                                ),
                              if (isDesktop)
                                const SizedBox(
                                  width: 18,
                                ),

                              // Показ текста песни.
                              IconButton(
                                onPressed: player.currentAudio!.hasLyrics
                                    ? () {
                                        user.settings.trackLyricsEnabled =
                                            !user.settings.trackLyricsEnabled;

                                        user.markUpdated();
                                      }
                                    : null,
                                icon: Icon(
                                  user.settings.trackLyricsEnabled &&
                                          player.currentAudio!.hasLyrics
                                      ? Icons.lyrics
                                      : Icons.lyrics_outlined,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(
                                        player.currentAudio!.hasLyrics
                                            ? 1.0
                                            : 0.5,
                                      ),
                                ),
                              ),
                              const SizedBox(
                                width: 8,
                              ),

                              // Выход из полноэкранного режима.
                              IconButton(
                                onPressed: () => closeFullscreenPlayer(context),
                                icon: Icon(
                                  Icons.fullscreen_exit,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

/// Mobile layout для полноэкранного плеера.
class FullscreenPlayerMobileRoute extends StatelessWidget {
  final AppLogger logger = getLogger("FullscreenPlayerMobileRoute");

  FullscreenPlayerMobileRoute({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final UserProvider user = Provider.of<UserProvider>(context);

    const double padding = 20;

    const double imageSize = 400;

    final double lyricsBlockSize = MediaQuery.of(context).size.height -
        padding * 2 -
        200 -
        MediaQuery.of(context).systemGestureInsets.bottom -
        MediaQuery.of(context).systemGestureInsets.top;

    /// Указывает, что пользователь включил показа текста песни, а так же текст существует и он загружен.
    final bool lyricsLoadedAndShown = user.settings.trackLyricsEnabled &&
        player.currentAudio!.hasLyrics &&
        player.currentAudio!.lyrics != null;

    /// Указывает, сохранён ли этот трек в лайкнутых.
    final bool isFavorite =
        user.favoriteMediaKeys.contains(player.currentAudio!.mediaKey);

    return Padding(
      padding: const EdgeInsets.all(
        padding,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Кнопки управления полноэкранным плеером.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Кнопка для выхода из полноэкранного плеера.
              IconButton(
                icon: Icon(
                  Icons.adaptive.arrow_back,
                ),
                onPressed: () => closeFullscreenPlayer(context),
              ),

              // Название плейлиста, из которого идёт воспроизведение.
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context)!
                        .music_fullscreenPlaylistNameTitle,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.75),
                    ),
                  ),
                  Text(
                    player.currentPlaylist?.title ??
                        AppLocalizations.of(context)!
                            .music_fullscreenFavoritePlaylistName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              // Дополнительные действия над треком.
              if (player.currentPlaylist != null)
                IconButton(
                  icon: Icon(
                    Icons.adaptive.more,
                  ),
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (BuildContext context) => BottomAudioOptionsDialog(
                      audio: player.currentAudio!,
                      playlist: player.currentPlaylist!,
                    ),
                  ),
                ),
            ],
          ),

          // Изображение трека, либо текст песни поверх него.
          SizedBox(
            height: lyricsBlockSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Изображение трека.
                HeroMode(
                  enabled: !lyricsLoadedAndShown,
                  child: Hero(
                    tag: "image",
                    child: FittedBox(
                      child: Padding(
                        padding: const EdgeInsets.all(
                          36,
                        ),
                        child: AnimatedOpacity(
                          opacity: lyricsLoadedAndShown ? 0.0 : 1.0,
                          duration: const Duration(
                            milliseconds: 500,
                          ),
                          child: Container(
                            width: imageSize,
                            height: imageSize,
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 15,
                                  spreadRadius: -3,
                                  color: Theme.of(context).colorScheme.tertiary,
                                  blurStyle: BlurStyle.outer,
                                )
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                globalBorderRadius,
                              ),
                              child: player.currentAudio!.album?.thumb != null
                                  ? CachedNetworkImage(
                                      imageUrl: player.currentAudio!.album!
                                          .thumb!.photo600!,
                                      cacheKey:
                                          "${player.currentAudio!.mediaKey}600",
                                      width: imageSize,
                                      height: imageSize,
                                      fit: BoxFit.fill,
                                      placeholder:
                                          (BuildContext context, String url) =>
                                              const FallbackAudioAvatar(),
                                      cacheManager:
                                          CachedNetworkImagesManager.instance,
                                      memCacheWidth: (imageSize * 2).toInt(),
                                      memCacheHeight: (imageSize * 2).toInt(),
                                    )
                                  : const FallbackAudioAvatar(
                                      width: imageSize,
                                      height: imageSize,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Текст песни данного трека.
                if (player.currentAudio!.lyrics != null)
                  Align(
                    alignment: Alignment.topCenter,
                    child: AnimatedOpacity(
                      opacity: lyricsLoadedAndShown ? 1.0 : 0.0,
                      duration: const Duration(
                        milliseconds: 500,
                      ),
                      curve: Curves.ease,
                      child: TrackLyricsBlock(
                        lyrics: player.currentAudio!.lyrics!,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Управление плеером, а так же информация по текущему треку.
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 22,
            ),
            child: Column(
              children: [
                // Кнопки для лайка/дизлайка, а так же включения/отключения текста песни.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Кнопка для дизлайка/лайка трека.
                    IconButton(
                      onPressed: () => toggleTrackLikeState(
                        context,
                        player.currentAudio!,
                        !isFavorite,
                      ),
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),

                    // Информация по текущему треку: его исполнителю и названию.
                    Expanded(
                      child: Column(
                        children: [
                          // Название трека (и иконка explicit).
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  player.currentAudio!.title,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                                ),
                              ),
                              if (player.currentAudio!.isExplicit)
                                const SizedBox(
                                  width: 4,
                                ),
                              if (player.currentAudio!.isExplicit)
                                Icon(
                                  Icons.explicit,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onBackground
                                      .withOpacity(0.5),
                                  size: 12,
                                ),
                            ],
                          ),

                          // Иссполнитель трека.
                          Text(
                            player.currentAudio!.artist,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer
                                  .withOpacity(0.75),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Кнопка для включения/отключения показа текста песни.
                    IconButton(
                      onPressed: player.currentAudio!.hasLyrics
                          ? () {
                              user.settings.trackLyricsEnabled =
                                  !user.settings.trackLyricsEnabled;

                              user.markUpdated();
                            }
                          : null,
                      icon: Icon(
                        user.settings.trackLyricsEnabled &&
                                player.currentAudio!.hasLyrics
                            ? Icons.lyrics
                            : Icons.lyrics_outlined,
                        color:
                            Theme.of(context).colorScheme.primary.withOpacity(
                                  player.currentAudio!.hasLyrics ? 1.0 : 0.5,
                                ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),

                // Slider для отображения прогресса воспроизведения трека.
                SliderTheme(
                  data: SliderThemeData(
                    trackShape: CustomTrackShape(),
                    overlayShape: SliderComponentShape.noOverlay,
                    inactiveTrackColor:
                        Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  child: Slider(
                    value: player.progress,
                    onChanged: (double value) {},
                    onChangeEnd: (double newProgress) =>
                        player.seekNormalized(newProgress),
                  ),
                ),

                // Кнопки управления воспроизведением.
                SizedBox(
                  height: 70,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () => player.setShuffle(
                          !player.shuffleModeEnabled,
                        ),
                        icon: Icon(
                          player.shuffleModeEnabled
                              ? Icons.shuffle_on_outlined
                              : Icons.shuffle,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      IconButton(
                        onPressed: () => player.previous(
                          allowSeekToBeginning: true,
                        ),
                        icon: Icon(
                          Icons.skip_previous,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      IconButton(
                        onPressed: () => player.togglePlay(),
                        icon: Icon(
                          player.playing
                              ? Icons.pause_circle
                              : Icons.play_circle,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        iconSize: 50,
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      IconButton(
                        onPressed: () => player.next(),
                        icon: Icon(
                          Icons.skip_next,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      IconButton(
                        onPressed: () => player.setLoop(
                          player.loopMode == LoopMode.one
                              ? LoopMode.off
                              : LoopMode.one,
                        ),
                        icon: Icon(
                          player.loopMode == LoopMode.one
                              ? Icons.repeat_on_outlined
                              : Icons.repeat,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Desktop layout для полноэкранного плеера.
class FullscreenPlayerRoute extends StatefulWidget {
  const FullscreenPlayerRoute({
    super.key,
  });

  @override
  State<FullscreenPlayerRoute> createState() => _FullscreenPlayerRouteState();
}

class _FullscreenPlayerRouteState extends State<FullscreenPlayerRoute> {
  static AppLogger logger = getLogger("FullscreenPlayerDesktopRoute");

  /// Подписки на изменения состояния воспроизведения трека.
  late final List<StreamSubscription> subscriptions;

  /// Список из [Audio.mediaKey] треков, текст песен которых пытается загрузиться в данный момент.
  ///
  /// Данное поле нужно, что бы при повторном вызове метода [build] не делалось множество HTTP-запросов.
  final List<String> lyricsQueue = [];

  @override
  void initState() {
    super.initState();

    subscriptions = [
      // Событие изменения громкости плеера.
      player.volumeStream.listen(
        (double volume) => setState(() {}),
      ),

      // Изменения состояния работы shuffle.
      player.shuffleModeEnabledStream.listen(
        (bool shuffleEnabled) => setState(() {}),
      ),

      // Изменения состояния работы повтора плейлиста.
      player.loopModeStream.listen(
        (LoopMode loopMode) => setState(() {}),
      ),

      // Событие изменение прогресса "прослушанности" трека.
      player.positionStream.listen(
        (Duration position) => setState(() {}),
      ),

      // Изменения плейлиста.
      player.sequenceStateStream.listen(
        (SequenceState? state) => setState(() {}),
      ),
    ];
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
    final PlayerSchemeProvider colorScheme =
        Provider.of<PlayerSchemeProvider>(context, listen: false);

    /// Запускаем задачу по получению цветовой схемы.
    player
        .getColorSchemeAsync(
      MediaQuery.of(context).platformBrightness,
    )
        .then(
      (ColorScheme? scheme) {
        if (scheme == null) return;

        colorScheme.setScheme(
          scheme,
          mediaKey: player.currentAudio!.mediaKey,
        );
      },
    );

    // Если известно, что у трека есть текст песни, то пытаемся его загрузить.
    if ((player.currentAudio?.hasLyrics ?? false) &&
        player.currentAudio!.lyrics == null &&
        !lyricsQueue.contains(player.currentAudio!.mediaKey)) {
      lyricsQueue.add(player.currentAudio!.mediaKey);

      user.audioGetLyrics(player.currentAudio!.mediaKey).then(
        (APIAudioGetLyricsResponse response) {
          // Проверяем, что в ответе нет ошибок.
          if (response.error != null) {
            throw Exception(
              "API error ${response.error!.errorCode}: ${response.error!.errorMessage}",
            );
          }

          // Сохраняем текст песни.
          player.currentAudio!.lyrics = response.response!.lyrics;

          setState(() {});
        },
      ).onError(
        (error, stackTrace) {
          logger.e(
            "Ошибка при попытке получить lyrics трека с ID ${player.currentAudio!.mediaKey}: ",
            error: error,
            stackTrace: stackTrace,
          );

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.musicFullscreenLyricsLoadError(
                    error.toString(),
                  ),
                ),
              ),
            );
          }
        },
      );
    }

    /// Указывает, что будет использоваться mobile layout.
    final bool useMobileLayout =
        getDeviceType(MediaQuery.of(context).size) == DeviceScreenType.mobile;

    return Theme(
      data: ThemeData(
        colorScheme: colorScheme.colorScheme,
      ),
      child: Scaffold(
        body: CallbackShortcuts(
          bindings: {
            const SingleActivator(
              LogicalKeyboardKey.escape,
            ): () => closeFullscreenPlayer(context),
          },
          child: Focus(
            autofocus: true,
            canRequestFocus: true,
            child: AnimatedContainer(
              duration: const Duration(
                milliseconds: 500,
              ),
              curve: Curves.ease,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer,
                    darkenColor(
                      Theme.of(context).colorScheme.primaryContainer,
                      50,
                    ),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Размытое фоновое изображение.
                  if (player.currentAudio?.album?.thumb != null &&
                      user.settings.playerThumbAsBackground)
                    SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(
                          sigmaX: 50,
                          sigmaY: 50,
                        ),
                        child: CachedNetworkImage(
                          imageUrl:
                              player.currentAudio!.album!.thumb!.photo600!,
                          cacheKey: "${player.currentAudio!.mediaKey}600",
                          fit: BoxFit.cover,
                          cacheManager: CachedNetworkImagesManager.instance,
                          color: Theme.of(context)
                              .colorScheme
                              .background
                              .withOpacity(0.75),
                          colorBlendMode: BlendMode.darken,
                        ),
                      ),
                    ),

                  // Внутреннее содержимое, зависящее от типа layout'а.
                  SafeArea(
                    child: useMobileLayout
                        ? FullscreenPlayerMobileRoute()
                        : FullscreenPlayerDesktopRoute(),
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
