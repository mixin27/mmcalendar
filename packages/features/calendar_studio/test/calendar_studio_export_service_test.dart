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
}

class _FakeRasterizer implements CalendarStudioPageRasterizer {
  int calls = 0;

  @override
  Future<Uint8List> renderPage(
    CalendarStudioProject project,
    CalendarStudioPage page, {
    required int width,
    required int height,
  }) async {
    calls++;
    final image = img.Image(width: 2, height: 3)
      ..clear(img.ColorRgb8(14, 107, 92));
    return Uint8List.fromList(img.encodePng(image));
  }
}
