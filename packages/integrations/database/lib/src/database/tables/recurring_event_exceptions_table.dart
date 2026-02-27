import 'package:drift/drift.dart';

/// Modified, deleted, or completed instances for recurring event masters.
class RecurringEventExceptions extends Table {
  IntColumn get id => integer().autoIncrement()();

  // Reference to recurring master event id from `calendar_events`.
  IntColumn get masterEventId => integer()();

  // Specific occurrence date this exception applies to.
  DateTimeColumn get occurrenceDate => dateTime()();

  // 'modified', 'deleted', 'completed'
  TextColumn get exceptionType => text()();

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
