import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../services/db.dart"
    if (dart.library.js_interop) "../services/db_stub.dart";

part "db.g.dart";

/// Возвращает объект [AppStorage], используемый как БД для приложения.
@Riverpod(keepAlive: true)
AppStorage appStorage(Ref ref) => AppStorage(ref: ref);
