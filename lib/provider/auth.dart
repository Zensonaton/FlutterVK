import "dart:io";

import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../api/vk/shared.dart";
import "../services/cache_manager.dart";
import "../services/player/server.dart";
import "../utils.dart";
import "db.dart";
import "player.dart";
import "playlists.dart";
import "shared_prefs.dart";

part "auth.g.dart";

/// [Provider] для хранения состояния авторизации пользователя. Позволяет авторизовывать и деавторизовывать пользователя.
///
/// Для получения доступа к этому [Provider] используйте [currentAuthStateProvider]:
/// ```dart
/// final AuthState authState = ref.read(currentAuthStateProvider);
/// ```
@riverpod
class CurrentAuthState extends _$CurrentAuthState {
  @override
  AuthState build() {
    final SharedPreferences prefs = ref.watch(sharedPrefsProvider);
    final bool isAuthorized = prefs.getBool("IsAuthorized") ?? false;

    return isAuthorized ? AuthState.authenticated : AuthState.unauthenticated;
  }

  /// Сохраняет основной токен (Kate Mobile) ВКонтакте в [SharedPreferences] ([sharedPrefsProvider]), а так же обновляет состояние этого Provider.
  ///
  /// Для выхода из аккаунта используйте метод [logout].
  Future<void> login(String token, APIUser info, {bool isDemo = false}) async {
    final SharedPreferences prefs = ref.read(sharedPrefsProvider);

    // Сохраняем токен.
    prefs.setString("Token", token);
    prefs.setBool("IsAuthorized", true);
    prefs.setInt("ID", info.id);
    prefs.setString("FirstName", info.firstName);
    prefs.setString("LastName", info.lastName);
    if (info.domain != null) prefs.setString("Domain", info.domain!);
    if (info.photo50 != null) prefs.setString("Photo50", info.photo50!);
    if (info.photoMax != null) prefs.setString("PhotoMax", info.photoMax!);
    if (isDemo) {
      prefs.setBool("IsDemoMode", true);
      prefs.setString("RecommendationsToken", token);
    }

    // Обновляем состояние авторизации.
    ref.invalidateSelf();
    ref.invalidate(tokenProvider);
  }

  /// Деавторизует пользователя, удаляя токен из [SharedPreferences] ([sharedPrefsProvider]), а так же обновляет состояние этого Provider.
  void logout() async {
    final prefs = ref.read(sharedPrefsProvider);
    final appStorage = ref.read(appStorageProvider);
    final player = ref.read(playerProvider);

    await player.stop();
    prefs.clear();
    CachedNetworkImagesManager.instance.emptyCache();
    CachedAlbumImagesManager.instance.emptyCache();

    if (!isWeb) {
      await appStorage.resetDB();
      final Directory tracksDirectory = Directory(
        await PlayerLocalServer.getTrackStorageDirectory(),
      );
      if (tracksDirectory.existsSync()) {
        tracksDirectory.deleteSync(recursive: true);
      }
    }
    ref
      ..invalidate(dbPlaylistsProvider)
      ..invalidate(playlistsProvider)
      ..invalidate(tokenProvider)
      ..invalidate(secondaryTokenProvider)
      ..invalidate(isDemoProvider)
      ..invalidateSelf();
  }
}

/// Enum, перечисляющий состояния авторизации пользователя, а так же route, которые доступны пользователю.
enum AuthState {
  /// [AuthState], отображающий неизвестное состояние авторизации пользователя.
  ///
  /// Чаще всего существует лишь некоторое время, пока не будет получено состояние авторизации пользователя, после чего оно сменяется на [unauthenticated] или [authenticated].
  unknown(
    redirectPath: "/welcome",
    allowedPaths: [
      "/welcome",
    ],
  ),

  /// [AuthState], отображающий состояние авторизации пользователя, когда он не авторизован.
  unauthenticated(
    redirectPath: "/welcome",
    allowedPaths: [
      "/welcome",
      "/login",
    ],
  ),

  /// [AuthState], отображающий состояние авторизации пользователя, когда он авторизован.
  authenticated(
    redirectPath: "/music",
    allowedPaths: [
      "/music",
      "/library",
      "/profile",
      "/playlist",
    ],
  );

  /// Путь к route, который будет использован для редиректа, в случае, если пользователь окажется в том route, которого нет в [allowedPaths].
  final String redirectPath;

  /// Список из разрешённых путей, в которые пользователь может попасть. Если пользователь окажется в пути, которого нет в данном списке, то его перенаправит на [redirectPath].
  final List<String> allowedPaths;

  const AuthState({
    required this.redirectPath,
    required this.allowedPaths,
  });
}

/// Возвращает основной токен (Kate Mobile) для ВКонтакте.
@riverpod
String? token(Ref ref) {
  final SharedPreferences prefs = ref.read(sharedPrefsProvider);

  return prefs.getString("Token");
}

/// Возвращает вторичный токен (VK Admin) для ВКонтакте.
@riverpod
String? secondaryToken(Ref ref) {
  final SharedPreferences prefs = ref.read(sharedPrefsProvider);

  return prefs.getString("RecommendationsToken");
}

/// Возвращает true, если включён демо-режим.
@riverpod
bool isDemo(Ref ref) {
  final SharedPreferences prefs = ref.read(sharedPrefsProvider);

  return prefs.getBool("IsDemoMode") ?? false;
}
