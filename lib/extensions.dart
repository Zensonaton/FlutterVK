import "dart:math";

import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "api/vk/shared.dart";
import "provider/l18n.dart";
import "provider/playlists.dart";
import "provider/user.dart";
import "provider/vk_api.dart";
import "services/logger.dart";
import "widgets/dialogs.dart";

extension RandomListItem<T> on List<T> {
  /// Возвращает случайный элемент из данного [List].
  T randomItem() {
    return this[Random().nextInt(length)];
  }
}

extension RandomSetItem<T> on Set<T> {
  /// Возвращает случайный элемент из данного [Set].
  T randomItem() {
    return elementAt(Random().nextInt(length));
  }
}

extension HexColor on Color {
  // Код взят со StackOverflow:
  // https://stackoverflow.com/a/50081214/15227244

  /// Возвращает объект [Color] из Hex-цвета вида `aabbcc` или `ffaabbcc`.
  static Color fromHex(
    String hexString,
  ) {
    final buffer = StringBuffer();

    if (hexString.length == 6 || hexString.length == 7) buffer.write("ff");
    buffer.write(hexString.replaceFirst("#", ""));

    return Color(
      int.parse(
        buffer.toString(),
        radix: 16,
      ),
    );
  }
}

extension ColorBrightness on Color {
  /// Понижает яркость передаваемого цвета [color] на процент [factor], значение которого - число от `0.0` (т.е., никакого изменения) до `1.0` (т.е., максимальное затемнение цвета).
  Color darken(double factor) {
    assert(
      factor >= 0.0 && factor <= 1.0,
      "Expected factor to be in range of 0.0 to 1.0, but got $factor instead",
    );

    if (factor == 0.0) {
      return this;
    }

    factor = 1.0 - factor;

    return Color.fromARGB(
      (a * 255).toInt(),
      max(
        0,
        (r * factor * 255).toInt(),
      ),
      max(
        0,
        (g * factor * 255).toInt(),
      ),
      max(
        0,
        (b * factor * 255).toInt(),
      ),
    );
  }

  /// Повышает яркость передаваемого цвета [color] на процент [factor], значение которого - число от `0.0` (т.е., никакого изменения) до `1.0` (т.е., максимальное засветление цвета).
  Color lighten(double factor) {
    assert(
      factor >= 0.0 && factor <= 1.0,
      "Expected factor to be in range of 0.0 to 1.0, but got $factor instead",
    );

    if (factor == 0.0) {
      return this;
    }

    factor = 1.0 + factor;

    return Color.fromARGB(
      (a * 255).toInt(),
      min(
        255,
        (r * factor * 255).toInt(),
      ),
      min(
        255,
        (g * factor * 255).toInt(),
      ),
      min(
        255,
        (b * factor * 255).toInt(),
      ),
    );
  }
}

extension AudioActionsExtension on ExtendedAudio {
  /// Проверяет то, существует ли похожий трек в плейлисте с лайкнутыми треками, и если да, то показывает диалог, спрашивающий у пользователя то, хочет он сохранить трек или нет.
  ///
  /// Возвращает true, если пользователь разрешил сохранение дубликата либо дубликата и вовсе не было, либо false, если пользователь не разрешил.
  Future<bool> checkForDuplicates(WidgetRef ref, BuildContext context) async {
    final l18n = ref.watch(l18nProvider);
    final favorites = ref.read(favoritesPlaylistProvider)!;

    final bool isDuplicate = favorites.audios!.any(
      (favAudio) =>
          favAudio.isLiked &&
          favAudio.title == title &&
          favAudio.artist == artist &&
          favAudio.album == album,
    );

    if (!isDuplicate) return true;

    return await showYesNoDialog(
          context,
          icon: Icons.copy,
          title: l18n.track_duplicate_found_title,
          description: l18n.track_duplicate_found_desc,
        ) ??
        false;
  }

