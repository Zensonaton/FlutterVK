import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:flutter_inappwebview/flutter_inappwebview.dart";

import "../../consts.dart";
import "../../utils.dart";
import "../../widgets/dialogs.dart";
import "../login.dart";

/// Часть Route'а [LoginRoute], показываемая при запуске на мобильных платформах.
class MobileLoginWidget extends StatefulWidget {
  /// Указывает, что вместо авторизации с Kate Mobile (главный токен) будет проводиться вторичная авторизация от имени VK Admin.
  ///
  /// Используется при подключении рекомендаций ВКонтакте.
  final bool useAlternateAuth;

  const MobileLoginWidget({
    super.key,
    this.useAlternateAuth = false,
  });

  @override
  State<MobileLoginWidget> createState() => _MobileLoginWidgetState();
}

class _MobileLoginWidgetState extends State<MobileLoginWidget> {
  bool isWebViewShown = true;

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      return const Text(
        "MobileLoginWidget предназначен для работы на мобильных платформах.",
      );
    }

    if (!isWebViewShown) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(
              height: 12,
            ),
            Text(
              AppLocalizations.of(context)!.login_mobileSuccessAuth,
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ),
      );
    }

    return InAppWebView(
      initialUrlRequest: URLRequest(
        url: WebUri(
          widget.useAlternateAuth
              ? vkMusicRecommendationsOAuthURL
              : vkMainOAuthURL,
        ),
      ),
      onLoadStop: (InAppWebViewController controller, WebUri? action) async {
        if (action == null) return;

        // Убеждаемся, что мы попали на страницу с оконченной авторизацией.
        String url = action.toString();
        if (!url.startsWith("https://oauth.vk.com/blank.html")) return;

        // Извлекаем access-токен из URL.
        String? token = extractAccessToken(url);
        if (token == null) {
          isWebViewShown = true;

          showErrorDialog(
            context,
            description: "Access-токен не был найден в URL.",
          );

          return;
        }

        // Пытаемся авторизоваться по токену.
        setState(() => isWebViewShown = false);

        await tryAuthorize(
          context,
          token,
          widget.useAlternateAuth,
        );
      },
    );
  }
}
