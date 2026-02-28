import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:printing/printing.dart';

import '../../domain/entities/calendar_generation_request.dart';
import '../../domain/entities/calendar_page_model.dart';
import '../../domain/entities/generation_artifact.dart';
import 'calendar_export_layout.dart';
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
    final imageSize = CalendarExportLayout.resolveImageSize(request);
    final pageImages = await _imageRenderer.renderPages(
      request: request,
      pages: pages,
      width: imageSize.width,
      height: imageSize.height,
    );
    final bytes = await _pdfRenderer.renderFromImages(
      request: request,
      pageImages: pageImages,
    );
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
    final imageSize = CalendarExportLayout.resolveImageSize(request);
    final imageBytes = await _imageRenderer.renderPages(
      request: request,
      pages: pages,
      width: imageSize.width,
      height: imageSize.height,
    );

    return List<GenerationArtifact>.generate(imageBytes.length, (index) {
      final model = pages[index];
      return GenerationArtifact(
        fileName: _buildImageFileName(
          year: model.year,
          month: model.month,
          includeMonth: pages.length > 1 || request.month == null,
        ),
        mimeType: 'image/jpeg',
        bytes: imageBytes[index],
      );
    }, growable: false);
  }

  GenerationArtifact buildImagesZip({
    required int year,
    required List<GenerationArtifact> images,
  }) {
    final archive = Archive();
    for (final image in images) {
      archive.addFile(
        ArchiveFile(image.fileName, image.bytes.length, image.bytes),
      );
    }

    final zipBytes = ZipEncoder().encode(archive);

    return GenerationArtifact(
      fileName: 'myanmar_calendar_${year}_images.zip',
      mimeType: 'application/zip',
      bytes: Uint8List.fromList(zipBytes),
    );
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
      return 'myanmar_calendar_$year.jpg';
    }

    final monthText = month.toString().padLeft(2, '0');
    return 'myanmar_calendar_${year}_$monthText.jpg';
  }
}
