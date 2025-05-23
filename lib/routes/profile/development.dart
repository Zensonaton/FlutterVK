import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:gap/gap.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../../provider/auth.dart";
import "../../provider/download_manager.dart";
import "../../provider/l18n.dart";
import "../../provider/player.dart";
import "../../provider/preferences.dart";
import "../../provider/updater.dart";
import "../../provider/user.dart";
import "../../provider/vk_api.dart";
import "../../services/download_manager.dart";
import "../../services/logger.dart";
import "../../utils.dart";
import "../../widgets/audio_player.dart";
import "../../widgets/dialogs.dart";
import "../profile.dart";

/// Route, отображающий опции и инструменты, предназначенные только для режима отладки приложения.
/// Пользователь может попасть в этот раздел через [ProfileRoute], нажав на "Development options".
///
/// go_route: `/profile/settings/development`
class SettingsDevelopmentRoute extends ConsumerWidget {
  static final AppLogger logger = getLogger("SettingsDevelopmentRoute");

  const SettingsDevelopmentRoute({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);
    final player = ref.read(playerProvider);
    ref.watch(playerIsLoadedProvider);

    final mobileLayout = isMobileLayout(context);

    final prefsNotifier = ref.read(preferencesProvider.notifier);
    final preferences = ref.watch(preferencesProvider);

    final recommendationsConnected = ref.watch(secondaryTokenProvider) != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l18n.development_options,
        ),
      ),
      body: ListView(
        children: [
          // Информация о том, что данный раздел показан поскольку включен режим отладки.
          Padding(
            padding: const EdgeInsets.all(
              24,
            ),
            child: Text(
              kDebugMode
                  ? "Those options are shown because the app is running in debug mode."
                  : "This section is shown because \"force-show debug\" is enabled in settings.\nNormally, this section is hidden in non-debug modes.",
              style: TextStyle(
                color: ColorScheme.of(context).primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Кнопка для копирования ID пользователя.
          ListTile(
            leading: const Icon(
              Icons.person,
            ),
            title: const Text(
              "Copy user ID",
            ),
            onTap: () {
              Clipboard.setData(
                ClipboardData(
                  text: ref.read(userProvider).id.toString(),
                ),
              );
            },
          ),

          // Кнопка для копирования Kate Mobile токена.
          ListTile(
            leading: const Icon(
              Icons.key,
            ),
            title: const Text(
              "Copy main token",
            ),
            onTap: () {
              Clipboard.setData(
                ClipboardData(
                  text: ref.read(tokenProvider)!,
                ),
              );
            },
          ),

          // Кнопка для копирования рекомендационного токена (VK Admin).
          ListTile(
            leading: const Icon(
              Icons.key,
            ),
            title: const Text(
              "Copy secondary token",
            ),
            enabled: recommendationsConnected,
            onTap: () {
              Clipboard.setData(
                ClipboardData(
                  text: ref.read(secondaryTokenProvider)!,
                ),
              );
            },
          ),

          // Debug-меню для тестирования ColorScheme.
          ListTile(
            leading: const Icon(
              Icons.palette,
            ),
            title: const Text(
              "ColorScheme test menu",
            ),
            onTap: () => context.push("/profile/color_scheme_debug"),
          ),

          // Debug-меню для отображения всех плейлистов.
          ListTile(
            leading: const Icon(
              Icons.art_track_outlined,
            ),
            title: const Text(
              "Playlists viewer",
            ),
            onTap: () => context.push("/profile/playlists_viewer_debug"),
          ),

          // Debug-меню для отображения Markdown-разметки.
          ListTile(
            leading: const Icon(
              Icons.article,
            ),
            title: const Text(
              "Markdown viewer",
            ),
            onTap: () => context.push("/profile/markdown_viewer_debug"),
          ),

          // Debug-меню для отображения информации о плееру.
          ListTile(
            leading: const Icon(
              Icons.music_note,
            ),
            title: const Text(
              "Player debug menu",
            ),
            onTap: () => context.push("/profile/player_debug"),
          ),

          // Кнопка для запуска фейковой загрузки.
          ListTile(
            leading: const Icon(
              Icons.download,
            ),
            title: const Text(
              "Fake download task",
            ),
            onTap: () {
              final downloadManagerNotifier =
                  ref.read(downloadManagerProvider.notifier);

              downloadManagerNotifier.newTask(
                DownloadTask(
                  id: "debug",
                  smallTitle: "Debug",
                  longTitle: "Fake debug download task",
                  tasks: [
                    FakeDownloadItem(
                      ref: downloadManagerNotifier.ref,
                    ),
                  ],
                ),
              );
            },
          ),

          // Кнопка для force-запуска обновления.
          ListTile(
            leading: const Icon(
              Icons.update,
            ),
            title: const Text(
              "Force-trigger update dialog",
            ),
            onTap: () => ref.read(updaterProvider).checkForUpdates(
                  context,
                  allowPre: true,
                  showMessageOnNoUpdates: true,
                  disableCurrentVersionCheck: true,
                ),
          ),

          // Кнопка для открытия экрана загрузок.
          ListTile(
            leading: const Icon(
              Icons.download,
            ),
            title: const Text(
              "Open download manager",
            ),
            onTap: () => context.go("/profile/download_manager"),
          ),

          // Кнопка для создания тестового API-запроса.
          ListTile(
            leading: const Icon(
              Icons.speed,
            ),
            title: const Text(
              "API call test",
            ),
            onTap: () async {
              if (!networkRequiredDialog(ref, context)) return;

              final totalStopwatch = Stopwatch()..start();

              final List<int> times = [];
              for (int i = 0; i < 10; i++) {
                final stopwatch = Stopwatch()..start();
                await ref.read(vkAPIProvider).execute.massGetAudio(
                      ref.read(userProvider).id,
                    );
                stopwatch.stop();

                times.add(stopwatch.elapsedMilliseconds);
              }

              totalStopwatch.stop();
              final String printString =
                  "Time took: ${totalStopwatch.elapsedMilliseconds}ms, avg: ${times.reduce((a, b) => a + b) ~/ times.length}ms, times: ${times.join(", ")}";
              logger.d(printString);

              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    printString,
                  ),
                ),
              );
            },
          ),

          // Включение отладочного режима.
          SwitchListTile(
            secondary: const Icon(
              Icons.developer_mode,
            ),
            title: const Text(
              "Force-show debug",
            ),
            subtitle: const Text(
              "Shows debugging options in profile even in non-debug modes",
            ),
            value: preferences.debugOptionsEnabled,
            onChanged: (bool? enabled) async {
              HapticFeedback.lightImpact();
              if (enabled == null) return;

              prefsNotifier.setDebugOptionsEnabled(enabled);
            },
          ),

          // Данный Gap нужен, что бы плеер снизу при Mobile Layout'е не закрывал ничего важного.
          if (player.isLoaded && mobileLayout)
            const Gap(MusicPlayerWidget.mobileHeightWithPadding),
        ],
      ),
    );
  }
}
