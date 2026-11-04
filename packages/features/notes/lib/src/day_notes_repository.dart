import 'package:get_it/get_it.dart';
import 'package:integrations_database/integrations_database.dart';

import 'day_note.dart';

/// The app's [DayNotesRepository], when registered.
DayNotesRepository? get dayNotes =>
    GetIt.instance.isRegistered<DayNotesRepository>()
    ? GetIt.instance<DayNotesRepository>()
    : null;

/// Notes by calendar day, stored in the app database.
class DayNotesRepository {
  DayNotesRepository(this._dao, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DayNotesDao _dao;
  final DateTime Function() _clock;

  /// [date]'s day as stored: `yyyy-MM-dd`.
  static String keyOf(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static DateTime dayOf(String key) {
    final parts = key.split('-').map(int.parse).toList();
    return DateTime(parts[0], parts[1], parts[2]);
  }

  static DayNote _note(DayNoteRow row) =>
      DayNote(date: dayOf(row.day), text: row.body, updatedAt: row.updatedAt);

  /// [date]'s note, or null, as it changes.
  Stream<DayNote?> watchDay(DateTime date) =>
      _dao.watchDay(keyOf(date)).map((row) => row == null ? null : _note(row));

  /// The days from [from] to [to] (inclusive) that have a note.
  Stream<Set<DateTime>> watchDays(DateTime from, DateTime to) => _dao
      .watchBetween(keyOf(from), keyOf(to))
      .map((rows) => {for (final r in rows) dayOf(r.day)});

  /// Every note, latest day first.
  Stream<List<DayNote>> watchAll() =>
      _dao.watchAll().map((rows) => rows.map(_note).toList());

  /// Notes containing [query], latest day first; every note for an empty
  /// query.
  Future<List<DayNote>> search(String query) async {
    final q = query.trim();
    final rows = q.isEmpty ? await _dao.all() : await _dao.search(q);
    return rows.map(_note).toList();
  }

  /// Saves [text] on [date]; blank text deletes the day's note.
  Future<void> save(DateTime date, String text) {
    final body = text.trim();
    if (body.isEmpty) return _dao.deleteDay(keyOf(date));
    return _dao.save(keyOf(date), body, _clock());
  }
}
