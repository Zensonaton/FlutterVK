<!-- markdownlint-disable-file MD029 MD033 MD041 -->

<img align="left" src="assets/icon.png" width="64" height="64" alt="Flutter VK logo"></img>

<h1 align="left">Flutter VK</h1>

Экспериментальный музыкальный клиент ВКонтакте для Windows и Android, построенный на [фреймворке Flutter](https://flutter.dev), не требующий подписки VK BOOM.

[Демо веб-версия](https://Zensonaton.github.io/FlutterVK) • [Скачать](https://github.com/Zensonaton/FlutterVK/releases) • [CI билды](https://t.me/fluttervkci).

![Главный экран на ПК](assets/readme/Desktop%20home.png)

## Демонстрация

![Видео с полноэкранным плеером на ПК](https://github.com/user-attachments/assets/7c063f00-18e6-4827-82df-54d24bf588fe)

<table>
  <tr>
    <td>
      <img src="assets/readme/Mobile%20home.png" alt="Главный экран на мобильных устройствах">
    </td>
    <td>
      <img src="assets/readme/Mobile%20home%20light.png" alt="Главный экран на мобильных устройствах (светлая тема)">
    </td>
    <td>
      <img src="assets/readme/Mobile%20favorites.png" alt="Экран 'любимая музыка'">
    </td>
    <td>
      <img src="assets/readme/Mobile%20favorites%20light.png" alt="Экран 'любимая музыка' (светлая тема)">
    </td>
  </tr>
</table>

> [!NOTE]
> Приложение часто меняет свой облик, поэтому изображения могут не соответствовать текущему дизайну приложения.

## Основной функционал

- Прослушивание музыки из ВКонтакте без рекламы и требования подписки VK BOOM.
- Полноэкранный плеер, отображающий тексты песен с очередью из воспроизведения.
- Огромное количество настроек.
- Тёмная и светлая тема.
- Цвета приложения полностью зависят от воспроизводимого трека.
- Расширенный функционал для обложек: поддержка анимированных обложек с Apple Music, загрузка недостающих обложек с Deezer, возможность локальной замены обложек.
- Получение недостающих текстов песен с LRCLib.
- Оффлайн режим: плейлисты можно скачивать (кэшировать) для прослушивания без интернета.
- Интеграция с Discord Rich Presence для отображения текущей песни в профиле Discord.
- Система обновлений.
- Синхронизация настроек, а так же недоступных (но кэшированных) треков между устройствами.
- Фоновое воспроизведение.
- Поддержка SMTC (System Media Transport Controls) для управления воспроизведением с клавиатуры или гарнитуры на Windows, а так же через Taskbar.
- Поддержка VK Mix, а так же других рекомендаций ВКонтакте.

## В чём смысл?

Несмотря на бесчисленное количество клиентов ВКонтакте, у каждого из них есть свои недостатки. К примеру, у одного из клиентов для музыки, возможность получения текстов песен с LRCLib доступна лишь после приобретения платной подписки. Точно так же, меня не устраивало то, что никакой из известных мне клиентов не пытался решить проблему того, что во ВКонтакте огромная часть треков не имеет обложек (альбомов), пока как дизайн Flutter VK сильно зависит от обложек.

Желая создать что-то лучшее, появился Flutter VK, где я пытаюсь решить эти проблемы, и не успокаиваюсь до тех пор, пока всё не будет блистать. Ну, не без косяков, конечно же. 😄

## Платформы

> [!TIP]
> Flutter VK, что, очевидно, написан на [фреймворке Flutter](https://flutter.dev). Благодаря этому, Flutter VK может запускаться на множестве платформ одновременно.

Поддерживаемые платформы:

- Android: [скачать](https://github.com/Zensonaton/FlutterVK/releases).
- Windows: [скачать](https://github.com/Zensonaton/FlutterVK/releases).
- Демо веб-версия: [открыть](https://Zensonaton.github.io/FlutterVK).

Планируется поддержка:

- Linux.
- MacOS (требуется тестировщик с Macbook'ом).
- Aurora OS (см. [#4](https://github.com/Zensonaton/FlutterVK/issues/4)).
