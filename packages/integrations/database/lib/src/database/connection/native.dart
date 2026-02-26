import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:drift/native.dart';

Future<File> get databaseFile async {
  // We use `path_provider` to find a suitable path to store our data in.
  final dbFolder = await getApplicationDocumentsDirectory();
  final dbPath = p.join(dbFolder.path, 'myanmar_calendar.sqlite');
  return File(dbPath);
}

Future<void> validateDatabaseSchema(GeneratedDatabase _) async {}

Future<void> resetDatabase(String name) async {
  final dbFolder = await getApplicationDocumentsDirectory();
  final file = File(p.join(dbFolder.path, '$name.sqlite'));

  if (await file.exists()) {
    await file.delete();
  }
}

QueryExecutor openConnectionForTesting(String name) {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, '$name.db'));
    return NativeDatabase(file);
  });
}
