// ignore_for_file: non_constant_identifier_names

import "../../main.dart";
import "shared.dart";

/// Возвращает информацию по последнему Github Release заданного репозитория.
Future<Release> get_latest(
  String owner,
  String repository,
) async {
  var response = await dio.get(
    "https://api.github.com/repos/$owner/$repository/releases/latest",
  );

  return Release.fromJson(response.data);
}
