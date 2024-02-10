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

Благодаря магии фреймворка [Flutter](https://flutter.dev/), приложение Flutter VK может запускаться сразу на множестве платформ. В данный момент, Flutter VK можно запустить на следующих платформах:

- Windows
- Android

В будущем планируется поддержка:

- Linux
- MacOS *(необходим тестировщик с Macbook'ом)*
- ~~iOS~~ Обычным пользователям без Dev-сертификатов будет трудным устанавливать приложение. Поскольку релиз приложения в App Store не считается приоритетной задачей, поддержка iOS не будет осуществлена
- ~~Web-версия приложения~~ Flutter поддерживает запуск приложения в Web, однако стабильность и плавность таких приложений оставляет желать лучшего, поэтому эта платформа не будет поддерживаться

## Загрузка и установка

Данное приложение находится на ранней стадии разработки, поэтому релизы приложения не создаются на Github Releases. Несмотря на это, Вы можете загрузить CI-билды приложения в Telegram-канале.

> [!WARNING]
> CI-билды приложения **не могут быть стабильными**. CI-билды создаются при любом изменении исходного кода приложения, даже очень маленького.
>
> Если Вы хотите получить стабильный опыт пользования приложением, то воздержитесь от использования CI-билдов, вместо них дождитесь выхода Release-версии приложения.

CI-билды приложения можно загрузить со следующего Telegram-канала: [@FlutterVKCI](https://t.me/fluttervkci).

Я, как разработчик, не считаю нужным публиковать приложение в Google Play или App Store, однако это мнение может поменяться в будущем.

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
