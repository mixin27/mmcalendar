import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _openPhoneEditor(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final project = CalendarStudioTemplates.byId('jade-wall').create(
    id: 'ux-project',
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

Future<void> _selectGrid(WidgetTester tester) async {
  await tester.tap(find.text('Layers'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Calendar grid').last);
  await tester.pumpAndSettle();
  // Close the layers sheet by tapping the barrier above it.
  await tester.tapAt(const Offset(195, 20));
  await tester.pumpAndSettle();
}

String? _selected(WidgetTester tester) => tester
    .widget<CalendarStudioScene>(find.byType(CalendarStudioScene))
    .selectedBlockId;

void main() {
  testWidgets('tapping the board outside the page deselects', (tester) async {
    await _openPhoneEditor(tester);
    await _selectGrid(tester);
    expect(_selected(tester), 'grid');

    final board = tester.getRect(
      find.byKey(const ValueKey('calendar-studio-board')),
    );
    final page = tester.getRect(find.byType(CalendarStudioScene));
    // Near the page edge: ignored so edge handles stay usable.
    await tester.tapAt(Offset(page.right + 10, page.center.dy));
    await tester.pumpAndSettle();
    expect(_selected(tester), 'grid');

    // Well outside the page: clears the selection.
    await tester.tapAt(Offset(board.left + 4, board.bottom - 4));
    await tester.pumpAndSettle();
    expect(_selected(tester), isNull);
  });

  testWidgets('phone inspector is a tall, draggable, scrolling sheet', (
    tester,
  ) async {
    await _openPhoneEditor(tester);
    await _selectGrid(tester);
    await tester.tap(find.byTooltip('Edit item'));
    await tester.pumpAndSettle();

    final sheet = find.byType(DraggableScrollableSheet);
    expect(sheet, findsOneWidget);
    final collapsedTop = tester.getTopLeft(find.text('Calendar grid').last).dy;

    await tester.drag(find.text('Calendar grid').last, const Offset(0, -400));
    await tester.pumpAndSettle();
    final expandedTop = tester.getTopLeft(find.text('Calendar grid').last).dy;
    expect(expandedTop, lessThan(collapsedTop - 100));
    expect(expandedTop, lessThan(844 * .2));

    // Dragging it all the way down closes the inspector but keeps selection.
    await tester.drag(find.text('Calendar grid').last, const Offset(0, 800));
    await tester.pumpAndSettle();
    expect(sheet, findsNothing);
    expect(_selected(tester), 'grid');
  });

  testWidgets('page and theme sheet opens tall and scrolls', (tester) async {
    await _openPhoneEditor(tester);
    await tester.tap(find.text('Page'));
    await tester.pumpAndSettle();
    expect(find.text('Page and theme'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('Page and theme'),
        matching: find.byType(SingleChildScrollView),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
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
