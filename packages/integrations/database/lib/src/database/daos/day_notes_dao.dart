import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/day_notes_table.dart';

part 'day_notes_dao.g.dart';

@DriftAccessor(tables: [DayNotes])
class DayNotesDao extends DatabaseAccessor<AppDatabase>
    with _$DayNotesDaoMixin {
  DayNotesDao(super.db);

  /// The note for [day] (`yyyy-MM-dd`), as it changes.
  Stream<DayNoteRow?> watchDay(String day) =>
      (select(dayNotes)..where((n) => n.day.equals(day))).watchSingleOrNull();

  /// Notes on days from [from] to [to] (`yyyy-MM-dd`, inclusive).
  Stream<List<DayNoteRow>> watchBetween(String from, String to) =>
      (select(dayNotes)
            ..where((n) => n.day.isBetweenValues(from, to))
            ..orderBy([(n) => OrderingTerm.asc(n.day)]))
          .watch();

  /// Every note, latest day first.
  Stream<List<DayNoteRow>> watchAll() =>
      (select(dayNotes)..orderBy([(n) => OrderingTerm.desc(n.day)])).watch();

  Future<List<DayNoteRow>> all() =>
      (select(dayNotes)..orderBy([(n) => OrderingTerm.desc(n.day)])).get();

  /// Notes whose text contains [query], latest day first.
  Future<List<DayNoteRow>> search(String query) =>
      (select(dayNotes)
            ..where((n) => n.body.like('%${_escape(query)}%', escapeChar: r'\'))
            ..orderBy([(n) => OrderingTerm.desc(n.day)]))
          .get();

  /// Saves [body] for [day], keeping the first creation time.
  Future<void> save(String day, String body, DateTime now) =>
      into(dayNotes).insert(
        DayNotesCompanion.insert(
          day: day,
          body: body,
          createdAt: now,
          updatedAt: now,
        ),
        onConflict: DoUpdate(
          (_) => DayNotesCompanion(body: Value(body), updatedAt: Value(now)),
        ),
      );

  Future<void> deleteDay(String day) =>
      (delete(dayNotes)..where((n) => n.day.equals(day))).go();

  static String _escape(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');
}
