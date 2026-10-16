import 'package:alchemist/alchemist.dart';
import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2027, 3, 10, 12);

Widget _workspace() {
  final store = _Store();
  for (final (id, template, exported) in const [
    ('a', 'family', false),
    ('b', 'love_relationship', true),
    ('c', 'festival', false),
    ('d', 'pagoda', false),
    ('e', 'ocean', false),
  ]) {
    final project = CalendarStudioTemplates.byId(template).create(
      id: id,
      source: const CalendarStudioSource(year: 2027),
      now: _now.subtract(Duration(hours: id.codeUnitAt(0) - 96)),
    );
    store.values[id] = exported
        ? project.copyWith(
            lastExport: CalendarStudioExportRecord(
              exportedAt: _now.subtract(const Duration(days: 2)),
              presetLabel: 'A4 print',
              format: CalendarStudioExportFormat.pdf,
              pageCount: 12,
              fileName: 'rose-bond-2027.pdf',
            ),
          )
        : project;
  }
  return SizedBox(
    width: 390,
    height: 800,
    child: CalendarStudioWorkspace(
      configuration: CalendarStudioConfiguration(
        projects: store,
        now: () => _now,
      ),
    ),
  );
}

void main() {
  goldenTest('dashboard', fileName: 'dashboard', builder: _workspace);

  goldenTest(
    'project detail',
    fileName: 'project_detail',
    pumpBeforeTest: (tester) async {
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rose Bond 2027').last);
      await tester.pumpAndSettle();
    },
    builder: _workspace,
  );
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
