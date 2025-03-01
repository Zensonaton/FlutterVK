import "dart:async";
import "dart:ui";

import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:gap/gap.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:scroll_to_index/scroll_to_index.dart";

import "../../../api/vk/audio/get_lyrics.dart";
import "../../../provider/l18n.dart";
import "../../../provider/player.dart";
import "../../../utils.dart";
import "../../../widgets/fading_list_view.dart";
import "../desktop.dart";
import "../shared.dart";

/// Отображает текст песни.
class _Items extends HookConsumerWidget {
  /// Время, через которое после ручного скроллинга пользователем, автоскролл будет включен.
  static const Duration autoScrollDelay = Duration(seconds: 3);

  /// Расстояние между строчками.
  static const double lineSpacing = 12;

  /// Объект [Lyrics], содержащий в себе текст песни.
  final Lyrics lyrics;

  const _Items({
    super.key,
    required this.lyrics,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(playerProvider);

    final controller = useMemoized(
      () => AutoScrollController(),
    );

    final autoScrollStopped = useState(false);
    final autoScrollStopTimer = useRef<Timer?>(null);

    final texts = lyrics.text;
    final timestamps = lyrics.timestamps;
    final isSynchronized = timestamps != null;
    final textOrTimestamps = useMemoized(
      () {
        if (timestamps != null) return timestamps;
        if (texts == null) return null;

        return texts
            .map(
              (line) => LyricTimestamp(
                line: line.isNotEmpty ? line : null,
              ),
            )
            .toList();
      },
      [texts, lyrics],
    );
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

    void scrollToCurrent() {
      controller.scrollToIndex(
        lyricIndex.value ?? 0,
        preferPosition: AutoScrollPosition.middle,
      );
    }

    void onPositionUpdate(_) {
      final index = getCurrentIndex();
      if (index == lyricIndex.value) return;

      lyricIndex.value = index;

      if (!isSynchronized || autoScrollStopped.value || !isLifecycleActive()) {
        return;
      }

      scrollToCurrent();
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

    return NotificationListener(
      onNotification: (Notification notification) {
        if (controller.isAutoScrolling) return false;

        if (notification is ScrollStartNotification) {
          autoScrollStopTimer.value?.cancel();

          autoScrollStopped.value = true;
        } else if (notification is ScrollEndNotification) {
          autoScrollStopTimer.value = Timer(
            autoScrollDelay,
            () {
              if (!context.mounted) return;

              autoScrollStopped.value = false;
            },
          );
        }

        return false;
      },
      child: ScrollConfiguration(
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
          itemCount: textOrTimestamps!.length,
          separatorBuilder: (BuildContext context, int index) {
            return const Gap(lineSpacing);
          },
          itemBuilder: (BuildContext context, int index) {
            final timestamp = textOrTimestamps[index];

            return AutoScrollTag(
              key: ValueKey(
                index,
              ),
              controller: controller,
              index: index,
              child: LyricWidget(
                line: timestamp.line,
                isActive: isSynchronized && index == lyricIndex.value,
                distance: (!autoScrollStopped.value && lyricIndex.value != null)
                    ? index - lyricIndex.value!
                    : 0,
                onTap: isSynchronized
                    ? () => player.seek(
                          Duration(
                            milliseconds: timestamp.begin!,
                          ),
                          play: true,
                        )
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Обёртка для [_Items] для реализации анимации перехода между текстами песни.
class _ItemsAnimated extends ConsumerWidget {
  const _ItemsAnimated();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(playerProvider);
    ref.watch(playerAudioProvider);

    final audio = player.audio;
    final lyrics = audio?.lyrics;

    return AnimatedSwitcher(
      duration: DesktopPlayerWidget.transitionDuration,
      child: lyrics != null
          ? _Items(
              key: ValueKey(
                audio!.id,
              ),
              lyrics: audio.lyrics!,
            )
          : const SizedBox.shrink(
              key: ValueKey(null),
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
              child: _ItemsAnimated(),
            ),
          ),
        ],
      ),
    );
  }
}
