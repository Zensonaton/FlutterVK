import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:flutter_inappwebview/flutter_inappwebview.dart";
import "package:gap/gap.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../../api/vk/consts.dart";
import "../../provider/l18n.dart";
import "../../utils.dart";
import "../../widgets/dialogs.dart";
import "../../widgets/page_route_builders.dart";
import "../login.dart";
import "desktop.dart";

/// Часть Route'а [LoginRoute], показываемая при запуске на мобильных платформах.
///
/// Данный Route нельзя показывать на Desktop-платформах, поскольку inappwebview, используемый для рендеринга страницы, не поддерживается на Desktop-платформах.
class MobileLoginWidget extends HookConsumerWidget {
  /// Указывает, что вместо авторизации с Kate Mobile (главный токен) будет проводиться вторичная авторизация от имени VK Admin.
  ///
  /// Используется при подключении рекомендаций ВКонтакте.
  final bool useAlternateAuth;

  const MobileLoginWidget({
    super.key,
    this.useAlternateAuth = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // InAppWebView, используемый для рендеринга Web-страницы, не поддерживается на Desktop-платформах.
    if (!isMobile) {
      throw Exception("MobileLoginWidget can only work on mobile platforms.");
    }

    final isWebViewShown = useState(true);

    final l18n = ref.watch(l18nProvider);

    if (!isWebViewShown.value) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Иконка.
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            ),
            const Gap(12),

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
                        useAlternateAuth: useAlternateAuth,
                      ),
                    ),
                  ),
                  child: Text(
                    l18n.login_mobileAlternateAuthTitle,
                  ),
                ),
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
              useAlternateAuth
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
              isWebViewShown.value = false;

              showErrorDialog(
                context,
                description: l18n.login_noTokenFound,
              );

              return;
            }

            // Пытаемся авторизоваться по токену.
            isWebViewShown.value = false;

            await tryAuthorize(
              ref,
              context,
              token,
              useAlternateAuth,
            );
          },
        ),
      ),
    );
  }
}
