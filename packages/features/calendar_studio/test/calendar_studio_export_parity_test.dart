import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// "Preview is what you export": the editor's render path (cached data
/// provider, interactive scene, nothing selected) must match the offscreen
/// export renderer pixel for pixel, within anti-aliasing noise.
void main() {
  const source = CalendarStudioSource(
    year: 2027,
    month: 4,
    period: CalendarStudioPeriod.month,
  );

  for (final templateId in const ['jade-wall', 'annual', 'square']) {
    testWidgets('$templateId editor render matches export', (tester) async {
      final project = CalendarStudioTemplates.byId(
        templateId,
      ).create(id: 'parity-$templateId', source: source, now: DateTime(2027));
      final page = project.pages.first;
      final design = CalendarStudioScene.designSizeFor(page.canvas);
      final width = design.width.round();
      final height = design.height.round();
      const provider = MyanmarCalendarStudioDataProvider();

      final exported = (await tester.runAsync(
        () => const CalendarStudioRasterRenderer(
          dataProvider: provider,
        ).renderPage(project, page, width: width, height: height),
      ))!;

      final cache = CachedCalendarStudioDataProvider(provider);
      await tester.runAsync(
        () => cache.warm(source.copyWith(year: page.year, month: page.month), {
          for (final block in page.blocks)
            if (block.type == CalendarStudioBlockType.calendarGrid)
              block.content['month'] as int? ?? page.month,
        }),
      );
      tester.view.physicalSize = Size(width * 1.0, height * 1.0);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: boundaryKey,
              // The editor canvas sits inside Material, like the renderer.
              child: Material(
                type: MaterialType.transparency,
                child: SizedBox.fromSize(
                  size: design,
                  child: CalendarStudioScene(
                    page: page,
                    source: project.source,
                    dataProvider: cache,
                    onSelect: (_) {},
                    onTransform: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final editorPixels = (await tester.runAsync(() async {
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        image.dispose();
        return data!.buffer.asUint8List();
      }))!;
      final exportPixels = (await tester.runAsync(() async {
        final codec = await ui.instantiateImageCodec(exported);
        final frame = await codec.getNextFrame();
        expect((frame.image.width, frame.image.height), (width, height));
        final data = await frame.image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        frame.image.dispose();
        return data!.buffer.asUint8List();
      }))!;

      expect(editorPixels.length, exportPixels.length);
      expect(_differingPixelRatio(editorPixels, exportPixels), lessThan(.002));
    });
  }
}

/// Share of pixels whose channels differ by more than a small tolerance.
double _differingPixelRatio(Uint8List a, Uint8List b) {
  var differing = 0;
  for (var i = 0; i < a.length; i += 4) {
    for (var c = 0; c < 4; c++) {
      if ((a[i + c] - b[i + c]).abs() > 8) {
        differing++;
        break;
      }
    }
  }
  return differing / (a.length / 4);
}
