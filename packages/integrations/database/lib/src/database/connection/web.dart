import 'package:drift/drift.dart';

import 'package:drift_flutter/drift_flutter.dart';

Future<void> validateDatabaseSchema(GeneratedDatabase _) async {}

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
