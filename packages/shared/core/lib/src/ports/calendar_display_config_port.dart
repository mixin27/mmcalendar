import 'package:equatable/equatable.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

/// How the month grid draws its days. Users pick it in Settings › Display.
enum CalendarGridStyle {
  /// Ruled cells with the lunar day, holiday name, moon and events.
  detailed,

  /// Calm, numbers first; the moon only on full and new moon days.
  clean,

  /// The original bordered tiles with coloured dots.
  classic,

  /// A calmer detailed cell: no ruling, the moon only on moon days.
  detailedV2,

  /// The lunar day as the big figure, the Gregorian date in the corner.
  lunarFirst,

  /// The date and one status dot.
  minimal,

  /// Tonight's moon in every day.
  moonStrip,

  /// Event titles and holiday chips inside the cells.
  agenda,

  /// A ruled table like a printed wall calendar.
  classicPrint,

  /// Every day a small card; holidays rose, Sabbath days gold.
  tiles,

  /// Each day glows with the moon, brightest at the full moon.
  moonlight,

  /// The date and the lunar day divided by a diagonal.
  split,

  /// Big bold numbers with a coloured bar for special days.
  poster,

  /// A ring around each date that fills with the moon's light.
  moonRing,

  /// Astrological days and holidays as tags.
  astrology;

  static const defaultStyle = CalendarGridStyle.detailed;

  static CalendarGridStyle fromName(String? name) => values.firstWhere(
    (style) => style.name == name,
    orElse: () => defaultStyle,
  );
}

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
    required this.useDeviceTimezone,
    required this.sasanaYearType,
    required this.calendarType,
    required this.gregorianStart,
    required this.timezoneOffset,
    required this.defaultLanguage,
    this.gridStyle = CalendarGridStyle.defaultStyle,
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
      useDeviceTimezone: true,
      sasanaYearType: 0,
      calendarType: 0,
      gregorianStart: 2361222,
      timezoneOffset: 6.5,
      defaultLanguage: 'en',
      gridStyle: CalendarGridStyle.defaultStyle,
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
  final bool useDeviceTimezone;
  final int sasanaYearType;
  final int calendarType;
  final int gregorianStart;
  final double timezoneOffset;
  final String defaultLanguage;
  final CalendarGridStyle gridStyle;

  CalendarConfig get calendarConfig {
    return CalendarConfig(
      sasanaYearType: sasanaYearType,
      calendarType: 0,
      gregorianStart: gregorianStart,
      timezoneOffset: timezoneOffset,
      defaultLanguage: defaultLanguage,
    );
  }

  bool requiresCalendarRefreshComparedTo(CalendarDisplayConfig previous) {
    return calendarLanguage != previous.calendarLanguage ||
        useDeviceTimezone != previous.useDeviceTimezone ||
        sasanaYearType != previous.sasanaYearType ||
        gregorianStart != previous.gregorianStart ||
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
    useDeviceTimezone,
    sasanaYearType,
    calendarType,
    gregorianStart,
    timezoneOffset,
    defaultLanguage,
    gridStyle,
  ];
}

abstract interface class CalendarDisplayConfigPort {
  Future<CalendarDisplayConfig> getDisplayConfig();

  Stream<CalendarDisplayConfig> watchDisplayConfig();
}
