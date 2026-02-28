import 'package:equatable/equatable.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';

class CalendarDisplayConfig extends Equatable {
  const CalendarDisplayConfig({
    required this.calendarLanguage,
    required this.showHolidays,
    required this.showAnniversaryDays,
    required this.showSabbaths,
    required this.showAstrology,
    required this.showWesternDates,
    required this.showMyanmarDates,
    required this.showShanCalendar,
    required this.sasanaYearType,
    required this.calendarType,
    required this.gregorianStart,
    required this.timezoneOffset,
    required this.defaultLanguage,
  });

  factory CalendarDisplayConfig.defaults() {
    return const CalendarDisplayConfig(
      calendarLanguage: Language.myanmar,
      showHolidays: true,
      showAnniversaryDays: true,
      showSabbaths: true,
      showAstrology: false,
      showWesternDates: true,
      showMyanmarDates: true,
      showShanCalendar: true,
      sasanaYearType: 0,
      calendarType: 0,
      gregorianStart: 2361222,
      timezoneOffset: 6.5,
      defaultLanguage: 'en',
    );
  }

  final Language calendarLanguage;
  final bool showHolidays;
  final bool showAnniversaryDays;
  final bool showSabbaths;
  final bool showAstrology;
  final bool showWesternDates;
  final bool showMyanmarDates;
  final bool showShanCalendar;
  final int sasanaYearType;
  final int calendarType;
  final int gregorianStart;
  final double timezoneOffset;
  final String defaultLanguage;

  CalendarConfig get calendarConfig {
    return CalendarConfig(
      sasanaYearType: sasanaYearType,
      calendarType: calendarType,
      gregorianStart: gregorianStart,
      timezoneOffset: timezoneOffset,
      defaultLanguage: defaultLanguage,
    );
  }

  bool requiresCalendarRefreshComparedTo(CalendarDisplayConfig previous) {
    return calendarLanguage != previous.calendarLanguage ||
        sasanaYearType != previous.sasanaYearType ||
        calendarType != previous.calendarType ||
        gregorianStart != previous.gregorianStart ||
        timezoneOffset != previous.timezoneOffset ||
        defaultLanguage != previous.defaultLanguage;
  }

  @override
  List<Object?> get props => <Object?>[
    calendarLanguage,
    showHolidays,
    showAnniversaryDays,
    showSabbaths,
    showAstrology,
    showWesternDates,
    showMyanmarDates,
    showShanCalendar,
    sasanaYearType,
    calendarType,
    gregorianStart,
    timezoneOffset,
    defaultLanguage,
  ];
}

abstract interface class CalendarDisplayConfigPort {
  Future<CalendarDisplayConfig> getDisplayConfig();

  Stream<CalendarDisplayConfig> watchDisplayConfig();
}
