import 'dart:typed_data';

import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('live interactions', () {
    late CalendarStudioController controller;

    setUp(() async {
      controller = CalendarStudioController(
        CalendarStudioConfiguration(projects: _MemoryStore()),
      );
      await controller.create(
        'jade-wall',
        const CalendarStudioSource(
          year: 2027,
          period: CalendarStudioPeriod.month,
        ),
      );
    });

    tearDown(() => controller.dispose());

    test('drag frames notify only the canvas until the drag ends', () {
      var workspaceNotifications = 0;
      var canvasNotifications = 0;
      controller.addListener(() => workspaceNotifications++);
      controller.canvasChanges.addListener(() => canvasNotifications++);
      final block = controller.currentPage.blocks.first;

      controller.beginBlockInteraction();
      for (var i = 1; i <= 10; i++) {
        controller.updateBlockDuringInteraction(
          block.copyWith(bounds: block.bounds.copyWith(left: i / 100)),
        );
      }
      expect(workspaceNotifications, 0);
      expect(canvasNotifications, 10);

      controller.endBlockInteraction();
      expect(workspaceNotifications, greaterThanOrEqualTo(1));
      expect(controller.currentPage.blocks.first.bounds.left, .1);
    });

    test('a slider gesture is a single undo step', () {
      final block = controller.currentPage.blocks.first;
      controller.beginBlockInteraction();
      for (final rotation in [.1, .2, .3, .4]) {
        controller.updateBlockLive(block.copyWith(rotation: rotation));
      }
      controller.endBlockInteraction();

      expect(controller.currentPage.blocks.first.rotation, .4);
      controller.undo();
      expect(controller.currentPage.blocks.first.rotation, block.rotation);
      expect(controller.canUndo, isFalse);
    });

    test('undo history is capped', () {
      final block = controller.currentPage.blocks.first;
      for (var i = 0; i < CalendarStudioController.historyLimit + 20; i++) {
        controller.updateBlock(block.copyWith(rotation: i / 1000));
      }
      var steps = 0;
      while (controller.canUndo) {
        controller.undo();
        steps++;
      }
      expect(steps, CalendarStudioController.historyLimit);
    });
  });

  group('caches', () {
    test('calendar data is computed once per source and month', () async {
      final delegate = _CountingDataProvider();
      final cache = CachedCalendarStudioDataProvider(delegate);
      const source = CalendarStudioSource(year: 2027);

      expect(cache.peek(source, month: 1), isNull);
      await Future.wait([
        cache.daysFor(source, month: 1),
        cache.daysFor(source, month: 1),
      ]);
      await cache.daysFor(source, month: 1);

      expect(delegate.calls, 1);
      expect(cache.peek(source, month: 1), hasLength(31));
      await cache.daysFor(source.copyWith(showHolidays: false), month: 1);
      expect(delegate.calls, 2);
    });

    test('asset bytes keep one stable instance', () async {
      final cache = CachedCalendarStudioAssetStore(_MemoryAssets());
      final first = await cache.loadBytes('logo');
      final second = await cache.loadBytes('logo');
      expect(first, isA<Uint8List>());
      expect(identical(first, second), isTrue);
      expect(identical(cache.peekBytes('logo'), first), isTrue);
    });
  });

  testWidgets('dragging a block does not recompute calendar data', (
    tester,
  ) async {
    final delegate = _CountingDataProvider();
    final cache = CachedCalendarStudioDataProvider(delegate);
    final project = CalendarStudioTemplates.byId('annual').create(
      id: 'annual',
      source: const CalendarStudioSource(year: 2027),
      now: DateTime(2027),
    );
    var page = project.pages.first;
    final moving = page.blocks.firstWhere(
      (block) => block.type != CalendarStudioBlockType.calendarGrid,
    );

    Widget scene() => MaterialApp(
      home: SizedBox(
        width: 400,
        child: CalendarStudioScene(
          page: page,
          source: project.source,
          dataProvider: cache,
          selectedBlockId: moving.id,
          onSelect: (_) {},
          onTransform: (_) {},
        ),
      ),
    );

    await tester.pumpWidget(scene());
    await tester.pumpAndSettle();
    final firstPass = delegate.calls;
    expect(firstPass, greaterThan(0));

    for (var i = 1; i <= 20; i++) {
      page = page.copyWith(
        blocks: [
          for (final block in page.blocks)
            if (block.id == moving.id)
              block.copyWith(
                bounds: block.bounds.copyWith(left: (i % 10) / 100),
              )
            else
              block,
        ],
      );
      await tester.pumpWidget(scene());
    }
    expect(delegate.calls, firstPass);
  });
}

class _CountingDataProvider implements CalendarStudioDataProvider {
  var calls = 0;

  @override
  Future<List<CalendarStudioDayData>> daysFor(
    CalendarStudioSource source, {
    required int month,
  }) async {
    calls++;
    final count = DateUtils.getDaysInMonth(source.year, month);
    return [
      for (var day = 1; day <= count; day++)
        CalendarStudioDayData(
          date: DateTime(source.year, month, day),
          gregorianLabel: '$day',
        ),
    ];
  }
}

class _MemoryAssets implements CalendarStudioAssetStore {
  @override
  Future<List<int>?> loadBytes(String assetId) async => [1, 2, 3];
  @override
  Future<CalendarStudioAsset?> load(String assetId) async => null;
  @override
  Future<CalendarStudioAsset> importAsset(CalendarStudioAssetInput input) =>
      throw UnimplementedError();
  @override
  Future<void> deleteUnusedAssets(Set<String> usedAssetIds) async {}
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
