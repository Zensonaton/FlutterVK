import "dart:io";

import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:gap/gap.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:share_plus/share_plus.dart";

import "../../main.dart";
import "../../provider/auth.dart";
import "../../provider/download_manager.dart";
import "../../provider/l18n.dart";
import "../../provider/player_events.dart";
import "../../provider/preferences.dart";
import "../../provider/user.dart";
import "../../services/cache_manager.dart";
import "../../services/logger.dart";
import "../../utils.dart";
import "../../widgets/audio_player.dart";
import "../../widgets/dialogs.dart";
import "../../widgets/fallback_user_avatar.dart";
import "../../widgets/page_route_builders.dart";
import "../../widgets/tip_widget.dart";
import "../login.dart";
import "profile/categories/about.dart";
import "profile/categories/debug.dart";
import "profile/categories/experimental.dart";
import "profile/categories/music_player.dart";
import "profile/categories/visual.dart";

/// Вызывает окно, дающее пользователю возможность поделиться файлом логов приложения ([logFilePath]), либо же открывающее проводник (`explorer.exe`) с файлом логов (на OS Windows).
void shareLogs() async {
  final File path = await logFilePath();

  // Если пользователь на OS Windows, то просто открываем папку с файлом.
  if (Platform.isWindows) {
    await Process.run(
      "explorer.exe",
      ["/select,", path.path],
    );

    return;
  }

  // В ином случае делимся файлом.
  await Share.shareXFiles([XFile(path.path)]);
}

/// Виджет, отображающий [ListView] с кнопкой внутри (при Desktop Layout) с текущим значением этой настройки, а так же отображающий диалог при нажатии.
class SettingWithDialog extends StatelessWidget {
  /// Иконка настройки.
  final IconData icon;

  /// Название настройки.
  final String title;

  /// Описание настройки.
  final String? subtitle;

  /// [Widget], отображаемый как диалог, который будет открыт при нажатии на эту настройку.
  final Widget dialog;

  /// Указывает, можно ли изменить значение данной настройки.
  final bool enabled;

  /// Текст у кнопки у этой настройки. Текст должен быть равен текущему текстовому описанию настройки.
  final String settingText;

  const SettingWithDialog({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.dialog,
    this.enabled = true,
    required this.settingText,
  });

  @override
  Widget build(BuildContext context) {
    final bool mobileLayout = isMobileLayout(context);

    void onTap() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return dialog;
        },
      );
    }

    return ListTile(
      leading: Icon(
        icon,
      ),
      title: Text(
        title,
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
            )
          : null,
      enabled: enabled,
      onTap: onTap,
      trailing: !mobileLayout
          ? FilledButton.icon(
              icon: const Icon(
                Icons.open_in_new,
              ),
              label: Text(
                settingText,
                overflow: TextOverflow.ellipsis,
              ),
              onPressed: enabled ? onTap : null,
            )
          : null,
    );
  }
}

/// Диалог, подтверждающий у пользователя действие для выхода из аккаунта на экране [HomeProfilePage].
///
/// Пример использования:
/// ```dart
/// showDialog(
/// 	context: context,
/// 	builder: (context) => const ProfileLogoutExitDialog()
/// );
/// ```
class ProfileLogoutExitDialog extends ConsumerWidget {
  const ProfileLogoutExitDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void onLogoutPressed() =>
        ref.read(currentAuthStateProvider.notifier).logout();

    final user = ref.watch(userProvider);
    final l18n = ref.watch(l18nProvider);

    return MaterialDialog(
      icon: Icons.logout_outlined,
      title: l18n.home_profilePageLogoutTitle,
      text: l18n.home_profilePageLogoutDescription(
        user.fullName,
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: Text(
            l18n.general_no,
          ),
        ),
        FilledButton(
          onPressed: onLogoutPressed,
          child: Text(
            l18n.general_yes,
          ),
        ),
      ],
    );
  }
}

/// Диалог, подтверждающий у пользователя действие подключения рекомендаций ВКонтакте на экране [HomeMusicPage].
///
/// Пример использования:
/// ```dart
/// showDialog(
/// 	context: context,
/// 	builder: (context) => const ConnectRecommendationsDialog()
/// );
/// ```
class ConnectRecommendationsDialog extends ConsumerWidget {
  const ConnectRecommendationsDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);

    return MaterialDialog(
      icon: Icons.auto_fix_high,
      title: l18n.music_connectRecommendationsTitle,
      text: l18n.music_connectRecommendationsDescription,
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: Text(
            l18n.general_no,
          ),
        ),
        FilledButton(
          onPressed: () {
            context.pop();

            Navigator.push(
              context,
              Material3PageRoute(
                builder: (context) => const LoginRoute(
                  useAlternateAuth: true,
                ),
              ),
            );
          },
          child: Text(
            l18n.music_connectRecommendationsConnect,
          ),
        ),
      ],
    );
  }
}

