import 'package:calendar/calendar.dart';
import 'package:calendar/src/presentation/widgets/home_day_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:holidays/holidays.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

class _Analytics implements AnalyticsPort {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _Display implements DisplayPreferencesPort {
  @override
  Future<bool> getShowShanCalendar() async => false;
  @override
  Stream<bool> watchShowShanCalendar() => Stream.value(false);
}

class _Actions implements EventActionsPort {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _Markers implements EventMarkersPort {
  @override
  Stream<List<CalendarEventItem>> watchEventsForDate(DateTime date) =>
      Stream.value(const []);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Visitors asked what Thingyan, Thadingyut and the other festivals are:
/// tapping a festival day explains it, not only on the Holidays page.
void main() {
  final thingyan = DateTime(2026, 4, 13);
  final l10n = lookupAppLocalizations(const Locale('en'));
  final about = HolidayCatalog.thingyan.about(l10n)!;

  Future<void> pump(WidgetTester tester, Widget home) async {
    final getIt = GetIt.instance;
    await getIt.reset();
    getIt
      ..registerSingleton<AnalyticsPort>(_Analytics())
      ..registerSingleton<DisplayPreferencesPort>(_Display())
      ..registerSingleton<EventActionsPort>(_Actions())
      ..registerSingleton<EventMarkersPort>(_Markers());
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 2600);
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(body: home),
          routes: [
            GoRoute(
              path: 'home/holiday/:id',
              builder: (_, state) =>
                  Text('holiday page ${state.pathParameters['id']}'),
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.build(
          style: AppStyle.clear,
          colorScheme: AppColorSchemes.modernLight,
        ),
        builder: (context, child) =>
            CalendarLanguageScope(language: Language.english, child: child!),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(HolidayYears.clearCache);

  test('every built-in holiday has an explanation in both languages', () {
    for (final locale in ['en', 'my']) {
      final strings = lookupAppLocalizations(Locale(locale));
      for (final entry in HolidayCatalog.all) {
        expect(entry.about(strings), isNotEmpty, reason: '$locale ${entry.id}');
      }
    }
  });

  testWidgets('day details explain the holiday', (tester) async {
    await pump(tester, DayDetailsPage(date: thingyan));
    final row = find.byKey(const ValueKey('day-holiday-thingyan'));
    expect(row, findsOneWidget);
    expect(
      find.descendant(of: row, matching: find.textContaining(about)),
      findsOneWidget,
    );
  });

  testWidgets('the home sheet explains the holiday and opens its page', (
    tester,
  ) async {
    final day = MyanmarCalendar.getCompleteDate(thingyan);
    await pump(
      tester,
      HomeDaySheet(
        peekFraction: .9,
        day: day,
        today: thingyan,
        events: const [],
        upcomingEvents: const {},
        options: const DayCellOptions(),
        onOpenDetails: (_) {},
        onOpenEvent: (_) {},
        onAddEvent: (_) {},
        onOpenDay: (_) {},
        onStudioTap: () {},
      ),
    );
    final row = find.byKey(const ValueKey('sheet-holiday-thingyan'));
    expect(row, findsOneWidget);
    expect(
      find.descendant(of: row, matching: find.text(about)),
      findsOneWidget,
    );
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.text('holiday page thingyan'), findsOneWidget);
  });

  testWidgets('holiday explanations hide with Show holidays off', (
    tester,
  ) async {
    await pump(
      tester,
      HomeDaySheet(
        peekFraction: .9,
        day: MyanmarCalendar.getCompleteDate(thingyan),
        today: thingyan,
        events: const [],
        upcomingEvents: const {},
        options: const DayCellOptions(showHolidays: false),
        onOpenDetails: (_) {},
        onOpenEvent: (_) {},
        onAddEvent: (_) {},
        onOpenDay: (_) {},
        onStudioTap: () {},
      ),
    );
    expect(find.text(about), findsNothing);
  });
}
