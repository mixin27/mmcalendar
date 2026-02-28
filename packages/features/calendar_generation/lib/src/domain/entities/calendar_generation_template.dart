import 'package:equatable/equatable.dart';

import 'calendar_generation_mode.dart';
import 'calendar_image_quality.dart';
import 'calendar_page_orientation.dart';
import 'calendar_paper_size.dart';
import 'calendar_preview_theme.dart';

class CalendarGenerationTemplate extends Equatable {
  const CalendarGenerationTemplate({
    required this.id,
    required this.name,
    required this.mode,
    required this.showHolidays,
    required this.showAstrology,
    required this.showWesternDates,
    required this.showMyanmarDates,
    required this.firstDayOfWeek,
    required this.paperSize,
    required this.pageOrientation,
    required this.imageQuality,
    required this.theme,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final CalendarGenerationMode mode;
  final bool showHolidays;
  final bool showAstrology;
  final bool showWesternDates;
  final bool showMyanmarDates;
  final int firstDayOfWeek;
  final CalendarPaperSize paperSize;
  final CalendarPageOrientation pageOrientation;
  final CalendarImageQuality imageQuality;
  final CalendarPreviewTheme theme;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    id,
    name,
    mode,
    showHolidays,
    showAstrology,
    showWesternDates,
    showMyanmarDates,
    firstDayOfWeek,
    paperSize,
    pageOrientation,
    imageQuality,
    theme,
    updatedAt,
  ];
}
