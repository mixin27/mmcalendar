import 'package:equatable/equatable.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

import 'calendar_generation_mode.dart';
import 'calendar_preview_theme.dart';

class CalendarGenerationRequest extends Equatable {
  const CalendarGenerationRequest({
    required this.mode,
    required this.year,
    required this.language,
    required this.calendarConfig,
    required this.useDeviceTimezone,
    required this.showHolidays,
    required this.showAstrology,
    required this.showWesternDates,
    required this.showMyanmarDates,
    required this.firstDayOfWeek,
    required this.theme,
    this.month,
  });

  final CalendarGenerationMode mode;
  final int year;
  final int? month;
  final Language language;
  final CalendarConfig calendarConfig;
  final bool useDeviceTimezone;
  final bool showHolidays;
  final bool showAstrology;
  final bool showWesternDates;
  final bool showMyanmarDates;
  final int firstDayOfWeek;
  final CalendarPreviewTheme theme;

  CalendarGenerationRequest copyWith({
    CalendarGenerationMode? mode,
    int? year,
    int? month,
    Language? language,
    CalendarConfig? calendarConfig,
    bool? useDeviceTimezone,
    bool? showHolidays,
    bool? showAstrology,
    bool? showWesternDates,
    bool? showMyanmarDates,
    int? firstDayOfWeek,
    CalendarPreviewTheme? theme,
  }) {
    return CalendarGenerationRequest(
      mode: mode ?? this.mode,
      year: year ?? this.year,
      month: month ?? this.month,
      language: language ?? this.language,
      calendarConfig: calendarConfig ?? this.calendarConfig,
      useDeviceTimezone: useDeviceTimezone ?? this.useDeviceTimezone,
      showHolidays: showHolidays ?? this.showHolidays,
      showAstrology: showAstrology ?? this.showAstrology,
      showWesternDates: showWesternDates ?? this.showWesternDates,
      showMyanmarDates: showMyanmarDates ?? this.showMyanmarDates,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
      theme: theme ?? this.theme,
    );
  }

  @override
  List<Object?> get props => [
    mode,
    year,
    month,
    language,
    calendarConfig,
    useDeviceTimezone,
    showHolidays,
    showAstrology,
    showWesternDates,
    showMyanmarDates,
    firstDayOfWeek,
    theme,
  ];
}
