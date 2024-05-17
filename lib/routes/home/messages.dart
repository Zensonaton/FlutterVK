import "package:flutter/material.dart";
import "package:responsive_builder/responsive_builder.dart";

import "../home.dart";

/// Виджет для поиска диалогов и/ли сообщения.
class MessagesSearchBar extends StatelessWidget {
  const MessagesSearchBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      child: SearchAnchor.bar(
        barHintText: "Поиск",
        barElevation: WidgetStateProperty.all(1),
        viewTrailing: const [],
        suggestionsBuilder:
            (BuildContext context, SearchController controller) {
          return List.generate(30, (int index) {
            return ListTile(
              leading: const Icon(
                Icons.flutter_dash,
              ),
              title: Text("Элемент с индексом #$index"),
            );
          });
        },
      ),
    );
  }
}

/// Мобильный дизайн.
class MobileLayout extends StatelessWidget {
  const MobileLayout({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        MessagesSearchBar(),
      ],
    );
  }
}

/// Компьютерный дизайн.
class DesktopLayout extends StatelessWidget {
  const DesktopLayout({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 270,
          child: ListView(
            children: const [
              MessagesSearchBar(),
            ],
          ),
        ),
        const VerticalDivider(
          width: 1,
        ),
        const Text(
          "Диалог с пользователем будет отображён здесь. Да, это placeholder :)",
        ),
      ],
    );
  }
}

/// Страница для [HomeRoute] для работы с сообщениями.
class HomeMessagesPage extends StatelessWidget {
  const HomeMessagesPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (getDeviceType(MediaQuery.of(context).size) == DeviceScreenType.mobile) {
      return const MobileLayout();
    }

    return const DesktopLayout();
  }
}
