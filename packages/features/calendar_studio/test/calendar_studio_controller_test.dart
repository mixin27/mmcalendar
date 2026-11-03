import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('one drag interaction creates one undo step', () async {
    final store = _MemoryStore();
    final controller = CalendarStudioController(
      CalendarStudioConfiguration(projects: store),
    );
    await controller.create(
      'jade-wall',
      const CalendarStudioSource(
        year: 2027,
        period: CalendarStudioPeriod.month,
      ),
    );
    final original = controller.currentPage.blocks.first;

    controller.beginBlockInteraction();
    controller.updateBlockDuringInteraction(
      original.copyWith(bounds: original.bounds.copyWith(left: .1)),
    );
    controller.updateBlockDuringInteraction(
      original.copyWith(bounds: original.bounds.copyWith(left: .2)),
    );
    controller.endBlockInteraction();

    expect(controller.canUndo, isTrue);
    expect(controller.currentPage.blocks.first.bounds.left, .2);
    controller.undo();
    expect(
      controller.currentPage.blocks.first.bounds.left,
      original.bounds.left,
    );
    controller.dispose();
  });

  test('calendar visibility and page theme updates are undoable', () async {
    final controller = CalendarStudioController(
      CalendarStudioConfiguration(projects: _MemoryStore()),
    );
    await controller.create(
      'jade-wall',
      const CalendarStudioSource(
        year: 2027,
        period: CalendarStudioPeriod.month,
      ),
    );

    controller.updateSource(
      controller.project!.source.copyWith(showMoonPhases: false),
    );
    expect(controller.project!.source.showMoonPhases, isFalse);
    controller.updateCurrentCanvas(
      controller.currentPage.canvas.copyWith(backgroundColor: 0xFFF3EBD8),
    );
    expect(controller.currentPage.canvas.backgroundColor, 0xFFF3EBD8);
    controller.undo();
    expect(controller.currentPage.canvas.backgroundColor, 0xFFFFFFFF);
    controller.undo();
    expect(controller.project!.source.showMoonPhases, isTrue);
    controller.dispose();
  });

  test(
    'project configuration refreshes dates and preserves added layers',
    () async {
      final controller = CalendarStudioController(
        CalendarStudioConfiguration(projects: _MemoryStore()),
      );
      await controller.create(
        'jade-wall',
        const CalendarStudioSource(
          year: 2027,
          period: CalendarStudioPeriod.month,
        ),
      );
      final addedId = controller.addBlock(
        CalendarStudioBlockType.text,
        content: const {'text': 'Keep this note'},
      );

      controller.updateConfiguration(
        controller.project!.source.copyWith(
          year: 2028,
          month: 2,
          period: CalendarStudioPeriod.year,
          weekStartsMonday: true,
        ),
      );

      expect(controller.project!.name, 'Jade wall 2028');
      expect(controller.project!.pages, hasLength(12));
      expect(controller.project!.pages.first.month, 2);
      expect(controller.project!.pages.first.year, 2028);
      expect(controller.project!.source.weekStartsMonday, isTrue);
      expect(
        controller.project!.pages.first.blocks.any(
          (block) => block.id == addedId,
        ),
        isTrue,
      );
      expect(
        controller.project!.pages.first.blocks
            .firstWhere((block) => block.id == 'month-en')
            .content['text'],
        'February 2028',
      );
      controller.dispose();
    },
  );

  group('a new year on a design its template did not make', () {
    // A Studio pack project: its own cover and month pages under a real
    // preset's id, with block ids the preset never uses.
    CalendarStudioProject pack(String templateId) {
      final now = DateTime(2026);
      CalendarStudioPage page(String id, int month) => CalendarStudioPage(
        id: id,
        label: id,
        year: 2027,
        month: month,
        canvas: const StudioCanvas(width: 210, height: 297),
        blocks: [
          const CalendarStudioBlock(
            id: 'pack-shape',
            type: CalendarStudioBlockType.shape,
            name: 'Card',
            bounds: StudioRect(left: .1, top: .1, width: .8, height: .8),
          ),
          CalendarStudioBlock(
            id: 'pack-title',
            type: CalendarStudioBlockType.text,
            name: 'Title',
            bounds: const StudioRect(left: .1, top: .1, width: .8, height: .1),
            content: {
              'text': '${month == 1 ? 'January' : 'February'} 2027',
              'binding': 'monthYear',
            },
          ),
        ],
      );
      return CalendarStudioProject(
        id: 'pack',
        name: 'Love letters 2027',
        templateId: templateId,
        source: const CalendarStudioSource(year: 2027),
        createdAt: now,
        updatedAt: now,
        pages: [page('cover', 1), page('jan', 1), page('feb', 2)],
      );
    }

    Future<CalendarStudioController> openPack(String templateId) async {
      final controller = CalendarStudioController(
        CalendarStudioConfiguration(projects: _MemoryStore()),
      );
      await controller.open(pack(templateId));
      controller.updateConfiguration(
        controller.project!.source.copyWith(year: 2028),
      );
      return controller;
    }

    void expectMoved(CalendarStudioProject project) {
      final pages = {for (final page in project.pages) page.id: page};
      for (final id in ['cover', 'jan', 'feb']) {
        expect(pages[id]!.blocks.map((block) => block.id), [
          'pack-shape',
          'pack-title',
        ], reason: '$id keeps its own blocks, and no template blocks');
        expect(pages[id]!.year, 2028);
      }
      expect(pages['jan']!.blocks.last.content['text'], 'January 2028');
      expect(pages['feb']!.blocks.last.content['text'], 'February 2028');
      expect(pages['feb']!.month, 2);
    }

    test('with its template, no template blocks are added', () async {
      final controller = await openPack('jade-wall');
      expectMoved(controller.project!);
      controller.dispose();
    });

    test('without its template, the pages still move', () async {
      final controller = await openPack('user:missing');
      expectMoved(controller.project!);
      controller.dispose();
    });
  });

  test('a block deleted from a preset page stays deleted', () async {
    final controller = CalendarStudioController(
      CalendarStudioConfiguration(projects: _MemoryStore()),
    );
    await controller.create(
      'jade-wall',
      const CalendarStudioSource(
        year: 2027,
        period: CalendarStudioPeriod.month,
      ),
    );
    final before = controller.currentPage.blocks.map((b) => b.id).toList();
    controller
      ..select(before.first)
      ..deleteSelected();

    controller.updateConfiguration(
      controller.project!.source.copyWith(year: 2028),
    );

    expect(
      controller.currentPage.blocks.map((block) => block.id),
      before.skip(1),
    );
    controller.dispose();
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
