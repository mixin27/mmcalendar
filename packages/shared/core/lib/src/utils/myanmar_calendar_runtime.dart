import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

enum MyanmarCalendarCacheProfile { highPerformance, memoryEfficient }

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

const double kMyanmarTimezoneOffset = 6.5;

double getDeviceTimezoneOffsetHours() {
  final offset = DateTime.now().timeZoneOffset;
  return offset.inMinutes / 60.0;
}

void applyMyanmarCalendarRuntimeConfig({
  required CalendarConfig baseConfig,
  Language? language,
  List<CustomHoliday> customHolidayRules = const <CustomHoliday>[],
  List<HolidayId>? disabledHolidays,
  Map<int, List<HolidayId>>? disabledHolidaysByYear,
  Map<String, List<HolidayId>>? disabledHolidaysByDate,
  bool useDeviceTimezone = true,
  bool lockCalendarTypeToBritish = true,
  MyanmarCalendarCacheProfile cacheProfile =
      MyanmarCalendarCacheProfile.highPerformance,
}) {
  final mergedCustomRules = <String, CustomHoliday>{
    for (final holiday in baseConfig.customHolidayRules) holiday.id: holiday,
    for (final holiday in customHolidayRules) holiday.id: holiday,
  }.values.toList(growable: false);

  final targetLanguage =
      language ?? Language.fromCode(baseConfig.defaultLanguage);
  final effectiveTimezoneOffset = useDeviceTimezone
      ? getDeviceTimezoneOffsetHours()
      : kMyanmarTimezoneOffset;
  final effectiveCalendarType = lockCalendarTypeToBritish
      ? 0
      : baseConfig.calendarType;

  MyanmarCalendar.configure(
    language: targetLanguage,
    timezoneOffset: effectiveTimezoneOffset,
    sasanaYearType: baseConfig.sasanaYearType,
    calendarType: effectiveCalendarType,
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
