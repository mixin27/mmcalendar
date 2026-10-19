import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integrations_database/integrations_database.dart';
import 'package:settings/src/data/services/database_display_preferences_port.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  test('a fresh install uses the Almanac grid', () async {
    final config = await DatabaseDisplayPreferencesPort(
      database,
    ).getDisplayConfig();
    expect(config.gridStyle, CalendarGridStyle.almanac);
  });

  test('the chosen grid style is stored and survives a restart', () async {
    final port = DatabaseDisplayPreferencesPort(database);
    final watched = port.watchDisplayConfig().map((c) => c.gridStyle);
    final changes = expectLater(watched, emitsThrough(CalendarGridStyle.clean));

    await database.settingsDao.setSetting(
      StorageKeys.calendarGridStyle,
      CalendarGridStyle.clean.name,
    );
    await changes;

    // A new port over the same database, as after an app restart.
    final reopened = await DatabaseDisplayPreferencesPort(
      database,
    ).getDisplayConfig();
    expect(reopened.gridStyle, CalendarGridStyle.clean);
  });

  test('an unknown stored value falls back to the default', () async {
    await database.settingsDao.setSetting(
      StorageKeys.calendarGridStyle,
      'mosaic',
    );
    final config = await DatabaseDisplayPreferencesPort(
      database,
    ).getDisplayConfig();
    expect(config.gridStyle, CalendarGridStyle.defaultStyle);
  });
}
