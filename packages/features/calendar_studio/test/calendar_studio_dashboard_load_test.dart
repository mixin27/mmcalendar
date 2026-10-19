import 'dart:async';

import 'package:calendar_studio/calendar_studio.dart';
import 'package:calendar_studio/src/presentation/calendar_studio_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2027, 3, 10, 12);

class _SlowStore implements CalendarStudioProjectStore {
  _SlowStore(this.projects);
  final List<CalendarStudioProject> projects;
  final ready = Completer<void>();

  @override
  Future<List<CalendarStudioProject>> list() async {
    await ready.future;
    return projects;
  }

  @override
  Future<void> delete(String id) async {}
  @override
  Future<CalendarStudioProject?> load(String id) async => null;
  @override
  Future<void> save(CalendarStudioProject project) async {}
}

void main() {
  testWidgets('60 projects: skeleton first, then pages build a few at a time', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    StudioThumbnailCache.clear();

    final template = CalendarStudioTemplates.byId('family');
    final store = _SlowStore([
      for (var i = 0; i < 60; i++)
        template.create(
          id: 'p$i',
          source: CalendarStudioSource(year: 2027 + i % 5),
          now: _now.subtract(Duration(minutes: i)),
        ),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: CalendarStudioWorkspace(
          configuration: CalendarStudioConfiguration(
            projects: store,
            now: () => _now,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));

    // Loading: the dashboard's shape in shimmer, no live pages.
    expect(find.byType(StudioShimmer), findsWidgets);
    expect(find.byType(CalendarStudioScene), findsNothing);

    store.ready.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    // Cards are on screen, but their pages wait their turn.
    expect(find.text('Your projects'), findsOneWidget);
    expect(find.byType(CalendarStudioScene).evaluate().length, lessThan(3));

    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    // Only cards on screen are built, never all sixty.
    final built = find.byType(CalendarStudioScene).evaluate().length;
    expect(built, greaterThan(2));
    expect(built, lessThan(12));

    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });
}
