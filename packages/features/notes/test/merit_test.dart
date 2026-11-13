import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:integrations_database/integrations_database.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:notes/notes.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

late AppDatabase _db;
late MeritRepository _merit;

MeritEntry _e(DateTime day, MeritKind kind, {int? amount}) =>
    MeritEntry(id: 0, date: day, kind: kind, amount: amount, createdAt: day);

Widget _app(Widget home) => MaterialApp.router(
  routerConfig: GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => home),
      GoRoute(
        path: '/views/day',
        builder: (_, state) =>
            Text('day ${DayNotesRepository.keyOf(state.extra! as DateTime)}'),
      ),
    ],
  ),
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: AppTheme.build(
    style: AppStyle.clear,
    colorScheme: AppColorSchemes.modernLight,
  ),
  builder: (context, child) =>
      CalendarLanguageScope(language: Language.english, child: child!),
);

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 80)),
  );
  await tester.pumpAndSettle();
}

Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(Duration.zero);
}

void main() {
  setUpAll(() {
    _db = AppDatabase(NativeDatabase.memory());
    _merit = MeritRepository(_db.meritDao, clock: () => DateTime(2026, 11, 1));
    GetIt.instance.registerSingleton<MeritRepository>(_merit);
  });
  setUp(() => _db.delete(_db.meritEntries).go());

  group('stats', () {
    // Sabbaths 2026: 26 Oct, 3, 9, 17 and 24 Nov.
    test('the streak counts Sabbaths with precepts or meditation', () {
      final entries = [
        _e(DateTime(2026, 11, 17), MeritKind.precepts),
        _e(DateTime(2026, 11, 9), MeritKind.precepts),
        _e(DateTime(2026, 11, 3), MeritKind.meditation, amount: 30),
        // A donation doesn't keep the streak.
        _e(DateTime(2026, 10, 26), MeritKind.donation, amount: 5000),
      ];
      // 24 Nov is a Sabbath with nothing logged yet: it doesn't break it.
      expect(MeritStats.sabbathStreak(entries, DateTime(2026, 11, 24)), 3);
      // The next day, the missed 24 Nov does.
      expect(MeritStats.sabbathStreak(entries, DateTime(2026, 11, 25)), 0);
      expect(MeritStats.sabbathStreak(const [], DateTime(2026, 11, 24)), 0);
    });

    test('the year counts kinds, minutes and kyats', () {
      final y = MeritStats.year([
        _e(DateTime(2026, 3, 1), MeritKind.meditation, amount: 30),
        _e(DateTime(2026, 4, 1), MeritKind.meditation, amount: 15),
        _e(DateTime(2026, 5, 1), MeritKind.donation, amount: 5000),
        _e(DateTime(2025, 5, 1), MeritKind.donation, amount: 9000),
      ], 2026);
      expect(y.counts[MeritKind.meditation], 2);
      expect(y.counts[MeritKind.donation], 1);
      expect(y.meditationMinutes, 45);
      expect(y.donated, 5000);
    });
  });

  test('the repository adds, trims and removes', () async {
    final day = DateTime(2026, 11, 9);
    await _merit.add(
      day,
      MeritKind.precepts,
      note: '  Eight precepts ',
      amount: 9,
    );
    final [entry] = await _merit.watchDay(day).first;
    expect(entry.note, 'Eight precepts');
    // Precepts have no amount.
    expect(entry.amount, isNull);
    await _merit.remove(entry.id);
    expect(await _merit.watchDay(day).first, isEmpty);
  });

  testWidgets('add merit from a day, then remove it', (tester) async {
    final day = DateTime(2026, 11, 9);
    await tester.runAsync(() async {
      await tester.pumpWidget(_app(Scaffold(body: MeritGroup(date: day))));
    });
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('merit-add')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('merit-kind-meditation')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('merit-amount')), '30');
    await tester.tap(find.byKey(const ValueKey('merit-save')));
    await _settle(tester);
    expect(find.text('Meditation'), findsOneWidget);
    expect(find.text('30 min'), findsOneWidget);

    final [entry] = (await tester.runAsync(() => _merit.watchDay(day).first))!;
    await tester.tap(find.byKey(ValueKey('merit-entry-${entry.id}')).first);
    await tester.tap(
      find.descendant(
        of: find.byKey(ValueKey('merit-entry-${entry.id}')),
        matching: find.byType(IconButton),
      ),
    );
    await _settle(tester);
    expect(find.text('Meditation'), findsNothing);
    await _unmount(tester);
  });

  testWidgets('the diary shows the streak, the year and entries', (
    tester,
  ) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 2000);
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await _merit.add(DateTime(2026, 11, 17), MeritKind.precepts);
      await _merit.add(DateTime(2026, 11, 9), MeritKind.precepts);
      await _merit.add(
        DateTime(2026, 11, 10),
        MeritKind.donation,
        amount: 5000,
        note: 'Monastery',
      );
      await tester.pumpWidget(
        _app(MeritDiaryPage(today: DateTime(2026, 11, 20))),
      );
    });
    await _settle(tester);
    expect(find.text('2 Sabbaths in a row'), findsOneWidget);
    expect(find.text('5,000 Ks'), findsOneWidget);
    expect(find.text('5,000 Ks · Monastery'), findsOneWidget);
    await tester.tap(find.textContaining('Tue 10 Nov'));
    await tester.pumpAndSettle();
    expect(find.text('day 2026-11-10'), findsOneWidget);
    await _unmount(tester);
  });
}
