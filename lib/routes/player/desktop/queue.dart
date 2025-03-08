import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../../../provider/l18n.dart";
import "../../../provider/player.dart";
import "../../../widgets/fading_list_view.dart";
import "../shared.dart";

/// Отображает блок с информацией по очереди воспроизведения.
class QueueInfoBlock extends HookConsumerWidget {
  /// Размер этого блока.
  final Size size;

  /// Действие, вызваемое при нажатии на кнопку закрытия этого блока.
  final VoidCallback? onClose;

  const QueueInfoBlock({
    super.key,
    required this.size,
    this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(playerProvider);
    final l18n = ref.watch(l18nProvider);
    ref.watch(playerPlaylistProvider);

    final playlist = player.playlist;

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 50,
        children: [
          CategoryTextWidget(
            header: l18n.player_queue_header,
            text: playlist!.title ?? l18n.general_favorites_playlist,
            icon: Icons.queue_music,
            isLeft: true,
            onClose: onClose,
          ),
          const Expanded(
            child: FadingListView(
              strength: 0.05,
              child: PlayerQueueListView(),
            ),
          ),
        ],
      ),
    );
  }
}
