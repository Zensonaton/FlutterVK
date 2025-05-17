import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:universal_back_gesture/back_gesture_config.dart";
import "package:universal_back_gesture/back_gesture_page_transitions_builder.dart";

import "../main.dart";
import "../routes/login.dart";
import "../routes/music.dart";
import "../routes/music/playlist.dart";
import "../routes/player.dart";
import "../routes/profile.dart";
import "../routes/profile/categories/visual/alternative_slider.dart";
import "../routes/profile/categories/visual/app_wide_colors.dart";
import "../routes/profile/categories/visual/crossfade_audio_colors.dart";
import "../routes/profile/categories/visual/dynamic_scheme_type.dart";
import "../routes/profile/categories/visual/oled.dart";
import "../routes/profile/categories/visual/show_audio_thumbs.dart";
import "../routes/profile/categories/visual/spoiler_next_audio.dart";
import "../routes/profile/categories/visual/theme.dart";
import "../routes/profile/debug/color_scheme.dart";
import "../routes/profile/debug/markdown_viewer.dart";
import "../routes/profile/debug/player.dart";
import "../routes/profile/debug/playlists_viewer.dart";
import "../routes/profile/download_manager.dart";
import "../routes/profile/settings_exporter.dart";
import "../routes/profile/settings_importer.dart";
import "../routes/search/search.dart";
import "../routes/welcome.dart";
import "../widgets/shell_route_wrapper.dart";
import "auth.dart";
import "l18n.dart";
import "playlists.dart";
import "user.dart";

part "navigation_router.g.dart";

/// Расширение для [MaterialPageRoute], которое добавляет поддержку [BackGestureConfig], используемая для навигации назад с помощью жеста.
///
/// Взято из [документации universal_back_gesture](https://pub.dev/packages/universal_back_gesture#2-configuration-for-individual-routes).
class CustomBackGesturePageRoute extends MaterialPageRoute {
  final BackGestureConfig config;

  final PageTransitionsBuilder parentTransitionBuilder;

  CustomBackGesturePageRoute({
    required super.builder,
    required this.config,
    required this.parentTransitionBuilder,
    super.settings,
  });

  @override
  Duration get transitionDuration => parentTransitionBuilder.transitionDuration;

  @override
  Duration get reverseTransitionDuration =>
      parentTransitionBuilder.reverseTransitionDuration;

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      parentTransitionBuilder.delegatedTransition;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return BackGesturePageTransitionsBuilder(
      parentTransitionBuilder: parentTransitionBuilder,
      config: config,
    ).buildTransitions(this, context, animation, secondaryAnimation, child);
  }
}

