import 'package:drift/drift.dart';

/// Event categories used by normalized and legacy-compatible event flows.
class EventCategories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  TextColumn get iconName => text()();
  IntColumn get colorCode => integer()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer()();
  DateTimeColumn get createdAt => dateTime()();
}
