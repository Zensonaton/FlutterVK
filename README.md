<!-- markdownlint-disable-file MD029 MD033 MD041 -->

<div align="center">

<img width="300" src="assets/icon.png" alt="Лого Flutter VK">

# Flutter VK

Экспериментальный, неофициальный клиент ВКонтакте, с открытым исходным кодом, построенный при помощи фреймворка [Flutter](https://flutter.dev/), с поддержкой прослушивания музыки без необходимости приобретать подписку VK BOOM.

[![Windows & Android release](https://github.com/Zensonaton/FlutterVK/actions/workflows/build.yml/badge.svg)](https://github.com/Zensonaton/FlutterVK/actions/workflows/build.yml)

</div>

# Скриншоты

> [!TIP]
> Приложение часто меняет свой облик, поэтому учтите, что приложение может немного отличаться от того, что показано на скриншотах.

<div align="center">
  <i>Полноэкранный плеер:</i>

  <br>

  <img src="assets/screenshots/Windows Fullscreen Player.png" alt="Скриншот Windows, полноэкранный плеер" width=625>
</div>

<br>

<div align="center">
  <i>Главная страница:</i>

  <br>

  <img src="assets/screenshots/Windows Music Page.png" alt="Скриншот Windows, страница «Музыка» (светлая и тёмная)" width=625>
</div>

<br>

<div align="center">
  <i>Страница «Любимая музыка»</i>

  <br>

  <img src="assets/screenshots/Windows Favorite Music Page.png" alt="Скриншот Windows, страница «Любимая музыка» (светлая и тёмная)" width=625>
</div>

<br>

<div align="center">
  <i>Цветовая схема приложения может меняться в зависимости от обложки текущего трека, если включена особая настройка:</i>

  <br>

  <img src="assets/screenshots/Android Colorful.png" alt="Скриншот Android, страница «Музыка» (тёмная, разные цвета)" width=310>
</div>

<br>

<div align="center">
  <i>Android, главный экран:</i>

  <br>

  <img src="assets/screenshots/Android Music Page Light.png" alt="Скриншот Android, страница «Музыка» (светлая)" width=310>
  <img src="assets/screenshots/Android Music Page Dark.png" alt="Скриншот Android, страница «Музыка» (тёмная)" width=310>
</div>

<br>

<div align="center">
  <i>Android, полноэкранный плеер:</i>

  <br>

  <img src="assets/screenshots/Android Fullscreen Player 1.png" alt="Скриншот Android, полноэкранный плеер" width=310>
  <img src="assets/screenshots/Android Fullscreen Player 2.png" alt="Скриншот Android, полноэкранный плеер (с тексом)" width=310>
</div>

# Установка

## Поддерживаемые платформы

Благодаря магии фреймворка [Flutter](https://flutter.dev/), приложение Flutter VK может запускаться сразу на множестве платформ. В данный момент, Flutter VK работает на этих платформах:

- Windows
- Android

В будущем планируется поддержка:

- Linux
- MacOS *(необходим тестировщик с Macbook'ом)*
- ~~iOS~~ Обычным пользователям без Dev-сертификатов будет трудным устанавливать приложение. Поскольку релиз приложения в App Store не считается приоритетной задачей, поддержка iOS не будет осуществлена
- ~~Web-версия приложения~~ Flutter поддерживает запуск приложения в Web, однако стабильность и плавность таких приложений оставляет желать лучшего, поэтому эта платформа не будет поддерживаться

## Загрузка и установка

> [!WARNING]
> Flutter VK всё ещё находится в состоянии разработки, поэтому Вы рано или поздно столкнётесь с ошибками, как большими, так и маленькими.
>
> Столкнувшись с ошибками, не забывайте их репортить в [Github Issues](https://github.com/Zensonaton/FlutterVK/issues).

В данный момент, Flutter VK можно загрузить для Windows или Android с [Github Release'ов](https://github.com/Zensonaton/FlutterVK/releases), либо с [Telegram-канала Flutter VK CI](https://t.me/fluttervkci).

> [!TIP]
> При загрузке с [Github Release'ов](https://github.com/Zensonaton/FlutterVK/releases) рекомендуется загружать именно Release-версии приложений, что обеспечит Вас более стабильным опытом использования приложения.

# Компиляция/запуск debug-приложения

Компиляция или запуск приложения состоит из нескольких шагов.

1. Установите фреймворк Flutter. Шаги для этого описаны [на официальном сайте Flutter](https://docs.flutter.dev/get-started/install).
2. Установите зависимости для приложения:

   ```bash
   flutter pub get
   ```

3. Запустите приложение. Если Вы пользуетесь VS Code, то нажмите F5, и через некоторое время приложение запустится в Debug-режиме. В ином случае, воспользуйтесь:

   ```bash
   flutter run
   ```

> [!NOTE]
> Debug-версии билдов имеют отвратительную производительность, а также имеют огромный размер `.exe`/`.apk`-файлов, и это нормально.

4. Завершив делать изменения, протестируйте приложение, запустив его в Release-режиме:

   ```bash
   flutter run --release
   ```
