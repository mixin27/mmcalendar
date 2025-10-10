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

  // Recurrence
  TextColumn get recurrenceType =>
      text().nullable()(); // none, daily, weekly, monthly, yearly
  IntColumn get recurrenceInterval =>
      integer().nullable()(); // Every X days/weeks
  TextColumn get recurrenceDays =>
      text().nullable()(); // JSON: [1,3,5] for Mon,Wed,Fri
  DateTimeColumn get recurrenceEndDate => dateTime().nullable()();
  IntColumn get recurrenceCount => integer().nullable()();

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
