import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2027, 3, 10, 12);

CalendarStudioProject _project(
  String id,
  String templateId, {
  CalendarStudioExportRecord? lastExport,
  Duration savedAgo = const Duration(minutes: 2),
}) {
  final project = CalendarStudioTemplates.byId(templateId).create(
    id: id,
    source: const CalendarStudioSource(year: 2027),
    now: _now.subtract(savedAgo),
  );
  return project.copyWith(lastExport: lastExport);
}

Future<_Store> _pump(
  WidgetTester tester,
  List<CalendarStudioProject> projects,
) async {
  tester.view.physicalSize = const Size(430, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final store = _Store()..values.addAll({for (final p in projects) p.id: p});
  await tester.pumpWidget(
    MaterialApp(
      home: CalendarStudioWorkspace(
        configuration: CalendarStudioConfiguration(
          projects: store,
          now: () => _now,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

void main() {
  testWidgets('dashboard shows preset, period, save time and export badge', (
    tester,
  ) async {
    await _pump(tester, [
      _project(
        'family',
        'family',
        lastExport: CalendarStudioExportRecord(
          exportedAt: _now.subtract(const Duration(days: 3)),
          presetLabel: 'A4 print',
          format: CalendarStudioExportFormat.pdf,
          pageCount: 12,
          fileName: 'family-2027.pdf',
        ),
      ),
    ]);
    expect(
      find.text('Hearth & Home · Jan–Dec 2027 · Saved 2 min ago'),
      findsOneWidget,
    );
    expect(find.text('Exported'), findsOneWidget);
    expect(find.textContaining('family'), findsNothing);

    await tester.tap(find.byTooltip('List view'));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsOneWidget);
    expect(find.byTooltip('Grid view'), findsOneWidget);
  });

  testWidgets('project detail shows exports and opens a page', (tester) async {
    await _pump(tester, [_project('ocean', 'ocean')]);
    await tester.tap(find.text('Tidewater 2027').last);
    await tester.pumpAndSettle();

    expect(find.text('Not exported yet'), findsOneWidget);
    expect(find.text('Open editor'), findsOneWidget);
    expect(find.textContaining('Myanmar + English'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('calendar-studio-detail-page-4')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(
      find.byKey(const ValueKey('calendar-studio-detail-page-4')),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('May · 5/12'), findsOneWidget);
  });

  testWidgets('long-pressing a page exports just that month', (tester) async {
    await _pump(tester, [_project('ocean', 'ocean')]);
    await tester.tap(find.text('Tidewater 2027').last);
    await tester.pumpAndSettle();
    await tester.longPress(
      find.byKey(const ValueKey('calendar-studio-detail-page-1')),
    );
    await tester.pumpAndSettle();
    expect(find.text('This page'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      endsWith('-2027-02'),
    );
  });

  testWidgets('empty dashboard offers presets and import', (tester) async {
    await _pump(tester, []);
    expect(find.text('Design your first calendar'), findsOneWidget);
    expect(find.text('Browse presets'), findsOneWidget);
    expect(find.text('Import a project file'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
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
