import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _openEditor(
  WidgetTester tester, {
  required Size size,
  CalendarStudioPeriod period = CalendarStudioPeriod.month,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final project = CalendarStudioTemplates.byId('jade-wall').create(
    id: 'layout-project',
    source: CalendarStudioSource(year: 2027, period: period),
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
    tester.widget<CalendarStudioScene>(find.byType(CalendarStudioScene).first);

const _dock = ValueKey('calendar-studio-docked-inspector');

void main() {
  testWidgets('tablets dock the inspector beside the page', (tester) async {
    await _openEditor(tester, size: const Size(820, 1100));
    expect(find.byKey(_dock), findsNothing);

    await tester.tap(find.byKey(const ValueKey('calendar-studio-tool-text')));
    await tester.pumpAndSettle();
    expect(find.byKey(_dock), findsOneWidget);
    expect(find.byType(DraggableScrollableSheet), findsNothing);
    // The page stays fully usable to the left of the dock.
    final page = tester.getRect(find.byType(CalendarStudioScene));
    expect(page.right, lessThan(tester.getRect(find.byKey(_dock)).left));

    await tester.tap(find.byTooltip('Close inspector'));
    await tester.pumpAndSettle();
    expect(find.byKey(_dock), findsNothing);
    expect(_scene(tester).selectedBlockId, isNotNull);

    await tester.tap(find.byTooltip('Edit item'));
    await tester.pumpAndSettle();
    expect(find.byKey(_dock), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop shows every page in a strip', (tester) async {
    await _openEditor(
      tester,
      size: const Size(1440, 900),
      period: CalendarStudioPeriod.year,
    );
    expect(
      find.byKey(const ValueKey('calendar-studio-page-strip')),
      findsOneWidget,
    );
    final third = find.byKey(const ValueKey('calendar-studio-strip-page-2'));
    expect(third, findsOneWidget);
    await tester.tap(third);
    await tester.pumpAndSettle();
    expect(_scene(tester).page.month, 3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('single-page projects have no strip', (tester) async {
    await _openEditor(tester, size: const Size(1440, 900));
    expect(
      find.byKey(const ValueKey('calendar-studio-page-strip')),
      findsNothing,
    );
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
