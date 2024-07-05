import "package:animations/animations.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../main.dart";
import "../routes/fullscreen_player.dart";
import "../routes/home/music.dart";
import "../routes/home/profile.dart";
import "../routes/login.dart";
import "../routes/welcome.dart";
import "../widgets/shell_route_wrapper.dart";
import "auth.dart";
import "l18n.dart";

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
    NavigationItem(
      path: "/music",
      body: (_) => const HomeMusicPage(),
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: l18n.music_label,
    ),
    NavigationItem(
      path: "/profile",
      body: (_) => const HomeProfilePage(),
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: l18n.home_profilePageLabel,
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
      if (!authState.allowedPaths.contains(state.fullPath)) {
        return authState.redirectPath;
      }

      // Всё отлично, редиректы не нужны.
      return null;
    },
    routes: [
      GoRoute(
        path: "/",
        pageBuilder: (BuildContext context, GoRouterState state) {
          return buildPageWithDefaultTransition(
            context: context,
            child: const WelcomeRoute(),
            state: state,
          );
        },
      ),
      GoRoute(
        path: "/login",
        pageBuilder: (BuildContext context, GoRouterState state) {
          return buildPageWithDefaultTransition(
            context: context,
            child: const LoginRoute(),
            state: state,
          );
        },
      ),
      ShellRoute(
        builder: (_, state, child) => ShellRouteWrapper(
          currentPath: state.uri.path,
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
                  child: item.body!(context),
                  state: state,
                  transitionType: SharedAxisTransitionType.vertical,
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