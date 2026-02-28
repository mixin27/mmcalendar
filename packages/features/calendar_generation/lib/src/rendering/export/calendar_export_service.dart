import 'package:printing/printing.dart';

import '../../domain/entities/calendar_generation_request.dart';
import '../../domain/entities/calendar_page_model.dart';
import '../../domain/entities/generation_artifact.dart';
import '../image/calendar_image_renderer.dart';
import '../pdf/calendar_pdf_renderer.dart';

class CalendarExportService {
  CalendarExportService({
    required CalendarPdfRenderer pdfRenderer,
    required CalendarImageRenderer imageRenderer,
  }) : _pdfRenderer = pdfRenderer,
       _imageRenderer = imageRenderer;

  final CalendarPdfRenderer _pdfRenderer;
  final CalendarImageRenderer _imageRenderer;

  Future<GenerationArtifact> buildPdf({
    required CalendarGenerationRequest request,
    required List<CalendarPageModel> pages,
  }) async {
    final bytes = await _pdfRenderer.render(request: request, pages: pages);
    return GenerationArtifact(
      fileName: _buildPdfFileName(request: request, pagesCount: pages.length),
      mimeType: 'application/pdf',
      bytes: bytes,
    );
  }

  Future<List<GenerationArtifact>> buildImages({
    required CalendarGenerationRequest request,
    required List<CalendarPageModel> pages,
  }) async {
    final imageBytes = await _imageRenderer.renderPages(
      request: request,
      pages: pages,
    );

    return List<GenerationArtifact>.generate(imageBytes.length, (index) {
      final model = pages[index];
      return GenerationArtifact(
        fileName: _buildImageFileName(
          year: model.year,
          month: model.month,
          includeMonth: pages.length > 1 || request.month == null,
        ),
        mimeType: 'image/png',
        bytes: imageBytes[index],
      );
    }, growable: false);
  }

  Future<void> print({
    required CalendarGenerationRequest request,
    required List<CalendarPageModel> pages,
  }) async {
    final artifact = await buildPdf(request: request, pages: pages);
    await Printing.layoutPdf(
      name: artifact.fileName,
      onLayout: (_) async => artifact.bytes,
    );
  }

  String _buildPdfFileName({
    required CalendarGenerationRequest request,
    required int pagesCount,
  }) {
    if (pagesCount > 1 || request.month == null) {
      return 'myanmar_calendar_${request.year}.pdf';
    }

    final month = request.month!.toString().padLeft(2, '0');
    return 'myanmar_calendar_${request.year}_$month.pdf';
  }

  String _buildImageFileName({
    required int year,
    required int month,
    required bool includeMonth,
  }) {
    if (!includeMonth) {
      return 'myanmar_calendar_$year.png';
    }

    final monthText = month.toString().padLeft(2, '0');
    return 'myanmar_calendar_${year}_$monthText.png';
  }
}
