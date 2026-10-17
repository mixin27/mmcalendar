import 'dart:typed_data';

import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2027, 3, 10, 12);

Future<(_Projects, _Templates)> _pump(
  WidgetTester tester, {
  List<CalendarStudioProject> projects = const [],
  List<CalendarStudioUserTemplate> templates = const [],
  Future<Uint8List?> Function()? pickTemplateFile,
}) async {
  tester.view.physicalSize = const Size(430, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final projectStore = _Projects()
    ..values.addAll({for (final p in projects) p.id: p});
  final templateStore = _Templates()
    ..values.addAll({for (final t in templates) t.id: t});
  await tester.pumpWidget(
    MaterialApp(
      home: CalendarStudioWorkspace(
        configuration: CalendarStudioConfiguration(
          projects: projectStore,
          templates: templateStore,
          pickTemplateFile: pickTemplateFile,
          now: () => _now,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (projectStore, templateStore);
}

CalendarStudioProject _jade() => CalendarStudioTemplates.byId(
  'jade-wall',
).create(id: 'jade', source: const CalendarStudioSource(year: 2027), now: _now);

CalendarStudioUserTemplate _saved(String name) {
  final project = _jade();
  final page = project.pages.first;
  return CalendarStudioUserTemplates.capture(
    project,
    page,
    name: name,
    author: 'Aye',
    blocks: CalendarStudioUserTemplates.detectBindings(page),
    keepPhotos: false,
    now: _now,
  );
}

Future<void> _openGallery(WidgetTester tester) async {
  await tester.tap(find.text('New calendar'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Save as template keeps the chosen titles bound', (tester) async {
    final (_, templates) = await _pump(tester, projects: [_jade()]);
    await tester.tap(find.text('Jade wall 2027').last);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('calendar-studio-save-template')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Save as template'), findsWidgets);
    expect(find.text('Updates every month'.toUpperCase()), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('calendar-studio-template-name')),
      'Gold wall',
    );
    // Keep the year as typed; the month titles stay bound.
    final year = find.byKey(
      const ValueKey('calendar-studio-template-binding-year-mm'),
    );
    await tester.ensureVisible(year);
    await tester.pumpAndSettle();
    await tester.tap(year);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('calendar-studio-template-save')),
    );
    await tester.pumpAndSettle();

    final saved = templates.values.values.single;
    expect(saved.name, 'Gold wall');
    expect(saved.basePresetId, 'jade-wall');
    CalendarStudioBinding? bindingOf(String id) => CalendarStudioBindings.of(
      saved.blocks.firstWhere((block) => block.id == id),
    );
    expect(bindingOf('month-mm'), CalendarStudioBinding.monthTitle);
    expect(bindingOf('month-en'), CalendarStudioBinding.monthYear);
    expect(bindingOf('year-mm'), isNull);
    expect(find.text('Saved “Gold wall” to My templates.'), findsOneWidget);
  });

  testWidgets('the gallery lists My templates first and creates from them', (
    tester,
  ) async {
    final template = _saved('Gold wall');
    final (projects, _) = await _pump(
      tester,
      projects: [_jade()],
      templates: [template],
    );
    await _openGallery(tester);
    expect(find.text('MY TEMPLATES'), findsOneWidget);
    expect(find.text('Gold wall'), findsOneWidget);
    final mine = tester.getTopLeft(find.text('MY TEMPLATES')).dy;
    final fresh = tester.getTopLeft(find.text('NEW · VOL 1 & 2')).dy;
    expect(mine, lessThan(fresh));

    await tester.tap(find.text('Gold wall'));
    await tester.pumpAndSettle();
    expect(find.text('By'), findsOneWidget);
    expect(find.text('Aye'), findsOneWidget);
    expect(find.text('Based on'), findsOneWidget);
    expect(find.text('Jade wall'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('calendar-studio-use-preset')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create project').last);
    await tester.pumpAndSettle();
    final created = projects.values.values.firstWhere(
      (project) => project.templateId == template.templateId,
    );
    expect(created.pages, hasLength(12));
    expect(created.name, startsWith('Gold wall '));
  });

  testWidgets('a template can be renamed and deleted from its menu', (
    tester,
  ) async {
    final template = _saved('Gold wall');
    final (_, templates) = await _pump(
      tester,
      projects: [_jade()],
      templates: [template],
    );
    await _openGallery(tester);

    final menu = find.byKey(
      ValueKey('calendar-studio-template-menu-${template.id}'),
    );
    await tester.tap(menu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'Rose wall',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Rename'));
    await tester.pumpAndSettle();
    expect(templates.values.values.single.name, 'Rose wall');
    expect(find.text('Rose wall'), findsOneWidget);

    await tester.tap(menu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete…'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(templates.values, isEmpty);
    expect(find.text('MY TEMPLATES'), findsNothing);
  });

  testWidgets('Import template reviews the file and adds it', (tester) async {
    final bytes = (await tester.runAsync(() async {
      final artifact = await CalendarStudioTemplateBundle.export(
        _saved('Shared wall'),
        fileName: 'shared',
      );
      return Uint8List.fromList(artifact.bytes);
    }))!;
    final (_, templates) = await _pump(
      tester,
      projects: [_jade()],
      pickTemplateFile: () async => bytes,
    );
    await _openGallery(tester);
    expect(find.text('MY TEMPLATES'), findsNothing);

    await tester.runAsync(() async {
      await tester.tap(find.byTooltip('Import template'));
      await tester.pump();
      for (
        var i = 0;
        i < 100 && find.text('Saved to').evaluate().isEmpty;
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await tester.pump();
      }
    });
    await tester.pumpAndSettle();
    expect(find.text('Import template'), findsWidgets);
    expect(find.text('By Aye'), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(
        find.byKey(const ValueKey('calendar-studio-template-import-confirm')),
      );
      for (var i = 0; i < 100 && templates.values.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await tester.pump();
      }
    });
    await tester.pumpAndSettle();
    expect(templates.values.values.single.name, 'Shared wall');
    expect(find.text('MY TEMPLATES'), findsOneWidget);
    expect(find.text('Added “Shared wall” to My templates.'), findsOneWidget);
  });
}

class _Projects implements CalendarStudioProjectStore {
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

class _Templates implements CalendarStudioTemplateStore {
  final values = <String, CalendarStudioUserTemplate>{};
  @override
  Future<void> delete(String id) async => values.remove(id);
  @override
  Future<List<CalendarStudioUserTemplate>> list() async =>
      values.values.toList();
  @override
  Future<void> save(CalendarStudioUserTemplate template) async =>
      values[template.id] = template;
}
