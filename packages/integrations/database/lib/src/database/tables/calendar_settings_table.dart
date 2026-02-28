import 'package:drift/drift.dart';

class CalendarSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sasanaYearType => integer().withDefault(const Constant(0))();
  IntColumn get calendarType => integer().withDefault(const Constant(0))();
  IntColumn get gregorianStart =>
      integer().withDefault(const Constant(2361222))();
  RealColumn get timezoneOffset => real().withDefault(const Constant(6.5))();
  TextColumn get defaultLanguage => text().withDefault(const Constant('en'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
