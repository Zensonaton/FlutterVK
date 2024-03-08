import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../../../provider/user.dart";
import "../../../services/logger.dart";
import "../../../utils.dart";
import "../../../widgets/dialogs.dart";
import "../../../widgets/loading_overlay.dart";
import "spotify_auth/desktop.dart";
import "spotify_auth/mobile.dart";

/// Производит авторизацию по передаваемому значению Cookie `sp_dc` Spotify.
///
/// Данный метод делает изменения в интерфейсе во время загрузки, и возвращает `true`, если авторизация прошла успешно.
Future<bool> spotifyAuthorize(BuildContext context, String spDC) async {
  final AppLogger logger = getLogger("spotifyAuthorize");
  final UserProvider user = Provider.of<UserProvider>(context, listen: false);

  LoadingOverlay.of(context).show();

  try {
    await user.updateSpotifyToken(spDC);
  } catch (e, stackTrace) {
    // ignore: use_build_context_synchronously
    showLogErrorDialog(
      "Ошибка при авторизации Spotify: ",
      e,
      stackTrace,
      logger,
      context,
    );

    return false;
  } finally {
    if (context.mounted) {
      LoadingOverlay.of(context).hide();
    }
  }

  // Авторизация прошла успешно!
  if (context.mounted) {
    user.markUpdated();
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
