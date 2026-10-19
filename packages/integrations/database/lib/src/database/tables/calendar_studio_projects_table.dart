import 'package:drift/drift.dart';

/// Atomic, versioned Calendar Studio documents with queryable dashboard fields.
/// Pages and blocks stay inside [documentJson] because the editor loads and
/// saves them as one consistency boundary.
@DataClassName('CalendarStudioProjectRow')
class CalendarStudioProjects extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 240)();
  TextColumn get templateId => text()();
  IntColumn get documentSchemaVersion => integer()();
  TextColumn get documentJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