  /// Меняет состояние "лайка" у передаваемого трека.
  ///
  /// Если [isLiked] = true, то трек будет восстановлен (если он был удалён ранее), либо же лайкнут. В ином же случае, трек будет удалён из лайкнутых.
  Future<void> likeDislikeRestore(
    Ref ref, {
    ExtendedPlaylist? sourcePlaylist,
  }) async {
    final logger = getLogger("likeDislikeRestore");
    final playlistsNotifier = ref.read(playlistsProvider.notifier);
    final favsPlaylist = ref.read(favoritesPlaylistProvider);
    final user = ref.read(userProvider);
    final api = ref.read(vkAPIProvider);
    if (favsPlaylist == null) {
      throw Exception("Favorites playlist is null");
    }

    final newLikeState = !isLiked;

    // Новый объект ExtendedAudio, хранящий в себе новую версию трека после лайка/дизлайка.
    ExtendedAudio newAudio = copyWith();

    // Список из плейлистов, которые должны быть сохранены.
    List<ExtendedPlaylist> playlistsModified = [];

    if (newLikeState) {
      // Пользователь попытался лайкнуть трек.

      // Здесь мы должны проверить, пытается ли пользователь восстановить ранее удалённый трек или нет.
      final bool shouldRestore = favsPlaylist.audios!.contains(newAudio);

      // Если пользователь пытается восстановить трек, то вызываем audio.restore,
      // в ином случае просто добавляем его методом audio.add.
      int newTrackID;
      if (shouldRestore) {
        final int ownerID = newAudio.relativeOwnerID ?? newAudio.ownerID;
        newTrackID = newAudio.relativeID ?? newAudio.id;

        logger.d("Restore ${ownerID}_$newTrackID");

        // Восстанавливаем трек.
        await api.audio.restore(
          newTrackID,
          ownerID,
        );

        newAudio = newAudio.copyWith(
          isLiked: true,
        );
      } else {
        final int ownerID = newAudio.relativeOwnerID ?? newAudio.ownerID;
        newTrackID = newAudio.id;

        // Сохраняем трек как лайкнутый.
        newTrackID = await api.audio.add(
          newTrackID,
          ownerID,
        );

        logger.d("Add ${ownerID}_${newAudio.id}, got ${user.id}_$newTrackID");

        newAudio = newAudio.copyWith(
          isLiked: true,
          relativeID: newTrackID,
          relativeOwnerID: user.id,
          savedFromPlaylist: sourcePlaylist != null,
          savedPlaylistID: sourcePlaylist?.id,
          savedPlaylistOwnerID: sourcePlaylist?.ownerID,
        );
      }

      // Прекрасно, трек был добавлен либо восстановлён.
      // Запоминаем новую версию плейлиста с лайкнутыми треками.
      playlistsModified.add(
        favsPlaylist.basicCopyWith(
          audiosToUpdate: [newAudio],
          count: favsPlaylist.count! + 1,
        ),
      );

      // Меняем второй плейлист, откуда этот трек был взят.
      // Здесь мы не трогаем playlistsModified, поскольку сохранять в БД такое изменение не нужно.
      if (sourcePlaylist != null) {
        await playlistsNotifier.updatePlaylist(
          sourcePlaylist.basicCopyWith(
            audiosToUpdate: [
              basicCopyWith(
                isLiked: true,
                relativeID: newTrackID,
                relativeOwnerID: user.id,
              ),
            ],
          ),
        );
      }
    } else {
      // Пользователь пытается удалить трек.

      final int ownerID = newAudio.relativeOwnerID ?? newAudio.ownerID;
      final int newTrackID = newAudio.relativeID ?? newAudio.id;
      logger.d("Delete ${ownerID}_$newTrackID");

      // Удаляем трек из лайкнутых.
      await api.audio.delete(
        newTrackID,
        ownerID,
      );

      // Запоминаем новую версию плейлиста "любимые треки" с удалённым треком.
      playlistsModified.add(
        favsPlaylist.basicCopyWith(
          audiosToUpdate: [
            newAudio.basicCopyWith(
              isLiked: false,
              savedFromPlaylist: false,
            ),
          ],
          audios: favsPlaylist.audios!,
          count: favsPlaylist.count! - 1,
        ),
      );

      // Если мы не трогали плейлист "любимые" треки, то модифицируем его.
      if (sourcePlaylist != null &&
          !(sourcePlaylist.id == favsPlaylist.id &&
              sourcePlaylist.ownerID == favsPlaylist.ownerID)) {
        playlistsModified.add(
          sourcePlaylist.basicCopyWith(
            audiosToUpdate: [
              newAudio.basicCopyWith(
                isLiked: false,
                savedFromPlaylist: false,
              ),
            ],
          ),
        );
      }

      // Удаляем лайкнутый трек из сохранённого ранее плейлиста.
      if (newAudio.savedFromPlaylist) {
        final ExtendedPlaylist? savedPlaylist = playlistsNotifier.getPlaylist(
          newAudio.savedPlaylistOwnerID!,
          newAudio.savedPlaylistID!,
        );
        if (savedPlaylist == null) {
          throw Exception(
            "Attempted to delete track with non-existing parent playlist",
          );
        }

        playlistsModified.add(
          savedPlaylist.basicCopyWith(
            audiosToUpdate: [
              newAudio.basicCopyWith(
                isLiked: false,
                savedFromPlaylist: false,
              ),
            ],
          ),
        );
      }
    }

    await playlistsNotifier.updatePlaylists(
      playlistsModified,
      saveInDB: true,
    );
  }

  /// Обёртка для метода [likeDislikeRestore], отображающая информация об возможной ошибке в случае, если метод [likeDislikeRestore] выбросил исключение.
  ///
  /// Возвращает true, если всё прошло успешно.
  Future<bool> likeDislikeRestoreSafe(
    BuildContext context,
    Ref ref, {
    ExtendedPlaylist? sourcePlaylist,
  }) async {
    final logger = getLogger("trackLike");
    final l18n = ref.read(l18nProvider);

    try {
      await likeDislikeRestore(ref);
    } on VKAPIException catch (error, stackTrace) {
      if (!context.mounted) return false;

      if (error.errorCode == 15) {
        showErrorDialog(
          context,
          description: l18n.audio_restore_too_late_desc,
        );
      }

      showLogErrorDialog(
        "Error while restoring audio:",
        error,
        stackTrace,
        logger,
        context,
      );

      return false;
    } catch (error, stackTrace) {
      if (!context.mounted) return false;

      showLogErrorDialog(
        "Error while toggling like state:",
        error,
        stackTrace,
        logger,
        context,
      );

      return false;
    }

    return true;
  }

  /// Помечает трек как дизлайкнутый.
  Future<void> dislike(Ref ref) async {
    final api = ref.read(vkAPIProvider);

    final bool response = await api.audio.addDislike([mediaKey]);

    if (!response) {
      throw Exception("Track is not disliked: $response");
    }
  }
}
