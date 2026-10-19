
import 'package:drift/drift.dart';

import 'app_database.dart';

/// App-facing persistence for Calendar Studio user templates, keeping Drift
/// types out of the Studio package.
class CalendarStudioTemplateDatabase {
  const CalendarStudioTemplateDatabase(this.database);

  final AppDatabase database;

  Future<List<CalendarStudioTemplateRow>> list() => (database.select(
    database.calendarStudioTemplates,
  )..orderBy([(row) => OrderingTerm.desc(row.updatedAt)])).get();

  Future<void> save({
    required String id,
    required String name,
    required int formatVersion,
    required String documentJson,
    Uint8List? preview,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) => database
      .into(database.calendarStudioTemplates)
      .insertOnConflictUpdate(
        CalendarStudioTemplatesCompanion.insert(
          id: id,
          name: name,
          formatVersion: formatVersion,
          documentJson: documentJson,
          preview: Value(preview),
          createdAt: createdAt,
          updatedAt: updatedAt,
        ),
      );

  Future<void> delete(String id) => (database.delete(
    database.calendarStudioTemplates,
  )..where((row) => row.id.equals(id))).go();
}
