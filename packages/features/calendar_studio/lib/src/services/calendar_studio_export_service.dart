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
    CalendarStudioExportCancellationToken? cancellationToken,
    ValueChanged<CalendarStudioExportProgress>? onProgress,
  }) async {
    final token = cancellationToken ?? CalendarStudioExportCancellationToken();
    final pages = <_RenderedPage>[];
    for (var index = 0; index < project.pages.length; index++) {
      token.throwIfCancelled();
      final page = project.pages[index];
      final png = await renderer.renderPage(
        project,
        page,
        width: preset.width,
        height: preset.height,
      );
      token.throwIfCancelled();
      pages.add(_RenderedPage(png));
      onProgress?.call(
        CalendarStudioExportProgress(
          completed: index + 1,
          total: project.pages.length,
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

  Future<CalendarStudioExportArtifact> _pdf(
    List<_RenderedPage> pages,
    CalendarStudioExportPreset preset,
    String baseName,
  ) async {
    final output = await Isolate.run<TransferableTypedData>(
      () => _buildPdf(<String, Object>{
        'pages': pages
            .map((page) => TransferableTypedData.fromList([page.png]))
            .toList(growable: false),
        'width': preset.width,
        'height': preset.height,
        'dpi': preset.dpi,
      }),
    );
    return CalendarStudioExportArtifact(
      name: '$baseName.pdf',
      mimeType: 'application/pdf',
      bytes: output.materialize().asUint8List(),
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
          ? (await Isolate.run<TransferableTypedData>(
              () => _encodeJpeg(
                TransferableTypedData.fromList([pages.single.png]),
              ),
            )).materialize().asUint8List()
          : pages.single.png;
      return CalendarStudioExportArtifact(
        name: '$baseName.$extension',
        mimeType: mimeType,
        bytes: bytes,
      );
    }
    final output = await Isolate.run<TransferableTypedData>(
      () => _buildImagesZip(<String, Object>{
        'pages': pages
            .map((page) => TransferableTypedData.fromList([page.png]))
            .toList(growable: false),
        'baseName': baseName,
        'extension': extension,
        'encodeJpeg': encodeJpeg,
      }),
    );
    return CalendarStudioExportArtifact(
      name: '$baseName-images.zip',
      mimeType: 'application/zip',
      bytes: output.materialize().asUint8List(),
    );
  }

  String _safeName(String value) {
    final safe = value.trim().replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '-');
    return safe.isEmpty ? 'my-calendar' : safe;
  }
}

class _RenderedPage {
  const _RenderedPage(this.png);
  final Uint8List png;
}

Future<TransferableTypedData> _buildPdf(Map<String, Object> payload) async {
  final width = payload['width'] as int;
  final height = payload['height'] as int;
  final dpi = payload['dpi'] as int;
  final document = pw.Document();
  final format = PdfPageFormat(
    width / dpi * PdfPageFormat.inch,
    height / dpi * PdfPageFormat.inch,
    marginAll: 0,
  );
  for (final transfer in payload['pages']! as List<TransferableTypedData>) {
    final image = pw.MemoryImage(transfer.materialize().asUint8List());
    document.addPage(
      pw.Page(
        pageFormat: format,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Image(image, fit: pw.BoxFit.fill),
      ),
    );
  }
  return TransferableTypedData.fromList([await document.save()]);
}

TransferableTypedData _encodeJpeg(TransferableTypedData transfer) {
  final bytes = _jpegBytes(transfer.materialize().asUint8List());
  return TransferableTypedData.fromList([bytes]);
}

TransferableTypedData _buildImagesZip(Map<String, Object> payload) {
  final archive = Archive();
  final pages = payload['pages']! as List<TransferableTypedData>;
  final baseName = payload['baseName']! as String;
  final extension = payload['extension']! as String;
  final encodeJpeg = payload['encodeJpeg']! as bool;
  for (var index = 0; index < pages.length; index++) {
    final png = pages[index].materialize().asUint8List();
    final bytes = encodeJpeg ? _jpegBytes(png) : png;
    final number = (index + 1).toString().padLeft(2, '0');
    archive.addFile(
      ArchiveFile('$baseName-$number.$extension', bytes.length, bytes),
    );
  }
  return TransferableTypedData.fromList([
    Uint8List.fromList(ZipEncoder().encode(archive)),
  ]);
}

Uint8List _jpegBytes(Uint8List png) {
  final decoded = img.decodePng(png);
  if (decoded == null) throw StateError('Could not encode JPEG export');
  return Uint8List.fromList(img.encodeJpg(decoded, quality: 94));
}
