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
