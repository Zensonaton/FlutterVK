import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:styled_text/styled_text.dart";
import "package:url_launcher/url_launcher.dart";

import "../../consts.dart";
import "../provider/l18n.dart";
import "../widgets/page_route_builders.dart";
import "login.dart";

/// Route, показываемый при первом входе в приложение.
class WelcomeRoute extends ConsumerWidget {
  const WelcomeRoute({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  Text(
                    l18n.welcome_welcomeTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  StyledText(
                    text: l18n.welcome_welcomeDescription,
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
                          Uri.parse(repoURL),
                        ),
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    },
                  ),
                  const SizedBox(
                    height: 36,
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        Material3PageRoute(
                          builder: (context) => const LoginRoute(),
                        ),
                      ),
                      icon: const Icon(
                        Icons.arrow_forward_ios,
                      ),
                      label: Text(
                        l18n.welcome_welcomeContinue,
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
