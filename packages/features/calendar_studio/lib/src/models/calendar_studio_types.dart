import 'dart:math' as math;
import 'dart:ui';

import 'package:equatable/equatable.dart';

/// The language of a project's calendar data. [both] is Myanmar with
/// English alongside; the others follow `myanmar_calendar_dart`'s languages.
enum CalendarStudioLanguage { myanmar, english, both, zawgyi, mon, shan, karen }

enum CalendarStudioPeriod { month, year }

enum CalendarStudioBlockType {
  calendarGrid,
  text,
  image,
  logo,
  eventList,
  holidayLegend,
  shape,
  decoration,
}

enum CalendarStudioExportFormat {
  pdf,

  /// Text, shapes and photos as editable artwork (Illustrator), not a
  /// picture of the page.
  pdfEditable,
  png,
  jpeg,
  zip;

  String get label => switch (this) {
    pdf => 'PDF',
    pdfEditable => 'Vector PDF',
    png => 'PNG',
    jpeg => 'JPEG',
    zip => 'ZIP',
  };

  bool get isPdf => this == pdf || this == pdfEditable;
}

enum CalendarStudioIssueSeverity { error, warning, tip }

/// Normalized geometry deliberately keeps documents resolution-independent.
class StudioRect extends Equatable {
  const StudioRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  }) : assert(left >= 0 && top >= 0 && width > 0 && height > 0);
  final double left;
  final double top;
  final double width;
  final double height;
  double get right => left + width;
  double get bottom => top + height;
  Rect resolve(Size size) => Rect.fromLTWH(
    left * size.width,
    top * size.height,
    width * size.width,
    height * size.height,
  );
  StudioRect copyWith({
    double? left,
    double? top,
    double? width,
    double? height,
  }) => StudioRect(
    left: left ?? this.left,
    top: top ?? this.top,
    width: width ?? this.width,
    height: height ?? this.height,
  );
  @override
  List<Object> get props => [left, top, width, height];
}

class StudioCanvas extends Equatable {
  const StudioCanvas({
    required this.width,
    required this.height,
    this.safeInset = .04,
    this.bleed = 0,
    this.backgroundColor = 0xFFFFFFFF,
  });
  final double width;
  final double height;
  final double safeInset;
  final double bleed;
  final int backgroundColor;
  double get aspectRatio => width / height;
  StudioCanvas copyWith({
    double? width,
    double? height,
    double? safeInset,
    double? bleed,
    int? backgroundColor,
  }) => StudioCanvas(
    width: width ?? this.width,
    height: height ?? this.height,
    safeInset: safeInset ?? this.safeInset,
    bleed: bleed ?? this.bleed,
    backgroundColor: backgroundColor ?? this.backgroundColor,
  );
  @override
  List<Object> get props => [width, height, safeInset, bleed, backgroundColor];
}

class CalendarStudioSource extends Equatable {
  const CalendarStudioSource({
    required this.year,
    this.month = 1,
    this.period = CalendarStudioPeriod.year,
    this.language = CalendarStudioLanguage.both,
    this.weekStartsMonday = false,
    this.timeZoneLabel = 'Myanmar Time (UTC+6:30)',
    this.showMyanmarDate = true,
    this.showMoonPhases = true,
    this.showHolidays = true,
    this.showAstrology = true,
    this.showEvents = true,
  });
  final int year;
  final int month;
  final CalendarStudioPeriod period;
  final CalendarStudioLanguage language;
  final bool weekStartsMonday;
  final String timeZoneLabel;
  final bool showMyanmarDate;
  final bool showMoonPhases;
  final bool showHolidays;
  final bool showAstrology;
  final bool showEvents;
  int get pageCount => period == CalendarStudioPeriod.year ? 12 : 1;
  CalendarStudioSource copyWith({
    int? year,
    int? month,
    CalendarStudioPeriod? period,
    CalendarStudioLanguage? language,
    bool? weekStartsMonday,
    String? timeZoneLabel,
    bool? showMyanmarDate,
    bool? showMoonPhases,
    bool? showHolidays,
    bool? showAstrology,
    bool? showEvents,
  }) => CalendarStudioSource(
    year: year ?? this.year,
    month: month ?? this.month,
    period: period ?? this.period,
    language: language ?? this.language,
    weekStartsMonday: weekStartsMonday ?? this.weekStartsMonday,
    timeZoneLabel: timeZoneLabel ?? this.timeZoneLabel,
    showMyanmarDate: showMyanmarDate ?? this.showMyanmarDate,
    showMoonPhases: showMoonPhases ?? this.showMoonPhases,
    showHolidays: showHolidays ?? this.showHolidays,
    showAstrology: showAstrology ?? this.showAstrology,
    showEvents: showEvents ?? this.showEvents,
  );
  @override
  List<Object> get props => [
    year,
    month,
    period,
    language,
    weekStartsMonday,
    timeZoneLabel,
    showMyanmarDate,
    showMoonPhases,
    showHolidays,
    showAstrology,
    showEvents,
  ];
}

