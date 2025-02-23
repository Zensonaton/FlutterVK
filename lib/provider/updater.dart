import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../services/updater.dart";

part "updater.g.dart";

/// [Provider] для получения объекта [Updater].
@riverpod
Updater updater(Ref ref) => Updater(ref: ref);
