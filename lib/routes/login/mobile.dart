import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:flutter_inappwebview/flutter_inappwebview.dart";

import "../../consts.dart";
import "../../utils.dart";
import "../../widgets/dialogs.dart";
import "../../widgets/page_route_builders.dart";
import "../login.dart";
import "desktop.dart";

/// Часть Route'а [LoginRoute], показываемая при запуске на мобильных платформах.
///
/// Данный Route нельзя показывать на Desktop-платформах, поскольку inappwebview, используемый для рендеринга страницы, не поддерживается на Desktop-платформах.
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
      // Данный Route нельзя показывать на Desktop-платформах, поскольку inappwebview, используемый для рендеринга страницы, не поддерживается на Desktop-платформах.

      return const Text(
        "MobileLoginWidget предназначен для работы на мобильных платформах.",
      );
    }

    if (!isWebViewShown) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Иконка.
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(
              height: 12,
            ),

            // Текст "Авторизация успешна".
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Flutter VK",
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton(
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: true,
                  onTap: () => Navigator.push(
                    context,
                    Material3PageRoute(
                      builder: (context) => DesktopLoginWidget(
                        useAlternateAuth: widget.useAlternateAuth,
                      ),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!
                        .login_mobileAlternateAuthTitle,
                  ),
                )
              ];
            },
          ),
        ],
      ),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        maintainBottomViewPadding: true,
        child: InAppWebView(
          initialUrlRequest: URLRequest(
            url: WebUri(
              widget.useAlternateAuth
                  ? vkMusicRecommendationsOAuthURL
                  : vkMainOAuthURL,
            ),
          ),
          onLoadStop: (
            InAppWebViewController controller,
            WebUri? action,
          ) async {
            if (action == null) return;

            // Убеждаемся, что новая страница является blank-страницей, которая передаётся только после окончания авторизации.
            String url = action.toString();
            if (!url.startsWith("https://oauth.vk.com/blank.html")) return;

            // Извлекаем access-токен из URL.
            String? token = extractAccessToken(url);
            if (token == null) {
              isWebViewShown = true;

              showErrorDialog(
                context,
                description: AppLocalizations.of(context)!.login_noTokenFound,
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
        ),
      ),
    );
  }
}
