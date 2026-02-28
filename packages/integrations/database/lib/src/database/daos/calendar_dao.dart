import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/calendar_settings_table.dart';

part 'calendar_dao.g.dart';

@DriftAccessor(tables: [CalendarSettings])
class CalendarDao extends DatabaseAccessor<AppDatabase>
    with _$CalendarDaoMixin {
  CalendarDao(super.db);

  /// Get calendar settings (should only have one row)
  Future<CalendarSetting?> getSettings() async {
    return await (select(calendarSettings)..limit(1)).getSingleOrNull();
  }

  /// Create initial settings
  Future<int> createDefaultSettings() {
    return into(calendarSettings).insert(CalendarSettingsCompanion.insert());
  }

  /// Update settings
  Future<int> updateSettings(CalendarSettingsCompanion settings) {
    return update(calendarSettings).write(settings);
  }

  /// Get or create settings
  Future<CalendarSetting> getOrCreateSettings() async {
    var settings = await getSettings();
    if (settings == null) {
      await createDefaultSettings();
      settings = await getSettings();
    }
    return settings!;
  }

  /// Update specific field
  Future<void> updateSasanaYearType(int type) async {
    await (update(calendarSettings)..where((tbl) => tbl.id.equals(1))).write(
      CalendarSettingsCompanion(
        sasanaYearType: Value(type),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateCalendarType(int type) async {
    await (update(calendarSettings)..where((tbl) => tbl.id.equals(1))).write(
      CalendarSettingsCompanion(
        calendarType: Value(type),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateTimezoneOffset(double offset) async {
    await (update(calendarSettings)..where((tbl) => tbl.id.equals(1))).write(
      CalendarSettingsCompanion(
        timezoneOffset: Value(offset),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateDefaultLanguage(String language) async {
    await (update(calendarSettings)..where((tbl) => tbl.id.equals(1))).write(
      CalendarSettingsCompanion(
        defaultLanguage: Value(language),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
