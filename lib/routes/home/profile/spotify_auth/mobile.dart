import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:flutter_inappwebview/flutter_inappwebview.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../../../../consts.dart";
import "../../../../provider/l18n.dart";
import "../../../../utils.dart";
import "../../../../widgets/dialogs.dart";
import "../../../../widgets/page_route_builders.dart";
import "../../../login.dart";
import "../spotify_auth.dart";
import "desktop.dart";

/// Виджет, отображаемый при успешной авторизации.
class SuccessAuthWidget extends ConsumerWidget {
  const SuccessAuthWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);

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
            l18n.login_mobileSuccessAuth,
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
class MobileSpotifyLogin extends HookConsumerWidget {
  const MobileSpotifyLogin({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // InAppWebView, используемый для рендеринга Web-страницы, не поддерживается на Desktop-платформах.
    assert(
      isDesktop,
      "MobileSpotifyLogin предназначен для работы на мобильных платформах.",
    );

    final l18n = ref.watch(l18nProvider);

    final isWebViewShown = useState(true);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l18n.profile_spotifyAuthTitle,
        ),
        centerTitle: true,
        actions: isWebViewShown.value
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
                          l18n.login_mobileAlternateAuthTitle,
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
        child: isWebViewShown.value
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
                  if (action == null || !isWebViewShown.value) return;

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
                      description: l18n.profile_spotifyAuthNoSPDC,
                    );

                    isWebViewShown.value = true;

                    return;
                  }

                  // Пытаемся авторизоваться по токену.
                  isWebViewShown.value = false;
                  final bool authorized =
                      await spotifyAuthorize(ref, context, spDC);

                  // Если авторизация успешно, то выкидываем пользователя на главный экран.
                  if (authorized && context.mounted) context.pop();
                },
              )
            : const SuccessAuthWidget(),
      ),
    );
  }
}
