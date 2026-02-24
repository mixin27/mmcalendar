import 'package:drift/drift.dart';

class UserEvents extends Table {
  IntColumn get id => integer().autoIncrement()();

  // Basic info
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();

  // Date & Time
  DateTimeColumn get eventDate => dateTime()();
  DateTimeColumn get eventTime => dateTime().nullable()();
  BoolColumn get isAllDay => boolean().withDefault(const Constant(true))();

  // Category
  TextColumn get category => text()(); // personal, work, religious, custom
  IntColumn get categoryId => integer().nullable()(); // FK to EventCategories
  IntColumn get colorCode => integer().nullable()();

  // Recurrence (Master Event)
  TextColumn get recurrenceType =>
      text().nullable()(); // none, daily, weekly, monthly, yearly
  IntColumn get recurrenceInterval =>
      integer().nullable()(); // Every X days/weeks
  TextColumn get recurrenceDays =>
      text().nullable()(); // JSON: [1,3,5] for Mon,Wed,Fri
  DateTimeColumn get recurrenceEndDate => dateTime().nullable()();
  IntColumn get recurrenceCount => integer().nullable()();

  // Master event identifier
  BoolColumn get isRecurringMaster =>
      boolean().withDefault(const Constant(false))();

  // Notifications
  BoolColumn get hasNotification =>
      boolean().withDefault(const Constant(false))();
  TextColumn get notificationTimes =>
      text().nullable()(); // JSON: [-60, -30, 0] minutes

  // Location
  TextColumn get location => text().nullable()();

  // Status
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  IntColumn get priority => integer().withDefault(const Constant(0))(); // 0-3

  // Metadata
  TextColumn get tags => text().nullable()(); // JSON array
  DateTimeColumn get createdAt =>
      dateTime().withDefault(Constant(DateTime.now()))();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(Constant(DateTime.now()))();
}

// Event Categories Table
class EventCategories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  TextColumn get iconName => text()();
  IntColumn get colorCode => integer()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer()();
  DateTimeColumn get createdAt => dateTime()();
}

// Exception Instances (Modified or Deleted Occurrences)
class RecurringEventExceptions extends Table {
  IntColumn get id => integer().autoIncrement()();

  // Reference to master event
  IntColumn get masterEventId => integer()();

  // The specific occurrence date this exception applies to
  DateTimeColumn get occurrenceDate => dateTime()();

  // Exception type
  TextColumn get exceptionType =>
      text()(); // 'modified', 'deleted', 'completed'

  // Modified values (if type = 'modified')
  TextColumn get modifiedTitle => text().nullable()();
  TextColumn get modifiedDescription => text().nullable()();
  DateTimeColumn get modifiedDate => dateTime().nullable()();
  DateTimeColumn get modifiedTime => dateTime().nullable()();
  TextColumn get modifiedLocation => text().nullable()();

  // Completion info (if type = 'completed')
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime()();
}
