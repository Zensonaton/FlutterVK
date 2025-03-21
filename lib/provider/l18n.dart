import "dart:ui" as ui;

import "package:flutter/material.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../l10n/app_localizations.dart";
import "../services/logger.dart";

final AppLogger _logger = getLogger("l18n");

/// Метод, ищущий [AppLocalizations] для переданной [Locale]. Если таковая не находится, то возвращает первую из списка поддерживаемых локалей.
Locale localeResolutionCallback(
  Locale? locale,
  Iterable<Locale> supportedLocales,
) {
  for (final supportedLocale in supportedLocales) {
    if (supportedLocale.languageCode == locale?.languageCode) {
      return supportedLocale;
    }
  }

  _logger.w(
    "(localeResolutionCallback) No supported locale found for $locale, falling back to ${supportedLocales.first}",
  );

  return supportedLocales.first;
}

/// Метод, ищущий [AppLocalizations] для переданной [Locale]. Если таковая не находится, то возвращает первую из списка поддерживаемых локалей.
AppLocalizations safeLookupAppLocalizations(Locale locale) {
  if (AppLocalizations.delegate.isSupported(locale)) {
    return lookupAppLocalizations(locale);
  }

  final fallbackLocale = AppLocalizations.supportedLocales.first;

  _logger.w(
    "(safeLookupAppLocalizations) No supported locale found for $locale, falling back to $fallbackLocale",
  );

  return lookupAppLocalizations(fallbackLocale);
}

/// [Provider] для локализации приложения, вызывающий события обновления когда изменяется язык системы.
final l18nProvider = Provider<AppLocalizations>((ref) {
  // ignore: deprecated_member_use
  ref.state = safeLookupAppLocalizations(ui.window.locale);

  final _LocaleObserver observer = _LocaleObserver((List<Locale>? locales) {
    // ignore: deprecated_member_use
    ref.state = safeLookupAppLocalizations(ui.window.locale);
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
