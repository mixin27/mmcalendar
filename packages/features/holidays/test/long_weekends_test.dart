import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:holidays/holidays.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

void main() {
  setUp(HolidayYears.clearCache);

  List<LongWeekend> plan({int leave = 1, DateTime? today}) => LongWeekends.plan(
    2026,
    Language.english,
    maxLeave: leave,
    today: today ?? DateTime(2026, 1, 1),
  );

  test('one day of leave: Thingyan becomes 12 days', () {
    final thingyan = plan().singleWhere(
      (b) => b.holidays.any((o) => o.entry.id == 'thingyan'),
    );
    expect(thingyan.start, DateTime(2026, 4, 10));
    expect(thingyan.end, DateTime(2026, 4, 21));
    expect(thingyan.length, 12);
    expect(thingyan.leave, [DateTime(2026, 4, 10)]);
  });

  test('Union Day and Chinese New Year join up for one day of leave', () {
    final b = plan().firstWhere((b) => b.start.month == 2);
    expect(b.start, DateTime(2026, 2, 12));
    expect(b.end, DateTime(2026, 2, 17));
    expect(b.leave, [DateTime(2026, 2, 13)]);
  });

  test('every break is worth it, has a holiday and none overlap', () {
    for (final leave in [1, 2, 3]) {
      final breaks = plan(leave: leave);
      expect(breaks, isNotEmpty);
      for (final (i, b) in breaks.indexed) {
        expect(b.holidays, isNotEmpty);
        expect(b.leave.length, lessThanOrEqualTo(leave));
        expect(b.length, greaterThanOrEqualTo(LongWeekends.minLength));
        expect(
          b.length - b.leave.length,
          greaterThanOrEqualTo(LongWeekends.minFreeDays),
          reason: '$b',
        );
        for (final day in b.leave) {
          expect(day.weekday, lessThan(DateTime.saturday));
        }
        if (i > 0) expect(b.start.isAfter(breaks[i - 1].end), isTrue);
      }
    }
  });

  test('two days of leave for a four-day break is not suggested', () {
    // Martyrs' Day 2026 falls on a Sunday: Mon and Tue off would give 4.
    expect(
      plan(leave: 2).where((b) => b.start == DateTime(2026, 7, 18)),
      isEmpty,
    );
  });

  test('breaks already over are left out', () {
    final breaks = plan(today: DateTime(2026, 11, 6));
    expect(breaks.first.start.isAfter(DateTime(2026, 11, 5)), isTrue);
    expect(
      breaks.first.holidays.map((o) => o.entry.id),
      contains('tazaungdaing'),
    );
  });

  Widget app(String location) => MaterialApp.router(
    routerConfig: GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(
          path: '/views/holidays/long-weekends',
          builder: (_, _) =>
              LongWeekendsPage(year: 2026, today: DateTime(2026, 1, 1)),
        ),
        GoRoute(
          path: '/views/holidays/:id',
          builder: (_, state) => Text('holiday ${state.pathParameters['id']}'),
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

  testWidgets('the page lists breaks, by leave days, and opens one', (
    tester,
  ) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 3000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app('/views/holidays/long-weekends'));
    await tester.pumpAndSettle();
    expect(find.text('10–21 Apr · 12 days off'), findsOneWidget);
    expect(find.textContaining('Take Fri 10 Apr off'), findsOneWidget);

    await tester.tap(find.text('Up to 2'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Lent'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('long-weekend-4-10')));
    await tester.pumpAndSettle();
    expect(find.text('holiday thingyan'), findsOneWidget);
  });
}
