// ignore_for_file: non_constant_identifier_names

import "dart:convert";

import "package:http/http.dart";

import "shared.dart";

/// Возвращает информацию по последним Github Release'ам указанного репозитория.
Future<List<Release>> get_releases(
  String owner,
  String repository,
) async {
  var response = await get(
    Uri.parse("https://api.github.com/repos/$owner/$repository/releases"),
  );

  return (jsonDecode(response.body) as List<dynamic>)
      .map(
        (item) => Release.fromJson(item),
      )
      .toList();
}
