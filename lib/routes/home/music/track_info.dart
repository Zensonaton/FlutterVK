import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:gap/gap.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../../../api/vk/consts.dart";
import "../../../main.dart";
import "../../../provider/l18n.dart";
import "../../../provider/user.dart";
import "../../../services/logger.dart";
import "../../../widgets/audio_track.dart";
import "../../../widgets/dialogs.dart";
import "../../../widgets/loading_overlay.dart";

/// Диалог, который позволяет пользователю отредактировать данные о треке.
///
/// Пример использования:
/// ```dart
/// openDialog(
///   context: context,
///   builder: (BuildContext context) => const TrackInfoEditDialog(...),
/// ),
/// ```
class TrackInfoEditDialog extends HookConsumerWidget {
  static final AppLogger logger = getLogger("TrackInfoEditDialog");

  /// Трек, данные которого будут изменяться.
  final ExtendedAudio audio;

  const TrackInfoEditDialog({
    super.key,
    required this.audio,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);

    final trackTitle = useState(audio.title);
    final trackArtist = useState(audio.artist);
    final trackGenre = useState(audio.genreID ?? 18);

    // Создаём копию трека, засовывая в неё новые значения с новым именем трека и прочим.
    final ExtendedAudio newAudio = ExtendedAudio(
      title: trackTitle.value,
      artist: trackArtist.value,
      id: audio.id,
      ownerID: audio.ownerID,
      duration: audio.duration,
      accessKey: audio.accessKey,
      url: audio.url,
      date: audio.date,
      album: audio.album,
      isLiked: audio.isLiked,
    );

    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Открытый трек.
            AudioTrackTile(
              audio: newAudio,
              isSelected: newAudio == player.currentAudio,
              isPlaying: player.loaded && player.playing,
            ),
            const Gap(8),

            // Разделитель.
            const Divider(),

            // Текстовое поле для изменения названия.
            TextField(
              decoration: InputDecoration(
                label: Text(
                  l18n.music_trackTitle,
                ),
                prefixIcon: const Padding(
                  padding: EdgeInsetsDirectional.only(
                    end: 12,
                  ),
                  child: Icon(
                    Icons.music_note,
                  ),
                ),
              ),
              onChanged: (String value) => trackTitle.value = value,
            ),

            // Текстовое поле для изменения исполнителя.
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Padding(
                  padding: EdgeInsetsDirectional.only(
                    end: 12,
                  ),
                  child: Icon(
                    Icons.album,
                  ),
                ),
                label: Text(
                  l18n.music_trackArtist,
                ),
              ),
              onChanged: (String value) => trackArtist.value = value,
            ),
            const Gap(28),

            // Выпадающее меню с жанром.
            DropdownMenu(
              label: Text(
                l18n.music_trackGenre,
              ),
              initialSelection: trackGenre.value,
              dropdownMenuEntries: [
                for (MapEntry<int, String> genre in musicGenres.entries)
                  DropdownMenuEntry(
                    value: genre.key,
                    label: genre.value,
                  ),
              ],
              onSelected: (int? genreID) {
                if (genreID == null) return;

                trackGenre.value = genreID;
              },
            ),
            const Gap(24),

            // Кнопка для сохранения.
            Align(
              alignment: Alignment.bottomRight,
              child: FilledButton.icon(
                icon: const Icon(
                  Icons.edit,
                ),
                label: Text(
                  l18n.general_save,
                ),
                onPressed: () async {
                  final LoadingOverlay overlay = LoadingOverlay.of(context);

                  context.pop();
                  overlay.show();

                  try {
                    // final APIAudioEditResponse response = await user.audioEdit(
                    //   audio.ownerID,
                    //   audio.id,
                    //   titleController.text,
                    //   artistController.text,
                    //   trackGenre,
                    // );
                    // raiseOnAPIError(response);

                    // Обновляем данные о треке у пользователя.
                    // newAudio.title = titleController.text;
                    // newAudio.artist = artistController.text;
                    // newAudio.genreID = trackGenre;

                    // user.markUpdated(false);
                  } catch (e, stackTrace) {
                    logger.e(
                      "Error while modifying track info: ",
                      error: e,
                      stackTrace: stackTrace,
                    );

                    if (context.mounted) {
                      showErrorDialog(
                        context,
                        description: e.toString(),
                      );
                    }
                  } finally {
                    overlay.hide();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
