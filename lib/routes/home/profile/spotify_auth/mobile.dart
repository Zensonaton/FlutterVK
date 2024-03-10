import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:flutter_inappwebview/flutter_inappwebview.dart";

import "../../../../consts.dart";
import "../../../../utils.dart";
import "../../../../widgets/dialogs.dart";
import "../../../../widgets/page_route_builders.dart";
import "../../../login.dart";
import "../spotify_auth.dart";
import "desktop.dart";

/// Виджет, отображаемый при успешной авторизации.
class SuccessAuthWidget extends StatelessWidget {
  const SuccessAuthWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Иконка.
          Padding(
            padding: const EdgeInsets.only(
              bottom: 12,
            ),
            child: Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            ),
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
}

/// Часть Route'а [LoginRoute], показываемая при запуске на мобильных платформах.
///
/// Данный Route нельзя показывать на Desktop-платформах, поскольку inappwebview, используемый для рендеринга страницы, не поддерживается на Desktop-платформах.
class MobileSpotifyLogin extends StatefulWidget {
  const MobileSpotifyLogin({
    super.key,
  });

  @override
  State<MobileSpotifyLogin> createState() => _MobileSpotifyLoginState();
}

class _MobileSpotifyLoginState extends State<MobileSpotifyLogin> {
  bool isWebViewShown = true;

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      // Данный Route нельзя показывать на Desktop-платформах, поскольку inappwebview, используемый для рендеринга страницы, не поддерживается на Desktop-платформах.

      return const Text(
        "MobileSpotifyLogin предназначен для работы на мобильных платформах.",
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.profile_spotifyAuthTitle,
        ),
        centerTitle: true,
        actions: isWebViewShown
            ? [
                PopupMenuButton(
                  itemBuilder: (BuildContext context) {
                    return [
                      PopupMenuItem(
                        value: true,
                        onTap: () => Navigator.push(
                          context,
                          Material3PageRoute(
                            builder: (context) => const DesktopSpotifyLogin(),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!
                              .login_mobileAlternateAuthTitle,
                        ),
                      ),
                    ];
                  },
                ),
              ]
            : null,
      ),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        maintainBottomViewPadding: true,
        child: isWebViewShown
            ? InAppWebView(
                initialUrlRequest: URLRequest(
                  url: WebUri(
                    spotifyAuthUrl,
                  ),
                ),
                initialSettings: InAppWebViewSettings(
                  userAgent:
                      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.0.0 afari/537.36",
                  incognito: true,
                ),
                onLoadStop: (
                  InAppWebViewController controller,
                  WebUri? action,
                ) async {
                  if (action == null || !isWebViewShown) return;

                  String url = action.toString();
                  if (url.endsWith("/")) {
                    url = url.substring(0, url.length - 1);
                  }

                  // Проверяем, что мы на правильной странице.
                  final exp =
                      RegExp(r"https:\/\/accounts.spotify.com\/.+\/status");
                  if (!exp.hasMatch(url)) return;

                  // Извлекаем Cookie.
                  final cookies = await CookieManager.instance().getCookies(
                    url: action,
                  );
                  final String? spDC = cookies
                      .firstWhereOrNull(
                        (cookie) => cookie.name == "sp_dc",
                      )
                      ?.value;

                  if (!context.mounted) return;

                  // Проверка на случай, если sp_dc равен null.
                  if (spDC == null) {
                    showErrorDialog(
                      context,
                      description: AppLocalizations.of(context)!
                          .profile_spotifyAuthNoSPDC,
                    );

                    setState(() => isWebViewShown = true);

                    return;
                  }

                  // Пытаемся авторизоваться по токену.
                  setState(() => isWebViewShown = false);
                  final bool authorized = await spotifyAuthorize(context, spDC);

                  // Если авторизация успешно, то выкидываем пользователя на главный экран.
                  if (authorized && context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              )
            : const SuccessAuthWidget(),
      ),
    );
  }
}
