import 'package:drift/drift.dart';

class AppSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get key => text().unique()();
  TextColumn get value => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
