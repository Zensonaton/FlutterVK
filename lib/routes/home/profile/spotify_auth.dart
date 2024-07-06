import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../../../provider/spotify_api.dart";
import "../../../services/logger.dart";
import "../../../utils.dart";
import "../../../widgets/dialogs.dart";
import "../../../widgets/loading_overlay.dart";
import "spotify_auth/desktop.dart";
import "spotify_auth/mobile.dart";

/// Производит авторизацию по передаваемому значению Cookie `sp_dc` Spotify.
///
/// Данный метод делает изменения в интерфейсе во время загрузки, и возвращает `true`, если авторизация прошла успешно.
Future<bool> spotifyAuthorize(
  WidgetRef ref,
  BuildContext context,
  String spDC,
) async {
  final AppLogger logger = getLogger("spotifyAuthorize");

  LoadingOverlay.of(context).show();

  try {
    await ref.read(spotifyAPIProvider.notifier).login(spDC);
  } catch (e, stackTrace) {
    showLogErrorDialog(
      "Ошибка при авторизации Spotify: ",
      e,
      stackTrace,
      logger,
      // ignore: use_build_context_synchronously
      context,
    );

    return false;
  } finally {
    if (context.mounted) {
      LoadingOverlay.of(context).hide();
    }
  }

  return true;
}

/// Route для подключения сервиса Spotify.
class SpotifyLoginRoute extends StatelessWidget {
  const SpotifyLoginRoute({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return const MobileSpotifyLogin();
    }

    return const DesktopSpotifyLogin();
  }
}