class CalendarStudioExportPreset extends Equatable {
  const CalendarStudioExportPreset({
    required this.id,
    required this.label,
    required this.format,
    required this.dpi,
    required this.width,
    required this.height,
    this.fileName = 'my-calendar',
  });
  final String id;
  final String label;
  final CalendarStudioExportFormat format;
  final int dpi;
  final int width;
  final int height;
  final String fileName;
  CalendarStudioExportPreset copyWith({
    String? id,
    String? label,
    CalendarStudioExportFormat? format,
    int? dpi,
    int? width,
    int? height,
    String? fileName,
  }) => CalendarStudioExportPreset(
    id: id ?? this.id,
    label: label ?? this.label,
    format: format ?? this.format,
    dpi: dpi ?? this.dpi,
    width: width ?? this.width,
    height: height ?? this.height,
    fileName: fileName ?? this.fileName,
  );

  /// Whether this preset exports each page at the page's own size
  /// ([pagePdf], [pagePng]) rather than at [width] × [height].
  bool get matchesPage => id.startsWith('page-');

  /// The pixel size [canvas] exports at. A page-size preset follows the
  /// canvas: paper canvases are in millimetres and export at [dpi]; screen
  /// canvases (square, story) export at 1080 px on the short side. Other
  /// presets are always [width] × [height]; the page is fitted inside,
  /// never stretched.
  ({int width, int height}) pixelSizeFor(StudioCanvas canvas) {
    if (!matchesPage) return (width: width, height: height);
    final paper = math.max(canvas.width, canvas.height) <= 500;
    final scale = paper
        ? dpi / 25.4
        : 1080 / math.min(canvas.width, canvas.height);
    return (
      width: (canvas.width * scale).round(),
      height: (canvas.height * scale).round(),
    );
  }

  /// Each page at its own paper size, as a print PDF.
  static const pagePdf = CalendarStudioExportPreset(
    id: 'page-pdf',
    label: 'Page size print',
    format: CalendarStudioExportFormat.pdf,
    dpi: 300,
    width: 2480,
    height: 3508,
  );

  /// Each page at its own size, as PNG images.
  static const pagePng = CalendarStudioExportPreset(
    id: 'page-png',
    label: 'Page size image',
    format: CalendarStudioExportFormat.png,
    dpi: 300,
    width: 2480,
    height: 3508,
  );

  static const screenPng = CalendarStudioExportPreset(
    id: 'screen-png',
    label: 'Screen sharing',
    format: CalendarStudioExportFormat.png,
    dpi: 144,
    width: 1080,
    height: 1528,
  );
  static const a4Pdf = CalendarStudioExportPreset(
    id: 'a4-pdf',
    label: 'A4 print',
    format: CalendarStudioExportFormat.pdf,
    dpi: 300,
    width: 2480,
    height: 3508,
  );
  static const squarePng = CalendarStudioExportPreset(
    id: 'square-png',
    label: 'Square social',
    format: CalendarStudioExportFormat.png,
    dpi: 144,
    width: 1080,
    height: 1080,
  );
  static const storyPng = CalendarStudioExportPreset(
    id: 'story-png',
    label: 'Story',
    format: CalendarStudioExportFormat.png,
    dpi: 144,
    width: 1080,
    height: 1920,
  );
  static const highQualityPng = CalendarStudioExportPreset(
    id: 'high-quality-png',
    label: 'High quality',
    format: CalendarStudioExportFormat.png,
    dpi: 300,
    width: 2480,
    height: 3508,
  );
  static const a3Pdf = CalendarStudioExportPreset(
    id: 'a3-pdf',
    label: 'A3 print',
    format: CalendarStudioExportFormat.pdf,
    dpi: 300,
    width: 3508,
    height: 4961,
  );
  @override
  List<Object> get props => [id, label, format, dpi, width, height, fileName];
}
