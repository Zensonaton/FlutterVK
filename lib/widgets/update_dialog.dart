import "package:flutter/material.dart";
import "package:flutter_markdown/flutter_markdown.dart";
import "package:gap/gap.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:styled_text/styled_text.dart";
import "package:url_launcher/url_launcher.dart";

import "../api/github/shared.dart";
import "../main.dart";
import "../provider/l18n.dart";
import "../provider/updater.dart";
import "../services/logger.dart";
import "../utils.dart";
import "dialogs.dart";

/// Диалог, появляющийся снизу экрана, показывающий информацию о том, что доступно новое обновление.
///
/// Пример использования:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   builder: (BuildContext context) => const UpdateAvailableDialog(...),
/// ),
/// ```
class UpdateAvailableDialog extends ConsumerWidget {
  static final AppLogger logger = getLogger("UpdateAvailableDialog");

  /// Github Release с новым обновлением.
  final Release release;

  const UpdateAvailableDialog({
    super.key,
    required this.release,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);

    final scheme = Theme.of(context).colorScheme;

    void onMorePressed() {
      launchUrl(
        Uri.parse(release.htmlUrl),
      );
    }

    void onInstallPressed(BuildContext parentContext) async {
      final messenger = ScaffoldMessenger.of(context);

      Navigator.of(context).pop();

      messenger.showSnackBar(
        SnackBar(
          duration: const Duration(
            seconds: 10,
          ),
          content: Text(
            l18n.update_pending,
          ),
          action: SnackBarAction(
            label: l18n.general_show,
            onPressed: () =>
                navigatorKey.currentContext?.go("/profile/download_manager"),
          ),
        ),
      );

      try {
        await ref.read(updaterProvider).downloadAndgeneral_install(release);
      } catch (error, stackTrace) {
        showLogErrorDialog(
          "Update download/installation error:",
          error,
          stackTrace,
          logger,
          // ignore: use_build_context_synchronously
          context,
          title: l18n.update_install_error,
        );
      } finally {
        messenger.hideCurrentSnackBar();
      }
    }

    return DraggableScrollableSheet(
      expand: false,
      builder: (BuildContext context, ScrollController controller) {
        return SafeArea(
          child: Container(
            width: 500,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 18,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Внутреннее содержимое.
                Expanded(
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      scrollbars: false,
                    ),
                    child: ListView(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      children: [
                        // Иконка обновления.
                        Icon(
                          Icons.update,
                          size: 28,
                          color: scheme.primary,
                        ),
                        const Gap(2),

                        // Текст "Доступно обновление Flutter VK".
                        Text(
                          l18n.update_available,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: scheme.primary,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Gap(2),

                        // Информация о старой и новой версии.
                        StyledText(
                          text: l18n.update_available_desc(
                            oldVersion: appVersion,
                            newVersion: release.tagName,
                            date: release.createdAt!.toLocal(),
                            time: release.createdAt!.toLocal(),
                            badges: release.prerelease
                                ? "(${l18n.update_prerelease_type})"
                                : "",
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: scheme.onSurface.withValues(alpha: 0.75),
                          ),
                          tags: {
                            "arrow": StyledTextIconTag(
                              Icons.arrow_right,
                              color: scheme.onSurface.withValues(alpha: 0.75),
                              size: 18,
                            ),
                            "debug": StyledTextIconTag(
                              Icons.bug_report,
                              color: scheme.onSurface.withValues(alpha: 0.75),
                              size: 18,
                            ),
                          },
                        ),
                        const Gap(6),

                        const Divider(),
                        const Gap(6),

                        // Описание обновления.
                        MarkdownBody(
                          data: release.body,
                          shrinkWrap: false,
                        ),
                        const Gap(4),
                      ],
                    ),
                  ),
                ),
                const Divider(),
                const Gap(6),

                // Кнопки "Подробнее" и "Установить".
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  child: Wrap(
                    spacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      // Подробности.
                      FilledButton.tonalIcon(
                        icon: const Icon(
                          Icons.library_books,
                        ),
                        label: Text(
                          l18n.general_details,
                        ),
                        onPressed: onMorePressed,
                      ),

                      // Установить.
                      FilledButton.icon(
                        icon: Icon(
                          isMobile
                              ? Icons.install_mobile
                              : Icons.install_desktop,
                        ),
                        label: Text(
                          l18n.general_install,
                        ),
                        onPressed: () => onInstallPressed(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Диалог, появляющийся снизу экрана, показывающий список изменений текущей версии приложения.
///
/// Пример использования:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   builder: (BuildContext context) => const ChangelogDialog(...),
/// ),
/// ```
class ChangelogDialog extends ConsumerWidget {
  static final AppLogger logger = getLogger("ChangelogDialog");

  /// Github Release с новым обновлением.
  final Release release;

  const ChangelogDialog({
    super.key,
    required this.release,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);

    final scheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      expand: false,
      builder: (BuildContext context, ScrollController controller) {
        return Container(
          width: 500,
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Внутреннее содержимое.
              Expanded(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    scrollbars: false,
                  ),
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    children: [
                      // Иконка обновления.
                      Icon(
                        Icons.article,
                        size: 28,
                        color: scheme.primary,
                      ),
                      const Gap(2),

                      // Текст "Список изменений в этой версии".
                      Text(
                        l18n.changelog_dialog(
                          version: "v${release.tagName}",
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: scheme.primary,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Gap(2),

                      const Divider(),
                      const Gap(6),

                      // Описание обновления.
                      MarkdownBody(
                        data: release.body,
                        shrinkWrap: false,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Диалог, отображающий информацию о том, что пользователь впервые установил бета-версию приложения.
///
/// Пример использования:
/// ```dart
/// showDialog(
/// 	context: context,
/// 	builder: (context) => const PreReleaseInstalledDialog()
/// );
/// ```
class PreReleaseInstalledDialog extends ConsumerWidget {
  const PreReleaseInstalledDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);

    return MaterialDialog(
      icon: Icons.bug_report,
      title: l18n.prerelease_app_version_warning,
      text: l18n.prerelease_app_version_warning_desc,
    );
  }
}
