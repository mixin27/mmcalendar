import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter_test/flutter_test.dart';

Future<CalendarStudioController> _create({
  String templateId = 'blank',
  CalendarStudioPeriod period = CalendarStudioPeriod.month,
}) async {
  final controller = CalendarStudioController(
    CalendarStudioConfiguration(projects: _MemoryStore()),
  );
  await controller.create(
    templateId,
    CalendarStudioSource(year: 2027, period: period),
  );
  return controller;
}

CalendarStudioBlock _block(String id, double left, double top, double size) =>
    CalendarStudioBlock(
      id: id,
      type: CalendarStudioBlockType.shape,
      name: id,
      bounds: StudioRect(left: left, top: top, width: size, height: size),
    );

String _add(CalendarStudioController c, double left, double top, double w) =>
    c.addBlock(
      CalendarStudioBlockType.shape,
      bounds: StudioRect(left: left, top: top, width: w, height: w),
    );

CalendarStudioBlock _byId(CalendarStudioController c, String id) =>
    c.currentPage.blocks.firstWhere((b) => b.id == id);

void main() {
  group('arrange maths', () {
    test('one block aligns to the page', () {
      final [moved] = CalendarStudioArrange.align([
        _block('a', .1, .1, .2),
      ], CalendarStudioAlign.right);
      expect(moved.bounds.left, closeTo(.8, 1e-9));
    });

    test('several blocks align to their shared bounds', () {
      final blocks = [_block('a', .1, .1, .2), _block('b', .5, .4, .1)];
      final centred = CalendarStudioArrange.align(
        blocks,
        CalendarStudioAlign.centerX,
      );
      // The selection spans .1 to .6, so the centre is .35.
      expect(centred[0].bounds.left, closeTo(.25, 1e-9));
      expect(centred[1].bounds.left, closeTo(.30, 1e-9));
      final bottom = CalendarStudioArrange.align(
        blocks,
        CalendarStudioAlign.bottom,
      );
      expect(bottom[0].bounds.top, closeTo(.3, 1e-9));
      expect(bottom[1].bounds.top, closeTo(.4, 1e-9));
    });

    test('locked blocks stay put', () {
      final locked = _block('a', .1, .1, .2).copyWith(locked: true);
      final [same, moved] = CalendarStudioArrange.align([
        locked,
        _block('b', .5, .5, .1),
      ], CalendarStudioAlign.left);
      expect(same, locked);
      expect(moved.bounds.left, .1);
    });

    test('distribute leaves equal gaps and keeps the ends', () {
      final blocks = [
        _block('c', .8, 0, .1),
        _block('a', 0, 0, .1),
        _block('b', .2, 0, .2),
      ];
      final out = CalendarStudioArrange.distribute(
        blocks,
        CalendarStudioDistribute.horizontal,
      );
      expect([for (final b in out) b.id], ['c', 'a', 'b']);
      expect(out[1].bounds.left, 0);
      expect(out[0].bounds.left, .8);
      // Span .9, widths .4, so two gaps of .25.
      expect(out[2].bounds.left, closeTo(.35, 1e-9));
      expect(
        CalendarStudioArrange.distribute(
          blocks.take(2).toList(),
          CalendarStudioDistribute.vertical,
        ),
        blocks.take(2).toList(),
      );
    });
  });

  group('controller', () {
    test('a typing session is one undo step', () async {
      final c = await _create();
      final id = c.addBlock(CalendarStudioBlockType.text);
      final undoBefore = c.canUndo;
      c.beginEditGroup();
      for (final text in ['H', 'He', 'Hel', 'Hello']) {
        final block = _byId(c, id);
        c.updateBlock(
          block.copyWith(content: {...block.content, 'text': text}),
        );
      }
      c.endEditGroup();
      expect(undoBefore, isTrue);
      expect(_byId(c, id).content['text'], 'Hello');
      c.undo();
      expect(_byId(c, id).content['text'], 'New text');
      // The next edit after the session is its own step again.
      c.redo();
      final block = _byId(c, id);
      c.updateBlock(block.copyWith(content: {...block.content, 'text': 'Hi'}));
      c.undo();
      expect(_byId(c, id).content['text'], 'Hello');
      c.dispose();
    });

    test('multi-select, align, delete and duplicate', () async {
      final c = await _create();
      final a = _add(c, .1, .1, .2);
      final b = _add(c, .5, .4, .1);
      expect(c.selectedBlockIds, [b]);
      c.toggleSelection(a);
      expect(c.selectedBlockIds, [b, a]);
      expect(c.selectedBlockId, a);

      c.alignSelected(CalendarStudioAlign.top);
      expect(_byId(c, b).bounds.top, closeTo(.1, 1e-9));
      c.undo();
      expect(_byId(c, b).bounds.top, .4);

      c.selectMany([a, b]);
      c.duplicateSelected();
      expect(c.currentPage.blocks.length, 4);
      expect(c.selectedBlockIds, hasLength(2));
      expect(c.selectedBlockIds, isNot(contains(a)));

      c.deleteSelected();
      expect(c.currentPage.blocks.map((x) => x.id), [a, b]);
      expect(c.selectedBlockIds, isEmpty);

      c.toggleSelection(a);
      c.toggleSelection(a);
      expect(c.selectedBlockIds, isEmpty);
      c.selectAll();
      expect(c.selectedBlockIds.toSet(), {a, b});
      c.dispose();
    });

    test('a group drag is one undo step', () async {
      final c = await _create();
      final a = _add(c, .1, .1, .2);
      final b = _add(c, .5, .4, .1);
      c.beginBlockInteraction();
      for (final dx in [.01, .02, .03]) {
        c.updateBlocksDuringInteraction([
          for (final id in [a, b])
            () {
              final start = c.interactionStartBlock(id)!;
              return start.copyWith(
                bounds: start.bounds.copyWith(left: start.bounds.left + dx),
              );
            }(),
        ]);
      }
      c.endBlockInteraction();
      expect(_byId(c, a).bounds.left, closeTo(.13, 1e-9));
      expect(_byId(c, b).bounds.left, closeTo(.53, 1e-9));
      c.undo();
      expect(_byId(c, a).bounds.left, .1);
      expect(_byId(c, b).bounds.left, .5);
      c.dispose();
    });

    test('layers reorder and rename', () async {
      final c = await _create();
      final a = _add(c, .1, .1, .2);
      final b = _add(c, .2, .2, .2);
      final d = _add(c, .3, .3, .2);
      List<String> order() =>
          ([...c.currentPage.blocks]
                ..sort((x, y) => x.zIndex.compareTo(y.zIndex)))
              .map((x) => x.id)
              .where({a, b, d}.contains)
              .toList();
      expect(order(), [a, b, d]);
      final top = c.currentPage.blocks.length - 1;
      c.reorderLayer(a, top);
      expect(order(), [b, d, a]);
      c.reorderLayer(a, 0);
      expect(order().first, a);

      c.renameBlock(b, '  Sun badge ');
      expect(_byId(c, b).name, 'Sun badge');
      final steps = c.canUndo;
      c.renameBlock(b, '   ');
      expect(_byId(c, b).name, 'Sun badge');
      expect(steps, isTrue);
      c.dispose();
    });

    test('apply to all months copies the style to every page', () async {
      final c = await _create(
        templateId: 'jade-wall',
        period: CalendarStudioPeriod.year,
      );
      final pages = c.project!.pages.length;
      expect(pages, greaterThan(1));
      final grid = c.currentPage.blocks.firstWhere(
        (b) => b.type == CalendarStudioBlockType.calendarGrid,
      );
      final restyled = grid.copyWith(
        style: {...grid.style, 'inkColor': 0xFF101010},
        bounds: grid.bounds.copyWith(top: grid.bounds.top + .01),
      );
      c.updateBlock(restyled);

      expect(c.applyToAllPages(restyled), pages - 1);
      for (final page in c.project!.pages) {
        final g = page.blocks.firstWhere((b) => b.id == grid.id);
        expect(g.style['inkColor'], 0xFF101010);
        if (page != c.currentPage) expect(g.bounds, grid.bounds);
      }
      expect(c.applyToAllPages(restyled), 0);
      expect(c.applyToAllPages(restyled, layout: true), pages - 1);
      for (final page in c.project!.pages) {
        expect(
          page.blocks.firstWhere((b) => b.id == grid.id).bounds,
          restyled.bounds,
        );
      }
      c.undo();
      c.undo();
      expect(
        c.project!.pages.last.blocks
            .firstWhere((b) => b.id == grid.id)
            .style['inkColor'],
        grid.style['inkColor'],
      );
      c.dispose();
    });
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
