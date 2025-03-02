import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../consts.dart";
import "../enums.dart";
import "../main.dart";
import "../provider/auth.dart";
import "../provider/download_manager.dart";
import "../provider/l18n.dart";
import "../provider/player.dart";
import "../provider/preferences.dart";
import "../provider/updater.dart";
import "../services/logger.dart";
import "../utils.dart";
import "audio_player.dart";
import "dialogs.dart";
import "download_manager_icon.dart";

/// Класс для отображения Route'ов в [BottomNavigationBar], вместе с их названиями, а так же иконками.
class NavigationItem {
  /// Путь к данному элементу.
  final String path;

  /// Страница, которая будет отображена при выборе данного элемента. Если не будет указано, то Route будет отключён.
  final WidgetBuilder? body;

  /// Иконка, которая используется на [BottomNavigationBar].
  final IconData icon;

  /// Иконка, которая используется при выборе элемента в [BottomNavigationBar]. Если не указано, то будет использоваться [icon].
  final IconData? selectedIcon;

  /// Текст, используемый в [BottomNavigationBar].
  final String label;

  /// Указывает, что данная запись будет видна только в Mobile Layout'е.
  final bool mobileOnly;

  /// Опциональный список из путей, которые могут быть использованы в [GoRouter].
  final List<RouteBase> routes;

  NavigationItem({
    required this.path,
    this.body,
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.mobileOnly = false,
    this.routes = const [],
  });
}

/// Обёртка для [DownloadManagerIconWidget], добавляющая анимацию появления и исчезновения этого виджета.
class DownloadManagerWrapperWidget extends HookConsumerWidget {
  /// Длительность анимации появления/исчезновения иконки менеджера загрузок.
  static const Duration slideAnimationDuration = Duration(milliseconds: 500);

  const DownloadManagerWrapperWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(playerProvider);
    final downloadManager = ref.watch(downloadManagerProvider);
    ref.watch(playerIsLoadedProvider);

    final isLoaded = player.isLoaded;
    final downloadStarted = downloadManager.downloadStarted;

    final progressValue = useValueListenable(downloadManager.progress);
    final showAnimation = useAnimationController(
      duration: slideAnimationDuration,
      initialValue: downloadStarted ? 1.0 : 0.0,
    );
    useValueListenable(showAnimation);

    final timer = useRef<Timer?>(null);
    useEffect(
      () {
        timer.value?.cancel();

        if (downloadStarted) {
          showAnimation.animateTo(
            1.0,
            curve: Easing.emphasizedDecelerate,
          );
        } else {
          // Прячем виджет, если прошло 5 секунд после полной загрузки.
          timer.value = Timer(
            const Duration(seconds: 5),
            () {
              if (!context.mounted) return;

              showAnimation.animateTo(
                0.0,
                curve: Easing.emphasizedAccelerate,
              );
            },
          );
        }

        return null;
      },
      [downloadStarted],
    );

    if (showAnimation.value == 0.0) return const SizedBox();

    const double position = 40 - downloadManagerMinimizedSize / 2;
    const double left = position + 4;
    final double bottom = (isLoaded
            ? MusicPlayerWidget.desktopMiniPlayerHeightWithSafeArea(context)
            : 0) +
        position;

