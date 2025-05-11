import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:gap/gap.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../../../provider/player.dart";
import "../../../provider/user.dart";
import "../../../widgets/audio_track.dart";

class TrueFalseWidget extends StatelessWidget {
  final String text;
  final bool value;

  const TrueFalseWidget({
    super.key,
    required this.text,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final color = value ? Colors.green : Colors.red;

    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            color: color,
          ),
        ),
        const Gap(8),
        Icon(
          value ? Icons.check : Icons.close,
          color: color,
        ),
      ],
    );
  }
}

/// Информация о плеере.
class PlayerInfoCard extends ConsumerWidget {
  const PlayerInfoCard({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(playerProvider);
    ref.watch(playerIsPlayingProvider);
    ref.watch(playerIsShufflingProvider);
    ref.watch(playerIsRepeatingProvider);
    ref.watch(playerPositionProvider);
    ref.watch(playerVolumeProvider);
    ref.watch(playerVolumeNormalizationProvider);
    ref.watch(playerSilenceRemovalEnabledProvider);

    final backend = player.backend;
    final isPlaying = player.isPlaying;
    final isShuffling = player.isShuffling;
    final isRepeating = player.isRepeating;
    final position = player.position;
    final duration = player.duration;
    final volume = player.volume;
    final volumeNormalization = player.volumeNormalization;
    final silenceRemovalEnabled = player.silenceRemovalEnabled;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(
          16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Backend: $backend",
            ),
            TrueFalseWidget(
              value: isPlaying,
              text: "Is Playing",
            ),
            TrueFalseWidget(
              value: isShuffling,
              text: "Is Shuffling",
            ),
            TrueFalseWidget(
              value: isRepeating,
              text: "Is Repeating",
            ),
            Text(
              "Position: $position",
            ),
            Text(
              "Duration: $duration",
            ),
            Text(
              "Volume: $volume",
            ),
            Text(
              "Volume normalization: ${volumeNormalization.name}",
            ),
            TrueFalseWidget(
              value: silenceRemovalEnabled,
              text: "Is removing silence",
            ),
          ],
        ),
      ),
    );
  }
}

/// Треки в очереди. Используется в [QueueInfoCard].
class QueueItems extends HookConsumerWidget {
  const QueueItems({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(playerProvider);

    ref.watch(playerAudioProvider);
    ref.watch(playerQueueProvider);

    final List<ExtendedAudio?> audios = useMemoized(
      () {
        return [
          for (var i = -2; i < 3; i++) player.audioAtRelativeIndex(i),
        ];
      },
      [player.audio, player.queue],
    );

    return Column(
      spacing: 8,
      children: [
        for (ExtendedAudio? audio in audios)
          AudioTrackTile(
            audio: audio ??
                ExtendedAudio(
                  id: 0,
                  ownerID: 0,
                  artist: "Unknown",
                  title: "Unknown",
                  duration: Duration.zero,
                ),
            isSelected: audio?.id == player.audio?.id,
            isPlaying: true,
            isAvailable: audio != null,
            glowIfSelected: true,
          ),
      ],
    );
  }
}

/// Информация об очереди.
class QueueInfoCard extends ConsumerWidget {
  const QueueInfoCard({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(playerProvider);
    ref.watch(playerPlaylistProvider);
    ref.watch(playerQueueProvider);
    ref.watch(playerAudioProvider);

    final playlist = player.playlist;
    final queue = player.queue;
    final index = player.index;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(
          16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Playlist: $playlist",
            ),
            Text(
              "Queue items: $index/${queue?.length}",
            ),
            const Gap(12),
            const QueueItems(),
          ],
        ),
      ),
    );
  }
}

/// Route для debug-меню, отображающую техническую информацию о плеере.
///
/// go_route: `/player_debug`.
class PlayerDebugMenu extends ConsumerWidget {
  const PlayerDebugMenu({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Player debug",
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
        children: [
          const PlayerInfoCard(),
          const Gap(10),
          const QueueInfoCard(),
          const Gap(200),
        ],
      ),
    );
  }
}
