import 'package:drift/drift.dart';

// (Phase 2 - Placeholder)
class UserEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  DateTimeColumn get eventDate => dateTime()();
  DateTimeColumn get eventTime => dateTime().nullable()();
  BoolColumn get isAllDay => boolean().withDefault(const Constant(true))();

  // Category
  TextColumn get category => text()();
  IntColumn get colorCode => integer().nullable()();

  // Recurrence (Phase 2)
  TextColumn get recurrenceType => text().nullable()();

  // Notifications
  BoolColumn get hasNotification =>
      boolean().withDefault(const Constant(false))();

  // Metadata
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
