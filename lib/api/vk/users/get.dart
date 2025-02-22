// ignore_for_file: non_constant_identifier_names

import "../../../main.dart";
import "../consts.dart";
import "../shared.dart";

/// Возвращает фейковые данные для этого метода.
List<Map<String, dynamic>> _getFakeData() {
  return [
    {
      "id": 1,
      "domain": "ivanov",
      "first_name": "Иван",
      "last_name": "Иванов",
    }
  ];
}

/// {@template VKAPI.users.get}
/// Получает публичную информацию о пользователях с передаваемым ID, либо же о владельце текущей страницы, если ID не передаётся.
/// {@endtemplate}
///
/// API: `users.get`.
Future<List<APIUser>> users_get({
  String? token,
  List<int>? ids,
  String? fields = vkAPIallUserFields,
}) async {
  var response = await vkDio.post(
    "users.get",
    data: {
      "user_ids": ids,
      "fields": fields,
      if (token != null) "access_token": token,

      // Demo response
      "_demo_": _getFakeData(),
    },
  );

  return response.data
      .map<APIUser>(
        (item) => APIUser.fromJson(item),
      )
      .toList();
}
