import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/entities/calendar_generation_request.dart';
import '../../domain/entities/calendar_page_model.dart';
import '../export/background_image_loader.dart';
import '../export/calendar_export_layout.dart';

class CalendarPdfRenderer {
  CalendarPdfRenderer(this._backgroundImageLoader);

  final BackgroundImageLoader _backgroundImageLoader;

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
      backgroundImagesByMonth[page.month] = imageBytes == null
          ? null
          : pw.MemoryImage(imageBytes);
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
                opacity: 0.18,
                child: pw.Image(backgroundImage, fit: pw.BoxFit.cover),
              ),
            ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(12),
            child: pw.LayoutBuilder(
              builder: (context, constraints) {
                const gridTopSpacing = 8.0;
                const headerHeight = 32.0;
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
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        page.title,
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 20,
                          color: foregroundColor,
                        ),
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
    required PdfColor accentColor,
    required PdfColor backgroundColor,
    required double rowHeight,
  }) {
    final rows = List<pw.TableRow>.generate(6, (rowIndex) {
      return pw.TableRow(
        children: List<pw.Widget>.generate(7, (colIndex) {
          final day = page.dayCells[(rowIndex * 7) + colIndex];
          final hasMarker =
              (request.showHolidays && day.hasHoliday) ||
              (request.showAstrology && day.hasAstrology);

          final cellColor = day.isCurrentMonth
              ? _withAlpha(backgroundColor, 0.92)
              : _withAlpha(foregroundColor, 0.06);
          final cellBorderColor = day.isToday
              ? accentColor
              : _withAlpha(foregroundColor, 0.15);

          return pw.Container(
            height: rowHeight,
            padding: const pw.EdgeInsets.all(4),
            decoration: pw.BoxDecoration(
              color: cellColor,
              border: pw.Border.all(
                color: cellBorderColor,
                width: day.isToday ? 1.1 : 0.55,
              ),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
            ),
            child: pw.Stack(
              children: [
                if (request.showWesternDates)
                  pw.Positioned(
                    left: 0,
                    top: 0,
                    child: pw.Text(
                      day.westernDayLabel,
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 9,
                        color: _withAlpha(
                          foregroundColor,
                          day.isCurrentMonth ? 0.95 : 0.50,
                        ),
                      ),
                    ),
                  ),
                if (request.showMyanmarDates)
                  pw.Positioned(
                    right: 0,
                    bottom: 0,
                    child: pw.Text(
                      day.myanmarDayLabel,
                      style: pw.TextStyle(
                        font: regularFont,
                        fontSize: 8,
                        color: _withAlpha(
                          foregroundColor,
                          day.isCurrentMonth ? 0.78 : 0.45,
                        ),
                      ),
                    ),
                  ),
                if (hasMarker)
                  pw.Positioned(
                    top: 1,
                    right: 1,
                    child: pw.Container(
                      width: 5,
                      height: 5,
                      decoration: pw.BoxDecoration(
                        color: accentColor,
                        shape: pw.BoxShape.circle,
                      ),
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
}
