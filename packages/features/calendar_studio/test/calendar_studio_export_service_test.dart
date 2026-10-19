import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  late _FakeRasterizer renderer;
  late CalendarStudioProject project;

  setUp(() {
    renderer = _FakeRasterizer();
    final now = DateTime(2027);
    project = CalendarStudioTemplates.byId('jade-wall').create(
      id: 'export-test',
      source: const CalendarStudioSource(year: 2027),
      now: now,
    );
  });

  test('fidelity-first PDF contains every rendered page', () async {
    final progress = <CalendarStudioExportProgress>[];
    final artifact = await CalendarStudioExportService(renderer: renderer)
        .export(
          project: project,
          preset: const CalendarStudioExportPreset(
            id: 'test-pdf',
            label: 'Test PDF',
            format: CalendarStudioExportFormat.pdf,
            dpi: 72,
            width: 40,
            height: 60,
          ),
          onProgress: progress.add,
        );

    expect(artifact.mimeType, 'application/pdf');
    expect(String.fromCharCodes(artifact.bytes.take(4)), '%PDF');
    expect(renderer.calls, project.pages.length);
    expect(progress.last.completed, project.pages.length);
  });

  test('multi-page PNG export is delivered as a named ZIP', () async {
    final artifact = await CalendarStudioExportService(renderer: renderer)
        .export(
          project: project,
          preset: const CalendarStudioExportPreset(
            id: 'test-png',
            label: 'Test PNG',
            format: CalendarStudioExportFormat.png,
            dpi: 72,
            width: 40,
            height: 60,
            fileName: 'Myanmar Calendar 2027',
          ),
        );
    final archive = ZipDecoder().decodeBytes(artifact.bytes);

    expect(artifact.mimeType, 'application/zip');
    expect(artifact.name, 'Myanmar-Calendar-2027-images.zip');
    expect(archive.length, project.pages.length);
    expect(archive.first.name, 'Myanmar-Calendar-2027-01.png');
  });

  test('cancellation stops before rendering starts', () async {
    final token = CalendarStudioExportCancellationToken()..cancel();

    expect(
      () => CalendarStudioExportService(renderer: renderer).export(
        project: project,
        preset: CalendarStudioExportPreset.a4Pdf,
        cancellationToken: token,
      ),
      throwsA(isA<CalendarStudioExportCancelled>()),
    );
    expect(renderer.calls, 0);
  });

  testWidgets('shared Flutter scene renders Myanmar text at target size', (
    tester,
  ) async {
    final monthly = CalendarStudioTemplates.byId('jade-wall').create(
      id: 'myanmar-render',
      source: const CalendarStudioSource(
        year: 2027,
        period: CalendarStudioPeriod.month,
      ),
      now: DateTime(2027),
    );
    final title = monthly.pages.single.blocks.firstWhere(
      (block) => block.type == CalendarStudioBlockType.text,
    );
    final page = monthly.pages.single.copyWith(
      blocks: [
        for (final block in monthly.pages.single.blocks)
          if (block.id == title.id)
            block.copyWith(
              content: {...block.content, 'text': 'မြန်မာ ပြက္ခဒိန်'},
            )
          else
            block,
      ],
    );
    final bytes = await tester.runAsync(
      () => const CalendarStudioRasterRenderer().renderPage(
        monthly.copyWith(pages: [page]),
        page,
        width: 80,
        height: 120,
      ),
    );
    final rendered = img.decodePng(bytes!);

    expect(rendered, isNotNull);
    expect(rendered!.width, 80);
    expect(rendered.height, 120);
  });

  test('page-size presets export each page at its own paper size', () {
    ({int width, int height}) size(String templateId) =>
        CalendarStudioExportPreset.pagePdf.pixelSizeFor(
          CalendarStudioTemplates.byId(templateId).canvas,
        );
    // A4 at 300 dpi, portrait and landscape; screen pages at 1080 px.
    expect(size('jade-wall'), (width: 2480, height: 3508));
    expect(size('ledger-desk'), (width: 3508, height: 2480));
    expect(size('square'), (width: 1080, height: 1080));
    expect(size('story'), (width: 1080, height: 1920));
    // A fixed preset keeps its own size, whatever the page.
    expect(
      CalendarStudioExportPreset.squarePng.pixelSizeFor(
        CalendarStudioTemplates.byId('jade-wall').canvas,
      ),
      (width: 1080, height: 1080),
    );
  });

  test('a page-size PDF renders every page at its own size', () async {
    final landscape = CalendarStudioTemplates.byId('ledger-desk').create(
      id: 'landscape',
      source: const CalendarStudioSource(
        year: 2027,
        period: CalendarStudioPeriod.month,
      ),
      now: DateTime(2027),
    );
    final mixed = project.copyWith(
      pages: [project.pages.first, landscape.pages.single],
    );
    final artifact = await CalendarStudioExportService(
      renderer: renderer,
    ).export(project: mixed, preset: CalendarStudioExportPreset.pagePdf);
    expect(renderer.sizes, [(2480, 3508), (3508, 2480)]);
    expect(String.fromCharCodes(artifact.bytes.take(4)), '%PDF');
  });

  testWidgets('a page of another shape is fitted, never stretched', (
    tester,
  ) async {
    const renderer = CalendarStudioRasterRenderer(
      dataProvider: MyanmarCalendarStudioDataProvider(),
    );
    final monthly = CalendarStudioTemplates.byId('jade-wall').create(
      id: 'fit',
      source: const CalendarStudioSource(
        year: 2027,
        period: CalendarStudioPeriod.month,
      ),
      now: DateTime(2027),
    );
    final page = monthly.pages.single;
    // The A4 page alone, and the same page in a square output.
    final alone = img.decodePng(
      (await tester.runAsync(
        () => renderer.renderPage(monthly, page, width: 141, height: 200),
      ))!,
    )!;
    final square = img.decodePng(
      (await tester.runAsync(
        () => renderer.renderPage(monthly, page, width: 200, height: 200),
      ))!,
    )!;
    expect(square.width, 200);
    // Page colour either side of the centred page.
    final paper = page.canvas.backgroundColor;
    for (final x in [2, 197]) {
      final pixel = square.getPixel(x, 100);
      expect(
        (pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()),
        ((paper >> 16) & 0xFF, (paper >> 8) & 0xFF, paper & 0xFF),
      );
    }
    // The centred page matches the page rendered at its own shape. Both
    // are averaged over 10 px blocks: the centred page sits a fraction of a
    // pixel off, which moves every edge, but a stretched page would move
    // whole regions.
    double block(img.Image image, int left, int top) {
      var sum = 0.0;
      for (var y = top; y < top + 10; y++) {
        for (var x = left; x < left + 10; x++) {
          final p = image.getPixel(x, y);
          sum += p.r + p.g + p.b;
        }
      }
      return sum / 300;
    }

    var total = 0.0;
    var blocks = 0;
    for (var y = 0; y + 10 <= 200; y += 10) {
      for (var x = 0; x + 10 <= 140; x += 10) {
        total += (block(alone, x, y) - block(square, x + 29, y)).abs();
        blocks++;
      }
    }
    expect(total / blocks, lessThan(8));
  });

  testWidgets('every mockup preset renders through the export scene', (
    tester,
  ) async {
    const renderer = CalendarStudioRasterRenderer(
      dataProvider: MyanmarCalendarStudioDataProvider(),
    );
    for (final template in CalendarStudioTemplates.all.where(
      (value) => value.id != 'blank',
    )) {
      final project = template.create(
        id: 'render-${template.id}',
        source: const CalendarStudioSource(
          year: 2027,
          period: CalendarStudioPeriod.month,
        ),
        now: DateTime(2027),
      );
      final page = project.pages.single;
      final size = CalendarStudioScene.designSizeFor(page.canvas);
      final width = 180;
      final height = (width * size.height / size.width).round();
      final bytes = await tester.runAsync(
        () => renderer.renderPage(project, page, width: width, height: height),
      );
      final rendered = img.decodePng(bytes!);
      expect(rendered, isNotNull, reason: template.id);
      expect(rendered!.width, width, reason: template.id);
      expect(rendered.height, height, reason: template.id);
    }
  });
}

class _FakeRasterizer implements CalendarStudioPageRasterizer {
  int calls = 0;
  final sizes = <(int, int)>[];

  @override
  Future<Uint8List> renderPage(
    CalendarStudioProject project,
    CalendarStudioPage page, {
    required int width,
    required int height,
  }) async {
    calls++;
    sizes.add((width, height));
    final image = img.Image(width: 2, height: 3)
      ..clear(img.ColorRgb8(14, 107, 92));
    return Uint8List.fromList(img.encodePng(image));
  }
}
