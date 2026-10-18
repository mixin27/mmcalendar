import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _openEditor(
  WidgetTester tester, {
  Size size = const Size(1440, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final project = CalendarStudioTemplates.byId('jade-wall').create(
    id: 'canvas-project',
    source: const CalendarStudioSource(
      year: 2027,
      period: CalendarStudioPeriod.month,
    ),
    now: DateTime(2027),
  );
  await tester.pumpWidget(
    MaterialApp(
      home: CalendarStudioWorkspace(
        configuration: CalendarStudioConfiguration(
          projects: _MemoryStore()..values[project.id] = project,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Resume'));
  await tester.pumpAndSettle();
}

CalendarStudioScene _scene(WidgetTester tester) =>
    tester.widget<CalendarStudioScene>(find.byType(CalendarStudioScene));

CalendarStudioBlock _block(WidgetTester tester, String id) =>
    _scene(tester).page.blocks.firstWhere((b) => b.id == id);

/// Adds a text block with the Text tool; it arrives selected, on top.
Future<String> _addText(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('calendar-studio-tool-text')));
  await tester.pumpAndSettle();
  return _scene(tester).selectedBlockId!;
}

Finder _blockFinder(String id) =>
    find.byKey(ValueKey('calendar-studio-block-$id'));

void main() {
  testWidgets('double-tap types on the page as one undo step', (tester) async {
    await _openEditor(tester);
    final id = await _addText(tester);
    final before = _block(tester, id).content['text'];

    await tester.tap(_blockFinder(id));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(_blockFinder(id));
    await tester.pumpAndSettle();

    final inline = find.byKey(ValueKey('calendar-studio-inline-text-$id'));
    expect(inline, findsOneWidget);
    expect(_scene(tester).editingBlockId, id);
    // The bar keeps text formatting while typing, without Edit text.
    expect(find.byTooltip('Larger text'), findsOneWidget);
    expect(find.byTooltip('Edit text'), findsNothing);

    final field = find.descendant(of: inline, matching: find.byType(TextField));
    for (final text in ['H', 'He', 'Hello']) {
      await tester.enterText(field, text);
      await tester.pump();
    }
    expect(_block(tester, id).content['text'], 'Hello');

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(inline, findsNothing);
    expect(_scene(tester).editingBlockId, isNull);
    expect(_scene(tester).selectedBlockId, id);

    await tester.tap(find.byIcon(Icons.undo));
    await tester.pumpAndSettle();
    expect(_block(tester, id).content['text'], before);
  });

  testWidgets('Enter edits the selected text; Edit text does too', (
    tester,
  ) async {
    await _openEditor(tester);
    final id = await _addText(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(_scene(tester).editingBlockId, id);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(_scene(tester).editingBlockId, isNull);

    await tester.tap(find.byTooltip('Edit text'));
    await tester.pumpAndSettle();
    expect(_scene(tester).editingBlockId, id);
  });

  testWidgets('the contextual bar fits the selected block', (tester) async {
    await _openEditor(tester, size: const Size(390, 844));
    final id = await _addText(tester);
    expect(
      find.byKey(const ValueKey('calendar-studio-contextual-bar')),
      findsOneWidget,
    );
    expect(find.byTooltip('Edit text'), findsOneWidget);
    expect(find.byTooltip('Edit item'), findsOneWidget);
    final size = _block(tester, id).style['fontSize'] as num? ?? 20;
    await tester.tap(find.byTooltip('Larger text'));
    await tester.pumpAndSettle();
    expect(_block(tester, id).style['fontSize'] as num, greaterThan(size));

    // The bar sits above the block on screen, inside the board.
    final bar = tester.getRect(
      find.byKey(const ValueKey('calendar-studio-contextual-bar')),
    );
    final block = tester.getRect(_blockFinder(id));
    expect(bar.bottom, lessThanOrEqualTo(block.top));
    expect(bar.left, greaterThanOrEqualTo(0));
    expect(bar.right, lessThanOrEqualTo(390));

    await tester.tap(find.byKey(const ValueKey('calendar-studio-bar-color')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('calendar-studio-bar-color-holiday')),
    );
    await tester.pumpAndSettle();
    expect(_block(tester, id).style['color'], isA<int>());

    await tester.tap(find.text('Layers'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calendar grid').last);
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(195, 20));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Days shown'), findsOneWidget);
    expect(find.byTooltip('Edit text'), findsNothing);
  });

  testWidgets('long-press adds to the selection; align lines them up', (
    tester,
  ) async {
    await _openEditor(tester);
    final text = await _addText(tester);
    final grid = _scene(tester).page.blocks.firstWhere(
      (b) => b.type == CalendarStudioBlockType.calendarGrid,
    );
    await tester.tap(find.text('Calendar grid').first);
    await tester.pumpAndSettle();
    expect(_scene(tester).selectedBlockId, grid.id);

    await tester.longPress(_blockFinder(text));
    await tester.pumpAndSettle();
    expect(_scene(tester).selectedBlockIds, {grid.id, text});
    expect(find.text('2 selected'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('calendar-studio-bar-align')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Align left'));
    await tester.pumpAndSettle();
    final left = [
      _block(tester, grid.id).bounds.left,
      _block(tester, text).bounds.left,
    ];
    expect(left[0], closeTo(left[1], 1e-9));

    // Shift-click takes one back out.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.tap(_blockFinder(text));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
    expect(_scene(tester).selectedBlockIds, {grid.id});
  });

  testWidgets('a mouse drag across the page selects what it touches', (
    tester,
  ) async {
    await _openEditor(tester);
    final text = await _addText(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(_scene(tester).selectedBlockIds, isEmpty);

    final page = tester.getRect(find.byType(CalendarStudioScene));
    final mouse = await tester.startGesture(
      page.topLeft + Offset(page.width * .9, page.height * .12),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    await mouse.moveTo(
      page.topLeft + Offset(page.width * .5, page.height * .2),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('calendar-studio-marquee')),
      findsOneWidget,
    );
    await mouse.moveTo(
      page.topLeft + Offset(page.width * .45, page.height * .25),
    );
    await mouse.up();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('calendar-studio-marquee')), findsNothing);
    expect(_scene(tester).selectedBlockIds, contains(text));
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
