import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_core/shared_core.dart'
    show CalendarGridStyle, CalendarGridTheme;
import 'package:shared_ui_kit/shared_ui_kit.dart' show AppStyle, CustomColors;

class AppSettingsEntity extends Equatable {
  final ThemeMode themeMode;
  final String themePreset;
  final AppStyle appStyle;
  final String appIcon;

  /// The person's own colours, used when [themePreset] is `custom`.
  final CustomColors? customColors;
  final String appLanguage;
  final Language calendarLanguage;
  final CalendarConfig calendarConfig;
  final bool showHolidays;
  final bool showAnniversaryDays;
  final bool showSabbaths;
  final bool showAstrology;
  final bool showWesternDates;
  final bool showMyanmarDates;
  final int firstDayOfWeek;
  final CalendarGridStyle calendarGridStyle;
  final CalendarGridTheme calendarGridTheme;
  final bool showGridMotif;
  final bool enableAnalytics;
  final bool enableCrashlytics;
  final bool hasShownConsentDialog;
  final bool showShanCalendar;

  /// Western dates in English digits whatever the calendar language.
  final bool englishWesternDigits;
  final bool useDeviceTimezone;

  const AppSettingsEntity({
    required this.themeMode,
    required this.themePreset,
    this.appStyle = AppStyle.automatic,
    this.appIcon = 'default',
    this.customColors,
    required this.appLanguage,
    required this.calendarLanguage,
    required this.calendarConfig,
    required this.showHolidays,
    required this.showAnniversaryDays,
    required this.showSabbaths,
    required this.showAstrology,
    required this.showWesternDates,
    required this.showMyanmarDates,
    required this.firstDayOfWeek,
    this.calendarGridStyle = CalendarGridStyle.defaultStyle,
    this.calendarGridTheme = CalendarGridTheme.defaultTheme,
    this.showGridMotif = true,
    this.enableAnalytics = true,
    this.enableCrashlytics = true,
    this.hasShownConsentDialog = false,
    this.showShanCalendar = true,
    this.englishWesternDigits = false,
    this.useDeviceTimezone = true,
  });

  AppSettingsEntity copyWith({
    ThemeMode? themeMode,
    String? themePreset,
    AppStyle? appStyle,
    String? appIcon,
    CustomColors? customColors,
    String? appLanguage,
    Language? calendarLanguage,
    CalendarConfig? calendarConfig,
    bool? showHolidays,
    bool? showAnniversaryDays,
    bool? showSabbaths,
    bool? showAstrology,
    bool? showWesternDates,
    bool? showMyanmarDates,
    int? firstDayOfWeek,
    CalendarGridStyle? calendarGridStyle,
    CalendarGridTheme? calendarGridTheme,
    bool? showGridMotif,
    bool? enableAnalytics,
    bool? enableCrashlytics,
    bool? hasShownConsentDialog,
    bool? showShanCalendar,
    bool? englishWesternDigits,
    bool? useDeviceTimezone,
  }) {
    return AppSettingsEntity(
      themeMode: themeMode ?? this.themeMode,
      themePreset: themePreset ?? this.themePreset,
      appStyle: appStyle ?? this.appStyle,
      appIcon: appIcon ?? this.appIcon,
      customColors: customColors ?? this.customColors,
      appLanguage: appLanguage ?? this.appLanguage,
      calendarLanguage: calendarLanguage ?? this.calendarLanguage,
      calendarConfig: calendarConfig ?? this.calendarConfig,
      showHolidays: showHolidays ?? this.showHolidays,
      showAnniversaryDays: showAnniversaryDays ?? this.showAnniversaryDays,
      showSabbaths: showSabbaths ?? this.showSabbaths,
      showAstrology: showAstrology ?? this.showAstrology,
      showWesternDates: showWesternDates ?? this.showWesternDates,
      showMyanmarDates: showMyanmarDates ?? this.showMyanmarDates,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
      calendarGridStyle: calendarGridStyle ?? this.calendarGridStyle,
      calendarGridTheme: calendarGridTheme ?? this.calendarGridTheme,
      showGridMotif: showGridMotif ?? this.showGridMotif,
      enableAnalytics: enableAnalytics ?? this.enableAnalytics,
      enableCrashlytics: enableCrashlytics ?? this.enableCrashlytics,
      hasShownConsentDialog:
          hasShownConsentDialog ?? this.hasShownConsentDialog,
      showShanCalendar: showShanCalendar ?? this.showShanCalendar,
      englishWesternDigits: englishWesternDigits ?? this.englishWesternDigits,
      useDeviceTimezone: useDeviceTimezone ?? this.useDeviceTimezone,
    );
  }

  @override
  List<Object?> get props => [
    themeMode.index,
    themeMode,
    themePreset,
    appStyle,
    appIcon,
    customColors,
    appLanguage,
    calendarLanguage,
    calendarConfig,
    showHolidays,
    showAnniversaryDays,
    showSabbaths,
    showAstrology,
    showWesternDates,
    showMyanmarDates,
    firstDayOfWeek,
    calendarGridStyle,
    calendarGridTheme,
    showGridMotif,
    enableAnalytics,
    enableCrashlytics,
    hasShownConsentDialog,
    showShanCalendar,
    englishWesternDigits,
    useDeviceTimezone,
  ];
}
