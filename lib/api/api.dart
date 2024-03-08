import "dart:async";
import "dart:convert";
import "dart:io";

import "package:http/http.dart";
import "package:retry/retry.dart";

import "../services/logger.dart";
import "vk/consts.dart";

String stringifyCookies(Map<String, String> cookies) =>
    cookies.entries.map((e) => "${e.key}=${e.value}").join("; ");

/// Делает API-GET запрос. Если запрос не был отправлен по какой-то причине (скажем, пользователь с WiFi переключился на LTE и/ли наоборот), то запрос будет выслан несколько раз, перед тем как вызывать исключение.
Future<Response> apiGet(
  String url, {
  Map<String, String>? moreHeaders,
  List<int>? retryHttpCodes,
  Map<String, String> cookies = const {},
}) async {
  AppLogger logger = getLogger("API");

  final Map<String, String> headers = {
    "Content-Type": "application/x-www-form-urlencoded",
    "User-Agent": vkAPIKateMobileUA,
    "Cookie": stringifyCookies(cookies),
  };
  if (moreHeaders != null) headers.addAll(moreHeaders);

  final response = await retry(
    () async {
      logger.d(
        "Begin GET to $url",
      );

      var req = await get(
        Uri.parse(url),
        headers: headers,
      );
      if (retryHttpCodes != null && retryHttpCodes.contains(req.statusCode)) {
        throw SocketException("Bad HTTP code recieved: ${req.statusCode}");
      }

      return req;
    },
    retryIf: (e) => e is SocketException || e is TimeoutException,
    onRetry: (e) => logger.w(
      "Req error, retrying",
      error: e,
    ),
  );

  String bodyConcat = response.body.replaceAll("\n", "");
  if (bodyConcat.length > 500) {
    bodyConcat =
        "${bodyConcat.substring(0, 500)}... (${bodyConcat.length} chars)";
  }

  logger.d("Req status code: ${response.statusCode}, body: $bodyConcat");

  return response;
}

/// Делает API-POST запрос. Если запрос не был отправлен по какой-то причине (скажем, пользователь с WiFi переключился на LTE и/ли наоборот), то запрос будет выслан несколько раз, перед тем как вызывать исключение.
Future<Response> apiPost(
  String url,
  Map<String, dynamic> body, {
  Map<String, String>? moreHeaders,
  List<int>? retryHttpCodes,
}) async {
  AppLogger logger = getLogger("API");

  final Map<String, String> headers = {
    "Content-Type": "application/x-www-form-urlencoded",
    "User-Agent": vkAPIKateMobileUA,
  };
  if (moreHeaders != null) headers.addAll(moreHeaders);

  // Избавляемся от null-полей.
  body.removeWhere(
    (String key, dynamic value) => value == null,
  );

  final response = await retry(
    () async {
      String bodyConcat = jsonEncode(body).replaceAll("\n", "");
      if (bodyConcat.length > 500) {
        bodyConcat =
            "${bodyConcat.substring(0, 500)}... (${bodyConcat.length} chars)";
      }

      logger.d(
        "Begin POST to $url, body: $bodyConcat",
      );

      var req = await post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );
      if (retryHttpCodes != null && retryHttpCodes.contains(req.statusCode)) {
        throw SocketException("Bad HTTP code recieved: ${req.statusCode}");
      }

      return req;
    },
    retryIf: (e) => e is SocketException || e is TimeoutException,
    onRetry: (e) => logger.w(
      "Req error, retrying",
      error: e,
    ),
  );

  String bodyConcat = response.body.replaceAll("\n", "");
  if (bodyConcat.length > 500) {
    bodyConcat =
        "${bodyConcat.substring(0, 500)}... (${bodyConcat.length} chars)";
  }

  logger.d("Req status code: ${response.statusCode}, body: $bodyConcat");

  return response;
}