    return AnimatedBuilder(
      animation: showAnimation,
      builder: (context, child) {
        return Positioned(
          left: left,
          bottom: bottom,
          child: FractionalTranslation(
            translation: Offset(
              0,
              1 - showAnimation.value,
            ),
            child: Opacity(
              opacity: showAnimation.value,
              child: RepaintBoundary(
                child: DownloadManagerIconWidget(
                  progress: progressValue,
                  title: downloadManager.currentTask?.smallTitle ?? "",
                  onTap: () => context.go("/profile/download_manager"),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Виджет, который содержит в себе [Scaffold] с [NavigationRail] или [BottomNavigationBar] в зависимости от того, какой используется Layout: Desktop ([isDesktopLayout]) или Mobile ([isMobileLayout]), а так же мини-плеер снизу ([BottomMusicPlayerWrapper]).
///
/// Данный виджет так же подписывается на некоторые события, по типу проверки на наличия новых обновлений.
class ShellRouteWrapper extends HookConsumerWidget {
  static final AppLogger logger = getLogger("ShellRouteWrapper");

  final Widget child;
  final String currentPath;
  final List<NavigationItem> navigationItems;

  const ShellRouteWrapper({
    super.key,
    required this.child,
    required this.currentPath,
    required this.navigationItems,
  });

  /// Проверяет на наличие обновлений, и дальше предлагает пользователю обновиться, если есть новое обновление.
  void checkForUpdates(WidgetRef ref, BuildContext context) async {
    final l18n = ref.watch(l18nProvider);
    final preferences = ref.read(preferencesProvider);
    final preferencesNotifier = ref.read(preferencesProvider.notifier);
    UpdateBranch updateBranch = preferences.updateBranch;

    // Отображаем уведомление о бета-обновлении, если мы находимся на бета-версии.
    if (isPrerelease && !preferences.preReleaseWarningShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        preferencesNotifier.setPreReleaseWarningShown(true);
        showErrorDialog(
          context,
          title: l18n.prerelease_app_version_warning,
          description: l18n.prerelease_app_version_warning_desc,
        );

        // Обновляем настройки.
        updateBranch = UpdateBranch.preReleases;
        preferencesNotifier.setUpdateBranch(updateBranch);
      });
    }

    // Проверяем, есть ли разрешение на обновления, а так же работу интернета.
    if (preferences.updatePolicy == UpdatePolicy.disabled ||
        !connectivityManager.hasConnection) {
      return;
    }

    // Проверяем на наличие обновлений.
    if (context.mounted) {
      ref.read(updaterProvider).checkForUpdates(
            context,
            allowPre: updateBranch == UpdateBranch.preReleases,
            useSnackbarOnUpdate: preferences.updatePolicy == UpdatePolicy.popup,
          );
    }
  }

  /// Отображает диалог о том, что запущена демо-версия приложения.
  void showDemoModeWarning(WidgetRef ref, BuildContext context) async {
    final l18n = ref.watch(l18nProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      showErrorDialog(
        context,
        title: l18n.demo_mode_welcome_warning,
        description: l18n.demo_mode_welcome_warning_desc,
      );
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDemo = ref.read(isDemoProvider);

    final bool mobileLayout = isMobileLayout(context);

    useEffect(
      () {
        // Проверяем на наличие обновлений, если мы не в debug-режиме.
        if (!isDemo && !kDebugMode) checkForUpdates(ref, context);

        // Делаем уведомление о демо-версии.
        if (isDemo && !kDebugMode) showDemoModeWarning(ref, context);

        return null;
      },
      [],
    );

    final List<NavigationItem> navigationItems = useMemoized(
      () => this.navigationItems.where(
        (item) {
          return !item.mobileOnly || (item.mobileOnly && mobileLayout);
        },
      ).toList(),
      [mobileLayout],
    );
    int currentIndex = clampInt(
      navigationItems.indexWhere(
        (item) => currentPath.startsWith(item.path),
      ),
      0,
      navigationItems.length,
    );

    /// Обработчик выбора элемента в [NavigationRail] либо [BottomNavigationBar].
    void onDestinationSelected(int index) {
      if (index == currentIndex) return;

      context.go(navigationItems[index].path);
      HapticFeedback.selectionClick();
    }

    final Widget wrappedChild = useMemoized(
      () {
        return Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (!mobileLayout)
                        RepaintBoundary(
                          child: NavigationRail(
                            selectedIndex: currentIndex,
                            onDestinationSelected: onDestinationSelected,
                            labelType: NavigationRailLabelType.all,
                            destinations: [
                              for (final item in navigationItems)
                                NavigationRailDestination(
                                  icon: Icon(
                                    item.icon,
                                  ),
                                  selectedIcon: Icon(
                                    item.selectedIcon ?? item.icon,
                                  ),
                                  label: Text(
                                    item.label,
                                  ),
                                  disabled: item.body == null,
                                ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: child,
                      ),
                    ],
                  ),
                ),
                if (!mobileLayout) const BottomMusicPlayerWrapper(),
              ],
            ),
            if (mobileLayout) const BottomMusicPlayerWrapper(),
            if (!mobileLayout) const DownloadManagerWrapperWidget(),
          ],
        );
      },
      [currentIndex, mobileLayout, child],
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: wrappedChild,
      bottomNavigationBar: mobileLayout
          ? NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: (int index) {
                onDestinationSelected(
                  index,
                );
              },
              destinations: [
                for (final item in navigationItems)
                  NavigationDestination(
                    icon: Icon(
                      item.icon,
                    ),
                    selectedIcon: Icon(
                      item.selectedIcon ?? item.icon,
                    ),
                    label: item.label,
                    enabled: item.body != null,
                  ),
              ],
            )
          : null,
    );
  }
}

/// Виджет, являющийся wrapper'ом для [MusicPlayerWidget], который добавляет анимацию появления и исчезновения мини-плеера.
class BottomMusicPlayerWrapper extends HookConsumerWidget {
  static final AppLogger logger = getLogger("BottomMusicPlayerWrapper");

  /// Длительность анимации появления/исчезновения мини-плеера.
  static const Duration playerAnimationDuration = Duration(milliseconds: 500);

  const BottomMusicPlayerWrapper({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(playerProvider);
    ref.watch(playerIsLoadedProvider);
    ref.watch(playerPositionProvider);

    final bool isLoaded = player.isLoaded;
    final animation = useAnimationController(
      duration: playerAnimationDuration,
      initialValue: isLoaded ? 1.0 : 0.0,
    );
    useValueListenable(animation);
    useEffect(
      () {
        animation.animateTo(
          isLoaded ? 1.0 : 0.0,
          curve: isLoaded
              ? Easing.emphasizedDecelerate
              : Easing.emphasizedAccelerate,
        );

        return null;
      },
      [isLoaded],
    );

    // Если плеер не загружен, то ничего не показываем.
    if (animation.value == 0.0) return const SizedBox();

    return Align(
      alignment: Alignment.bottomCenter,
      child: Opacity(
        opacity: animation.value,
        child: FractionalTranslation(
          translation: Offset(
            0.0,
            1.0 - animation.value,
          ),
          child: const MusicPlayerWidget(),
        ),
      ),
    );
  }
}
