import 'package:drift/drift.dart';

/// One good deed on a day, for the merit diary: a donation (ဒါန), keeping
/// precepts (သီလ), meditation (ဘာဝနာ) or something else.
@DataClassName('MeritEntryRow')
class MeritEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// The day as `yyyy-MM-dd`, like day notes.
  TextColumn get day => text()();

  /// `donation`, `precepts`, `meditation` or `other`.
  TextColumn get kind => text()();
  TextColumn get note => text().nullable()();

  /// Kyats for a donation, minutes for meditation; optional.
  IntColumn get amount => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}