/// Расширение для [Page], которое добавляет поддержку [BackGestureConfig], используемая для навигации назад с помощью жеста.
///
/// Взято из [документации universal_back_gesture](https://pub.dev/packages/universal_back_gesture#2-configuration-for-individual-routes).
class MyCustomGoRouterPage extends Page {
  const MyCustomGoRouterPage({
    required this.child,
    this.parentTransitionBuilder = const FadeUpwardsPageTransitionsBuilder(),
    this.config = const BackGestureConfig(),
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  final Widget child;
  final PageTransitionsBuilder parentTransitionBuilder;
  final BackGestureConfig config;

  @override
  Route createRoute(BuildContext context) {
    return CustomBackGesturePageRoute(
      builder: (BuildContext context) => child,
      settings: this,
      parentTransitionBuilder: parentTransitionBuilder,
      config: config,
    );
  }
}

/// [GoRouter], используемый для навигации по приложению.
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
      body: (_) => const MusicRoute(),
      routes: [
        GoRoute(
          path: "playlist/:owner_id/:id",
          builder: (_, GoRouterState state) {
            final ExtendedPlaylist? playlist =
                ref.read(playlistsProvider.notifier).getPlaylist(
                      int.parse(state.pathParameters["owner_id"]!),
                      int.parse(state.pathParameters["id"]!),
                    );
            if (playlist == null) {
              throw Exception("Playlist not found");
            }

            return PlaylistRoute(
              ownerID: playlist.ownerID,
              id: playlist.id,
            );
          },
        ),
      ],
    ),
    // TODO: Убрать проверку на kDebugMode, когда будет готов поиск.
    if (kDebugMode)
      NavigationItem(
        path: "/search",
        icon: Icons.search_outlined,
        selectedIcon: Icons.search,
        label: l18n.search_label,
        body: (_) => const SearchRoute(),
      ),
    NavigationItem(
      path: "/library",
      icon: Icons.favorite_outline,
      selectedIcon: Icons.favorite,
      label: l18n.music_library_label,
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
      body: (_) => const ProfileRoute(),
      routes: [
        GoRoute(
          path: "download_manager",
          builder: (_, __) => const DownloadManagerRoute(),
        ),
        GoRoute(
          path: "settings_exporter",
          builder: (_, __) => const SettingsExporterRoute(),
        ),
        GoRoute(
          path: "settings_importer",
          builder: (_, __) => const SettingsImporterRoute(),
        ),
        GoRoute(
          path: "setting_theme_mode",
          builder: (_, __) => const ThemeSettingPage(),
        ),
        GoRoute(
          path: "setting_oled",
          builder: (_, __) => const OLEDSettingPage(),
        ),
        GoRoute(
          path: "setting_app_wide_colors",
          builder: (_, __) => const AppWideColorsSettingPage(),
        ),
        GoRoute(
          path: "setting_dynamic_scheme_type",
          builder: (_, __) => const DynamicSchemeTypeSettingPage(),
        ),
        GoRoute(
          path: "setting_alternative_slider",
          builder: (_, __) => const AlternativeSliderSettingPage(),
        ),
        GoRoute(
          path: "setting_spoiler_next_audio",
          builder: (_, __) => const SpoilerNextAudioSettingPage(),
        ),
        GoRoute(
          path: "setting_show_audio_thumbs",
          builder: (_, __) => const ShowAudioThumbsSettingPage(),
        ),
        GoRoute(
          path: "setting_crossfade_audio_colors",
          builder: (_, __) => const CrossfadeAudioColorsSettingPage(),
        ),
        GoRoute(
          path: "color_scheme_debug",
          builder: (_, __) => const ColorSchemeDebugMenu(),
        ),
        GoRoute(
          path: "playlists_viewer_debug",
          builder: (_, __) => const PlaylistsViewerDebugMenu(),
        ),
        GoRoute(
          path: "markdown_viewer_debug",
          builder: (_, __) => const MarkdownViewerDebugMenu(),
        ),
        GoRoute(
          path: "player_debug",
          builder: (_, __) => const PlayerDebugMenu(),
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
      final nonAuthorizedPaths = ["/welcome", "/login"];

      switch (authState) {
        case AuthState.unknown:
        case AuthState.unauthenticated:
          if (nonAuthorizedPaths.contains(state.fullPath)) break;

          return nonAuthorizedPaths.first;
        case AuthState.authenticated:
          if (nonAuthorizedPaths.contains(state.fullPath)) {
            return "/music";
          }

          break;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: "/welcome",
        builder: (_, __) => const WelcomeRoute(),
      ),
      GoRoute(
        path: "/login",
        builder: (_, __) => const LoginRoute(),
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
                routes: item.routes,
                builder: (BuildContext context, _) => item.body!(context),
              ),
        ],
      ),
      GoRoute(
        path: "/player",
        pageBuilder: (_, __) {
          return CustomTransitionPage(
            child: const PlayerRoute(),
            transitionsBuilder: (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
              Widget child,
            ) {
              const builder = FadeUpwardsPageTransitionsBuilder();

              return builder.buildTransitions(
                null,
                context,
                animation,
                secondaryAnimation,
                child,
              );
            },
          );

          // TODO: Сделать поддержку жеста назад для этого route, если universal_back_gesture будет:
          //  1. Поддерживать вертикальный жест.
          //  2. Правильно отображать transition для parent route.
          //
          // return const MyCustomGoRouterPage(
          //   child: PlayerRoute(),
          // );
        },
      ),
    ],
  );
}
