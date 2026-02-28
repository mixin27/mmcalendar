import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/custom_holidays_table.dart';

part 'holidays_dao.g.dart';

@DriftAccessor(tables: [CustomHolidays])
class HolidaysDao extends DatabaseAccessor<AppDatabase>
    with _$HolidaysDaoMixin {
  HolidaysDao(super.db);

  /// Get all custom holidays
  Future<List<CustomHoliday>> getAllHolidays() {
    return select(customHolidays).get();
  }

  /// Get holidays for a specific date
  Future<List<CustomHoliday>> getHolidaysByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return (select(
      customHolidays,
    )..where((tbl) => tbl.date.isBetweenValues(startOfDay, endOfDay))).get();
  }

  /// Get holidays in date range
  Future<List<CustomHoliday>> getHolidaysInRange(DateTime start, DateTime end) {
    return (select(customHolidays)
          ..where((tbl) => tbl.date.isBetweenValues(start, end))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.date)]))
        .get();
  }

  /// Get holidays by type
  Future<List<CustomHoliday>> getHolidaysByType(String type) {
    return (select(
      customHolidays,
    )..where((tbl) => tbl.type.equals(type))).get();
  }

  /// Add a custom holiday
  Future<int> addHoliday(CustomHolidaysCompanion holiday) {
    return into(customHolidays).insert(holiday);
  }

  /// Update a holiday
  Future<bool> updateHoliday(CustomHolidaysCompanion holiday) {
    return update(customHolidays).replace(holiday);
  }

  /// Delete a holiday
  Future<int> deleteHoliday(int id) {
    return (delete(customHolidays)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Delete all holidays
  Future<int> deleteAllHolidays() {
    return delete(customHolidays).go();
  }

  /// Get holiday by id
  Future<CustomHoliday?> getHolidayById(int id) {
    return (select(
      customHolidays,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }
}
