import 'package:drift/drift.dart';

import 'app_database.dart';

/// Small app-facing persistence API that keeps Drift types out of the
/// standalone Calendar Studio feature package.
class CalendarStudioProjectDatabase {
  const CalendarStudioProjectDatabase(this.database);

  final AppDatabase database;

  Future<List<CalendarStudioProjectRow>> list() => (database.select(
    database.calendarStudioProjects,
  )..orderBy([(row) => OrderingTerm.desc(row.updatedAt)])).get();

  Future<CalendarStudioProjectRow?> load(String id) => (database.select(
    database.calendarStudioProjects,
  )..where((row) => row.id.equals(id))).getSingleOrNull();

  Future<void> save({
    required String id,
    required String name,
    required String templateId,
    required int documentSchemaVersion,
    required String documentJson,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) => database
      .into(database.calendarStudioProjects)
      .insertOnConflictUpdate(
        CalendarStudioProjectsCompanion.insert(
          id: id,
          name: name,
          templateId: templateId,
          documentSchemaVersion: documentSchemaVersion,
          documentJson: documentJson,
          createdAt: createdAt,
          updatedAt: updatedAt,
        ),
      );

  Future<void> delete(String id) => (database.delete(
    database.calendarStudioProjects,
  )..where((row) => row.id.equals(id))).go();
}
