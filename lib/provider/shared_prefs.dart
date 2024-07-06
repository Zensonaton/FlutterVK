import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:shared_preferences/shared_preferences.dart";

part "shared_prefs.g.dart";

/// [Provider] для [SharedPreferences], позволяющий получить доступ к хранилищу настроек.
@riverpod
Future<SharedPreferences> sharedPrefs(SharedPrefsRef ref) async =>
    await SharedPreferences.getInstance();
