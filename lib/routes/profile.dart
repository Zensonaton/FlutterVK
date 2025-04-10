import "dart:io";

import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:gap/gap.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:share_plus/share_plus.dart";
import "package:url_launcher/url_launcher.dart";

import "../consts.dart";
import "../main.dart";
import "../provider/auth.dart";
import "../provider/download_manager.dart";
import "../provider/l18n.dart";
import "../provider/player.dart";
import "../provider/preferences.dart";
import "../provider/user.dart";
import "../services/cache_manager.dart";
import "../services/logger.dart";
import "../utils.dart";
import "../widgets/audio_player.dart";
import "../widgets/dialogs.dart";
import "../widgets/fallback_user_avatar.dart";
import "../widgets/page_route_builders.dart";
import "../widgets/tip_widget.dart";
import "login.dart";
import "profile/categories/about.dart";
import "profile/categories/app.dart";
import "profile/categories/debug.dart";
import "profile/categories/experimental.dart";
import "profile/categories/music_player.dart";
import "profile/categories/visual.dart";

/// Вызывает окно, дающее пользователю возможность поделиться файлом логов приложения ([logFilePath]), либо же открывающее проводник (`explorer.exe`) с файлом логов (на OS Windows).
void shareLogs() async {
  final File path = await logFilePath();

  // Если пользователь на OS Windows, то просто открываем папку с файлом.
  if (isWindows) {
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
  /// Иконка настройки, отображаемое внутри [ListTile] и диалога.
  final IconData icon;

  /// Название настройки, отображаемое внутри [ListTile] и диалога.
  final String title;

  /// Описание настройки, отображаемое внутри [ListTile].
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

/// Виджет для [ProfileRoute], отображающий аватар пользователя, а так же кнопку для выхода из аккаунта.
class ProfileAvatar extends ConsumerWidget {
  const ProfileAvatar({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);
    final user = ref.watch(userProvider);

    final int cacheSize = 80 * MediaQuery.of(context).devicePixelRatio.toInt();

    void onLogoutPressed() async {
      final result = await showYesNoDialog(
        context,
        icon: Icons.logout_outlined,
        title: l18n.general_logout,
        description: l18n.logout_desc(
          name: user.fullName,
        ),
      );
      if (result != true) return;

      ref.read(currentAuthStateProvider.notifier).logout();
    }

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
            l18n.general_logout,
          ),
        ),
      ],
    );
  }
}

/// Route, отображающий информацию по профилю текущего пользователя, где пользователь может поменять настройки.
///
/// go_route: `/profile`.
class ProfileRoute extends HookConsumerWidget {
  static final AppLogger logger = getLogger("HomeProfilePage");

  const ProfileRoute({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(playerProvider);
    final l18n = ref.watch(l18nProvider);

    final downloadManager = ref.watch(downloadManagerProvider);
    ref.watch(playerIsLoadedProvider);

    final bool debugOptionsEnabled = ref.watch(
      preferencesProvider.select(
        (it) => it.debugOptionsEnabled,
      ),
    );
    final bool recommendationsConnected =
        ref.watch(secondaryTokenProvider) != null;
    final bool isDemo = ref.watch(isDemoProvider);

    final bool mobileLayout = isMobileLayout(context);

    return Scaffold(
      appBar: mobileLayout
          ? AppBar(
              title: StreamBuilder<bool>(
                stream: connectivityManager.connectionChange,
                builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                  final bool isConnected = connectivityManager.hasConnection;

                  return Text(
                    isConnected
                        ? l18n.profile_label
                        : l18n.profile_labelOffline,
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
      body: ListView(
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
        children: [
          // Аватар.
          const ProfileAvatar(),
          const Gap(16),

          // Блок, предупреждающий пользователя о том, что рекомендации не подключены.
          if (!recommendationsConnected) ...[
            TipWidget(
              icon: Icons.auto_fix_high,
              title: l18n.no_recommendations_warning,
              description: l18n.no_recommendations_warning_desc,
              onTap: () async {
                final result = await showYesNoDialog(
                  context,
                  icon: Icons.auto_fix_high,
                  title: l18n.connect_recommendations_title,
                  description: l18n.connect_recommendations_desc,
                );
                if (result != true || !context.mounted) return;

                Navigator.push(
                  context,
                  Material3PageRoute(
                    builder: (context) => const LoginRoute(
                      useAlternateAuth: true,
                    ),
                  ),
                );
              },
            ),
            const Gap(16),
          ],

          // Блок, предупреждающий пользователя о том, что включена демо-версия.
          if (isDemo) ...[
            TipWidget(
              icon: Icons.warning,
              title: l18n.demo_mode_warning,
              description: l18n.demo_mode_warning_desc,
              onTap: () => launchUrl(
                Uri.parse(telegramURL),
              ),
            ),
            const Gap(16),
          ],

          // Визуал.
          const ProfileVisualSettingsCategory(),
          const Gap(16),

          // Музыкальный плеер.
          const ProfileMusicPlayerSettingsCategory(),
          const Gap(16),

          // Экспериментальные функции.
          const ProfileExperimentalSettingsCategory(),
          const Gap(16),

          // Настройки приложения.
          const ProfileAppSettingsCategory(),
          const Gap(16),

          // О Flutter VK.
          const ProfileAboutSettingsCategory(),

          // Debug-опции.
          if (kDebugMode || debugOptionsEnabled) ...[
            const Gap(16),
            const ProfileDebugSettingsCategory(),
          ],

          // Данный Gap нужен, что бы плеер снизу при Mobile Layout'е не закрывал ничего важного.
          if (player.isLoaded && mobileLayout)
            const Gap(MusicPlayerWidget.mobileHeight),
        ],
      ),
    );
  }
}
