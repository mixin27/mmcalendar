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
    );
  }

  @override
  List<Object?> get props => [
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
  ];
}
