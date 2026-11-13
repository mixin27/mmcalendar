import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:integrations_database/integrations_database.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

import '../day_notes_repository.dart';

/// What kind of merit (ကုသိုလ်) an entry records.
enum MeritKind {
  donation,
  precepts,
  meditation,
  other;

  static MeritKind parse(String name) =>
      values.firstWhere((k) => k.name == name, orElse: () => other);

  /// Whether the entry can have an amount: kyats or minutes.
  bool get hasAmount => this == donation || this == meditation;

  /// Whether it keeps a Sabbath streak going.
  bool get keepsSabbath => this == precepts || this == meditation;
}

/// One entry in the merit diary.
@immutable
class MeritEntry {
  const MeritEntry({
    required this.id,
    required this.date,
    required this.kind,
    this.note,
    this.amount,
    required this.createdAt,
  });

  final int id;

  /// The day, at midnight.
  final DateTime date;
  final MeritKind kind;
  final String? note;

  /// Kyats for a donation, minutes for meditation.
  final int? amount;
  final DateTime createdAt;
}

/// The app's [MeritRepository], when registered.
MeritRepository? get meritRepository =>
    GetIt.instance.isRegistered<MeritRepository>()
    ? GetIt.instance<MeritRepository>()
    : null;

/// The merit diary, stored in the app database.
class MeritRepository {
  MeritRepository(this._dao, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final MeritDao _dao;
  final DateTime Function() _clock;

  static MeritEntry _entry(MeritEntryRow r) => MeritEntry(
    id: r.id,
    date: DayNotesRepository.dayOf(r.day),
    kind: MeritKind.parse(r.kind),
    note: r.note,
    amount: r.amount,
    createdAt: r.createdAt,
  );

  /// [day]'s entries, as added.
  Stream<List<MeritEntry>> watchDay(DateTime day) {
    final key = DayNotesRepository.keyOf(day);
    return _dao.watchBetween(key, key).map((rows) => rows.map(_entry).toList());
  }

  /// Every entry, latest day first.
  Stream<List<MeritEntry>> watchAll() =>
      _dao.watchAll().map((rows) => rows.map(_entry).toList());

  Future<void> add(DateTime day, MeritKind kind, {String? note, int? amount}) {
    final text = note?.trim();
    return _dao.add(
      MeritEntriesCompanion.insert(
        day: DayNotesRepository.keyOf(day),
        kind: kind.name,
        note: Value(text == null || text.isEmpty ? null : text),
        amount: Value(kind.hasAmount ? amount : null),
        createdAt: _clock(),
      ),
    );
  }

  Future<void> remove(int id) => _dao.remove(id);
}

/// A year in the merit diary.
@immutable
class MeritYear {
  const MeritYear({
    required this.counts,
    required this.meditationMinutes,
    required this.donated,
  });

  final Map<MeritKind, int> counts;
  final int meditationMinutes;

  /// Kyats.
  final int donated;
}

abstract final class MeritStats {
  /// [year]'s entries by kind, meditation minutes and kyats donated.
  static MeritYear year(List<MeritEntry> entries, int year) {
    final counts = {for (final k in MeritKind.values) k: 0};
    var minutes = 0, kyats = 0;
    for (final e in entries.where((e) => e.date.year == year)) {
      counts[e.kind] = counts[e.kind]! + 1;
      if (e.kind == MeritKind.meditation) minutes += e.amount ?? 0;
      if (e.kind == MeritKind.donation) kyats += e.amount ?? 0;
    }
    return MeritYear(
      counts: counts,
      meditationMinutes: minutes,
      donated: kyats,
    );
  }

  /// Sabbath days in a row, back from [today], with precepts or meditation
  /// logged. A Sabbath today that has nothing logged yet doesn't break it.
  static int sabbathStreak(List<MeritEntry> entries, DateTime today) {
    final kept = {
      for (final e in entries)
        if (e.kind.keepsSabbath) e.date,
    };
    var streak = 0;
    var day = DateTime(today.year, today.month, today.day);
    // At most about four years back.
    for (
      var i = 0;
      i < 1500;
      i++, day = DateTime(day.year, day.month, day.day - 1)
    ) {
      if (!MyanmarCalendar.getCompleteDateFor(
        day.year,
        day.month,
        day.day,
      ).isSabbath) {
        continue;
      }
      if (kept.contains(day)) {
        streak++;
      } else if (i == 0) {
        continue; // Today, still to come.
      } else {
        break;
      }
    }
    return streak;
  }
}
