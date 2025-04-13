import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:styled_text/tags/styled_text_tag.dart";
import "package:styled_text/tags/styled_text_tag_action.dart";
import "package:styled_text/widgets/styled_text.dart";
import "package:wakelock_plus/wakelock_plus.dart";

import "../provider/l18n.dart";
import "../provider/player.dart";
import "../utils.dart";
import "player/background.dart";
import "player/desktop.dart";
import "player/mobile.dart";

/// Виджет, отображаемый в случае, если плеер не активен.
class _InactivePlayerWidget extends ConsumerWidget {
  const _InactivePlayerWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 12,
                children: [
                  RepaintBoundary(
                    child: Image.asset(
                      "assets/images/dog.gif",
                    ),
                  ),
                  StyledText(
                    text: l18n.fullscreen_no_audio,
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                    tags: {
                      "bold": StyledTextTag(
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      "exit": StyledTextActionTag(
                        (_, __) {
                          Navigator.of(context).pop();
                        },
                        style: theme.textTheme.bodyLarge!.copyWith(
                          color: scheme.primary,
                        ),
                      ),
                    },
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      l18n.general_exit,
                      style: theme.textTheme.bodyLarge!.copyWith(
                        color: scheme.primary,
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

/// Route, отображаемый плеер на всё окно приложения.
///
/// go_route: `/player`.
class PlayerRoute extends HookConsumerWidget {
  /// Длительность перехода между состоянием работающего плеера, и неактивного.
  static const Duration transitionDuration = Duration(milliseconds: 500);

  const PlayerRoute({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(playerProvider);
    ref.watch(playerIsLoadedProvider);
    ref.watch(playerIsPlayingProvider);

    final isLoaded = player.isLoaded;
    final isPlaying = player.isPlaying;

    final mobileLayout = isMobileLayout(context);

    useEffect(
      () {
        WakelockPlus.toggle(enable: isPlaying);

        return null;
      },
      [isPlaying],
    );

    useEffect(
      () => WakelockPlus.disable,
      [],
    );

    return AnimatedSwitcher(
      duration: transitionDuration,
      child: isLoaded
          ? Scaffold(
              body: Stack(
                children: [
                  const RepaintBoundary(
                    child: BackgroundImage(),
                  ),
                  if (mobileLayout)
                    const MobilePlayerWidget()
                  else
                    const DesktopPlayerWidget(),
                ],
              ),
            )
          : const _InactivePlayerWidget(),
    );
  }
}
