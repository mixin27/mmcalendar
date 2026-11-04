import 'package:drift/drift.dart';

/// One note per calendar day, keyed by the day as `yyyy-MM-dd` so time
/// zones never move a note to another day.
@DataClassName('DayNoteRow')
class DayNotes extends Table {
  TextColumn get day => text()();
  TextColumn get body => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {day};
}
