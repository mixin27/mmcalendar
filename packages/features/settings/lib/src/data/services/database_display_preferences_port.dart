import 'package:integrations_database/integrations_database.dart';
import 'package:drift/drift.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_core/shared_core.dart';

class DatabaseDisplayPreferencesPort
    implements DisplayPreferencesPort, CalendarDisplayConfigPort {
  DatabaseDisplayPreferencesPort(this._database);

  final AppDatabase _database;

  static const String _displayConfigQuery = '''
    SELECT
      COALESCE((SELECT value FROM app_settings WHERE key = 'calendar_language' LIMIT 1), 'my') AS calendar_language,
      COALESCE((SELECT value FROM app_settings WHERE key = 'show_holidays' LIMIT 1), 'true') AS show_holidays,
      COALESCE((SELECT value FROM app_settings WHERE key = 'show_anniversary_days' LIMIT 1), 'true') AS show_anniversary_days,
      COALESCE((SELECT value FROM app_settings WHERE key = 'show_sabbaths' LIMIT 1), 'true') AS show_sabbaths,
      COALESCE((SELECT value FROM app_settings WHERE key = 'show_astrology' LIMIT 1), 'true') AS show_astrology,
      COALESCE((SELECT value FROM app_settings WHERE key = 'show_western_dates' LIMIT 1), 'true') AS show_western_dates,
      COALESCE((SELECT value FROM app_settings WHERE key = 'show_myanmar_dates' LIMIT 1), 'true') AS show_myanmar_dates,
      COALESCE((SELECT value FROM app_settings WHERE key = 'show_shan_calendar' LIMIT 1), 'true') AS show_shan_calendar,
      COALESCE((SELECT value FROM app_settings WHERE key = 'use_device_timezone' LIMIT 1), 'true') AS use_device_timezone,
      COALESCE((SELECT sasana_year_type FROM calendar_settings LIMIT 1), 0) AS sasana_year_type,
      COALESCE((SELECT calendar_type FROM calendar_settings LIMIT 1), 0) AS calendar_type,
      COALESCE((SELECT gregorian_start FROM calendar_settings LIMIT 1), 2361222) AS gregorian_start,
      COALESCE((SELECT timezone_offset FROM calendar_settings LIMIT 1), 6.5) AS timezone_offset,
      COALESCE((SELECT default_language FROM calendar_settings LIMIT 1), 'en') AS default_language
  ''';

  @override
  Future<bool> getShowShanCalendar() async {
    final config = await getDisplayConfig();
    return config.showShanCalendar;
  }

  @override
  Stream<bool> watchShowShanCalendar() {
    return watchDisplayConfig()
        .map((config) => config.showShanCalendar)
        .distinct();
  }

  @override
  Future<CalendarDisplayConfig> getDisplayConfig() async {
    final row = await _database
        .customSelect(
          _displayConfigQuery,
          readsFrom: {_database.appSettings, _database.calendarSettings},
        )
        .getSingle();

    return _mapDisplayConfig(row);
  }

  @override
  Stream<CalendarDisplayConfig> watchDisplayConfig() {
    return _database
        .customSelect(
          _displayConfigQuery,
          readsFrom: {_database.appSettings, _database.calendarSettings},
        )
        .watchSingle()
        .map(_mapDisplayConfig)
        .distinct();
  }

  CalendarDisplayConfig _mapDisplayConfig(QueryRow row) {
    return CalendarDisplayConfig(
      calendarLanguage: Language.fromCode(
        _readString(row, 'calendar_language'),
      ),
      showHolidays: _readBool(row, 'show_holidays'),
      showAnniversaryDays: _readBool(row, 'show_anniversary_days'),
      showSabbaths: _readBool(row, 'show_sabbaths'),
      showAstrology: _readBool(row, 'show_astrology'),
      showWesternDates: _readBool(row, 'show_western_dates'),
      showMyanmarDates: _readBool(row, 'show_myanmar_dates'),
      showShanCalendar: _readBool(row, 'show_shan_calendar'),
      useDeviceTimezone: _readBool(row, 'use_device_timezone'),
      sasanaYearType: _readInt(row, 'sasana_year_type'),
      calendarType: _readInt(row, 'calendar_type'),
      gregorianStart: _readInt(row, 'gregorian_start'),
      timezoneOffset: _readDouble(row, 'timezone_offset'),
      defaultLanguage: _readString(row, 'default_language'),
    );
  }

  String _readString(QueryRow row, String key) {
    final value = row.data[key];
    if (value is String) {
      return value;
    }
    return '$value';
  }

  int _readInt(QueryRow row, String key) {
    final value = row.data[key];
    if (value is int) {
      return value;
    }
    return int.tryParse('$value') ?? 0;
  }

  double _readDouble(QueryRow row, String key) {
    final value = row.data[key];
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    return double.tryParse('$value') ?? 0;
  }

  bool _readBool(QueryRow row, String key) {
    return _readString(row, key).toLowerCase() == 'true';
  }
}
