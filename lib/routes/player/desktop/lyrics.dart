import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../../../provider/l18n.dart";
import "../../../provider/player.dart";
import "../../../widgets/fading_list_view.dart";
import "../desktop.dart";
import "../shared.dart";

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
          ? AudioLyricsListView(
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

/// Отображает блок с информацией по тексту песни, которая играет в данный момент.
class LyricsInfoBlock extends HookConsumerWidget {
  /// Размер этого блока.
  final Size size;

  /// Действие, вызваемое при нажатии на кнопку закрытия этого блока.
  final VoidCallback? onClose;

  const LyricsInfoBlock({
    super.key,
    required this.size,
    this.onClose,
  });

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

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        spacing: 50,
        children: [
          CategoryTextWidget(
            header: l18n.player_lyrics_header,
            text: sourceString ?? l18n.general_nothing_found,
            icon: Icons.lyrics,
            isLeft: false,
            onClose: onClose,
          ),
          const Expanded(
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
