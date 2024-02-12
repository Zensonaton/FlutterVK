import "../../utils.dart";
import "api.dart";
import "executeScripts/mass_audio_get.dart" as api_scripts_mass_audio;
import "executeScripts/mass_audio_albums.dart" as api_scripts_mass_audio_albums;
import "executeScripts/mass_audio_albums.dart";
import "executeScripts/mass_audio_get.dart";

/// Класс с API ВКонтакте, связанный с API `execute`.
class VKExecuteAPI {
  /// Выполняет произвольный VKScript-код.
  ///
  /// API: `execute`.
  static Future<dynamic> execute(
    String token,
    String code,
  ) async =>
      await vkAPIcall(
        "execute",
        token,
        {
          "code": minimizeJS(code),
        },
      );

  /// Массово извлекает список лайкнутых треков ВКонтакте. Максимум извлекает около 5000 треков.
  ///
  /// Для данного метода требуется токен от Kate Mobile.
  static Future<APIMassAudioGetResponse> massAudioGet(
    String token,
    int userID,
  ) async =>
      await api_scripts_mass_audio.scripts_massAudioGet(token, userID);

  /// Массово извлекает информацию по альбомам (и, соответственно, изображениям) треков.
  ///
  /// Для данного метода требуется токен от VK Admin.
  static Future<APIMassAudioAlbumsResponse> massAudioAlbums(
    String token,
    List<String> audioMediaIDs,
  ) async =>
      await api_scripts_mass_audio_albums.scripts_massAlbumsGet(
          token, audioMediaIDs);
}
