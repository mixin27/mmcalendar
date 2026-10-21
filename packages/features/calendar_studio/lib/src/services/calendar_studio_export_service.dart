import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/calendar_studio_document.dart';
import '../models/calendar_studio_types.dart';
import 'calendar_studio_contracts.dart';
import 'calendar_studio_raster_renderer.dart';

class CalendarStudioExportCancelled implements Exception {
  const CalendarStudioExportCancelled();
}

class CalendarStudioExportCancellationToken {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
  void throwIfCancelled() {
    if (_cancelled) throw const CalendarStudioExportCancelled();
  }
}

class CalendarStudioExportProgress {
  const CalendarStudioExportProgress({
    required this.completed,
    required this.total,
  });
  final int completed;
  final int total;
}

/// Builds PDF, PNG, JPEG, and multi-page ZIP artifacts from the shared Flutter
/// scene. Myanmar text is shaped by Flutter before it reaches the PDF.
class CalendarStudioExportService {
  const CalendarStudioExportService({required this.renderer});

  final CalendarStudioPageRasterizer renderer;

  Future<CalendarStudioExportArtifact> export({
    required CalendarStudioProject project,
    required CalendarStudioExportPreset preset,
    Iterable<int>? pageIndexes,
    CalendarStudioExportCancellationToken? cancellationToken,
    ValueChanged<CalendarStudioExportProgress>? onProgress,
  }) async {
    final token = cancellationToken ?? CalendarStudioExportCancellationToken();
    final selected = selectPages(project, pageIndexes);
    final pages = <_RenderedPage>[];
    for (var index = 0; index < selected.length; index++) {
      token.throwIfCancelled();
      final page = selected[index];
      final size = preset.pixelSizeFor(page.canvas);
      final png = await renderer.renderPage(
        project,
        page,
        width: size.width,
        height: size.height,
      );
      token.throwIfCancelled();
      pages.add(_RenderedPage(png, size.width, size.height));
      onProgress?.call(
        CalendarStudioExportProgress(
          completed: index + 1,
          total: selected.length,
        ),
      );
      await Future<void>.delayed(Duration.zero);
    }

    token.throwIfCancelled();
    final baseName = _safeName(preset.fileName);
    return switch (preset.format) {
      CalendarStudioExportFormat.pdf => _pdf(pages, preset, baseName),
      CalendarStudioExportFormat.png => _images(
        pages,
        baseName,
        extension: 'png',
        mimeType: 'image/png',
      ),
      CalendarStudioExportFormat.jpeg => _images(
        pages,
        baseName,
        extension: 'jpg',
        mimeType: 'image/jpeg',
        encodeJpeg: true,
      ),
      CalendarStudioExportFormat.zip => _images(
        pages,
        baseName,
        extension: 'png',
        mimeType: 'image/png',
        forceZip: true,
      ),
    };
  }

  /// Pages to export in project order. Null exports every page; indexes
  /// outside the project are ignored, and an empty result is an error.
  static List<CalendarStudioPage> selectPages(
    CalendarStudioProject project,
    Iterable<int>? pageIndexes,
  ) {
    if (pageIndexes == null) return project.pages;
    final wanted = pageIndexes.toSet();
    final pages = [
      for (var i = 0; i < project.pages.length; i++)
        if (wanted.contains(i)) project.pages[i],
    ];
    if (pages.isEmpty) throw ArgumentError('Choose at least one page.');
    return pages;
  }

  Future<CalendarStudioExportArtifact> _pdf(
    List<_RenderedPage> pages,
    CalendarStudioExportPreset preset,
    String baseName,
  ) async {
    final pngs = [for (final page in pages) page.png];
    // Each page's own size, so page-size exports keep mixed papers.
    final sizes = [
      for (final page in pages) [page.width, page.height],
    ];
    final dpi = preset.dpi;
    final bytes = await _inBackground(
      pngs,
      (pngs) => _buildPdf(pngs, sizes, dpi),
    );
    return CalendarStudioExportArtifact(
      name: '$baseName.pdf',
      mimeType: 'application/pdf',
      bytes: bytes,
    );
  }

  Future<CalendarStudioExportArtifact> _images(
    List<_RenderedPage> pages,
    String baseName, {
    required String extension,
    required String mimeType,
    bool encodeJpeg = false,
    bool forceZip = false,
  }) async {
    if (pages.length == 1 && !forceZip) {
      final bytes = encodeJpeg
          ? await _inBackground([
              pages.single.png,
            ], (pngs) async => _jpegBytes(pngs.single))
          : pages.single.png;
      return CalendarStudioExportArtifact(
        name: '$baseName.$extension',
        mimeType: mimeType,
        bytes: bytes,
      );
    }
    final bytes = await _inBackground([
      for (final page in pages) page.png,
    ], (pngs) async => _buildImagesZip(pngs, baseName, extension, encodeJpeg));
    return CalendarStudioExportArtifact(
      name: '$baseName-images.zip',
      mimeType: 'application/zip',
      bytes: bytes,
    );
  }

  String _safeName(String value) {
    final safe = value.trim().replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '-');
    return safe.isEmpty ? 'my-calendar' : safe;
  }
}

class _RenderedPage {
  const _RenderedPage(this.png, this.width, this.height);
  final Uint8List png;
  final int width;
  final int height;
}

/// Runs [work] on [pngs] off the UI isolate where there is one.
///
/// Web has no isolates (`Isolate.run` throws there), so it runs inline; the
/// export is slower there but works. Elsewhere the pages move to the worker
/// as [TransferableTypedData], without copying.
Future<Uint8List> _inBackground(
  List<Uint8List> pngs,
  Future<Uint8List> Function(List<Uint8List> pngs) work,
) async {
  if (kIsWeb) return work(pngs);
  final transfers = [
    for (final png in pngs) TransferableTypedData.fromList([png]),
  ];
  final output = await Isolate.run<TransferableTypedData>(() async {
    final bytes = await work([
      for (final transfer in transfers) transfer.materialize().asUint8List(),
    ]);
    return TransferableTypedData.fromList([bytes]);
  });
  return output.materialize().asUint8List();
}

Future<Uint8List> _buildPdf(
  List<Uint8List> pngs,
  List<List<int>> sizes,
  int dpi,
) async {
  final document = pw.Document();
  for (var i = 0; i < pngs.length; i++) {
    final format = PdfPageFormat(
      sizes[i][0] / dpi * PdfPageFormat.inch,
      sizes[i][1] / dpi * PdfPageFormat.inch,
      marginAll: 0,
    );
    final image = pw.MemoryImage(pngs[i]);
    document.addPage(
      pw.Page(
        pageFormat: format,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Image(image, fit: pw.BoxFit.fill),
      ),
    );
  }
  return document.save();
}

Uint8List _buildImagesZip(
  List<Uint8List> pngs,
  String baseName,
  String extension,
  bool encodeJpeg,
) {
  final archive = Archive();
  for (var index = 0; index < pngs.length; index++) {
    final bytes = encodeJpeg ? _jpegBytes(pngs[index]) : pngs[index];
    final number = (index + 1).toString().padLeft(2, '0');
    archive.addFile(
      ArchiveFile('$baseName-$number.$extension', bytes.length, bytes),
    );
  }
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

Uint8List _jpegBytes(Uint8List png) {
  final decoded = img.decodePng(png);
  if (decoded == null) throw StateError('Could not encode JPEG export');
  return Uint8List.fromList(img.encodeJpg(decoded, quality: 94));
}
