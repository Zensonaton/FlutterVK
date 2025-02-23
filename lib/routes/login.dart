import "dart:async";

import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../api/vk/catalog/get_audio.dart";
import "../api/vk/shared.dart";
import "../api/vk/users/get.dart";
import "../provider/auth.dart";
import "../provider/l18n.dart";
import "../provider/playlists.dart";
import "../provider/user.dart";
import "../services/logger.dart";
import "../utils.dart";
import "../widgets/dialogs.dart";
import "login/desktop.dart";
import "login/mobile.dart";

/// Прозводит авторизацию по передаваемому [token]. Если всё в порядке, возвращает true, а так же перекидывает на главную страницу.
Future<bool> tryAuthorize(
  WidgetRef ref,
  BuildContext context,
  String token, [
  bool useAlternateAuth = false,
]) async {
  final logger = getLogger("tryAuthorize");
  final l18n = ref.watch(l18nProvider);
  final userNotifier = ref.read(userProvider.notifier);
  final authNotifier = ref.read(currentAuthStateProvider.notifier);

  logger.d("Trying to authorize with token");

  FocusScope.of(context).unfocus();

  try {
    final List<APIUser> response = await users_get(token: token);
    if (!context.mounted) return false;

    // Проверка, одинаковый ли ID юзера при основной и не основной авторизации.
    if (useAlternateAuth && ref.read(userProvider).id != response.first.id) {
      showErrorDialog(
        context,
        description: l18n.login_wrong_user_id(
          name: ref.read(userProvider).fullName,
        ),
      );

      return false;
    }

    // Делаем ещё один запрос, благодаря которому можно проверить, есть ли доступ к каталогам рекомендаций или нет.
    bool musicCatalogAccess;
    try {
      await catalog_get_audio(token: token);
      musicCatalogAccess = true;
    } catch (e) {
      musicCatalogAccess = false;
    }
    if (!context.mounted) return false;

    // Если мы делаем обычную авторизацию, то доступа к каталогу быть не должно, в ином случае он должен быть.
    if (useAlternateAuth != musicCatalogAccess) {
      showErrorDialog(
        context,
        description: l18n.login_no_music_access_desc,
      );

      return false;
    }

    // Если мы проводим альтернативную авторизацию, то мы должны сохранить вторичный токен,
    // а так же насильно обновить список из треков.
    if (useAlternateAuth) {
      userNotifier.loginSecondary(token);
      ref.invalidate(playlistsProvider);

      if (context.mounted) {
        context.pop();
      }

      return true;
    }

    // При основной авторизации мы сохраняем основной токен.
    authNotifier.login(token, response.first);
  } catch (error, stackTrace) {
    showLogErrorDialog(
      "Authorization error: ",
      error,
      stackTrace,
      logger,
      // ignore: use_build_context_synchronously
      context,
    );

    return false;
  }

  return true;
}

/// Производит демо-авторизацию.
Future<void> tryDemoAuth(WidgetRef ref) async {
  final authNotifier = ref.read(currentAuthStateProvider.notifier);

  final List<APIUser> response = await users_get(token: "DEMO");
  authNotifier.login(
    "DEMO",
    response.first,
    isDemo: true,
  );
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
