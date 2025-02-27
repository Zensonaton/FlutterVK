import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

import "../utils.dart";
import "player/background.dart";
import "player/desktop.dart";
import "player/mobile.dart";

/// Route, отображаемый плеер на всё окно приложения.
///
/// go_route: `/player`.
class PlayerRoute extends StatelessWidget {
  const PlayerRoute({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final mobileLayout = isMobileLayout(context);

    return Scaffold(
      body: Stack(
        children: [
          const BackgroundImage(),
          BackButton(
            onPressed: () => context.pop(),
          ),
          if (mobileLayout)
            const MobilePlayerWidget()
          else
            const DesktopPlayerWidget(),
        ],
      ),
    );
  }
}
