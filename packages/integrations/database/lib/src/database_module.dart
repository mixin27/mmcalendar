import 'database/app_database.dart';

/// Composition helper for database lifecycle in the app layer.
final class DatabaseModule {
  const DatabaseModule._();

  static AppDatabase createDatabase() {
    return AppDatabase();
  }

  static Future<void> closeDatabase(AppDatabase database) async {
    await database.close();
  }

  static Future<void> resetDatabase() async {
    await AppDatabase.reset();
  }
}
