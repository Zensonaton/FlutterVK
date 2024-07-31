// ignore_for_file: non_constant_identifier_names

import "../../main.dart";
import "shared.dart";

/// Возвращает информацию по последним Github Release'ам указанного репозитория.
Future<List<Release>> get_releases(
  String owner,
  String repository,
) async {
  var response = await dio.get(
    "https://api.github.com/repos/$owner/$repository/releases",
  );

  return (response.data as List<dynamic>)
      .map((item) => Release.fromJson(item))
      .toList();
}
