import "package:animations/animations.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../main.dart";
import "../routes/login.dart";
import "../routes/music.dart";
import "../routes/music/playlist.dart";
import "../routes/player.dart";
import "../routes/profile.dart";
import "../routes/profile/categories/visual/alternative_slider.dart";
import "../routes/profile/categories/visual/app_wide_colors.dart";
import "../routes/profile/categories/visual/dynamic_scheme_type.dart";
import "../routes/profile/categories/visual/oled.dart";
import "../routes/profile/categories/visual/spoiler_next_audio.dart";
import "../routes/profile/categories/visual/theme.dart";
import "../routes/profile/debug/color_scheme.dart";
import "../routes/profile/debug/markdown_viewer.dart";
import "../routes/profile/debug/player.dart";
import "../routes/profile/debug/playlists_viewer.dart";
import "../routes/profile/download_manager.dart";
import "../routes/profile/settings_exporter.dart";
import "../routes/profile/settings_importer.dart";
import "../routes/welcome.dart";
import "../widgets/shell_route_wrapper.dart";
import "auth.dart";
import "l18n.dart";
import "playlists.dart";
import "user.dart";

part "navigation_router.g.dart";

/// Helper-метод, помогающий создать страницу с анимацией перехода по умолчанию.
CustomTransitionPage buildPageWithDefaultTransition<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
  SharedAxisTransitionType transitionType = SharedAxisTransitionType.horizontal,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    ) {
      return SharedAxisTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        transitionType: transitionType,
        child: child,
      );
    },
  );
}

