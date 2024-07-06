import "dart:ui" as ui;

import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

/// [Provider] для локализации приложения, вызывающий события обновления когда изменяется язык системы.
final l18nProvider = Provider<AppLocalizations>((ref) {
  // ignore: deprecated_member_use
  ref.state = lookupAppLocalizations(ui.window.locale);

  final _LocaleObserver observer = _LocaleObserver((List<Locale>? locales) {
    // ignore: deprecated_member_use
    ref.state = lookupAppLocalizations(ui.window.locale);
  });

  final WidgetsBinding binding = WidgetsBinding.instance;
  binding.addObserver(observer);

  ref.onDispose(
    () => binding.removeObserver(observer),
  );

  return ref.state;
});

/// Возвращает [AppLocalizations] для переданной [Locale].
class _LocaleObserver extends WidgetsBindingObserver {
  final void Function(List<Locale>? locales) _didChangeLocales;

  _LocaleObserver(this._didChangeLocales);

  @override
  void didChangeLocales(List<Locale>? locales) => _didChangeLocales(locales);
}
