import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';

class AppSettingsEntity extends Equatable {
  final ThemeMode themeMode;
  final String themePreset;
  final ColorScheme? customColors;
  final String appLanguage;
  final Language calendarLanguage;
  final CalendarConfig calendarConfig;
  final bool showHolidays;
  final bool showAstrology;
  final bool showWesternDates;
  final bool showMyanmarDates;
  final int firstDayOfWeek;
  final bool enableAnalytics;
  final bool enableCrashlytics;
  final bool hasShownConsentDialog;

  const AppSettingsEntity({
    required this.themeMode,
    required this.themePreset,
    this.customColors,
    required this.appLanguage,
    required this.calendarLanguage,
    required this.calendarConfig,
    required this.showHolidays,
    required this.showAstrology,
    required this.showWesternDates,
    required this.showMyanmarDates,
    required this.firstDayOfWeek,
    this.enableAnalytics = true,
    this.enableCrashlytics = true,
    this.hasShownConsentDialog = false,
  });

  AppSettingsEntity copyWith({
    ThemeMode? themeMode,
    String? themePreset,
    ColorScheme? customColors,
    String? appLanguage,
    Language? calendarLanguage,
    CalendarConfig? calendarConfig,
    bool? showHolidays,
    bool? showAstrology,
    bool? showWesternDates,
    bool? showMyanmarDates,
    int? firstDayOfWeek,
    bool? enableAnalytics,
    bool? enableCrashlytics,
    bool? hasShownConsentDialog,
  }) {
    return AppSettingsEntity(
      themeMode: themeMode ?? this.themeMode,
      themePreset: themePreset ?? this.themePreset,
      customColors: customColors ?? this.customColors,
      appLanguage: appLanguage ?? this.appLanguage,
      calendarLanguage: calendarLanguage ?? this.calendarLanguage,
      calendarConfig: calendarConfig ?? this.calendarConfig,
      showHolidays: showHolidays ?? this.showHolidays,
      showAstrology: showAstrology ?? this.showAstrology,
      showWesternDates: showWesternDates ?? this.showWesternDates,
      showMyanmarDates: showMyanmarDates ?? this.showMyanmarDates,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
      enableAnalytics: enableAnalytics ?? this.enableAnalytics,
      enableCrashlytics: enableCrashlytics ?? this.enableCrashlytics,
      hasShownConsentDialog:
          hasShownConsentDialog ?? this.hasShownConsentDialog,
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
    showAstrology,
    showWesternDates,
    showMyanmarDates,
    firstDayOfWeek,
    enableAnalytics,
    enableCrashlytics,
    hasShownConsentDialog,
  ];
}