/// [GoRouter], используемый для навигации по приложению.
///
/// Если Вам нужно изменить redirect'ы, то обратитесь к [currentAuthStateProvider].
@riverpod
GoRouter router(Ref ref) {
  // ignore: avoid_manual_providers_as_generated_provider_dependency
  final l18n = ref.watch(l18nProvider);

  final authStateNotifier = ValueNotifier(AuthState.unknown);
  ref
    ..onDispose(authStateNotifier.dispose)
    ..listen(currentAuthStateProvider, (_, value) {
      authStateNotifier.value = value;
    });

  final List<NavigationItem> navigationItems = [
    NavigationItem(
      path: "/music",
      icon: Icons.music_note_outlined,
      selectedIcon: Icons.music_note,
      label: l18n.music_label,
      body: (_) => const HomeMusicPage(),
      routes: [
        GoRoute(
          path: "playlist/:owner_id/:id",
          pageBuilder: (BuildContext context, GoRouterState state) {
            final ExtendedPlaylist? playlist =
                ref.read(playlistsProvider.notifier).getPlaylist(
                      int.parse(state.pathParameters["owner_id"]!),
                      int.parse(state.pathParameters["id"]!),
                    );
            if (playlist == null) {
              throw Exception("Playlist not found");
            }

            return buildPageWithDefaultTransition(
              context: context,
              state: state,
              child: PlaylistRoute(
                ownerID: playlist.ownerID,
                id: playlist.id,
              ),
            );
          },
        ),
      ],
    ),

    // Библиотека.
    NavigationItem(
      path: "/library",
      icon: Icons.favorite_outline,
      selectedIcon: Icons.favorite,
      label: l18n.music_library_label,
      mobileOnly: true,
      body: (_) {
        final ExtendedPlaylist? playlist = ref.read(favoritesPlaylistProvider);
        if (playlist == null) {
          throw Exception("Playlist not found");
        }

        return PlaylistRoute(
          ownerID: playlist.ownerID,
          id: playlist.id,
        );
      },
    ),
    NavigationItem(
      path: "/profile",
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: l18n.profile_label,
      body: (_) => const HomeProfilePage(),
      routes: [
        GoRoute(
          path: "download_manager",
          pageBuilder: (BuildContext context, GoRouterState state) {
            return buildPageWithDefaultTransition(
              context: context,
              state: state,
              child: const DownloadManagerRoute(),
            );
          },
        ),
        GoRoute(
          path: "settings_exporter",
          pageBuilder: (BuildContext context, GoRouterState state) {
            return buildPageWithDefaultTransition(
              context: context,
              state: state,
              child: const SettingsExporterRoute(),
            );
          },
        ),
        GoRoute(
          path: "settings_importer",
          pageBuilder: (BuildContext context, GoRouterState state) {
            return buildPageWithDefaultTransition(
              context: context,
              state: state,
              child: const SettingsImporterRoute(),
            );
          },
        ),
        GoRoute(
          path: "setting_theme_mode",
          pageBuilder: (BuildContext context, GoRouterState state) {
            return buildPageWithDefaultTransition(
              context: context,
              state: state,
              child: const ThemeSettingPage(),
            );
          },
        ),
        GoRoute(
          path: "setting_oled",
          pageBuilder: (BuildContext context, GoRouterState state) {
            return buildPageWithDefaultTransition(
              context: context,
              state: state,
              child: const OLEDSettingPage(),
            );
          },
        ),
        GoRoute(
          path: "setting_app_wide_colors",
          pageBuilder: (BuildContext context, GoRouterState state) {
            return buildPageWithDefaultTransition(
              context: context,
              state: state,
              child: const AppWideColorsSettingPage(),
            );
          },
        ),
        GoRoute(
          path: "setting_dynamic_scheme_type",
          pageBuilder: (BuildContext context, GoRouterState state) {
            return buildPageWithDefaultTransition(
              context: context,
              state: state,
              child: const DynamicSchemeTypeSettingPage(),
            );
          },
        ),
        GoRoute(
          path: "setting_alternative_slider",
          pageBuilder: (BuildContext context, GoRouterState state) {
            return buildPageWithDefaultTransition(
              context: context,
              state: state,
              child: const AlternativeSliderSettingPage(),
            );
          },
        ),
        GoRoute(
          path: "setting_spoiler_next_audio",
          pageBuilder: (BuildContext context, GoRouterState state) {
            return buildPageWithDefaultTransition(
              context: context,
              state: state,
              child: const SpoilerNextAudioSettingPage(),
            );
          },
        ),
        GoRoute(
          path: "color_scheme_debug",
          pageBuilder: (BuildContext context, GoRouterState state) {
            return buildPageWithDefaultTransition(
              context: context,
              state: state,
              child: const ColorSchemeDebugMenu(),
            );
          },
        ),
        GoRoute(
          path: "playlists_viewer_debug",
          pageBuilder: (BuildContext context, GoRouterState state) {
            return buildPageWithDefaultTransition(
              context: context,
              state: state,
              child: const PlaylistsViewerDebugMenu(),
            );
          },
        ),
        GoRoute(
          path: "markdown_viewer_debug",
          pageBuilder: (BuildContext context, GoRouterState state) {
            return buildPageWithDefaultTransition(
              context: context,
              state: state,
              child: const MarkdownViewerDebugMenu(),
            );
          },
        ),
        GoRoute(
          path: "player_debug",
          pageBuilder: (BuildContext context, GoRouterState state) {
            return buildPageWithDefaultTransition(
              context: context,
              state: state,
              child: const PlayerDebugMenu(),
            );
          },
        ),
      ],
    ),
  ];

  return GoRouter(
    debugLogDiagnostics: true,
    refreshListenable: authStateNotifier,
    initialLocation: "/music",
    navigatorKey: navigatorKey,
    redirect: (_, GoRouterState state) {
      final authState = ref.read(currentAuthStateProvider);
      if (authState == AuthState.authenticated) return null;

      final nonAuthorizedPaths = ["/welcome", "/login"];
      if (!nonAuthorizedPaths.contains(state.fullPath)) {
        return "/welcome";
      }

      return null;
    },
    routes: [
      GoRoute(
        path: "/welcome",
        pageBuilder: (BuildContext context, GoRouterState state) {
          return buildPageWithDefaultTransition(
            context: context,
            state: state,
            child: const WelcomeRoute(),
          );
        },
      ),
      GoRoute(
        path: "/login",
        pageBuilder: (BuildContext context, GoRouterState state) {
          return buildPageWithDefaultTransition(
            context: context,
            state: state,
            child: const LoginRoute(),
          );
        },
      ),
      ShellRoute(
        builder: (_, state, child) => ShellRouteWrapper(
          currentPath: state.fullPath!,
          navigationItems: navigationItems,
          child: child,
        ),
        routes: [
          for (final item in navigationItems)
            if (item.body != null)
              GoRoute(
                path: item.path,
                pageBuilder: (BuildContext context, GoRouterState state) =>
                    buildPageWithDefaultTransition(
                  context: context,
                  state: state,
                  transitionType: SharedAxisTransitionType.vertical,
                  child: item.body!(context),
                ),
                routes: item.routes,
              ),
        ],
      ),
      GoRoute(
        path: "/player",
        pageBuilder: (BuildContext context, GoRouterState state) {
          return buildPageWithDefaultTransition(
            context: context,
            state: state,
            child: const PlayerRoute(),
          );
        },
      ),
    ],
  );
}
