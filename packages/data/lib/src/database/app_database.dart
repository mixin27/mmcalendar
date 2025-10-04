import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/calendar_settings_table.dart';
import 'tables/app_settings_table.dart';
import 'tables/custom_holidays_table.dart';
import 'tables/user_events_table.dart';
import 'daos/calendar_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/holidays_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [CalendarSettings, AppSettings, CustomHolidays, UserEvents],
  daos: [CalendarDao, SettingsDao, HolidaysDao],
)
class AppDatabase extends _$AppDatabase {
  // Singleton pattern
  static AppDatabase? _instance;

  AppDatabase._internal() : super(_openConnection());

  factory AppDatabase() {
    _instance ??= AppDatabase._internal();
    return _instance!;
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();

        // Create default calendar settings
        await calendarDao.createDefaultSettings();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle database migrations here
        // Example:
        // if (from < 2) {
        //   await m.addColumn(appSettings, appSettings.newColumn);
        // }
      },
      beforeOpen: (details) async {
        // Enable foreign keys
        await customStatement('PRAGMA foreign_keys = ON');

        // Verify database
        if (details.wasCreated) {
          // Database was just created
          debugPrint('Database created successfully');
        }
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
    final file = File(p.join(dbFolder.path, 'myanmar_calendar.db'));

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
