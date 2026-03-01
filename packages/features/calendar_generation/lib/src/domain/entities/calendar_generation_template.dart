import 'package:equatable/equatable.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

import 'calendar_export_tuning.dart';
import 'calendar_generation_mode.dart';
import 'calendar_image_quality.dart';
import 'calendar_landscape_decoration_area_side.dart';
import 'calendar_page_orientation.dart';
import 'calendar_paper_size.dart';
import 'calendar_preview_theme.dart';

class CalendarGenerationTemplate extends Equatable {
  const CalendarGenerationTemplate({
    required this.id,
    required this.name,
    required this.language,
    required this.mode,
    required this.showHolidays,
    required this.showAstrology,
    required this.showWesternDates,
    required this.showMyanmarDates,
    required this.firstDayOfWeek,
    required this.paperSize,
    required this.pageOrientation,
    required this.landscapeDecorationAreaSide,
    required this.imageQuality,
    required this.exportTuning,
    required this.theme,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final Language language;
  final CalendarGenerationMode mode;
  final bool showHolidays;
  final bool showAstrology;
  final bool showWesternDates;
  final bool showMyanmarDates;
  final int firstDayOfWeek;
  final CalendarPaperSize paperSize;
  final CalendarPageOrientation pageOrientation;
  final CalendarLandscapeDecorationAreaSide landscapeDecorationAreaSide;
  final CalendarImageQuality imageQuality;
  final CalendarExportTuning exportTuning;
  final CalendarPreviewTheme theme;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    id,
    name,
    language,
    mode,
    showHolidays,
    showAstrology,
    showWesternDates,
    showMyanmarDates,
    firstDayOfWeek,
    paperSize,
    pageOrientation,
    landscapeDecorationAreaSide,
    imageQuality,
    exportTuning,
    theme,
    updatedAt,
  ];
}
