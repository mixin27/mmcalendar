import 'package:equatable/equatable.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

/// How the month grid draws its days. Users pick it in Settings › Display.
enum CalendarGridStyle {
  /// Everything about a day in its cell: lunar day and moon, holiday,
  /// events, and a strip for Sabbath and good or careful days. Where a
  /// Myanmar month begins, a rule and the month's name.
  almanac,

  /// Each Myanmar month as a tinted region of the Western grid, named
  /// where it begins.
  monthRegions,

  /// A compact month whose selected week opens to show the day's
  /// details.
  focusWeek,

  /// Each day tinted by how it reads astrologically: good days green,
  /// days to be careful on striped, Sabbath outlined.
  auspice,

  /// Calm days with the moon as a band under each week, brightest at the
  /// full moon.
  moonBand,

  /// The selected day (or today) as a large card above a quiet month.
  heroToday,

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

  /// What a new install shows. Installs from before Almanac keep Detailed
  /// (the database stores it for them when it upgrades to version 7).
  static const defaultStyle = CalendarGridStyle.almanac;

  static CalendarGridStyle fromName(String? name) => values.firstWhere(
    (style) => style.name == name,
    orElse: () => defaultStyle,
  );
}

/// A look for the home calendar's header, weekday row and grid: paper,
/// ink, accent, number typeface and a small motif. Independent of the
/// [CalendarGridStyle] layout. [app] keeps the app's own colours.
enum CalendarGridTheme {
  app,
  pagoda,
  jade,
  lacquer,
  thadingyut,
  thingyan,
  botanical,
  monsoon,
  tidewater,
  morningPour,
  deepField,
  moonlight,
  nightChart;

  static const defaultTheme = CalendarGridTheme.app;

  static CalendarGridTheme fromName(String? name) => values.firstWhere(
    (theme) => theme.name == name,
    orElse: () => defaultTheme,
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
    this.gridTheme = CalendarGridTheme.defaultTheme,
    this.showGridMotif = true,
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
  final CalendarGridTheme gridTheme;

  /// Whether a theme's motif shows in the header corner.
  final bool showGridMotif;

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
    gridTheme,
    showGridMotif,
  ];
}

abstract interface class CalendarDisplayConfigPort {
  Future<CalendarDisplayConfig> getDisplayConfig();

  Stream<CalendarDisplayConfig> watchDisplayConfig();
}
