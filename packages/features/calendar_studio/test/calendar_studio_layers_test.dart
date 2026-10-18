import 'package:calendar_studio/calendar_studio.dart';
import 'package:calendar_studio/src/presentation/calendar_studio_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

CalendarStudioScene _scene(WidgetTester tester) =>
    tester.widget<CalendarStudioScene>(find.byType(CalendarStudioScene).first);

/// Block ids front to back, as the layers list shows them.
List<String> _frontToBack(WidgetTester tester) {
  final blocks = [..._scene(tester).page.blocks]
    ..sort((a, b) => b.zIndex.compareTo(a.zIndex));
  return [for (final b in blocks) b.id];
}

Future<void> _openDesktopEditor(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final project = CalendarStudioTemplates.byId('jade-wall').create(
    id: 'layers-project',
    source: const CalendarStudioSource(year: 2027),
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

void main() {
  testWidgets('layers list front to back and drag to reorder', (tester) async {
    await _openDesktopEditor(tester);
    final order = _frontToBack(tester);
    expect(order.length, greaterThan(2));

    // Rows appear in drawing order, frontmost first.
    final rows = tester
        .widgetList<ListTile>(
          find.descendant(
            of: find.byKey(const ValueKey('calendar-studio-layers')),
            matching: find.byType(ListTile),
          ),
        )
        .map((tile) => (tile.key! as ValueKey<String>).value)
        .toList();
    expect(rows, [for (final id in order) 'calendar-studio-layer-row-$id']);

    // Drag the frontmost layer below the next one.
    final top = order.first;
    final handle = find.descendant(
      of: find.byKey(ValueKey('calendar-studio-layer-row-$top')),
      matching: find.byIcon(Icons.drag_indicator),
    );
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(const Duration(milliseconds: 100));
    for (var i = 0; i < 8; i++) {
      await gesture.moveBy(const Offset(0, 12));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await gesture.up();
    await tester.pumpAndSettle();
    expect(_frontToBack(tester).indexOf(top), greaterThan(0));
    expect(_frontToBack(tester).toSet(), order.toSet());

    // One undo puts it back.
    await tester.tap(find.byTooltip('Undo').first);
    await tester.pumpAndSettle();
    expect(_frontToBack(tester), order);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a selected layer can be renamed', (tester) async {
    await _openDesktopEditor(tester);
    final id = _frontToBack(tester).first;
    await tester.tap(find.byKey(ValueKey('calendar-studio-layer-row-$id')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('calendar-studio-rename-layer')),
    );
    await tester.pumpAndSettle();
    expect(find.text(StudioStrings.renameLayer), findsOneWidget);
    await tester.enterText(find.byType(EditableText).last, 'Family photo');
    await tester.tap(find.text(StudioStrings.rename).last);
    await tester.pumpAndSettle();
    expect(
      _scene(tester).page.blocks.firstWhere((b) => b.id == id).name,
      'Family photo',
    );
    expect(find.text('Family photo'), findsWidgets);
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
