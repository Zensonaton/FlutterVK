import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:styled_text/styled_text.dart";
import "package:url_launcher/url_launcher.dart";

import "../../../../consts.dart";
import "../spotify_auth.dart";

/// Часть Route'а [LoginRoute], показываемая при запуске на desktop-платформах.
class DesktopSpotifyLogin extends StatefulWidget {
  const DesktopSpotifyLogin({
    super.key,
  });

  @override
  State<DesktopSpotifyLogin> createState() => _DesktopSpotifyLoginState();
}

class _DesktopSpotifyLoginState extends State<DesktopSpotifyLogin> {
  String spDC = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.profile_spotifyAuthTitle,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Текст "Авторизация".
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: 12,
                    ),
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)!.login_desktopTitle,
                        style: Theme.of(context).textTheme.titleLarge!,
                      ),
                    ),
                  ),

                  // Описание авторизации.
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: 8,
                    ),
                    child: StyledText(
                      text: AppLocalizations.of(context)!
                          .profile_spotifyAuthDescription,
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
                              spotifyAuthUrl,
                            ),
                          ),
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      },
                    ),
                  ),

                  // Поле для ввода токена.
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: 8,
                    ),
                    child: TextField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(
                          Icons.key,
                        ),
                        hintText:
                            "AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz...",
                      ),
                      onChanged: (String value) => setState(
                        () => spDC = value,
                      ),
                    ),
                  ),

                  // Дополнительная информация для помощи.
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: 36,
                    ),
                    child: StyledText(
                      text: AppLocalizations.of(context)!
                          .profile_spotifyAuthHelpDescription,
                      style: Theme.of(context).textTheme.bodyLarge,
                      tags: {
                        "link": StyledTextActionTag(
                          (String? text, Map<String?, String?> attrs) =>
                              launchUrl(
                            Uri.parse(wikiSpotifySPDCcookie),
                          ),
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      },
                    ),
                  ),

                  // Кнопки для продолжения авторизации.
                  Align(
                    alignment: Alignment.bottomRight,
                    child: FilledButton.icon(
                      onPressed: spDC.trim().length >= 75
                          ? () async {
                              if (!await spotifyAuthorize(context, spDC)) {
                                return;
                              }

                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            }
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
