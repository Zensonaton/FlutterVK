import "package:animations/animations.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../main.dart";
import "../routes/fullscreen_player.dart";
import "../routes/home/music.dart";
import "../routes/home/music/playlist.dart";
import "../routes/home/profile.dart";
import "../routes/home/profile/categories/visual/app_wide_colors.dart";
import "../routes/home/profile/categories/visual/dynamic_scheme_type.dart";
import "../routes/home/profile/categories/visual/oled.dart";
import "../routes/home/profile/categories/visual/theme.dart";
import "../routes/home/profile/debug/colorscheme.dart";
import "../routes/home/profile/debug/markdown_viewer.dart";
import "../routes/home/profile/debug/playlists_viewer.dart";
import "../routes/home/profile/download_manager.dart";
import "../routes/home/profile/settings_exporter.dart";
import "../routes/home/profile/settings_importer.dart";
import "../routes/login.dart";
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
GoRouter router(RouterRef ref) {
  // ignore: avoid_manual_providers_as_generated_provider_dependency
  final l18n = ref.watch(l18nProvider);

  final authStateNotifier = ValueNotifier(AuthState.unknown);
  ref
    ..onDispose(authStateNotifier.dispose)
    ..listen(currentAuthStateProvider, (_, value) {
      authStateNotifier.value = value;
    });

  final List<NavigationItem> navigationItems = [
    // Музыка.
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
      label: l18n.music_libraryLabel,
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

    // Профиль.
    NavigationItem(
      path: "/profile",
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: l18n.home_profilePageLabel,
      body: (_) => const HomeProfilePage(),
      routes: [
        // Менеджер загрузок.
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

        // Экспорт настроек.
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

        // Импорт настроек.
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

        // Настройка "Тема".
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

        // Настройка "OLED".
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

        // Настройка "Цвета трека по всему приложению".
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

        // Настройка "Тип палитры цветов обложки".
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

        // Color Scheme Debug.
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

        // Playlists Viewer.
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

        // Markdown Viewer.
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
      ],
    ),
  ];

  return GoRouter(
    debugLogDiagnostics: true,
    refreshListenable: authStateNotifier,
    initialLocation: "/music",
    navigatorKey: navigatorKey,
    redirect: (_, GoRouterState state) {
      final AuthState authState = ref.read(currentAuthStateProvider);

      // Проверяем, может ли пользователь попасть в этот route.
      // Если нет, то насильно пересылаем (редиректим) его в другое место.
      if (!authState.allowedPaths
          .any((path) => state.fullPath!.startsWith(path))) {
        return authState.redirectPath;
      }

      // Всё отлично, редиректы не нужны.
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
        path: "/fullscreenPlayer",
        pageBuilder: (BuildContext context, GoRouterState state) {
          return const MaterialPage(
            child: FullscreenPlayerRoute(),
          );
        },
      ),
    ],
  );
}
