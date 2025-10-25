import 'package:core/core.dart';
import 'package:data/data.dart';
import 'package:drift/drift.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';

// Local data source for calendar operations
abstract class CalendarLocalDataSource {
  Future<List<CompleteDate>> getMonthDates(DateTime month);
  Future<List<CompleteDate>> getCalendarGridDates(DateTime month);
  Future<CompleteDate> getDateDetails(DateTime date);
  Future<CalendarConfig> getCalendarConfig();
  Future<void> updateCalendarConfig(CalendarConfig config);
  Future<bool> isAstrologyExpanded();
  Future<void> setAstrologyExpanded(bool isExpanded);
}

class CalendarLocalDataSourceImpl implements CalendarLocalDataSource {
  final AppDatabase database;

  CalendarLocalDataSourceImpl(this.database);

  @override
  Future<List<CompleteDate>> getMonthDates(DateTime month) async {
    try {
      final firstDay = DateTime(month.year, month.month, 1);
      final lastDay = DateTime(month.year, month.month + 1, 0);

      final dates = <CompleteDate>[];

      for (int day = firstDay.day; day <= lastDay.day; day++) {
        final date = DateTime(month.year, month.month, day);
        final completeDate = MyanmarCalendar.getCompleteDate(date);
        dates.add(completeDate);
      }

      return dates;
    } catch (e) {
      throw CacheException('Failed to get month dates: ${e.toString()}');
    }
  }

  @override
  Future<List<CompleteDate>> getCalendarGridDates(DateTime month) async {
    try {
      // Get dates including previous/next month for calendar grid
      final gridDates = AppDateUtils.getCalendarGridDates(
        month,
        firstDayOfWeek: 1, // Sunday in Myanmar weekday system
      );

      final completeDates = <CompleteDate>[];

      for (final date in gridDates) {
        final completeDate = MyanmarCalendar.getCompleteDate(date);
        completeDates.add(completeDate);
      }

      return completeDates;
    } catch (e) {
      throw CacheException(
        'Failed to get calendar grid dates: ${e.toString()}',
      );
    }
  }

  @override
  Future<CompleteDate> getDateDetails(DateTime date) async {
    try {
      return MyanmarCalendar.getCompleteDate(date);
    } catch (e) {
      throw CacheException('Failed to get date details: ${e.toString()}');
    }
  }

  @override
  Future<CalendarConfig> getCalendarConfig() async {
    try {
      final settings = await database.calendarDao.getOrCreateSettings();

      return CalendarConfig(
        sasanaYearType: settings.sasanaYearType,
        calendarType: settings.calendarType,
        gregorianStart: settings.gregorianStart,
        timezoneOffset: settings.timezoneOffset,
        defaultLanguage: settings.defaultLanguage,
      );
    } catch (e) {
      throw CacheException('Failed to get calendar config: ${e.toString()}');
    }
  }

  @override
  Future<void> updateCalendarConfig(CalendarConfig config) async {
    try {
      await database.calendarDao.updateSettings(
        CalendarSettingsCompanion(
          sasanaYearType: Value(config.sasanaYearType),
          calendarType: Value(config.calendarType),
          gregorianStart: Value(config.gregorianStart),
          timezoneOffset: Value(config.timezoneOffset),
          defaultLanguage: Value(config.defaultLanguage),
          updatedAt: Value(DateTime.now()),
        ),
      );

      // Apply to Myanmar Calendar package
      MyanmarCalendar.configure(
        language: Language.fromCode(config.defaultLanguage),
        timezoneOffset: config.timezoneOffset,
        sasanaYearType: config.sasanaYearType,
        calendarType: config.calendarType,
        gregorianStart: config.gregorianStart,
      );

      MyanmarCalendar.clearCache();
      MyanmarCalendar.configureCache(const CacheConfig.memoryEfficient());
    } catch (e) {
      throw CacheException('Failed to update calendar config: ${e.toString()}');
    }
  }

  @override
  Future<bool> isAstrologyExpanded() async {
    try {
      final value = await database.settingsDao.getBoolSetting(
        StorageKeys.astrologyCardExpanded,
      );
      return value ?? false;
    } catch (e) {
      throw CacheException('Failed to get astrology state: ${e.toString()}');
    }
  }

  @override
  Future<void> setAstrologyExpanded(bool isExpanded) async {
    try {
      await database.settingsDao.setBoolSetting(
        StorageKeys.astrologyCardExpanded,
        isExpanded,
      );
    } catch (e) {
      throw CacheException('Failed to set astrology state: ${e.toString()}');
    }
  }
}
