import "dart:ui";

import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:gap/gap.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:scroll_to_index/scroll_to_index.dart";

import "../../../consts.dart";
import "../../../provider/l18n.dart";
import "../../../provider/player.dart";
import "../../../utils.dart";
import "../../../widgets/fading_list_view.dart";
import "../shared.dart";

/// Отображает отдельную строчку в тексте песни.
class LyricWidget extends StatelessWidget {
  /// Длительность перехода между строчками.
  static const Duration transitionDuration = Duration(milliseconds: 250);

  /// Curve для перехода между строчками.
  static const Curve transitionCurve = Curves.ease;

  /// Возвращает значение прозрачности (alpha) для строчки с указанным расстоянием.
  static double getDistanceAlpha(int distance) {
    const maxDistance = 5;
    const minAlpha = 0.1;
    const maxAlpha = 1.0;

    final normalizedDistance = (distance.abs() / maxDistance).clamp(0.0, 1.0);
    return maxAlpha - (normalizedDistance * (maxAlpha - minAlpha));
  }

  /// Текст строчки.
  ///
  /// Если не указан, то будет использоваться иконка ноты.
  final String? line;

  /// Указывает, что эта строчка воспроизводится в данный момент.
  ///
  /// У такой строчки текст будет увеличен.
  final bool isActive;

  /// Расстояние от активной строчки (т.е., той, которая воспроизводится в данный момент) от этой строчки.
  ///
  /// Если число отрицательное, то считается, что это старая строчка, если положительное - то строчка ещё не была воспроизведена.
  final int distance;

  /// Действие, вызываемое при нажатии на эту строчку.
  ///
  /// Если не указано, то нажатие будет проигнорировано, а так же текст не будет располагаться по центру.
  final void Function()? onTap;

  const LyricWidget({
    super.key,
    this.line,
    this.isActive = false,
    this.distance = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final textAlign = onTap == null ? TextAlign.start : TextAlign.center;
    final color = scheme.primary.withValues(
      alpha: getDistanceAlpha(distance),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          globalBorderRadius,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 50,
          ),
          child: AnimatedScale(
            duration: transitionDuration,
            curve: transitionCurve,
            scale: isActive ? 1.2 : 1,
            child: line != null
                ? Text(
                    line!,
                    textAlign: textAlign,
                    style: TextStyle(
                      fontSize: 20,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 2,
                    ),
                    child: Icon(
                      Icons.music_note,
                      size: 20,
                      color: color,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Отображает текст песни.
class _Items extends HookConsumerWidget {
  /// Расстояние между строчками.
  static const double lineSpacing = 12;

  const _Items();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(playerProvider);
    ref.watch(playerAudioProvider);

    final audio = player.audio;
    if (audio?.lyrics == null) {
      return const SizedBox.shrink();
    }

    final controller = useMemoized(() => AutoScrollController());

    final timestamps = audio!.lyrics!.timestamps!;
    final lyricIndex = useState<int?>(null);

    int? getCurrentIndex() {
      final audio = player.audio;
      if (audio == null || audio.lyrics?.timestamps == null) return null;

      final position = player.position.inMilliseconds;
      final timestamps = audio.lyrics!.timestamps!;

      for (int i = timestamps.length - 1; i >= 0; i--) {
        final timestamp = timestamps[i];

        if (timestamp.begin! <= position) {
          return i;
        }
      }

      return null;
    }

    void onPositionUpdate(_) {
      final index = getCurrentIndex();
      if (index == lyricIndex.value) return;

      lyricIndex.value = index;

      if (!isLifecycleActive()) return;
      controller.scrollToIndex(
        index ?? 0,
        preferPosition: AutoScrollPosition.middle,
      );
    }

    useEffect(
      () {
        onPositionUpdate(null);

        final subscriptions = [
          player.positionStream.listen(onPositionUpdate),
          player.seekStream.listen(onPositionUpdate),
        ];

        return () {
          for (final subscription in subscriptions) {
            subscription.cancel();
          }
        };
      },
      [],
    );

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        scrollbars: false,
        overscroll: false,
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
        },
      ),
      child: ListView.separated(
        controller: controller,
        itemCount: timestamps.length,
        separatorBuilder: (BuildContext context, int index) {
          return const Gap(lineSpacing);
        },
        itemBuilder: (BuildContext context, int index) {
          final timestamp = timestamps[index];

          return AutoScrollTag(
            key: ValueKey(index),
            controller: controller,
            index: index,
            child: LyricWidget(
              line: timestamp.line,
              isActive: index == lyricIndex.value,
              distance:
                  lyricIndex.value != null ? index - lyricIndex.value! : 0,
              onTap: () => player.seek(
                Duration(
                  milliseconds: timestamp.begin!,
                ),
                play: true,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Отображает строчку "Источник текста песни", "Источник".
class _Label extends HookConsumerWidget {
  const _Label();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(playerProvider);
    final l18n = ref.watch(l18nProvider);
    ref.watch(playerAudioProvider);

    final audio = player.audio;
    final sourceString = useMemoized(
      () {
        final lyrics = audio!.lyrics;

        if (lyrics == null) {
          return null;
        } else if (audio.lrcLibLyrics == lyrics) {
          return l18n.lyrics_lrclib_source;
        } else if (audio.vkLyrics == lyrics) {
          return l18n.lyrics_vk_source;
        }

        return null;
      },
      [audio?.lyrics],
    );

    return CategoryTextWidget(
      header: l18n.player_lyrics_header,
      text: sourceString ?? l18n.general_nothing_found,
      icon: Icons.lyrics,
      isLeft: false,
    );
  }
}

/// Отображает блок с информацией по тексту песни, которая играет в данный момент.
class LyricsInfoBlock extends StatelessWidget {
  /// Размер этого блока.
  final Size size;

  const LyricsInfoBlock({
    super.key,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size.width,
      height: size.height,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        spacing: 50,
        children: [
          _Label(),
          Expanded(
            child: FadingListView(
              strength: 0.05,
              child: _Items(),
            ),
          ),
        ],
      ),
    );
  }
}
