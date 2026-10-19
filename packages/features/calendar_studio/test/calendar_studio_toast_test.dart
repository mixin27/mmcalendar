import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _openAndDeleteGrid(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final project = CalendarStudioTemplates.byId('jade-wall').create(
    id: 'toast',
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
          projects: _Store()..values[project.id] = project,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Resume'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Calendar grid').first);
  await tester.pumpAndSettle();
  await tester.sendKeyEvent(LogicalKeyboardKey.delete);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

bool _hasGrid(WidgetTester tester) => tester
    .widget<CalendarStudioScene>(find.byType(CalendarStudioScene))
    .page
    .blocks
    .any((block) => block.id == 'grid');

void main() {
  testWidgets('delete toast counts down and goes away on its own', (
    tester,
  ) async {
    await _openAndDeleteGrid(tester);
    expect(_hasGrid(tester), isFalse);
    expect(find.text('Calendar grid deleted'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Calendar grid deleted'), findsNothing);
  });

  testWidgets('undo restores the block before the countdown ends', (
    tester,
  ) async {
    await _openAndDeleteGrid(tester);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(_hasGrid(tester), isTrue);
    expect(find.text('Calendar grid deleted'), findsNothing);
  });
}

class _Store implements CalendarStudioProjectStore {
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
