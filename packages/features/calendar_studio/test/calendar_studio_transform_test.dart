import 'dart:math' as math;

import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _design = Size(595, 842);

Offset _corner(StudioRect bounds, double rotation, double x, double y) {
  final rect = bounds.resolve(_design);
  final local = Offset((x - .5) * rect.width, (y - .5) * rect.height);
  return rect.center +
      Offset(
        local.dx * math.cos(rotation) - local.dy * math.sin(rotation),
        local.dx * math.sin(rotation) + local.dy * math.cos(rotation),
      );
}

void main() {
  const start = StudioRect(left: .2, top: .2, width: .4, height: .3);

  group('CalendarStudioTransform', () {
    test('move keeps size and clamps to the page', () {
      final moved = CalendarStudioTransform.move(
        start,
        const Offset(59.5, 0),
        _design,
      );
      expect(moved.left, closeTo(.3, 1e-9));
      expect(moved.width, start.width);
      final clamped = CalendarStudioTransform.move(
        start,
        const Offset(-1000, 0),
        _design,
      );
      expect(clamped.left, 0);
    });

    test('left handle resize keeps the right edge anchored', () {
      final resized = CalendarStudioTransform.resize(
        start,
        handleX: 0,
        handleY: .5,
        delta: const Offset(59.5, 0),
        rotation: 0,
        design: _design,
      );
      expect(resized.left, closeTo(.3, 1e-9));
      expect(resized.right, closeTo(start.right, 1e-9));
      expect(resized.height, closeTo(start.height, 1e-9));
    });

    test('rotated resize keeps the opposite corner fixed on screen', () {
      const rotation = math.pi / 6;
      final anchor = _corner(start, rotation, 0, 0);
      final resized = CalendarStudioTransform.resize(
        start,
        handleX: 1,
        handleY: 1,
        delta: const Offset(30, 40),
        rotation: rotation,
        design: _design,
      );
      final after = _corner(resized, rotation, 0, 0);
      expect((after - anchor).distance, lessThan(1e-6));
      expect(resized.width, greaterThan(start.width));
    });

    test('rotation follows the pointer and snaps near 15° steps', () {
      const center = Offset(100, 100);
      expect(
        CalendarStudioTransform.rotationFor(center, const Offset(100, 0)),
        0,
      );
      expect(
        CalendarStudioTransform.rotationFor(center, const Offset(200, 100)),
        closeTo(math.pi / 2, 1e-9),
      );
      final near = math.pi / 4 + .02;
      expect(
        CalendarStudioTransform.snapRotation(near),
        closeTo(math.pi / 4, 1e-9),
      );
      const free = math.pi / 4 + .2;
      expect(CalendarStudioTransform.snapRotation(free), free);
    });

    test('move snaps centres to the page centre with a guide', () {
      // Centre 2 px right of the page centre.
      final raw = StudioRect(
        left: .5 - .2 + 2 / 595,
        top: .37,
        width: .4,
        height: .1,
      );
      final result = CalendarStudioTransform.snapMove(
        raw,
        others: const [],
        design: _design,
      );
      expect(result.bounds.left + .2, closeTo(.5, 1e-9));
      expect(result.guides, contains(const StudioGuide.vertical(.5)));
    });

    test('move snaps to other blocks before the grid', () {
      const other = StudioRect(left: .123, top: .6, width: .2, height: .1);
      final raw = StudioRect(
        left: .123 + 3 / 595,
        top: .333,
        width: .1,
        height: .05,
      );
      final result = CalendarStudioTransform.snapMove(
        raw,
        others: const [other],
        design: _design,
        grid: true,
      );
      expect(result.bounds.left, closeTo(.123, 1e-9));
      expect(result.bounds.top, closeTo(.33, 1e-9));
    });

    test('slow drags are not swallowed by grid snapping', () {
      // 1 px per frame, snapped from the raw position each frame.
      var lastLeft = start.left;
      var advanced = false;
      for (var px = 1; px <= 12; px++) {
        final raw = CalendarStudioTransform.move(
          start,
          Offset(px.toDouble(), 0),
          _design,
        );
        final snapped = CalendarStudioTransform.snapMove(
          raw,
          others: const [],
          design: _design,
          grid: true,
          thresholdPx: 0,
        ).bounds;
        if (snapped.left > lastLeft + 1e-9) advanced = true;
        lastLeft = snapped.left;
      }
      expect(advanced, isTrue);
    });

    test('grid resize rounds only the moved edges', () {
      const offGrid = StudioRect(left: .123, top: .456, width: .3, height: .2);
      final raw = offGrid.copyWith(width: .3 + .0071);
      final snapped = CalendarStudioTransform.snapResizeToGrid(offGrid, raw);
      expect(snapped.left, offGrid.left);
      expect(snapped.top, offGrid.top);
      expect(snapped.right, closeTo(.43, 1e-9));
    });
  });

  group('scene gestures', () {
    late CalendarStudioProject project;
    late CalendarStudioBlock grid;

    setUp(() {
      project = CalendarStudioTemplates.byId('jade-wall').create(
        id: 'gesture-project',
        source: const CalendarStudioSource(year: 2027),
        now: DateTime(2027),
      );
      grid = project.pages.first.blocks.firstWhere(
        (block) => block.type == CalendarStudioBlockType.calendarGrid,
      );
    });

    Widget scene({
      required double zoom,
      required ValueChanged<CalendarStudioBlock> onTransform,
    }) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: Transform.scale(
            scale: zoom,
            child: SizedBox(
              width: 297.5, // half the design width
              child: CalendarStudioScene(
                page: project.pages.first,
                source: project.source,
                selectedBlockId: grid.id,
                onSelect: (_) {},
                onTransform: onTransform,
              ),
            ),
          ),
        ),
      ),
    );

    testWidgets('a zoomed drag moves the block by finger travel / scale', (
      tester,
    ) async {
      CalendarStudioBlock? latest;
      // Fitted at 0.5 × zoom 3 = on-screen scale 1.5.
      await tester.pumpWidget(
        scene(zoom: 3, onTransform: (block) => latest = block),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(
          find.byKey(ValueKey('calendar-studio-block-${grid.id}')),
        ),
      );
      // Past the touch slop, then on; the grid is nearly page-wide, so
      // travel stays below the page-edge clamp.
      await gesture.moveBy(const Offset(20, 0));
      await gesture.moveBy(const Offset(5, 0));
      await gesture.up();
      expect(latest, isNotNull);
      expect(
        (latest!.bounds.left - grid.bounds.left) * 595,
        closeTo(25 / 1.5, .5),
      );
    });

    testWidgets('small pointer jitter under the slop does not transform', (
      tester,
    ) async {
      var calls = 0;
      await tester.pumpWidget(scene(zoom: 1, onTransform: (_) => calls++));
      final gesture = await tester.startGesture(
        tester.getCenter(
          find.byKey(ValueKey('calendar-studio-block-${grid.id}')),
        ),
      );
      await gesture.moveBy(const Offset(3, 2));
      await gesture.up();
      expect(calls, 0);
    });

    testWidgets('the rotate handle rotates around the block centre', (
      tester,
    ) async {
      CalendarStudioBlock? latest;
      await tester.pumpWidget(
        scene(zoom: 2, onTransform: (block) => latest = block),
      );
      final handle = find.byKey(const ValueKey('calendar-studio-rotate'));
      expect(handle, findsOneWidget);
      final blockCenter = tester.getCenter(
        find.byKey(ValueKey('calendar-studio-block-${grid.id}')),
      );
      final gesture = await tester.startGesture(tester.getCenter(handle));
      // Swing the pointer to the right of the centre: a quarter turn.
      await gesture.moveTo(blockCenter + const Offset(400, 0));
      await gesture.up();
      expect(latest!.rotation, closeTo(math.pi / 2, .02));
    });
  });

  testWidgets('arrow keys nudge the selected block by one design pixel', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final project = CalendarStudioTemplates.byId('jade-wall').create(
      id: 'keys-project',
      source: const CalendarStudioSource(
        year: 2027,
        period: CalendarStudioPeriod.month,
      ),
      now: DateTime(2027),
    );
    final store = _MemoryStore()..values[project.id] = project;
    await tester.pumpWidget(
      MaterialApp(
        home: CalendarStudioWorkspace(
          configuration: CalendarStudioConfiguration(projects: store),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calendar grid').first);
    await tester.pumpAndSettle();

    CalendarStudioBlock gridBlock() => tester
        .widget<CalendarStudioScene>(find.byType(CalendarStudioScene))
        .page
        .blocks
        .firstWhere((block) => block.id == 'grid');
    final before = gridBlock().bounds;
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect((gridBlock().bounds.left - before.left) * 595, closeTo(1, 1e-6));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect((gridBlock().bounds.top - before.top) * 842, closeTo(10, 1e-6));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(gridBlock().bounds, before);
  });
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