/// Виджет для [HomeProfilePage], отображающий аватар пользователя, а так же кнопку для выхода из аккаунта.
class ProfileAvatar extends ConsumerWidget {
  const ProfileAvatar({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);
    final user = ref.watch(userProvider);

    final int cacheSize = 80 * MediaQuery.of(context).devicePixelRatio.toInt();

    void onLogoutPressed() => showDialog(
          context: context,
          builder: (context) => const ProfileLogoutExitDialog(),
        );

    return Column(
      children: [
        // Аватар пользователя, при наличии.
        if (user.photoMaxUrl != null)
          CachedNetworkImage(
            imageUrl: user.photoMaxUrl!,
            cacheKey: "${user.id}400",
            memCacheWidth: cacheSize,
            memCacheHeight: cacheSize,
            cacheManager: CachedNetworkImagesManager.instance,
            placeholder: (BuildContext context, String string) {
              return const UserAvatarPlaceholder();
            },
            imageBuilder: (_, imageProvider) {
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: imageProvider,
                    fit: BoxFit.scaleDown,
                  ),
                ),
              );
            },
          )
        else
          const UserAvatarPlaceholder(),
        const Gap(12),

        // Имя пользователя.
        Text(
          user.fullName,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),

        // @domain пользователя.
        if (user.domain != null) ...[
          SelectableText(
            "@${user.domain}",
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
            textAlign: TextAlign.center,
          ),
          const Gap(6),
        ],
        const Gap(6),

        // Выход из аккаунта.
        FilledButton.tonalIcon(
          onPressed: onLogoutPressed,
          icon: const Icon(
            Icons.logout,
          ),
          label: Text(
            l18n.home_profilePageLogout,
          ),
        ),
      ],
    );
  }
}

/// Route, отображающий информацию по профилю текущего пользователя, где пользователь может поменять настройки.
///
/// go_route: `/profile`.
class HomeProfilePage extends HookConsumerWidget {
  static final AppLogger logger = getLogger("HomeProfilePage");

  const HomeProfilePage({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);

    final downloadManager = ref.watch(downloadManagerProvider);
    ref.watch(playerLoadedStateProvider);

    final bool debugOptionsEnabled = ref.watch(
      preferencesProvider.select(
        (it) => it.debugOptionsEnabled,
      ),
    );
    final bool recommendationsConnected =
        ref.watch(secondaryTokenProvider) != null;

    final profileItems = useMemoized(
      () => [
        // Блок, предупреждающий пользователя о том, что рекомендации не подключены.
        if (!recommendationsConnected)
          TipWidget(
            icon: Icons.auto_fix_high,
            title: l18n.profile_recommendationsNotConnectedTitle,
            description: l18n.profile_recommendationsNotConnectedDescription,
            onTap: () => showDialog(
              context: context,
              builder: (context) {
                return const ConnectRecommendationsDialog();
              },
            ),
          ),

        // Визуал.
        const ProfileVisualSettingsCategory(),

        // Музыкальный плеер.
        const ProfileMusicPlayerSettingsCategory(),

        // Экспериментальные функции.
        const ProfileExperimentalSettingsCategory(),

        // О Flutter VK.
        const ProfileAboutSettingsCategory(),

        // Debug-опции.
        if (kDebugMode || debugOptionsEnabled)
          const ProfileDebugSettingsCategory(),
      ],
      [recommendationsConnected, debugOptionsEnabled],
    );

    final bool mobileLayout = isMobileLayout(context);

    final profileItemsCount = profileItems.length;
    final showGapOnBottom = player.loaded && mobileLayout;

    return Scaffold(
      appBar: mobileLayout
          ? AppBar(
              title: StreamBuilder<bool>(
                stream: connectivityManager.connectionChange,
                builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                  final bool isConnected = connectivityManager.hasConnection;

                  return Text(
                    isConnected
                        ? l18n.home_profilePageLabel
                        : l18n.home_profilePageLabelOffline,
                  );
                },
              ),
              actions: [
                // Кнопка для менеджера загрузок.
                if (downloadManager.downloadStarted)
                  IconButton(
                    onPressed: () => context.go("/profile/download_manager"),
                    icon: const Icon(
                      Icons.download,
                    ),
                  ),
                const Gap(16),
              ],
              centerTitle: true,
            )
          : null,
      body: ListView.separated(
        padding: getPadding(
          context,
          useLeft: mobileLayout,
          useRight: mobileLayout,
          useTop: !mobileLayout,
          useBottom: !mobileLayout,
          custom: EdgeInsets.symmetric(
            horizontal: mobileLayout ? 4 : 12,
          ),
        ).add(
          const EdgeInsets.all(12),
        ),
        itemCount: profileItemsCount + 1 + (showGapOnBottom ? 1 : 0),
        separatorBuilder: (BuildContext context, int index) {
          return const Gap(16);
        },
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return const ProfileAvatar();
          }

          if (showGapOnBottom && index == profileItemsCount + 1) {
            // Данный Gap нужен, что бы плеер снизу при Mobile Layout'е не закрывал ничего важного.
            return const Gap(MusicPlayerWidget.mobileHeight - 16);
          }

          return profileItems[index - 1];
        },
      ),
    );
  }
}
