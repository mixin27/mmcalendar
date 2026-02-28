import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

enum MyanmarCalendarCacheProfile {
  highPerformance,
  memoryEfficient,
}

extension MyanmarCalendarCacheProfileX on MyanmarCalendarCacheProfile {
  CacheConfig get cacheConfig {
    switch (this) {
      case MyanmarCalendarCacheProfile.highPerformance:
        return const CacheConfig.highPerformance();
      case MyanmarCalendarCacheProfile.memoryEfficient:
        return const CacheConfig.memoryEfficient();
    }
  }
}

void applyMyanmarCalendarRuntimeConfig({
  required CalendarConfig baseConfig,
  Language? language,
  List<CustomHoliday> customHolidayRules = const <CustomHoliday>[],
  List<HolidayId>? disabledHolidays,
  Map<int, List<HolidayId>>? disabledHolidaysByYear,
  Map<String, List<HolidayId>>? disabledHolidaysByDate,
  MyanmarCalendarCacheProfile cacheProfile =
      MyanmarCalendarCacheProfile.highPerformance,
}) {
  final mergedCustomRules = <String, CustomHoliday>{
    for (final holiday in baseConfig.customHolidayRules) holiday.id: holiday,
    for (final holiday in customHolidayRules) holiday.id: holiday,
  }.values.toList(growable: false);

  final targetLanguage = language ?? Language.fromCode(baseConfig.defaultLanguage);

  MyanmarCalendar.configure(
    language: targetLanguage,
    timezoneOffset: baseConfig.timezoneOffset,
    sasanaYearType: baseConfig.sasanaYearType,
    calendarType: baseConfig.calendarType,
    gregorianStart: baseConfig.gregorianStart,
    customHolidayRules: mergedCustomRules,
    disabledHolidays: disabledHolidays ?? baseConfig.disabledHolidays,
    disabledHolidaysByYear:
        disabledHolidaysByYear ?? baseConfig.disabledHolidaysByYear,
    disabledHolidaysByDate:
        disabledHolidaysByDate ?? baseConfig.disabledHolidaysByDate,
  );

  MyanmarCalendar.configureCache(cacheProfile.cacheConfig);
}
