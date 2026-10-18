import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter/material.dart';
import 'package:calendar_studio/src/presentation/calendar_studio_strings.dart';
import 'package:flutter_test/flutter_test.dart';

/// A year project starting January 2027, one page per month.
Future<CalendarStudioController> _yearProject() async {
  final controller = CalendarStudioController(
    CalendarStudioConfiguration(projects: _MemoryStore()),
  );
  await controller.create(
    'jade-wall',
    const CalendarStudioSource(year: 2027, period: CalendarStudioPeriod.year),
  );
  return controller;
}

List<int> _months(CalendarStudioController c) => [
  for (final page in c.project!.pages) page.month,
];

String _title(CalendarStudioPage page) =>
    page.blocks.firstWhere((b) => b.id == 'month-en').content['text'] as String;

void main() {
  group('page operations', () {
    test('duplicate inserts a copy after the page and shows it', () async {
      final c = await _yearProject();
      c.setPage(3);
      c.duplicatePage(3);
      final pages = c.project!.pages;
      expect(pages, hasLength(13));
      expect(_months(c).sublist(2, 6), [3, 4, 4, 5]);
      expect(pages[4].id, isNot(pages[3].id));
      expect(pages[4].blocks, pages[3].blocks);
      expect(pages.map((p) => p.id).toSet(), hasLength(13));
      expect(c.pageIndex, 4);

      c.undo();
      expect(c.project!.pages, hasLength(12));
      c.redo();
      expect(c.project!.pages, hasLength(13));
      c.dispose();
    });

    test('move reorders and keeps the moved page on screen', () async {
      final c = await _yearProject();
      c.setPage(0);
      c.movePage(0, 11);
      expect(_months(c), [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 1]);
      expect(c.pageIndex, 11);
      expect(c.currentPage.month, 1);

      // Moving another page keeps the current page in view.
      c.movePage(0, 5);
      expect(c.currentPage.month, 1);
      c.undo();
      c.undo();
      expect(_months(c), [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]);
      c.dispose();
    });

    test('delete removes the page; the last page cannot go', () async {
      final c = await _yearProject();
      c.setPage(11);
      c.deletePage(11);
      expect(c.project!.pages, hasLength(11));
      expect(c.pageIndex, 10);
      expect(c.currentPage.month, 11);

      c.setPage(2);
      c.deletePage(0);
      expect(c.currentPage.month, 3, reason: 'the shown page stays shown');

      while (c.project!.pages.length > 1) {
        c.deletePage(0);
      }
      expect(c.canDeletePage(0), isFalse);
      c.deletePage(0);
      expect(c.project!.pages, hasLength(1));
      c.dispose();
    });

    test('undo keeps the page index in range', () async {
      final c = await _yearProject();
      c.duplicatePage(11);
      expect(c.pageIndex, 12);
      c.undo();
      expect(c.pageIndex, 11);
      expect(() => c.currentPage, returnsNormally);
      c.dispose();
    });
  });

  group('Apply settings after page changes', () {
    test('reordered pages keep their order and their own edits', () async {
      final c = await _yearProject();
      c.setPage(0);
      final note = c.addBlock(
        CalendarStudioBlockType.text,
        content: const {'text': 'January note'},
      );
      c.movePage(0, 11);

      c.updateConfiguration(c.project!.source.copyWith(weekStartsMonday: true));
      expect(_months(c), [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 1]);
      final january = c.project!.pages.last;
      expect(january.blocks.any((b) => b.id == note), isTrue);
      expect(c.project!.pages.first.blocks.any((b) => b.id == note), isFalse);
      c.dispose();
    });

    test('a new year moves every page, duplicates included', () async {
      final c = await _yearProject();
      c.duplicatePage(3);
      c.setPage(4);
      final note = c.addBlock(
        CalendarStudioBlockType.text,
        content: const {'text': 'Second April'},
      );

      c.updateConfiguration(c.project!.source.copyWith(year: 2028));
      final pages = c.project!.pages;
      expect(pages, hasLength(13));
      expect([pages[3].month, pages[4].month], [4, 4]);
      expect(pages.every((p) => p.year == 2028), isTrue);
      expect(_title(pages[3]), 'April 2028');
      expect(pages[4].blocks.any((b) => b.id == note), isTrue);
      expect(pages[3].blocks.any((b) => b.id == note), isFalse);
      expect(pages.map((p) => p.id).toSet(), hasLength(13));
      c.dispose();
    });

    test('deleted months stay deleted', () async {
      final c = await _yearProject();
      c.deletePage(2); // March
      c.updateConfiguration(c.project!.source.copyWith(weekStartsMonday: true));
      expect(_months(c), [1, 2, 4, 5, 6, 7, 8, 9, 10, 11, 12]);
      c.dispose();
    });

    test('a longer period adds the new months in order', () async {
      final c = CalendarStudioController(
        CalendarStudioConfiguration(projects: _MemoryStore()),
      );
      await c.create(
        'jade-wall',
        const CalendarStudioSource(year: 2027, month: 3),
      );
      c.duplicatePage(0);
      c.updateConfiguration(
        c.project!.source.copyWith(period: CalendarStudioPeriod.year),
      );
      // March and its copy, then April 2027 to February 2028.
      expect(_months(c), [3, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 1, 2]);
      expect(c.project!.pages.last.year, 2028);
      c.dispose();
    });

    test('a shorter period drops the months outside it', () async {
      final c = await _yearProject();
      c.movePage(0, 11);
      c.updateConfiguration(
        c.project!.source.copyWith(period: CalendarStudioPeriod.month),
      );
      expect(_months(c), [1]);
      c.dispose();
    });
  });

  group('page actions in the editor', () {
    testWidgets('page settings duplicate and delete the page', (tester) async {
      final store = await _openEditor(tester, size: const Size(390, 844));
      await tester.tap(find.text('Page'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text(StudioStrings.duplicatePage),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text(StudioStrings.duplicatePage));
      await tester.pumpAndSettle();
      expect(await _saved(tester, store), hasLength(13));
      expect(_scene(tester).page.month, 1, reason: 'the copy is shown');
      expect(find.text(StudioStrings.pageDuplicated), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text(StudioStrings.deletePage),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text(StudioStrings.deletePage));
      await tester.pumpAndSettle();
      expect(await _saved(tester, store), hasLength(12));
      expect(find.text('Undo'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(await _saved(tester, store), hasLength(13));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the desktop strip moves pages from its menu', (tester) async {
      final store = await _openEditor(tester, size: const Size(1440, 900));
      await tester.tap(
        find.byKey(const ValueKey('calendar-studio-strip-menu')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(StudioStrings.moveLater).last);
      await tester.pumpAndSettle();
      final pages = await _saved(tester, store);
      expect([for (final p in pages.take(3)) p.month], [2, 1, 3]);
      expect(_scene(tester).page.month, 1);
      expect(tester.takeException(), isNull);
    });
  });
}

CalendarStudioScene _scene(WidgetTester tester) =>
    tester.widget<CalendarStudioScene>(find.byType(CalendarStudioScene).first);

/// The pages the editor saved, after its save debounce.
Future<List<CalendarStudioPage>> _saved(
  WidgetTester tester,
  _MemoryStore store,
) async {
  await tester.pump(const Duration(seconds: 1));
  return store.values['pages-project']!.pages;
}

Future<_MemoryStore> _openEditor(
  WidgetTester tester, {
  required Size size,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final project = CalendarStudioTemplates.byId('jade-wall').create(
    id: 'pages-project',
    source: const CalendarStudioSource(
      year: 2027,
      period: CalendarStudioPeriod.year,
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
  return store;
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
