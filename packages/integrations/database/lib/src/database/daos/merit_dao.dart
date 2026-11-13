import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/merit_entries_table.dart';

part 'merit_dao.g.dart';

@DriftAccessor(tables: [MeritEntries])
class MeritDao extends DatabaseAccessor<AppDatabase> with _$MeritDaoMixin {
  MeritDao(super.db);

  /// Entries on days from [from] to [to] (`yyyy-MM-dd`, inclusive), by day
  /// then as added.
  Stream<List<MeritEntryRow>> watchBetween(String from, String to) =>
      (select(meritEntries)
            ..where((m) => m.day.isBetweenValues(from, to))
            ..orderBy([
              (m) => OrderingTerm.asc(m.day),
              (m) => OrderingTerm.asc(m.id),
            ]))
          .watch();

  /// Every entry, latest day first.
  Stream<List<MeritEntryRow>> watchAll() =>
      (select(meritEntries)..orderBy([
            (m) => OrderingTerm.desc(m.day),
            (m) => OrderingTerm.desc(m.id),
          ]))
          .watch();

  Future<int> add(MeritEntriesCompanion entry) =>
      into(meritEntries).insert(entry);

  Future<void> remove(int id) =>
      (delete(meritEntries)..where((m) => m.id.equals(id))).go();
}
