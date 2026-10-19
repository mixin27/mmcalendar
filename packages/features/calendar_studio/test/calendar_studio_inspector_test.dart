import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _openEditor(
  WidgetTester tester, {
  String template = 'jade-wall',
}) async {
  tester.view.physicalSize = const Size(1440, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final project = CalendarStudioTemplates.byId(template).create(
    id: 'inspector-project',
    source: const CalendarStudioSource(
      year: 2027,
      month: 3,
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

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _tab(WidgetTester tester, String label) => _tap(
  tester,
  find.descendant(
    of: find.byKey(const ValueKey('studio-inspector-tabs')),
    matching: find.text(label),
  ),
);

Future<void> _addText(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('calendar-studio-tool-text')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('text: typing in the field is one undo step', (tester) async {
    await _openEditor(tester);
    await _addText(tester);
    for (final tab in ['Content', 'Style', 'Layout']) {
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('studio-inspector-tabs')),
          matching: find.text(tab),
        ),
        findsOneWidget,
      );
    }
    final field = find.widgetWithText(TextFormField, 'Text');
    await tester.tap(field);
    await tester.pump();
    for (final text in ['S', 'Sp', 'Spring']) {
      await tester.enterText(field, text);
      await tester.pump();
    }
    expect(_selected(tester).content['text'], 'Spring');
    // Leaving the field ends the typing session.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.undo));
    await tester.pumpAndSettle();
    expect(_selected(tester).content['text'], 'New text');
  });

  testWidgets('text: shows the month name for each page', (tester) async {
    await _openEditor(tester);
    await _addText(tester);
    await _tap(tester, find.byKey(const ValueKey('studio-binding-monthTitle')));
    final block = _selected(tester);
    expect(block.content['binding'], 'monthTitle');
    expect(block.content['text'], isNot('New text'));

    // Typing your own words drops the binding.
    await tester.enterText(find.widgetWithText(TextFormField, 'Text'), 'Mine');
    await tester.pump();
    expect(_selected(tester).content.containsKey('binding'), isFalse);
  });

  testWidgets('text: style presets, steppers, colour and font', (tester) async {
    await _openEditor(tester);
    await _addText(tester);
    await _tab(tester, 'Style');

    await _tap(tester, find.byKey(const ValueKey('studio-text-style-title')));
    expect(_selected(tester).style['fontSize'], 44);

    await _tap(tester, find.byTooltip('Size +'));
    expect(_selected(tester).style['fontSize'], 45);

    final theme = CalendarStudioProjectThemes.of(
      CalendarStudioTemplates.byId('jade-wall').create(
        id: 'x',
        source: const CalendarStudioSource(year: 2027),
        now: DateTime(2027),
      ),
    );
    await _tap(tester, find.byKey(const ValueKey('studio-color-text-holiday')));
    expect(_selected(tester).style['color'], theme.color('holiday'));

    await _tap(tester, find.byKey(const ValueKey('studio-font-field')));
    await _tap(tester, find.byKey(const ValueKey('studio-font-Lora')));
    expect(_selected(tester).style['fontFamily'], 'Lora');
  });

  testWidgets('layout: typed position moves the block', (tester) async {
    await _openEditor(tester);
    await _addText(tester);
    await _tab(tester, 'Layout');
    final x = find.byKey(const ValueKey('studio-stepper-X'));
    await tester.ensureVisible(x);
    await tester.enterText(x, '119');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    final size = CalendarStudioScene.designSizeFor(_scene(tester).page.canvas);
    expect(_selected(tester).bounds.left * size.width, closeTo(119, .01));
  });

  testWidgets('grid: every colour role is editable', (tester) async {
    await _openEditor(tester);
    await tester.tap(find.text('Calendar grid').first);
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(SwitchListTile, 'Myanmar dates'),
      findsOneWidget,
    );
    await _tab(tester, 'Style');
    for (final key in [
      'inkColor',
      'weekendColor',
      'headerColor',
      'holidayColor',
      'sabbathColor',
      'eventColor',
      'lineColor',
    ]) {
      expect(
        find.byKey(ValueKey('studio-color-$key-primary')),
        findsOneWidget,
        reason: key,
      );
    }
    await _tap(
      tester,
      find.byKey(const ValueKey('studio-color-weekendColor-accent')),
    );
    final grid = _selected(tester);
    expect(grid.type, CalendarStudioBlockType.calendarGrid);
    expect(grid.style['weekendColor'], isA<int>());
  });

  testWidgets('images get rounded corners and a border', (tester) async {
    const block = CalendarStudioBlock(
      id: 'photo',
      type: CalendarStudioBlockType.image,
      name: 'Photo',
      bounds: StudioRect(left: .1, top: .1, width: .5, height: .3),
      style: {'cornerRadius': 24, 'borderWidth': 4, 'borderColor': 0xFF0E6B5C},
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: CalendarStudioScene(
          page: CalendarStudioPage(
            id: 'p',
            label: 'March',
            year: 2027,
            month: 3,
            canvas: StudioCanvas(width: 210, height: 297),
            blocks: [block],
          ),
          source: CalendarStudioSource(year: 2027, month: 3),
        ),
      ),
    );
    final clip = tester.widget<ClipRRect>(find.byType(ClipRRect));
    expect(clip.borderRadius, BorderRadius.circular(24));
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
