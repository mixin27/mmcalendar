import 'package:integrations_database/integrations_database.dart';
import 'package:shared_core/shared_core.dart';

class DatabaseDisplayPreferencesPort implements DisplayPreferencesPort {
  DatabaseDisplayPreferencesPort(this._database);

  final AppDatabase _database;

  @override
  Future<bool> getShowShanCalendar() async {
    final value = await _database.settingsDao.getBoolSetting(
      StorageKeys.showShanCalendar,
    );
    return value ?? true;
  }

  @override
  Stream<bool> watchShowShanCalendar() {
    return _database.settingsDao
        .watchBoolSetting(StorageKeys.showShanCalendar)
        .map((value) => value ?? true)
        .distinct();
  }
}
