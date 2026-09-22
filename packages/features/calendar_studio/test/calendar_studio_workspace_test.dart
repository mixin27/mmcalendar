import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('editor canvas exposes zoom and fit controls', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final project = CalendarStudioTemplates.byId('jade-wall').create(
      id: 'zoom-project',
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

    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);

    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pump();
    expect(find.text('120%'), findsOneWidget);

    await tester.tap(find.byTooltip('Fit canvas'));
    await tester.pump();
    expect(find.text('100%'), findsOneWidget);
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
  Future<void> save(CalendarStudioProject project) async {
    values[project.id] = project;
  }
}
