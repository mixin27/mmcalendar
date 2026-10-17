import 'package:alchemist/alchemist.dart';
import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2027, 3, 10, 12);

CalendarStudioProject _jade() => CalendarStudioTemplates.byId(
  'jade-wall',
).create(id: 'jade', source: const CalendarStudioSource(year: 2027), now: _now);

CalendarStudioUserTemplate _saved() {
  final project = _jade();
  final page = project.pages.first;
  return CalendarStudioUserTemplates.capture(
    project,
    page,
    name: 'Gold wall',
    blocks: CalendarStudioUserTemplates.detectBindings(page),
    keepPhotos: false,
    now: _now,
  );
}

Widget _studio({List<CalendarStudioUserTemplate> templates = const []}) =>
    SizedBox(
      width: 390,
      height: 800,
      // The app supplies one; save and share report through it.
      child: ScaffoldMessenger(
        child: CalendarStudioWorkspace(
          configuration: CalendarStudioConfiguration(
            projects: _Projects([_jade()]),
            templates: _Templates(templates),
            now: () => _now,
          ),
        ),
      ),
    );

void main() {
  goldenTest(
    'My templates lead the gallery',
    fileName: 'user_templates_gallery',
    pumpBeforeTest: (tester) async {
      await tester.pumpAndSettle();
      await tester.tap(find.text('New calendar'));
      await tester.pumpAndSettle();
    },
    builder: () => _studio(templates: [_saved()]),
  );

  goldenTest(
    'Save as template sheet',
    fileName: 'user_templates_save_sheet',
    pumpBeforeTest: (tester) async {
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jade wall 2027').last);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('calendar-studio-save-template')),
      );
      await tester.pumpAndSettle();
    },
    builder: _studio,
  );
}

class _Projects implements CalendarStudioProjectStore {
  _Projects(List<CalendarStudioProject> projects)
    : values = {for (final p in projects) p.id: p};
  final Map<String, CalendarStudioProject> values;
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
  _Templates(List<CalendarStudioUserTemplate> templates)
    : values = {for (final t in templates) t.id: t};
  final Map<String, CalendarStudioUserTemplate> values;
  @override
  Future<void> delete(String id) async => values.remove(id);
  @override
  Future<List<CalendarStudioUserTemplate>> list() async =>
      values.values.toList();
  @override
  Future<void> save(CalendarStudioUserTemplate template) async =>
      values[template.id] = template;
}
