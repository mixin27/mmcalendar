import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

class AppSettingsEntity extends Equatable {
  final ThemeMode themeMode;
  final String themePreset;
  final ColorScheme? customColors;
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
  final bool enableAnalytics;
  final bool enableCrashlytics;
  final bool hasShownConsentDialog;
  final bool showShanCalendar;
  final bool useDeviceTimezone;

  const AppSettingsEntity({
    required this.themeMode,
    required this.themePreset,
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
    this.enableAnalytics = true,
    this.enableCrashlytics = true,
    this.hasShownConsentDialog = false,
    this.showShanCalendar = true,
    this.useDeviceTimezone = true,
  });

  AppSettingsEntity copyWith({
    ThemeMode? themeMode,
    String? themePreset,
    ColorScheme? customColors,
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
    bool? enableAnalytics,
    bool? enableCrashlytics,
    bool? hasShownConsentDialog,
    bool? showShanCalendar,
    bool? useDeviceTimezone,
  }) {
    return AppSettingsEntity(
      themeMode: themeMode ?? this.themeMode,
      themePreset: themePreset ?? this.themePreset,
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
      enableAnalytics: enableAnalytics ?? this.enableAnalytics,
      enableCrashlytics: enableCrashlytics ?? this.enableCrashlytics,
      hasShownConsentDialog:
          hasShownConsentDialog ?? this.hasShownConsentDialog,
      showShanCalendar: showShanCalendar ?? this.showShanCalendar,
      useDeviceTimezone: useDeviceTimezone ?? this.useDeviceTimezone,
    );
  }

  @override
  List<Object?> get props => [
    themeMode.index,
    themeMode,
    themePreset,
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
    enableAnalytics,
    enableCrashlytics,
    hasShownConsentDialog,
    showShanCalendar,
    useDeviceTimezone,
  ];
}
