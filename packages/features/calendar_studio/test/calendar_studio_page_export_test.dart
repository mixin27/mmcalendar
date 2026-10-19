import 'dart:typed_data';

import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  final project = CalendarStudioTemplates.byId('jade-wall').create(
    id: 'month-export',
    source: const CalendarStudioSource(year: 2027),
    now: DateTime(2027),
  );

  group('page selection', () {
    test('keeps project order and ignores unknown indexes', () {
      final pages = CalendarStudioExportService.selectPages(project, [
        5,
        3,
        3,
        40,
      ]);
      expect(pages.map((page) => page.month), [4, 6]);
      expect(
        CalendarStudioExportService.selectPages(project, null),
        project.pages,
      );
      expect(
        () => CalendarStudioExportService.selectPages(project, [99]),
        throwsArgumentError,
      );
    });

    test('a single month exports one page', () async {
      final renderer = _FakeRasterizer();
      final progress = <CalendarStudioExportProgress>[];
      final artifact = await CalendarStudioExportService(renderer: renderer)
          .export(
            project: project,
            preset: const CalendarStudioExportPreset(
              id: 'png',
              label: 'PNG',
              format: CalendarStudioExportFormat.png,
              dpi: 72,
              width: 40,
              height: 60,
              fileName: 'family-2027-04',
            ),
            pageIndexes: [3],
            onProgress: progress.add,
          );
      expect(renderer.months, [4]);
      expect(progress.single.total, 1);
      expect(artifact.mimeType, 'image/png');
      expect(artifact.name, 'family-2027-04.png');
    });
  });

  test('the default export preset survives a save', () {
    final custom = project.copyWith(
      defaultExportPreset: CalendarStudioExportPreset.storyPng,
    );
    final decoded = CalendarStudioDocumentCodec.decode(
      CalendarStudioDocumentCodec.encode(custom),
    );
    expect(decoded.defaultExportPreset.id, 'story-png');
    expect(decoded.defaultExportPreset.format, CalendarStudioExportFormat.png);
    final legacy = CalendarStudioDocumentCodec.encode(project)
      ..remove('defaultExportPreset');
    // Projects saved before export presets print at their own page size.
    expect(
      CalendarStudioDocumentCodec.decode(legacy).defaultExportPreset,
      CalendarStudioExportPreset.pagePdf,
    );
  });

  testWidgets('the export sheet offers page size and notes a shape change', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = _MemoryStore()..values[project.id] = project;
    await tester.pumpWidget(
      MaterialApp(
        home: CalendarStudioWorkspace(
          configuration: CalendarStudioConfiguration(
            projects: store,
            exportDelivery: _Delivery(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Export').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Export…'));
    await tester.pumpAndSettle();

    // Page size comes first and follows the A4 page.
    expect(find.text('Page size print'), findsOneWidget);
    expect(find.text('Page size image'), findsOneWidget);
    expect(find.text('2480 × 3508'), findsWidgets);
    const note = ValueKey('studio-export-shape-note');
    await tester.tap(find.text('Page size print'));
    await tester.pumpAndSettle();
    expect(find.byKey(note), findsNothing);

    // A square export of an A4 page says it will be fitted, not stretched.
    await tester.drag(find.text('Page size image'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Square social'));
    await tester.pumpAndSettle();
    expect(find.byKey(note), findsOneWidget);
  });

  testWidgets('exporting from April preselects this page', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final delivery = _Delivery();
    final store = _MemoryStore()..values[project.id] = project;
    await tester.pumpWidget(
      MaterialApp(
        home: CalendarStudioWorkspace(
          configuration: CalendarStudioConfiguration(
            projects: store,
            exportDelivery: delivery,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byIcon(Icons.chevron_right).first);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Export').first);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<PageView>(
            find.byKey(const ValueKey('calendar-studio-preview-pages')),
          )
          .controller!
          .initialPage,
      3,
    );
    await tester.tap(find.text('Export…'));
    await tester.pumpAndSettle();

    expect(find.text('This page'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      endsWith('-2027-04'),
    );
    expect(find.textContaining('· 1 page'), findsWidgets);

    await tester.tap(find.text('Choose'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'May'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      endsWith('-2027-04-to-05'),
    );

    await tester.tap(find.text('All 12'));
    await tester.pumpAndSettle();
    expect(find.textContaining('· 12 pages'), findsWidgets);

    // "Choose" can't drop to zero pages.
    await tester.tap(find.text('Choose'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'April'));
    await tester.tap(find.widgetWithText(FilterChip, 'May'));
    await tester.pumpAndSettle();
    expect(find.textContaining('· 1 page'), findsWidgets);
  });
}

class _FakeRasterizer implements CalendarStudioPageRasterizer {
  final months = <int>[];

  @override
  Future<Uint8List> renderPage(
    CalendarStudioProject project,
    CalendarStudioPage page, {
    required int width,
    required int height,
  }) async {
    months.add(page.month);
    return img.encodePng(img.Image(width: width, height: height));
  }
}

class _Delivery implements CalendarStudioExportDelivery {
  final artifacts = <CalendarStudioExportArtifact>[];
  @override
  Future<void> deliver(
    CalendarStudioExportArtifact artifact, {
    CalendarStudioExportDestination destination =
        CalendarStudioExportDestination.save,
  }) async => artifacts.add(artifact);
}

class _MemoryStore implements CalendarStudioProjectStore {
  final values = <String, CalendarStudioProject>{};
  @override
  Future<void> delete(String id) async => values.remove(id);
  @override
  Future<List<CalendarStudioProject>> list() async => values.values.toList();
  @override
  Future<CalendarStudioProject?> load(String id) async => values[id];
  @override
  Future<void> save(CalendarStudioProject project) async =>
      values[project.id] = project;
}
