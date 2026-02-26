import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integrations_database/integrations_database.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  test(
    'manual migration from v1 to v2 preserves data and adds new schema',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'mmcalendar_migration_',
      );
      final dbFile = File(p.join(tempDir.path, 'app.sqlite'));

      try {
        _seedSchemaV1(dbFile.path);

        final migratedDb = AppDatabase(NativeDatabase(dbFile));

        // Trigger open + migration.
        await migratedDb.customSelect('SELECT 1').getSingle();

        final userVersion = await migratedDb
            .customSelect('PRAGMA user_version')
            .map((row) => row.read<int>('user_version'))
            .getSingle();
        expect(userVersion, 2);

        final calendarCount = await migratedDb
            .customSelect('SELECT COUNT(*) AS c FROM calendar_settings')
            .map((row) => row.read<int>('c'))
            .getSingle();
        expect(calendarCount, 1);

        final eventsCount = await migratedDb
            .customSelect('SELECT COUNT(*) AS c FROM user_events')
            .map((row) => row.read<int>('c'))
            .getSingle();
        expect(eventsCount, 1);

        final recurringMasterValue = await migratedDb
            .customSelect(
              'SELECT is_recurring_master FROM user_events WHERE id = 1',
            )
            .map((row) => row.read<int>('is_recurring_master'))
            .getSingle();
        expect(recurringMasterValue, 0);

        final hasNewTable = await migratedDb
            .customSelect('''
            SELECT COUNT(*) AS c
            FROM sqlite_master
            WHERE type = 'table' AND name = 'recurring_event_exceptions'
            ''')
            .map((row) => row.read<int>('c'))
            .getSingle();
        expect(hasNewTable, 1);

        await migratedDb.close();
      } finally {
        if (await dbFile.exists()) {
          await dbFile.delete();
        }
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    },
  );
}

void _seedSchemaV1(String path) {
  final db = sqlite.sqlite3.open(path);

  try {
    for (final statement in _schemaV1Sql) {
      db.execute(statement);
    }

    db.execute(
      "INSERT INTO calendar_settings (default_language) VALUES ('my')",
    );
    db.execute('''
      INSERT INTO user_events (
        id,
        title,
        event_date,
        is_all_day,
        category,
        has_notification,
        is_completed,
        priority
      ) VALUES (
        1,
        'Water Festival',
        1704067200,
        1,
        'personal',
        0,
        0,
        2
      )
      ''');

    db.execute('PRAGMA user_version = 1');
  } finally {
    db.dispose();
  }
}

const _schemaV1Sql = <String>[
  '''
  CREATE TABLE calendar_settings (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    sasana_year_type INTEGER NOT NULL DEFAULT 0,
    calendar_type INTEGER NOT NULL DEFAULT 0,
    gregorian_start INTEGER NOT NULL DEFAULT 2361222,
    timezone_offset REAL NOT NULL DEFAULT 6.5,
    default_language TEXT NOT NULL DEFAULT 'en',
    created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
    updated_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
  )
  ''',
  '''
  CREATE TABLE app_settings (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    key TEXT NOT NULL UNIQUE,
    value TEXT NOT NULL,
    created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
    updated_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
  )
  ''',
  '''
  CREATE TABLE custom_holidays (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    date INTEGER NOT NULL,
    type TEXT NOT NULL,
    description TEXT,
    is_recurring INTEGER NOT NULL DEFAULT 0 CHECK ("is_recurring" IN (0, 1)),
    created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
    updated_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
  )
  ''',
  '''
  CREATE TABLE user_events (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL CHECK (length(title) BETWEEN 1 AND 200),
    description TEXT,
    event_date INTEGER NOT NULL,
    event_time INTEGER,
    is_all_day INTEGER NOT NULL DEFAULT 1 CHECK ("is_all_day" IN (0, 1)),
    category TEXT NOT NULL,
    category_id INTEGER,
    color_code INTEGER,
    recurrence_type TEXT,
    recurrence_interval INTEGER,
    recurrence_days TEXT,
    recurrence_end_date INTEGER,
    recurrence_count INTEGER,
    has_notification INTEGER NOT NULL DEFAULT 0 CHECK ("has_notification" IN (0, 1)),
    notification_times TEXT,
    location TEXT,
    is_completed INTEGER NOT NULL DEFAULT 0 CHECK ("is_completed" IN (0, 1)),
    completed_at INTEGER,
    priority INTEGER NOT NULL DEFAULT 0,
    tags TEXT,
    created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
    updated_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
  )
  ''',
  '''
  CREATE TABLE event_categories (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    icon_name TEXT NOT NULL,
    color_code INTEGER NOT NULL,
    is_default INTEGER NOT NULL DEFAULT 0 CHECK ("is_default" IN (0, 1)),
    sort_order INTEGER NOT NULL,
    created_at INTEGER NOT NULL
  )
  ''',
];
