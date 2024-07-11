import "package:riverpod_annotation/riverpod_annotation.dart";

import "../services/audio_player.dart";

part "player.g.dart";

/// [Provider] для получения [VKMusicPlayer].
@riverpod
VKMusicPlayer vkMusicPlayer(VkMusicPlayerRef ref) => VKMusicPlayer(ref: ref);
