import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'connection/connection.dart' as impl;

import 'daos/events_dao.dart';
import 'daos/events_v2_dao.dart';
import 'daos/recurring_exceptions_dao.dart';
import 'tables/calendar_settings_table.dart';
import 'tables/events_v2_tables.dart';
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
    CalendarEvents,
    EventReminders,
    EventRecurrenceRules,
  ],
  daos: [
    CalendarDao,
    SettingsDao,
    HolidaysDao,
    EventsDao,
    EventsV2Dao,
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
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();

        // Create default calendar settings
        await calendarDao.createDefaultSettings();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.create(recurringEventExceptions);
          await m.addColumn(userEvents, userEvents.isRecurringMaster);
        }
        if (from < 3) {
          await m.create(calendarEvents);
          await m.create(eventReminders);
          await m.create(eventRecurrenceRules);
          await _migrateLegacyEventsToV3();
        }
      },
      beforeOpen: (details) async {
        // Enable foreign keys
        await customStatement('PRAGMA foreign_keys = ON');

        // Verify database
        if (details.wasCreated) {
          // Database was just created
          debugPrint('Database created successfully');
        }

        // Manual migration policy: runtime drift_dev schema checks are disabled.
        await impl.validateDatabaseSchema(this);
      },
    );
  }

  Future<void> _migrateLegacyEventsToV3() async {
    final rows = await customSelect('''
      SELECT
        id,
        title,
        description,
        event_date,
        event_time,
        is_all_day,
        category,
        category_id,
        color_code,
        recurrence_type,
        recurrence_interval,
        recurrence_days,
        recurrence_end_date,
        recurrence_count,
        has_notification,
        notification_times,
        location,
        is_completed,
        completed_at,
        priority,
        tags,
        created_at,
        updated_at
      FROM user_events
      ''').get();

    for (final row in rows) {
      final legacyId = row.read<int>('id');
      final eventDate = row.read<DateTime>('event_date');
      final eventTime = row.readNullable<DateTime>('event_time');
      final isAllDay = row.read<bool>('is_all_day');
      final categoryName = row.read<String>('category');
      final status = row.read<bool>('is_completed') ? 'completed' : 'pending';
      final now = DateTime.now();

      await into(calendarEvents).insert(
        CalendarEventsCompanion.insert(
          id: Value(legacyId),
          title: row.read<String>('title'),
          description: Value(row.readNullable<String>('description')),
          eventDate: eventDate,
          eventTime: Value(eventTime),
          isAllDay: Value(isAllDay),
          timezoneId: const Value('Asia/Yangon'),
          categoryId: Value(row.readNullable<int>('category_id')),
          categoryName: Value(categoryName),
          colorCode: Value(row.readNullable<int>('color_code')),
          location: Value(row.readNullable<String>('location')),
          status: Value(status),
          priority: Value(row.read<int>('priority')),
          tags: Value(row.readNullable<String>('tags')),
          createdAt: row.read<DateTime>('created_at'),
          updatedAt: row.read<DateTime>('updated_at'),
          completedAt: Value(row.readNullable<DateTime>('completed_at')),
          legacyEventId: Value(legacyId),
        ),
        mode: InsertMode.insertOrIgnore,
      );

      final recurrenceType = row.readNullable<String>('recurrence_type');
      if (recurrenceType != null &&
          recurrenceType.isNotEmpty &&
          recurrenceType != 'none') {
        await into(eventRecurrenceRules).insert(
          EventRecurrenceRulesCompanion.insert(
            eventId: Value(legacyId),
            recurrenceType: recurrenceType,
            recurrenceInterval: Value(
              row.readNullable<int>('recurrence_interval') ?? 1,
            ),
            recurrenceDays: Value(row.readNullable<String>('recurrence_days')),
            dayOfMonth: Value(eventDate.day),
            monthOfYear: Value(
              recurrenceType == 'yearly' ? eventDate.month : null,
            ),
            recurrenceEndDate: Value(
              row.readNullable<DateTime>('recurrence_end_date'),
            ),
            recurrenceCount: Value(row.readNullable<int>('recurrence_count')),
            createdAt: row.read<DateTime>('created_at'),
            updatedAt: row.read<DateTime>('updated_at'),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }

      final hasNotification = row.read<bool>('has_notification');
      if (!hasNotification) {
        continue;
      }

      final reminderMinutes = _parseLegacyReminderMinutes(
        row.readNullable<String>('notification_times'),
      );
      for (final minutes in reminderMinutes) {
        await into(eventReminders).insert(
          EventRemindersCompanion.insert(
            eventId: legacyId,
            minutesBefore: minutes,
            channel: const Value('local'),
            createdAt: now,
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    }
  }

  List<int> _parseLegacyReminderMinutes(String? jsonValue) {
    if (jsonValue == null || jsonValue.isEmpty) return const [];
    try {
      final decoded = jsonDecode(jsonValue);
      if (decoded is! List) return const [];

      final result = <int>[];
      for (final value in decoded) {
        if (value is int) {
          result.add(value);
          continue;
        }
        if (value is String) {
          final parsed = int.tryParse(value);
          if (parsed != null) {
            result.add(parsed);
          }
        }
      }
      return result;
    } catch (_) {
      return const [];
    }
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

    await impl.resetDatabase('myanmar_calendar');

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
QueryExecutor _openConnectionForTesting() {
  return impl.openConnectionForTesting('myanmar_calendar_test');
}
