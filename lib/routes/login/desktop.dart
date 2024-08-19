import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:gap/gap.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:styled_text/styled_text.dart";
import "package:url_launcher/url_launcher.dart";

import "../../api/vk/consts.dart";
import "../../provider/l18n.dart";
import "../../utils.dart";
import "../login.dart";

/// Часть Route'а [LoginRoute], показываемая при запуске на desktop-платформах.
class DesktopLoginWidget extends HookConsumerWidget {
  /// Указывает, что вместо авторизации с Kate Mobile (главный токен) будет проводиться вторичная авторизация от имени VK Admin.
  ///
  /// Используется при подключении рекомендаций ВКонтакте.
  final bool useAlternateAuth;

  const DesktopLoginWidget({
    super.key,
    this.useAlternateAuth = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = useState("");
    final String? extractedToken = extractAccessToken(token.value);
    final l18n = ref.watch(l18nProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Flutter VK",
        ),
        centerTitle: true,
      ),
      resizeToAvoidBottomInset: false,
      body: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Текст "Авторизация".
                  Text(
                    useAlternateAuth
                        ? l18n.login_desktopConnectRecommendationsTitle
                        : l18n.login_desktopTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Gap(12),

                  // Описание авторизации.
                  StyledText(
                    text: useAlternateAuth
                        ? l18n.login_desktopConnectRecommendationsDescription
                        : l18n.login_desktopDescription,
                    style: Theme.of(context).textTheme.bodyLarge,
                    tags: {
                      "bold": StyledTextTag(
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      "link": StyledTextActionTag(
                        (String? text, Map<String?, String?> attrs) {
                          launchUrl(
                            Uri.parse(
                              useAlternateAuth
                                  ? vkMusicRecommendationsOAuthURL
                                  : vkMainOAuthURL,
                            ),
                          );
                        },
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    },
                  ),
                  const Gap(8),

                  // Поле для ввода токена.
                  TextField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(
                        Icons.key,
                      ),
                      hintText:
                          "https://oauth.vk.com/blank.html#access_token=vk1...",
                    ),
                    onChanged: (String text) => token.value = text,
                  ),
                  const Gap(36),

                  // Кнопки для продолжения авторизации.
                  Align(
                    alignment: Alignment.bottomRight,
                    child: FilledButton.icon(
                      onPressed: extractedToken != null
                          ? () => tryAuthorize(
                                ref,
                                context,
                                extractedToken,
                                useAlternateAuth,
                              )
                          : null,
                      icon: const Icon(
                        Icons.arrow_forward_ios,
                      ),
                      label: Text(
                        l18n.login_desktopContinue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
