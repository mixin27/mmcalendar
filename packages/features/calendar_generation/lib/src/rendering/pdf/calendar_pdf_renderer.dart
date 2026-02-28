import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/entities/calendar_generation_request.dart';
import '../../domain/entities/calendar_page_model.dart';
import '../../domain/entities/calendar_preview_theme.dart';
import '../export/background_image_loader.dart';
import '../export/calendar_export_layout.dart';

class CalendarPdfRenderer {
  CalendarPdfRenderer(this._backgroundImageLoader);

  final BackgroundImageLoader _backgroundImageLoader;

  Future<Uint8List> renderFromImages({
    required CalendarGenerationRequest request,
    required List<Uint8List> pageImages,
  }) async {
    final document = pw.Document();
    final pageFormat = CalendarExportLayout.resolvePdfPageFormat(request);
    var addedPages = 0;

    for (final bytes in pageImages) {
      pw.MemoryImage? memoryImage;
      try {
        memoryImage = pw.MemoryImage(bytes);
      } catch (_) {
        continue;
      }

      document.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.zero,
          build: (context) => pw.Container(
            width: double.infinity,
            height: double.infinity,
            child: pw.Image(memoryImage!, fit: pw.BoxFit.fill),
          ),
        ),
      );
      addedPages += 1;
    }

    if (addedPages == 0) {
      throw StateError('No printable page image could be generated for PDF');
    }

    return document.save();
  }

  Future<Uint8List> render({
    required CalendarGenerationRequest request,
    required List<CalendarPageModel> pages,
  }) async {
    final pdfPageFormat = CalendarExportLayout.resolvePdfPageFormat(request);
    final regularFont = await _loadFont(
      'assets/fonts/google_fonts/NotoSansMyanmar-Regular.ttf',
      fallback: pw.Font.helvetica(),
    );
    final boldFont = await _loadFont(
      'assets/fonts/google_fonts/NotoSansMyanmar-Bold.ttf',
      fallback: pw.Font.helveticaBold(),
    );
    final backgroundImagesByMonth = <int, pw.MemoryImage?>{};
    for (final page in pages) {
      if (backgroundImagesByMonth.containsKey(page.month)) {
        continue;
      }
      final url = request.theme.backgroundImageUrlForMonth(page.month);
      final imageBytes = await _backgroundImageLoader.loadBytes(url);
      final normalizedBytes = await _normalizePdfBackground(imageBytes);
      if (normalizedBytes == null) {
        backgroundImagesByMonth[page.month] = null;
        continue;
      }
      try {
        backgroundImagesByMonth[page.month] = pw.MemoryImage(normalizedBytes);
      } catch (_) {
        backgroundImagesByMonth[page.month] = null;
      }
    }

    final document = pw.Document();

    for (final page in pages) {
      document.addPage(
        pw.Page(
          pageFormat: pdfPageFormat,
          margin: const pw.EdgeInsets.all(18),
          build: (context) => _buildPage(
            request: request,
            page: page,
            regularFont: regularFont,
            boldFont: boldFont,
            backgroundImage: backgroundImagesByMonth[page.month],
          ),
        ),
      );
    }

    return document.save();
  }

  Future<pw.Font> _loadFont(
    String assetPath, {
    required pw.Font fallback,
  }) async {
    try {
      final data = await rootBundle.load(assetPath);
      return pw.Font.ttf(data);
    } catch (_) {
      return fallback;
    }
  }

  Future<Uint8List?> _normalizePdfBackground(Uint8List? rawBytes) async {
    if (rawBytes == null || rawBytes.isEmpty) {
      return null;
    }
    try {
      final codec = await ui.instantiateImageCodec(rawBytes);
      final frame = await codec.getNextFrame();
      final pngData = await frame.image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      frame.image.dispose();
      return pngData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  pw.Widget _buildPage({
    required CalendarGenerationRequest request,
    required CalendarPageModel page,
    required pw.Font regularFont,
    required pw.Font boldFont,
    pw.ImageProvider? backgroundImage,
  }) {
    final backgroundColor = _fromArgb(request.theme.backgroundColorValue);
    final foregroundColor = _fromArgb(request.theme.foregroundColorValue);
    final accentColor = _fromArgb(request.theme.accentColorValue);

    return pw.Container(
      width: double.infinity,
      height: double.infinity,
      decoration: pw.BoxDecoration(color: backgroundColor),
      child: pw.Stack(
        children: [
          if (backgroundImage != null)
            pw.Positioned.fill(
              child: pw.Opacity(
                opacity: request.theme.backgroundImageOpacity.clamp(0.0, 1.0),
                child: pw.Image(
                  backgroundImage,
                  fit: _toPdfFit(request.theme.backgroundImageFit),
                  alignment: _toPdfAlignment(
                    request.theme.backgroundImageAlignment,
                  ),
                ),
              ),
            ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(12),
            child: pw.LayoutBuilder(
              builder: (context, constraints) {
                const gridTopSpacing = 8.0;
                const headerHeight = 50.0;
                const weekdayHeight = 18.0;
                final gridHeight =
                    constraints!.maxHeight -
                    headerHeight -
                    weekdayHeight -
                    gridTopSpacing;
                final rowHeight = gridHeight / 6;

                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.Container(
                      height: headerHeight,
                      child: pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text(
                            page.westernTitle,
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 20,
                              color: foregroundColor,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                          if (page.myanmarTitle.trim().isNotEmpty)
                            pw.Text(
                              page.myanmarTitle,
                              style: pw.TextStyle(
                                font: regularFont,
                                fontSize: 10.5,
                                color: _withAlpha(foregroundColor, 0.82),
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                        ],
                      ),
                    ),
                    _buildWeekdayHeader(
                      labels: page.weekdayLabels,
                      regularFont: regularFont,
                      color: _withAlpha(foregroundColor, 0.9),
                      height: weekdayHeight,
                    ),
                    pw.SizedBox(height: gridTopSpacing),
                    _buildDayGrid(
                      request: request,
                      page: page,
                      regularFont: regularFont,
                      boldFont: boldFont,
                      foregroundColor: foregroundColor,
                      holidayColor: const PdfColor.fromInt(0xFFC62828),
                      accentColor: accentColor,
                      backgroundColor: backgroundColor,
                      rowHeight: rowHeight,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildWeekdayHeader({
    required List<String> labels,
    required pw.Font regularFont,
    required PdfColor color,
    required double height,
  }) {
    return pw.Container(
      height: height,
      child: pw.Row(
        children: labels
            .map(
              (label) => pw.Expanded(
                child: pw.Text(
                  label,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 10,
                    color: color,
                  ),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  pw.Widget _buildDayGrid({
    required CalendarGenerationRequest request,
    required CalendarPageModel page,
    required pw.Font regularFont,
    required pw.Font boldFont,
    required PdfColor foregroundColor,
    required PdfColor holidayColor,
    required PdfColor accentColor,
    required PdfColor backgroundColor,
    required double rowHeight,
  }) {
    final rows = List<pw.TableRow>.generate(6, (rowIndex) {
      return pw.TableRow(
        children: List<pw.Widget>.generate(7, (colIndex) {
          final day = page.dayCells[(rowIndex * 7) + colIndex];
          if (day.isPlaceholder) {
            return pw.Container(height: rowHeight);
          }
          final astroBadges = request.showAstrology
              ? _collectAstroBadges(day)
              : const <_PdfAstroBadge>[];
          final dayTextColor = day.hasPublicHoliday
              ? holidayColor
              : foregroundColor;
          final moonPhaseColor = day.hasPublicHoliday
              ? holidayColor
              : day.isFullMoon
              ? const PdfColor.fromInt(0xFFB45309)
              : day.isNewMoon
              ? const PdfColor.fromInt(0xFF4338CA)
              : dayTextColor;
          final moonBaseColor = _withAlpha(foregroundColor, 0.18);
          final moonBorderColor = _withAlpha(foregroundColor, 0.48);
          final westernFontSize = (rowHeight * 0.40).clamp(15.0, 30.0);
          final myanmarFontSize = (rowHeight * 0.10).clamp(7.0, 10.0);

          final cellBorderColor = day.isToday
              ? accentColor
              : _withAlpha(foregroundColor, 0.15);

          return pw.Container(
            height: rowHeight,
            padding: const pw.EdgeInsets.all(4),
            decoration: pw.BoxDecoration(
              color: _withAlpha(backgroundColor, 0.92),
              border: pw.Border.all(
                color: cellBorderColor,
                width: day.isToday ? 1.1 : 0.55,
              ),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
            ),
            child: pw.Stack(
              children: [
                if (request.showWesternDates)
                  pw.Positioned.fill(
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 10),
                      child: pw.Align(
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          day.westernDayLabel,
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: westernFontSize.toDouble(),
                            color: _withAlpha(dayTextColor, 0.97),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (request.showMyanmarDates)
                  pw.Positioned(
                    left: 0,
                    top: 0,
                    child: _buildMoonIndicator(
                      day: day,
                      regularFont: regularFont,
                      moonPhaseColor: moonPhaseColor,
                      darkColor: moonBaseColor,
                      borderColor: moonBorderColor,
                    ),
                  ),
                if (request.showMyanmarDates)
                  pw.Positioned(
                    right: 0,
                    top: 0,
                    child: pw.Text(
                      day.myanmarDayLabel,
                      style: pw.TextStyle(
                        font: regularFont,
                        fontSize: myanmarFontSize.toDouble(),
                        fontWeight: day.isFullMoon || day.isNewMoon
                            ? pw.FontWeight.bold
                            : pw.FontWeight.normal,
                        color: _withAlpha(moonPhaseColor, 0.82),
                      ),
                    ),
                  ),
                if (astroBadges.isNotEmpty)
                  pw.Positioned(
                    left: 0,
                    bottom: 0,
                    right: 0,
                    child: _buildAstroBadges(
                      badges: astroBadges,
                      regularFont: regularFont,
                    ),
                  ),
              ],
            ),
          );
        }, growable: false),
      );
    }, growable: false);

    return pw.Table(
      children: rows,
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: pw.FlexColumnWidth(),
        1: pw.FlexColumnWidth(),
        2: pw.FlexColumnWidth(),
        3: pw.FlexColumnWidth(),
        4: pw.FlexColumnWidth(),
        5: pw.FlexColumnWidth(),
        6: pw.FlexColumnWidth(),
      },
    );
  }

  pw.Widget _buildMoonIndicator({
    required CalendarDayCellModel day,
    required pw.Font regularFont,
    required PdfColor moonPhaseColor,
    required PdfColor darkColor,
    required PdfColor borderColor,
  }) {
    final symbol = _moonPhaseSymbol(day.moonPhase);
    final symbolColor = day.isNewMoon ? darkColor : moonPhaseColor;

    return pw.Container(
      width: 12,
      height: 12,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        color: _withAlpha(darkColor, 0.25),
        border: pw.Border.all(color: borderColor, width: 0.5),
        shape: pw.BoxShape.circle,
      ),
      child: pw.Text(
        symbol,
        style: pw.TextStyle(
          font: regularFont,
          fontSize: 6.6,
          fontWeight: pw.FontWeight.bold,
          color: _withAlpha(symbolColor, 0.96),
        ),
      ),
    );
  }

  pw.Widget _buildAstroBadges({
    required List<_PdfAstroBadge> badges,
    required pw.Font regularFont,
  }) {
    if (badges.isEmpty) {
      return pw.SizedBox.shrink();
    }

    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 1),
      child: pw.Wrap(
        alignment: pw.WrapAlignment.center,
        spacing: 1.5,
        runSpacing: 1.5,
        children: badges
            .take(6)
            .map(
              (badge) => pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 2,
                  vertical: 1,
                ),
                decoration: pw.BoxDecoration(
                  color: _withAlpha(badge.color, 0.22),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(2),
                  ),
                ),
                child: pw.Text(
                  badge.code,
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 4.9,
                    fontWeight: pw.FontWeight.bold,
                    color: _withAlpha(badge.color, 0.94),
                  ),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  List<_PdfAstroBadge> _collectAstroBadges(CalendarDayCellModel day) {
    return <_PdfAstroBadge>[
      if (day.sabbathLabel?.trim().isNotEmpty ?? false)
        const _PdfAstroBadge('S', PdfColor.fromInt(0xFFF59E0B)),
      if (day.sabbathEveLabel?.trim().isNotEmpty ?? false)
        const _PdfAstroBadge('SE', PdfColor.fromInt(0xFFD97706)),
      if (day.yatyazaLabel?.trim().isNotEmpty ?? false)
        const _PdfAstroBadge('Y', PdfColor.fromInt(0xFF7E22CE)),
      if (day.pyathadaLabel?.trim().isNotEmpty ?? false)
        const _PdfAstroBadge('P', PdfColor.fromInt(0xFF4F46E5)),
      if (day.afternoonPyathadaLabel?.trim().isNotEmpty ?? false)
        const _PdfAstroBadge('AP', PdfColor.fromInt(0xFFEA580C)),
      if (day.otherAstrologyLabel?.trim().isNotEmpty ?? false)
        const _PdfAstroBadge('+', PdfColor.fromInt(0xFF64748B)),
    ];
  }

  String _moonPhaseSymbol(int moonPhase) {
    return switch (moonPhase % 4) {
      1 => '●', // full moon
      2 => '◐', // waning
      3 => '○', // new moon
      _ => '◑', // waxing
    };
  }

  PdfColor _fromArgb(int argb) {
    final alpha = ((argb >> 24) & 0xFF) / 255;
    final red = ((argb >> 16) & 0xFF) / 255;
    final green = ((argb >> 8) & 0xFF) / 255;
    final blue = (argb & 0xFF) / 255;
    return PdfColor(red, green, blue, alpha);
  }

  PdfColor _withAlpha(PdfColor color, double opacity) {
    final nextOpacity = opacity.clamp(0.0, 1.0).toDouble();
    return PdfColor(color.red, color.green, color.blue, nextOpacity);
  }

  pw.BoxFit _toPdfFit(CalendarBackgroundImageFit fit) {
    return switch (fit) {
      CalendarBackgroundImageFit.cover => pw.BoxFit.cover,
      CalendarBackgroundImageFit.contain => pw.BoxFit.contain,
      CalendarBackgroundImageFit.fill => pw.BoxFit.fill,
    };
  }

  pw.Alignment _toPdfAlignment(CalendarBackgroundImageAlignment alignment) {
    return switch (alignment) {
      CalendarBackgroundImageAlignment.top => pw.Alignment.topCenter,
      CalendarBackgroundImageAlignment.center => pw.Alignment.center,
      CalendarBackgroundImageAlignment.bottom => pw.Alignment.bottomCenter,
    };
  }
}

class _PdfAstroBadge {
  const _PdfAstroBadge(this.code, this.color);

  final String code;
  final PdfColor color;
}
