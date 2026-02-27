import 'package:drift/drift.dart';

import 'event_categories_table.dart';

/// Normalized event master records.
class CalendarEvents extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();

  // Date/time fields are preserved from legacy schema for compatibility.
  DateTimeColumn get eventDate => dateTime()();
  DateTimeColumn get eventTime => dateTime().nullable()();
  BoolColumn get isAllDay => boolean().withDefault(const Constant(true))();

  // Event timezone for scheduling and future sync use cases.
  TextColumn get timezoneId =>
      text().withDefault(const Constant('Asia/Yangon'))();

  IntColumn get categoryId => integer().nullable().references(
    EventCategories,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get categoryName =>
      text().withDefault(const Constant('Personal'))();
  IntColumn get colorCode => integer().nullable()();

  TextColumn get location => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get priority => integer().withDefault(const Constant(1))();
  TextColumn get tags => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  // Legacy link to support migration integrity and rollback verification.
  IntColumn get legacyEventId => integer().nullable().unique()();
}

/// Normalized reminders. One row per (event, minutes-before, channel).
class EventReminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get eventId =>
      integer().references(CalendarEvents, #id, onDelete: KeyAction.cascade)();
  IntColumn get minutesBefore => integer()();
  TextColumn get channel => text().withDefault(const Constant('local'))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {eventId, minutesBefore, channel},
  ];
}

/// Normalized recurrence rule (one-to-one with event).
class EventRecurrenceRules extends Table {
  IntColumn get eventId =>
      integer().references(CalendarEvents, #id, onDelete: KeyAction.cascade)();

  TextColumn get recurrenceType => text()(); // daily/weekly/monthly/yearly
  IntColumn get recurrenceInterval =>
      integer().withDefault(const Constant(1))();
  TextColumn get recurrenceDays => text().nullable()(); // JSON [1,3,5]
  IntColumn get dayOfMonth => integer().nullable()();
  IntColumn get monthOfYear => integer().nullable()();
  DateTimeColumn get recurrenceEndDate => dateTime().nullable()();
  IntColumn get recurrenceCount => integer().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {eventId};
}
