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

  testWidgets('manual save and back preserve edited calendar data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final project = CalendarStudioTemplates.byId('jade-wall').create(
      id: 'saved-project',
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

    await tester.tap(find.text('Layers'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calendar grid'));
    await tester.tapAt(const Offset(8, 80));
    await tester.pumpAndSettle();

    final myanmarDates = find.widgetWithText(SwitchListTile, 'Myanmar dates');
    expect(myanmarDates, findsOneWidget);
    await tester.tap(myanmarDates);
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();

    expect(store.values[project.id]!.source.showMyanmarDate, isFalse);

    final moonPhases = find.widgetWithText(SwitchListTile, 'Moon phases');
    await tester.tap(moonPhases);
    await tester.pump();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(store.values[project.id]!.source.showMoonPhases, isFalse);
    expect(find.text('Resume'), findsOneWidget);
  });

  testWidgets('dark appearance uses the exact dark Studio tokens', (
    tester,
  ) async {
    final store = _MemoryStore();
    await tester.pumpWidget(
      MaterialApp(
        home: CalendarStudioWorkspace(
          configuration: CalendarStudioConfiguration(
            projects: store,
            appearance: CalendarStudioAppearance.dark,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold));
    final theme = Theme.of(context);
    final tokens = CalendarStudioTokens.of(context);
    expect(theme.brightness, Brightness.dark);
    expect(tokens.background, const Color(0xFF0D1412));
    expect(tokens.surface, const Color(0xFF151E1C));
    expect(tokens.ink, const Color(0xFFE4EEEB));
    expect(tokens.holiday, const Color(0xFFF2857B));
  });

  testWidgets('selected blocks expose eight resize handles and quick actions', (
    tester,
  ) async {
    final project = CalendarStudioTemplates.byId('jade-wall').create(
      id: 'selection-project',
      source: const CalendarStudioSource(year: 2027),
      now: DateTime(2027),
    );
    final page = project.pages.first;
    final grid = page.blocks.firstWhere(
      (block) => block.type == CalendarStudioBlockType.calendarGrid,
    );
    CalendarStudioBlock? transformed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 595,
            child: CalendarStudioScene(
              page: page,
              source: project.source,
              selectedBlockId: grid.id,
              onTransform: (block) => transformed = block,
              onDuplicate: () {},
              onToggleLock: () {},
              onToggleVisibility: () {},
              onMove: () {},
              onDelete: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    for (final name in const [
      'topLeft',
      'top',
      'topRight',
      'left',
      'right',
      'bottomLeft',
      'bottom',
      'bottomRight',
    ]) {
      expect(
        find.byKey(ValueKey('calendar-studio-resize-$name')),
        findsOneWidget,
      );
    }
    expect(find.byTooltip('Duplicate'), findsOneWidget);
    expect(find.byTooltip('Lock'), findsOneWidget);
    expect(find.byTooltip('Hide'), findsOneWidget);
    expect(find.byTooltip('Move'), findsOneWidget);
    expect(find.byTooltip('Delete'), findsOneWidget);

    await tester.drag(
      find.byKey(ValueKey('calendar-studio-block-${grid.id}')),
      const Offset(36, 18),
    );
    await tester.pump();
    expect(transformed, isNotNull);
    expect(transformed!.bounds.left, greaterThan(grid.bounds.left));
    expect(transformed!.bounds.top, greaterThan(grid.bounds.top));
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
