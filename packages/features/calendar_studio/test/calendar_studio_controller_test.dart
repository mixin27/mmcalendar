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
