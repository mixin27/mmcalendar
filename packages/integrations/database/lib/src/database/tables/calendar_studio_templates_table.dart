import 'package:drift/drift.dart';

/// Calendar Studio templates the user saved or imported. The design (one
/// page of blocks plus bindings) stays inside [documentJson]; the preview is
/// kept apart so the gallery can list templates without decoding them.
@DataClassName('CalendarStudioTemplateRow')
class CalendarStudioTemplates extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 240)();
  IntColumn get formatVersion => integer()();
  TextColumn get documentJson => text()();
  BlobColumn get preview => blob().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
