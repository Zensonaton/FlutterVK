import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:gap/gap.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:styled_text/styled_text.dart";
import "package:url_launcher/url_launcher.dart";

import "../../../../consts.dart";
import "../../../../provider/l18n.dart";
import "../spotify_auth.dart";

/// Часть Route'а [LoginRoute], показываемая при запуске на desktop-платформах.
class DesktopSpotifyLogin extends HookConsumerWidget {
  const DesktopSpotifyLogin({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spDC = useState("");

    final l18n = ref.watch(l18nProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l18n.profile_spotifyAuthTitle,
        ),
        centerTitle: true,
      ),
      resizeToAvoidBottomInset: false,
      body: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(
              24,
            ),
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Текст "Авторизация".
                  Center(
                    child: Text(
                      l18n.login_desktopTitle,
                      style: Theme.of(context).textTheme.titleLarge!,
                    ),
                  ),
                  const Gap(12),

                  // Описание авторизации.
                  StyledText(
                    text: l18n.profile_spotifyAuthDescription,
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
                          "AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz...",
                    ),
                    onChanged: (String value) => spDC.value = value,
                  ),
                  const Gap(8),

                  // Дополнительная информация для помощи.
                  StyledText(
                    text: l18n.profile_spotifyAuthHelpDescription,
                    style: Theme.of(context).textTheme.bodyLarge,
                    tags: {
                      "link": StyledTextActionTag(
                        (String? text, Map<String?, String?> attrs) =>
                            launchUrl(
                          Uri.parse(wikiSpotifySPDCcookie),
                        ),
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    },
                  ),
                  const Gap(36),

                  // Кнопки для продолжения авторизации.
                  Align(
                    alignment: Alignment.bottomRight,
                    child: FilledButton.icon(
                      icon: const Icon(
                        Icons.arrow_forward_ios,
                      ),
                      label: Text(
                        l18n.login_desktopContinue,
                      ),
                      onPressed: spDC.value.trim().length >= 75
                          ? () async {
                              if (!await spotifyAuthorize(
                                ref,
                                context,
                                spDC.value,
                              )) {
                                return;
                              }

                              if (context.mounted) context.pop();
                            }
                          : null,
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
