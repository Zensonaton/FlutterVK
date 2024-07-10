import "dart:io";

import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../api/vk/shared.dart";
import "../main.dart";
import "../services/audio_player.dart";
import "../services/cache_manager.dart";
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
  Future<void> login(String token, APIUser info) async {
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

    // Обновляем состояние авторизации.
    ref.invalidateSelf();
    ref.invalidate(tokenProvider);
  }

  /// Деавторизует пользователя, удаляя токен из [SharedPreferences] ([sharedPrefsProvider]), а так же обновляет состояние этого Provider.
  void logout() async {
    final SharedPreferences prefs = ref.read(sharedPrefsProvider);

    await player.stop();
    prefs.clear();

    // Очищаем кэш изображений.
    CachedNetworkImagesManager.instance.emptyCache();
    CachedAlbumImagesManager.instance.emptyCache();

    // Удаляем папку с кэшированными треками, если такие вообще есть.
    final Directory tracksDirectory = Directory(
      await CachedStreamedAudio.getTrackStorageDirectory(),
    );

    if (tracksDirectory.existsSync()) {
      tracksDirectory.deleteSync(recursive: true);
    }

    // Очищаем локальную базу данных.
    appStorage.resetDB();

    // Обновляем состояние авторизации, а так же Access-токен.
    ref.invalidateSelf();
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
      "/profile",
      "/fullscreenPlayer",
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
String? token(TokenRef ref) {
  final SharedPreferences prefs = ref.read(sharedPrefsProvider);

  return prefs.getString("Token");
}

/// Возвращает вторичный токен (VK Admin) для ВКонтакте.
@riverpod
String? secondaryToken(SecondaryTokenRef ref) {
  final SharedPreferences prefs = ref.read(sharedPrefsProvider);

  return prefs.getString("RecommendationsToken");
}
