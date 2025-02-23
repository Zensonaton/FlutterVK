import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:shared_preferences/shared_preferences.dart";

part "shared_prefs.g.dart";

/// [Provider] для [SharedPreferences], позволяющий получить доступ к хранилищу настроек.
@Riverpod(keepAlive: true)
SharedPreferences sharedPrefs(Ref ref) {
  // Данный Provider загружается внутри main-метода.

  throw UnimplementedError();
}
