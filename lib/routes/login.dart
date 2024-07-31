import "dart:async";

import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../api/vk/api.dart";
import "../api/vk/catalog/get_audio.dart";
import "../api/vk/users/get.dart";
import "../provider/auth.dart";
import "../provider/l18n.dart";
import "../provider/playlists.dart";
import "../provider/user.dart";
import "../services/logger.dart";
import "../utils.dart";
import "../widgets/dialogs.dart";
import "../widgets/loading_overlay.dart";
import "login/desktop.dart";
import "login/mobile.dart";

/// Прозводит авторизацию по передаваемому [token]. Если всё в порядке, возвращает true, а так же перекидывает на главную страницу.
Future<bool> tryAuthorize(
  WidgetRef ref,
  BuildContext context,
  String token, [
  bool useAlternateAuth = false,
]) async {
  final AppLogger logger = getLogger("tryAuthorize");
  final l18n = ref.watch(l18nProvider);

  logger.d("Trying to authorize with token");

  LoadingOverlay.of(context).show();
  FocusScope.of(context).unfocus();

  try {
    final APIUsersGetResponse response = await users_get(token);
    raiseOnAPIError(response);

    if (!context.mounted) return false;

    // Проверка, одинаковый ли ID юзера при основной и не основной авторизации.
    if (useAlternateAuth &&
        ref.read(userProvider).id != response.response!.first.id) {
      showErrorDialog(
        context,
        description: l18n.login_alternativeWrongUserID(
          ref.read(userProvider).fullName,
        ),
      );

      return false;
    }

    // Делаем ещё один запрос, благодаря которому можно проверить, есть ли доступ к каталогам рекомендаций или нет.
    final bool musicCatalogAccess =
        (await catalog_get_audio(token)).error == null;
    if (!context.mounted) return false;

    // Если мы делаем обычную авторизацию, то доступа к каталогу быть не должно, в ином случае он должен быть.
    if (useAlternateAuth != musicCatalogAccess) {
      showErrorDialog(
        context,
        description: l18n.login_noMusicAccessDescription,
      );

      return false;
    }

    // Если мы проводим альтернативную авторизацию, то мы должны сохранить вторичный токен,
    // а так же насильно обновить список из треков.
    if (useAlternateAuth) {
      ref.read(userProvider.notifier).loginSecondary(token);
      ref.invalidate(playlistsProvider);

      context.pop();

      return true;
    }

    // При основной авторизации мы сохраняем основной токен.
    ref
        .read(currentAuthStateProvider.notifier)
        .login(token, response.response!.first);
  } catch (e, stackTrace) {
    showLogErrorDialog(
      "Ошибка при авторизации: ",
      e,
      stackTrace,
      logger,
      // ignore: use_build_context_synchronously
      context,
    );

    return false;
  } finally {
    if (context.mounted) LoadingOverlay.of(context).hide();
  }

  return true;
}

/// Route для авторизации на свою страницу ВКонтакте.
class LoginRoute extends StatelessWidget {
  /// Указывает, что вместо авторизации с Kate Mobile (главный токен) будет проводиться вторичная авторизация от имени VK Admin.
  ///
  /// Используется при подключении рекомендаций ВКонтакте.
  final bool useAlternateAuth;

  const LoginRoute({
    super.key,
    this.useAlternateAuth = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return MobileLoginWidget(
        useAlternateAuth: useAlternateAuth,
      );
    }

    return DesktopLoginWidget(
      useAlternateAuth: useAlternateAuth,
    );
  }
}
