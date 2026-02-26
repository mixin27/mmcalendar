// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:data/src/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());
            await verifier.migrateAndValidate(
              db,
              toVersion,
              options: const ValidationOptions(
                validateColumnConstraints: false,
              ),
            );
            await db.close();
          });
        }
      });
    }
  });

  test('migration from v1 to v2 preserves existing rows', () async {
    final schema = await verifier.schemaAt(1);

    final oldDb = v1.DatabaseAtV1(schema.newConnection());
    await oldDb.customStatement('INSERT INTO calendar_settings DEFAULT VALUES');
    final oldCount = await oldDb
        .customSelect('SELECT COUNT(*) AS c FROM calendar_settings')
        .map((row) => row.read<int>('c'))
        .getSingle();
    await oldDb.close();

    final migratedDb = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(
      migratedDb,
      2,
      options: const ValidationOptions(validateColumnConstraints: false),
    );

    final newCount = await migratedDb
        .customSelect('SELECT COUNT(*) AS c FROM calendar_settings')
        .map((row) => row.read<int>('c'))
        .getSingle();

    expect(newCount, oldCount);

    await migratedDb.close();
    schema.close();
  });
}
