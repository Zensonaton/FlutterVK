import "package:riverpod_annotation/riverpod_annotation.dart";

import "../services/db.dart";

part "db_migrator.g.dart";

/// Возвращает экземпляр класса, производящего миграцию базы данных Isar.
@riverpod
IsarDBMigrator dbMigrator(DbMigratorRef ref) => IsarDBMigrator(ref: ref);
