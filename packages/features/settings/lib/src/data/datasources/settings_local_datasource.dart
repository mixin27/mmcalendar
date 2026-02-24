import 'package:shared_core/shared_core.dart';
import 'package:integrations_database/integrations_database.dart';

abstract class SettingsLocalDataSource {
  Future<Map<String, String>> getAllSettings();
  Future<String?> getSetting(String key);
  Future<void> setSetting(String key, String value);
  Future<void> deleteSetting(String key);
  Future<void> clearAllSettings();
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final AppDatabase database;

  SettingsLocalDataSourceImpl(this.database);

  @override
  Future<Map<String, String>> getAllSettings() async {
    try {
      return await database.settingsDao.getAllSettings();
    } catch (e) {
      throw CacheException('Failed to get all settings: ${e.toString()}');
    }
  }

  @override
  Future<String?> getSetting(String key) async {
    try {
      return await database.settingsDao.getSetting(key);
    } catch (e) {
      throw CacheException('Failed to get setting: ${e.toString()}');
    }
  }

  @override
  Future<void> setSetting(String key, String value) async {
    try {
      await database.settingsDao.setSetting(key, value);
    } catch (e) {
      throw CacheException('Failed to set setting: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteSetting(String key) async {
    try {
      await database.settingsDao.deleteSetting(key);
    } catch (e) {
      throw CacheException('Failed to delete setting: ${e.toString()}');
    }
  }

  @override
  Future<void> clearAllSettings() async {
    try {
      await database.settingsDao.clearAllSettings();
    } catch (e) {
      throw CacheException('Failed to clear settings: ${e.toString()}');
    }
  }
}
