import 'package:equatable/equatable.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

import 'calendar_image_quality.dart';
import 'calendar_generation_mode.dart';
import 'calendar_landscape_decoration_area_side.dart';
import 'calendar_overlay_element.dart';
import 'calendar_page_orientation.dart';
import 'calendar_paper_size.dart';
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
    required this.paperSize,
    required this.pageOrientation,
    required this.imageQuality,
    this.landscapeDecorationAreaSide =
        CalendarLandscapeDecorationAreaSide.right,
    this.overlayElementsByMonth = const <int, List<CalendarOverlayElement>>{},
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
  final CalendarPaperSize paperSize;
  final CalendarPageOrientation pageOrientation;
  final CalendarLandscapeDecorationAreaSide landscapeDecorationAreaSide;
  final CalendarImageQuality imageQuality;
  final Map<int, List<CalendarOverlayElement>> overlayElementsByMonth;

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
    CalendarPaperSize? paperSize,
    CalendarPageOrientation? pageOrientation,
    CalendarLandscapeDecorationAreaSide? landscapeDecorationAreaSide,
    CalendarImageQuality? imageQuality,
    Map<int, List<CalendarOverlayElement>>? overlayElementsByMonth,
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
      paperSize: paperSize ?? this.paperSize,
      pageOrientation: pageOrientation ?? this.pageOrientation,
      landscapeDecorationAreaSide:
          landscapeDecorationAreaSide ?? this.landscapeDecorationAreaSide,
      imageQuality: imageQuality ?? this.imageQuality,
      overlayElementsByMonth:
          overlayElementsByMonth ?? this.overlayElementsByMonth,
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
    paperSize,
    pageOrientation,
    landscapeDecorationAreaSide,
    imageQuality,
    _overlayElementsSignature,
  ];

  Object? get _overlayElementsSignature {
    final entries = overlayElementsByMonth.entries.toList(growable: false)
      ..sort((left, right) => left.key.compareTo(right.key));
    final signatures = <Object>[];
    for (final entry in entries) {
      signatures.add(entry.key);
      signatures.add(Object.hashAll(entry.value));
    }
    return signatures;
  }
}
