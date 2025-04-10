import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:flutter_markdown/flutter_markdown.dart";
import "package:gap/gap.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../../../widgets/shortcuts_propagator.dart";

/// Route для Debug-меню отображающее текстовое поле для ввода Markdown-разметки, которое будет отображено в виде Markdown-виджета.
///
/// go_route: `/profile/markdown_viewer_debug`.
class MarkdownViewerDebugMenu extends HookConsumerWidget {
  const MarkdownViewerDebugMenu({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    useValueListenable(controller);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Markdown viewer",
        ),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Текстовое поле.
          Expanded(
            child: ShortcutsPropagator(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.multiline,
                maxLines: null,
              ),
            ),
          ),
          const Gap(20),

          // Разделитель.
          const Padding(
            padding: EdgeInsets.symmetric(
              vertical: 20,
            ),
            child: VerticalDivider(),
          ),
          const Gap(20),

          // Markdown-виджет.
          Expanded(
            child: MarkdownBody(
              data: controller.text,
            ),
          ),
        ],
      ),
    );
  }
}
