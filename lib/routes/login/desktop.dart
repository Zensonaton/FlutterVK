import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:styled_text/styled_text.dart";
import "package:url_launcher/url_launcher.dart";

import "../../consts.dart";
import "../../utils.dart";
import "../login.dart";

/// Часть Route'а [LoginRoute], показываемая при запуске на desktop-платформах.
class DesktopLoginWidget extends StatefulWidget {
  /// Указывает, что вместо авторизации с Kate Mobile (главный токен) будет проводиться вторичная авторизация от имени VK Admin.
  ///
  /// Используется при подключении рекомендаций ВКонтакте.
  final bool useAlternateAuth;

  const DesktopLoginWidget({
    super.key,
    this.useAlternateAuth = false,
  });

  @override
  State<DesktopLoginWidget> createState() => _DesktopLoginWidgetState();
}

class _DesktopLoginWidgetState extends State<DesktopLoginWidget> {
  String? token;

  @override
  Widget build(BuildContext context) {
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
                    widget.useAlternateAuth
                        ? AppLocalizations.of(context)!
                            .login_desktopConnectRecommendationsTitle
                        : AppLocalizations.of(context)!.login_desktopTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(
                    height: 12,
                  ),

                  // Описание авторизации.
                  StyledText(
                    text: widget.useAlternateAuth
                        ? AppLocalizations.of(context)!
                            .login_desktopConnectRecommendationsDescription
                        : AppLocalizations.of(context)!
                            .login_desktopDescription,
                    style: Theme.of(context).textTheme.bodyLarge,
                    tags: {
                      "bold": StyledTextTag(
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      "link": StyledTextActionTag(
                        (String? text, Map<String?, String?> attrs) =>
                            launchUrl(
                          Uri.parse(
                            widget.useAlternateAuth
                                ? vkMusicRecommendationsOAuthURL
                                : vkMainOAuthURL,
                          ),
                        ),
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    },
                  ),
                  const SizedBox(
                    height: 8,
                  ),

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
                    onChanged: (String value) => setState(
                      () => token = extractAccessToken(value),
                    ),
                  ),
                  const SizedBox(
                    height: 36,
                  ),

                  // Кнопки для продолжения авторизации.
                  Align(
                    alignment: Alignment.bottomRight,
                    child: FilledButton.icon(
                      onPressed: token != null
                          ? () => tryAuthorize(
                                context,
                                token!,
                                widget.useAlternateAuth,
                              )
                          : null,
                      icon: const Icon(
                        Icons.arrow_forward_ios,
                      ),
                      label: Text(
                        AppLocalizations.of(context)!.login_desktopContinue,
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
