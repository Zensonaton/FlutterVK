// ignore_for_file: non_constant_identifier_names

import "dart:convert";

import "package:http/http.dart";

import "shared.dart";

/// Возвращает информацию по последнему Github Release заданного репозитория.
Future<Release> get_latest(
  String owner,
  String repository,
) async {
  var response = await get(
    Uri.parse(
      "https://api.github.com/repos/$owner/$repository/releases/latest",
    ),
  );

  return Release.fromJson(jsonDecode(response.body));
}
