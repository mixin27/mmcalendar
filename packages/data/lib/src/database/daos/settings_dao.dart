import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/app_settings_table.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [AppSettings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  /// Get all settings as a map
  Future<Map<String, String>> getAllSettings() async {
    final settings = await select(appSettings).get();
    return {for (var setting in settings) setting.key: setting.value};
  }

  /// Get a specific setting value
  Future<String?> getSetting(String key) async {
    final query = select(appSettings)..where((tbl) => tbl.key.equals(key));
    final setting = await query.getSingleOrNull();
    return setting?.value;
  }

  /// Set a setting value (insert or update)
  Future<void> setSetting(String key, String value) async {
    final query = select(appSettings)..where((tbl) => tbl.key.equals(key));
    final setting = await query.getSingleOrNull();
    if (setting == null) {
      await into(appSettings).insertOnConflictUpdate(
        AppSettingsCompanion.insert(
          key: key,
          value: value,
          updatedAt: Value(DateTime.now()),
        ),
      );
    } else {
      await into(appSettings).insertOnConflictUpdate(
        AppSettingsCompanion.insert(
          id: Value(setting.id),
          key: key,
          value: value,
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  /// Delete a setting
  Future<int> deleteSetting(String key) {
    return (delete(appSettings)..where((tbl) => tbl.key.equals(key))).go();
  }

  /// Clear all settings
  Future<int> clearAllSettings() {
    return delete(appSettings).go();
  }

  /// Batch set multiple settings
  Future<void> setMultipleSettings(Map<String, String> settings) async {
    await batch((batch) {
      for (final entry in settings.entries) {
        batch.insert(
          appSettings,
          AppSettingsCompanion.insert(
            key: entry.key,
            value: entry.value,
            updatedAt: Value(DateTime.now()),
          ),
          onConflict: DoUpdate(
            (_) => AppSettingsCompanion.custom(
              value: Variable(entry.value),
              updatedAt: Variable(DateTime.now()),
            ),
          ),
        );
      }
    });
  }

  /// Check if setting exists
  Future<bool> hasSetting(String key) async {
    final query = select(appSettings)..where((tbl) => tbl.key.equals(key));
    final setting = await query.getSingleOrNull();
    return setting != null;
  }

  /// Get setting with default value
  Future<String> getSettingWithDefault(String key, String defaultValue) async {
    final value = await getSetting(key);
    return value ?? defaultValue;
  }

  /// Get int setting
  Future<int?> getIntSetting(String key) async {
    final value = await getSetting(key);
    return value != null ? int.tryParse(value) : null;
  }

  /// Get double setting
  Future<double?> getDoubleSetting(String key) async {
    final value = await getSetting(key);
    return value != null ? double.tryParse(value) : null;
  }

  /// Get bool setting
  Future<bool?> getBoolSetting(String key) async {
    final value = await getSetting(key);
    return value != null ? value.toLowerCase() == 'true' : null;
  }

  /// Set int setting
  Future<void> setIntSetting(String key, int value) {
    return setSetting(key, value.toString());
  }

  /// Set double setting
  Future<void> setDoubleSetting(String key, double value) {
    return setSetting(key, value.toString());
  }

  /// Set bool setting
  Future<void> setBoolSetting(String key, bool value) {
    return setSetting(key, value.toString());
  }
}
