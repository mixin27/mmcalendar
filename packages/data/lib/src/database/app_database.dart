import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'connection/connection.dart' as impl;

import 'app_database.steps.dart';
import 'daos/events_dao.dart';
import 'daos/recurring_exceptions_dao.dart';
import 'tables/calendar_settings_table.dart';
import 'tables/app_settings_table.dart';
import 'tables/custom_holidays_table.dart';
import 'tables/user_events_table.dart';
import 'daos/calendar_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/holidays_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    CalendarSettings,
    AppSettings,
    CustomHolidays,
    UserEvents,
    EventCategories,
    RecurringEventExceptions,
  ],
  daos: [
    CalendarDao,
    SettingsDao,
    HolidaysDao,
    EventsDao,
    RecurringExceptionsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  // Singleton pattern
  static AppDatabase? _instance;

  AppDatabase._internal([QueryExecutor? e]) : super(e ?? _openConnection());

  factory AppDatabase([QueryExecutor? e]) {
    _instance ??= AppDatabase._internal(e);
    return _instance!;
  }

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();

        // Create default calendar settings
        await calendarDao.createDefaultSettings();
      },
      onUpgrade: stepByStep(
        from1To2: (m, schema) async {
          await m.create(recurringEventExceptions);
          await m.addColumn(userEvents, userEvents.isRecurringMaster);
        },
      ),
      beforeOpen: (details) async {
        // Enable foreign keys
        await customStatement('PRAGMA foreign_keys = ON');

        // Verify database
        if (details.wasCreated) {
          // Database was just created
          debugPrint('Database created successfully');
        }

        // This follows the recommendation to validate that the database schema
        // matches what drift expects (https://drift.simonbinder.eu/docs/advanced-features/migrations/#verifying-a-database-schema-at-runtime).
        // It allows catching bugs in the migration logic early.
        await impl.validateDatabaseSchema(this);
      },
    );
  }

  // Close database connection
  @override
  Future<void> close() async {
    await super.close();
    _instance = null;
  }

  // Reset database (for testing)
  static Future<void> reset() async {
    if (_instance != null) {
      await _instance!.close();
    }

    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'myanmar_calendar.sqlite'));

    if (await file.exists()) {
      await file.delete();
    }

    _instance = null;
  }
}

// Open database connection
QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'myanmar_calendar',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
      onResult: (result) {
        if (result.missingFeatures.isNotEmpty) {
          debugPrint(
            'Using ${result.chosenImplementation} due to unsupported '
            'browser features: ${result.missingFeatures}',
          );
        }
      },
    ),
  );
}

// Alternative connection for testing
// ignore: unused_element
LazyDatabase _openConnectionForTesting() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'myanmar_calendar_test.db'));
    return NativeDatabase(file);
  });
}
