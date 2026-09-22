import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/calendar_studio_document.dart';
import '../models/calendar_studio_types.dart';
import 'calendar_studio_contracts.dart';

/// Vector PDF renderer for the same normalized document consumed by preview.
class CalendarStudioPdfExporter {
  const CalendarStudioPdfExporter({this.dataProvider, this.assetStore});

  final CalendarStudioDataProvider? dataProvider;
  final CalendarStudioAssetStore? assetStore;

  Future<Uint8List> export(CalendarStudioProject project) async {
    final regular = await _font(
      'assets/fonts/google_fonts/NotoSansMyanmar-Regular.ttf',
      pw.Font.helvetica(),
    );
    final bold = await _font(
      'assets/fonts/google_fonts/NotoSansMyanmar-Bold.ttf',
      pw.Font.helveticaBold(),
    );
    final document = pw.Document(
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
    );
    for (final page in project.pages) {
      final pageSource = project.source.copyWith(
        year: page.year,
        month: page.month,
      );
      final days = await dataProvider?.daysFor(pageSource, month: page.month);
      final images = <String, pw.MemoryImage>{};
      for (final block in page.blocks) {
        final assetId = block.content['assetId'] as String?;
        if (assetId == null || images.containsKey(assetId)) continue;
        final bytes = await assetStore?.loadBytes(assetId);
        if (bytes != null && bytes.isNotEmpty) {
          try {
            images[assetId] = pw.MemoryImage(Uint8List.fromList(bytes));
          } catch (_) {
            // Preflight will surface unreadable or missing assets.
          }
        }
      }
      final format = _format(page.canvas);
      document.addPage(
        pw.Page(
          pageFormat: format,
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.Container(
            color: _color(page.canvas.backgroundColor),
            child: pw.Stack(
              children: [
                for (final block in [
                  ...page.blocks,
                ]..sort((a, b) => a.zIndex.compareTo(b.zIndex)))
                  if (block.visible)
                    _positioned(
                      block,
                      pageSource,
                      days,
                      images,
                      format.availableWidth,
                      format.availableHeight,
                    ),
              ],
            ),
          ),
        ),
      );
    }
    return document.save();
  }

  pw.Widget _positioned(
    CalendarStudioBlock block,
    CalendarStudioSource source,
    List<CalendarStudioDayData>? days,
    Map<String, pw.MemoryImage> images,
    double width,
    double height,
  ) {
    final bounds = block.bounds;
    return pw.Positioned(
      left: bounds.left * width,
      top: bounds.top * height,
      right: (1 - bounds.right) * width,
      bottom: (1 - bounds.bottom) * height,
      child: pw.Transform.rotate(
        angle: block.rotation,
        child: _block(block, source, days, images),
      ),
    );
  }

  pw.Widget _block(
    CalendarStudioBlock block,
    CalendarStudioSource source,
    List<CalendarStudioDayData>? days,
    Map<String, pw.MemoryImage> images,
  ) => switch (block.type) {
    CalendarStudioBlockType.text => pw.Align(
      alignment: _alignment(block.style['align'] as String?),
      child: pw.Text(
        block.content['text'] as String? ?? '',
        textAlign: _textAlign(block.style['align'] as String?),
        style: pw.TextStyle(
          fontSize: (block.style['fontSize'] as num?)?.toDouble() ?? 20,
          fontWeight: pw.FontWeight.bold,
          color: _color(block.style['color'] as int? ?? 0xFF15201D),
        ),
      ),
    ),
    CalendarStudioBlockType.shape => pw.Container(
      color: _color(block.style['color'] as int? ?? 0xFF0E6B5C),
    ),
    CalendarStudioBlockType.calendarGrid => _calendarGrid(source, days),
    CalendarStudioBlockType.eventList => pw.Text('My events'),
    CalendarStudioBlockType.holidayLegend => pw.Text('Holiday legend'),
    CalendarStudioBlockType.image || CalendarStudioBlockType.logo =>
      images[block.content['assetId']] == null
          ? pw.Container(
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#E1E8E4'),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(block.name),
            )
          : pw.Image(images[block.content['assetId']]!, fit: pw.BoxFit.cover),
    CalendarStudioBlockType.decoration => pw.Center(child: pw.Text('✦')),
  };

  pw.Widget _calendarGrid(
    CalendarStudioSource source,
    List<CalendarStudioDayData>? days,
  ) {
    final date = DateTime(source.year, source.month);
    final offset =
        (date.weekday % 7 - (source.weekStartsMonday ? 1 : 0) + 7) % 7;
    final count = DateTime(source.year, source.month + 1, 0).day;
    final headers = source.weekStartsMonday
        ? const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
        : const ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final cells = List<pw.Widget>.generate(42, (index) {
      final day = index - offset + 1;
      if (day < 1 || day > count) return pw.SizedBox();
      final data = days != null && day <= days.length ? days[day - 1] : null;
      final label = data == null || !source.showMyanmarDate
          ? '$day'
          : '${data.gregorianLabel}\n${data.myanmarLabel ?? ''}';
      return pw.Container(
        padding: const pw.EdgeInsets.all(2),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColor.fromHex('#D5DEDA'), width: .5),
        ),
        child: pw.Text(
          label,
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(fontSize: 6),
        ),
      );
    });
    return pw.Column(
      children: [
        pw.Row(
          children: [
            for (final header in headers)
              pw.Expanded(
                child: pw.Text(
                  header,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        pw.SizedBox(height: 3),
        pw.Expanded(child: pw.GridView(crossAxisCount: 7, children: cells)),
      ],
    );
  }

  PdfPageFormat _format(StudioCanvas canvas) {
    final portrait = canvas.aspectRatio <= 1;
    final base = portrait ? PdfPageFormat.a4 : PdfPageFormat.a4.landscape;
    return PdfPageFormat(base.width, base.height, marginAll: 0);
  }

  Future<pw.Font> _font(String path, pw.Font fallback) async {
    try {
      return pw.Font.ttf(await rootBundle.load(path));
    } catch (_) {
      return fallback;
    }
  }

  PdfColor _color(int value) => PdfColor(
    ((value >> 16) & 0xFF) / 255,
    ((value >> 8) & 0xFF) / 255,
    (value & 0xFF) / 255,
    ((value >> 24) & 0xFF) / 255,
  );
  pw.Alignment _alignment(String? value) => switch (value) {
    'center' => pw.Alignment.center,
    'right' => pw.Alignment.centerRight,
    _ => pw.Alignment.centerLeft,
  };
  pw.TextAlign _textAlign(String? value) => switch (value) {
    'center' => pw.TextAlign.center,
    'right' => pw.TextAlign.right,
    _ => pw.TextAlign.left,
  };
}
