import 'package:pdf/pdf.dart';

import '../../domain/entities/calendar_generation_request.dart';
import '../../domain/entities/calendar_image_quality.dart';
import '../../domain/entities/calendar_page_orientation.dart';
import '../../domain/entities/calendar_paper_size.dart';

class CalendarExportLayout {
  const CalendarExportLayout._();

  static PdfPageFormat resolvePdfPageFormat(CalendarGenerationRequest request) {
    final baseFormat = switch (request.paperSize) {
      CalendarPaperSize.a4 => PdfPageFormat.a4,
      CalendarPaperSize.letter => PdfPageFormat.letter,
    };
    return request.pageOrientation == CalendarPageOrientation.landscape
        ? baseFormat.landscape
        : baseFormat;
  }

  static ({int width, int height}) resolveImageSize(
    CalendarGenerationRequest request,
  ) {
    final (baseWidth, baseHeight) = switch (request.paperSize) {
      CalendarPaperSize.a4 => (8.27, 11.69),
      CalendarPaperSize.letter => (8.50, 11.00),
    };

    final dpi = switch (request.imageQuality) {
      CalendarImageQuality.screen => 150,
      CalendarImageQuality.print => 300,
    };

    var width = (baseWidth * dpi).round();
    var height = (baseHeight * dpi).round();
    if (request.pageOrientation == CalendarPageOrientation.landscape) {
      final swap = width;
      width = height;
      height = swap;
    }

    return (width: width, height: height);
  }

  static double previewAspectRatio(CalendarGenerationRequest request) {
    final (width, height) = switch (request.paperSize) {
      CalendarPaperSize.a4 => (1.0, 1.414),
      CalendarPaperSize.letter => (8.5, 11.0),
    };
    return request.pageOrientation == CalendarPageOrientation.landscape
        ? height / width
        : width / height;
  }
}
