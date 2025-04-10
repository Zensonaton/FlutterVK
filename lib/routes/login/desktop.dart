import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:gap/gap.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:styled_text/styled_text.dart";
import "package:url_launcher/url_launcher.dart";

import "../../api/vk/consts.dart";
import "../../consts.dart";
import "../../provider/l18n.dart";
import "../../utils.dart";
import "../../widgets/loading_button.dart";
import "../../widgets/shortcuts_propagator.dart";
import "../login.dart";

/// Часть Route'а [LoginRoute], показываемая при запуске на desktop-платформах.
class DesktopLoginWidget extends HookConsumerWidget {
  /// Текст, который нужно ввести в поле для ввода токена, чтобы войти в демо-режим.
  static const String demoText = "DEMO";

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
    final l18n = ref.watch(l18nProvider);

    final controller = useTextEditingController();
    useValueListenable(controller);

    final String? extractedToken = useMemoized(
      () => extractAccessToken(controller.text),
      [controller.text],
    );
    final bool isDemo = useMemoized(
      () => controller.text == demoText,
      [controller.text],
    );

    final isLoading = useState(false);

    Future<void> onAuthPressed() async {
      isLoading.value = true;

      await tryAuthorize(
        ref,
        context,
        extractedToken!,
        useAlternateAuth,
      );
      isLoading.value = false;
    }

    void onDemoPressed() {
      tryDemoAuth(ref);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          appName,
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
                        ? l18n.login_connect_recommendations_title
                        : l18n.login_title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Gap(12),

                  // Описание авторизации.
                  StyledText(
                    text: useAlternateAuth
                        ? l18n.login_connect_recommendations_desc
                        : l18n.login_desktop_desc,
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
                  ShortcutsPropagator(
                    child: TextField(
                      controller: controller,
                      enabled: !isLoading.value,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(
                          Icons.key,
                        ),
                        hintText:
                            "https://oauth.vk.com/blank.html#access_token=vk1...",
                      ),
                    ),
                  ),
                  const Gap(36),

                  // Кнопки для продолжения авторизации.
                  SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      spacing: 8,
                      alignment: WrapAlignment.end,
                      children: [
                        // Кнопка для входа в демо-режим.
                        if (isDemo)
                          FilledButton.icon(
                            icon: const Icon(
                              Icons.play_arrow,
                            ),
                            label: const Text(
                              "DEMO",
                            ),
                            onPressed: onDemoPressed,
                          ),

                        // Кнопка "авторизоваться".
                        LoadingIconButton(
                          icon: const Icon(
                            Icons.arrow_forward_ios,
                          ),
                          label: Text(
                            l18n.login_authorize,
                          ),
                          onPressed:
                              extractedToken != null ? onAuthPressed : null,
                        ),
                      ],
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
