import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<_MemoryStore> _openEditor(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final project = CalendarStudioTemplates.byId('love_relationship').create(
    id: 'settings-project',
    source: const CalendarStudioSource(year: 2027, month: 4),
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
  return store;
}

CalendarStudioScene _scene(WidgetTester tester) =>
    tester.widget<CalendarStudioScene>(find.byType(CalendarStudioScene));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find
        .byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        )
        .last,
  );
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Theme chips sit in a sideways list under the Theme heading.
Future<void> _pickTheme(WidgetTester tester, String id) async {
  final customise = find.byKey(const ValueKey('studio-theme-customize'));
  await tester.scrollUntilVisible(
    customise,
    200,
    scrollable: find
        .byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        )
        .last,
  );
  await tester.pumpAndSettle();
  final row = find
      .descendant(
        of: find.byKey(const ValueKey('studio-theme-row')),
        matching: find.byType(Scrollable),
      )
      .first;
  await tester.ensureVisible(find.byKey(const ValueKey('studio-theme-row')));
  await tester.pumpAndSettle();
  final chip = find.byKey(ValueKey('studio-theme-$id'));
  await tester.scrollUntilVisible(chip, 200, scrollable: row);
  await tester.pumpAndSettle();
  await tester.tap(chip);
  await tester.pumpAndSettle();
}

void main() {
  test('canvas changes reach every page as one undo step', () async {
    final controller = CalendarStudioController(
      CalendarStudioConfiguration(projects: _MemoryStore()),
    );
    await controller.create(
      'jade-wall',
      const CalendarStudioSource(year: 2027),
    );
    final before = controller.project!;
    expect(before.pages.length, 12);
    controller.updateCanvases((c) => c.copyWith(width: 600, height: 600));
    for (final page in controller.project!.pages) {
      expect(page.canvas.aspectRatio, 1);
    }
    controller.undo();
    expect(controller.project!.pages, before.pages);

    controller
      ..setPage(3)
      ..updateCanvases(
        (c) => c.copyWith(width: 297, height: 210),
        allPages: false,
      );
    expect(controller.project!.pages[3].canvas.width, 297);
    expect(controller.project!.pages[4].canvas.width, 210);
    controller.dispose();
  });

  testWidgets('project settings apply theme, size and output together', (
    tester,
  ) async {
    await _openEditor(tester);
    await tester.tap(find.byIcon(Icons.tune).first);
    await tester.pumpAndSettle();
    expect(find.text('Project settings'), findsOneWidget);
    expect(find.text('Myanmar Time (UTC+6:30)'), findsNothing);

    await _pickTheme(tester, 'indigo');
    await _tap(tester, find.byKey(const ValueKey('studio-page-size-story')));
    await _tap(tester, find.byKey(const ValueKey('studio-output-square-png')));
    expect(find.text('Myanmar Time (UTC+6:30)'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('studio-settings-apply')));
    await tester.pumpAndSettle();

    final indigo = CalendarStudioProjectThemes.library.firstWhere(
      (t) => t.id == 'indigo',
    );
    final page = _scene(tester).page;
    expect(page.canvas.width, 360);
    expect(page.canvas.backgroundColor, indigo.color('paper'));

    // One undo brings back the whole settings change.
    await tester.tap(find.byIcon(Icons.undo));
    await tester.pumpAndSettle();
    expect(_scene(tester).page.canvas.width, 600);
    expect(
      _scene(tester).page.canvas.backgroundColor,
      isNot(indigo.color('paper')),
    );
  });

  testWidgets('page settings colour the page from the theme', (tester) async {
    await _openEditor(tester);
    await tester.tap(find.text('Page'));
    await tester.pumpAndSettle();
    expect(find.text('Page settings'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('studio-color-page-background-accent')),
    );
    await tester.pumpAndSettle();
    final rose = CalendarStudioProjectThemes.library.firstWhere(
      (t) => t.id == 'love_relationship',
    );
    expect(_scene(tester).page.canvas.backgroundColor, rose.color('accent'));
  });

  testWidgets('setup has Calendar, Theme and Format steps', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = _MemoryStore();
    await tester.pumpWidget(
      MaterialApp(
        home: CalendarStudioWorkspace(
          configuration: CalendarStudioConfiguration(projects: store),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Browse presets'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rose Bond'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('calendar-studio-use-preset')));
    await tester.pumpAndSettle();
    expect(find.text('Set up Rose Bond'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('studio-setup-next')));
    await tester.pumpAndSettle();
    await _pickTheme(tester, 'mono');
    await tester.tap(find.byKey(const ValueKey('studio-setup-next')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('studio-setup-next')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('studio-setup-create')));
    await tester.pumpAndSettle();

    // Saving waits for a pause in editing.
    await tester.pump(const Duration(seconds: 1));
    final created = store.values.values.single;
    expect(created.theme?.id, 'mono');
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
