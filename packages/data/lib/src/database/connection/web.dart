import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_web.dart';
import 'package:flutter/foundation.dart';
import 'package:sqlite3/wasm.dart';

import 'package:drift_flutter/drift_flutter.dart';

Future<void> validateDatabaseSchema(GeneratedDatabase database) async {
  if (kDebugMode) {
    // We use a relative path here which works when the wasm file is in the web/ folder
    final sqlite = await WasmSqlite3.loadFromUrl(Uri.parse('sqlite3.wasm'));
    sqlite.registerVirtualFileSystem(InMemoryFileSystem(), makeDefault: true);

    await VerifySelf(database).validateDatabaseSchema(sqlite3: sqlite);
  }
}

Future<void> resetDatabase(String name) async {
  // Clear persistent storage for this database if possible.
  // Drift handles some of this internally if name remains same.
}

QueryExecutor openConnectionForTesting(String name) {
  return driftDatabase(
    name: name,
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}
