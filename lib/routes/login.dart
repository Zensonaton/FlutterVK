import "dart:async";

import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:provider/provider.dart";
import "package:styled_text/styled_text.dart";

import "../api/shared.dart";
import "../api/users/get.dart";
import "../provider/user.dart";
import "../services/logger.dart";
import "../utils.dart";
import "../widgets/error_dialog.dart";
import "../widgets/loading_overlay.dart";
import "../widgets/page_route.dart";
import "home.dart";
import "home/music.dart";
import "login/desktop.dart";
import "login/mobile.dart";

/// Прозводит авторизацию по передаваемому [token]. Если всё в порядке, возвращает true, а так же перекидывает на главную страницу.
Future<bool> tryAuthorize(
  BuildContext context,
  String token, [
  bool useAlternateAuth = false,
]) async {
  final UserProvider user = Provider.of<UserProvider>(context, listen: false);
  final AppLogger logger = getLogger("tryAuthorize");

  logger.d("Trying to authorize (tryAuthorize) with token");

  LoadingOverlay.of(context).show();
  FocusScope.of(context).unfocus();

  try {
    final APIUsersGetResponse response = await users_get(token);
    if (!context.mounted) return false;

    // Проверяем, что в ответе нет ошибок.
    if (response.error != null) {
      throw Exception(
          "API error ${response.error!.errorCode}: ${response.error!.errorMessage}");
    }

    LoadingOverlay.of(context).hide();

    // Если мы проводим альтернативную авторизацию, то мы должны сохранить вторичный токен.
    if (useAlternateAuth) {
      user.recommendationsToken = token;

      user.markUpdated();

      // Убираем текущий Route, что бы пользователя вернуло на главный экран.
      Navigator.of(context).pop();

      // Обновляем данные о музыке.
      ensureUserAudioAllInformation(
        context,
        forceUpdate: true,
      );

      return true;
    }

    User accountInfo = response.response![0];

    // При основной авторизации мы сохраняем основной токен.
    user.isAuthorized = true;
    user.mainToken = token;
    user.id = accountInfo.id;
    user.firstName = accountInfo.firstName;
    user.lastName = accountInfo.lastName;
    user.photo50Url = accountInfo.photo50;
    user.photoMaxUrl = accountInfo.photoMax;
    user.photoMaxOrigUrl = accountInfo.photoMaxOrig;

    user.markUpdated();

    // Показываем диалог, показывающий, что авторизация была произведена успешно.
    if (context.mounted) {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return WelcomeDialog(
            name: "${accountInfo.firstName} ${accountInfo.lastName}",
            avatarURL:
                (accountInfo.hasPhoto ?? 0) == 1 ? accountInfo.photoMax : null,
          );
        },
      );
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        Material3PageRoute(
          builder: (context) => const HomeRoute(),
        ),
        (route) => false,
      );
    }
  } catch (e, stackTrace) {
    logger.e("Ошибка при авторизации: ", error: e, stackTrace: stackTrace);
    if (context.mounted) showErrorDialog(context, description: e.toString());

    return false;
  } finally {
    if (context.mounted) LoadingOverlay.of(context).hide();
  }

  return true;
}

/// Виджет-диалог, который открывается на несколько секунд, после чего закрывается. Данный диалог показывает аватарку пользователя (если таковая имеется), а так же его имя в тексте "Добро пожаловать, Имя!"
class WelcomeDialog extends StatefulWidget {
  /// Имя пользователя, который авторизовался в приложении.
  final String name;

  /// URL на аватарку пользователя.
  final String? avatarURL;

  /// Время, после которого данный виджет автоматически закроется. Если указать null, то автоматическое закрытие происходить не будет.
  final Duration? duration;

  const WelcomeDialog({
    Key? key,
    required this.name,
    this.avatarURL,
    this.duration = const Duration(seconds: 5),
  }) : super(
          key: key,
        );

  @override
  createState() => _WelcomeDialogState();
}

class _WelcomeDialogState extends State<WelcomeDialog> {
  late Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = widget.duration != null
        ? Timer(
            widget.duration!,
            () => Navigator.of(context).pop(),
          )
        : null;
  }

  @override
  void dispose() {
    _timer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.avatarURL != null)
              CachedNetworkImage(
                imageUrl: widget.avatarURL!,
                placeholder: (BuildContext context, String url) {
                  return const SizedBox(
                    height: 80,
                    width: 80,
                  );
                },
                placeholderFadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
                imageBuilder: (context, imageProvider) => Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            if (widget.avatarURL != null)
              const SizedBox(
                height: 18,
              ),
            StyledText(
              text:
                  AppLocalizations.of(context)!.login_welcomeTitle(widget.name),
              style: Theme.of(context).textTheme.bodyLarge,
              tags: {
                "bold": StyledTextTag(
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Route для авторизации на свою страницу ВКонтакте.
class LoginRoute extends StatefulWidget {
  /// Указывает, что вместо авторизации с Kate Mobile (главный токен) будет проводиться вторичная авторизация от имени VK Admin.
  ///
  /// Используется при подключении рекомендаций ВКонтакте.
  final bool useAlternateAuth;

  const LoginRoute({
    super.key,
    this.useAlternateAuth = false,
  });

  @override
  State<LoginRoute> createState() => _LoginRouteState();
}

class _LoginRouteState extends State<LoginRoute> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Flutter VK"),
        centerTitle: true,
      ),
      resizeToAvoidBottomInset: false,
      body: isMobile
          ? MobileLoginWidget(
              useAlternateAuth: widget.useAlternateAuth,
            )
          : DesktopLoginWidget(
              useAlternateAuth: widget.useAlternateAuth,
            ),
    );
  }
}
