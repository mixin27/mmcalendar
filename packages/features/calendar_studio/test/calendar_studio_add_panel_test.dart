import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _openEditor(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final project = CalendarStudioTemplates.byId('love_relationship').create(
    id: 'add-project',
    source: const CalendarStudioSource(
      year: 2027,
      month: 5,
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

CalendarStudioBlock _selected(WidgetTester tester) {
  final scene = _scene(tester);
  return scene.page.blocks.firstWhere((b) => b.id == scene.selectedBlockId);
}

Future<void> _openAdd(WidgetTester tester, [String? tab]) async {
  await tester.tap(find.byKey(const ValueKey('calendar-studio-tool-add')));
  await tester.pumpAndSettle();
  if (tab != null) {
    await tester.tap(
      find.descendant(of: find.byType(TabBar), matching: find.text(tab)),
    );
    await tester.pumpAndSettle();
  }
}

Future<void> _add(WidgetTester tester, String id) async {
  final item = find.byKey(ValueKey('studio-add-$id'));
  await tester.scrollUntilVisible(
    item,
    120,
    scrollable: find
        .descendant(
          of: find.byKey(const ValueKey('calendar-studio-add-panel')),
          matching: find.byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          ),
        )
        .first,
  );
  await tester.ensureVisible(item);
  await tester.pumpAndSettle();
  await tester.tap(item, warnIfMissed: true);
  await tester.pumpAndSettle();
}

void main() {
  final rose = CalendarStudioProjectThemes.library.firstWhere(
    (t) => t.id == 'love_relationship',
  );

  testWidgets('text styles come in the project theme', (tester) async {
    await _openEditor(tester);
    await _openAdd(tester);
    await _add(tester, 'text-title');
    final block = _selected(tester);
    expect(block.type, CalendarStudioBlockType.text);
    expect(block.style['fontSize'], 44);
    expect(block.style['color'], rose.color('primary'));
    expect(block.style['fontFamily'], rose.displayFont);
    expect(
      find.byKey(const ValueKey('calendar-studio-add-panel')),
      findsNothing,
    );
  });

  testWidgets('decorations, calendar parts and Recent', (tester) async {
    await _openEditor(tester);
    await _openAdd(tester, 'Elements');
    await _add(tester, 'decoration-stupa');
    expect(_selected(tester).type, CalendarStudioBlockType.decoration);
    expect(_selected(tester).content['kind'], 'stupa');
    expect(_selected(tester).style['accent'], rose.color('accent'));

    await _openAdd(tester, 'Calendar');
    expect(find.text('Mini month · previous'), findsOneWidget);
    await _add(tester, 'events');
    final events = _selected(tester);
    expect(events.type, CalendarStudioBlockType.eventList);
    expect(events.content['title'], 'This month');

    await _openAdd(tester, 'Recent');
    final before = _scene(tester).page.blocks.length;
    await _add(tester, 'decoration-stupa');
    expect(_scene(tester).page.blocks.length, before + 1);
  });

  testWidgets('Elements opens on shapes', (tester) async {
    await _openEditor(tester);
    await tester.tap(
      find.byKey(const ValueKey('calendar-studio-tool-elements')),
    );
    await tester.pumpAndSettle();
    await _add(tester, 'shape-star');
    expect(_selected(tester).content['shape'], 'star');
    expect(_selected(tester).style['color'], rose.color('primary'));
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
