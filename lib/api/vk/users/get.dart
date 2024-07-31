// ignore_for_file: non_constant_identifier_names

import "package:json_annotation/json_annotation.dart";

import "../api.dart";
import "../consts.dart";
import "../shared.dart";

part "get.g.dart";

/// Ответ для метода [VKUsersAPI.get].
@JsonSerializable()
class APIUsersGetResponse {
  /// Массив с пользователями.
  final List<APIUser>? response;

  /// Объект ошибки.
  final APIError? error;

  APIUsersGetResponse({
    this.response,
    this.error,
  });

  factory APIUsersGetResponse.fromJson(Map<String, dynamic> json) =>
      _$APIUsersGetResponseFromJson(json);
  Map<String, dynamic> toJson() => _$APIUsersGetResponseToJson(this);
}

/// {@template VKAPI.users.get}
/// Получает публичную информацию о пользователях с передаваемым ID, либо же о владельце текущей страницы, если ID не передаётся.
/// {@endtemplate}
///
/// API: `users.get`.
Future<APIUsersGetResponse> users_get(
  String token, {
  List<int>? ids,
  String? fields = vkAPIallUserFields,
}) async {
  var response = await callVkAPI(
    "users.get",
    token,
    {
      "user_ids": ids?.toString(),
      "fields": fields,
    },
  );

  return APIUsersGetResponse.fromJson(response.data);
}
