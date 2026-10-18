import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:holidays/holidays.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

Future<void> _pump(WidgetTester tester, AppStyle style, String location) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(390, 6000);
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: '/views/holidays',
        builder: (_, state) =>
            HolidaysPage(year: int.parse(state.uri.queryParameters['year']!)),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, state) => HolidayDetailPage(
              id: state.pathParameters['id']!,
              year: int.parse(state.uri.queryParameters['year']!),
            ),
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
        style: style,
        colorScheme: AppColorSchemes.modernLight,
      ),
      builder: (context, child) =>
          CalendarLanguageScope(language: Language.english, child: child!),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(HolidayYears.clearCache);

  for (final style in [AppStyle.clear, AppStyle.material]) {
    group('${style.name} style', () {
      testWidgets('a year lists holidays month by month, ranges as one row', (
        tester,
      ) async {
        await _pump(tester, style, '/views/holidays?year=2030');
        expect(find.text('Holidays'), findsWidgets);
        expect(find.text('Thingyan and Myanmar New Year'), findsOneWidget);
        expect(find.text('Thadingyut'), findsOneWidget);
        expect(find.text('Independence Day'), findsOneWidget);
        expect(find.text('2030'), findsOneWidget);
      });

      testWidgets('search narrows to matches and offers all years', (
        tester,
      ) async {
        await _pump(tester, style, '/views/holidays?year=2030');
        await tester.enterText(find.byType(EditableText), 'water');
        await tester.pumpAndSettle();
        expect(find.text('Thingyan and Myanmar New Year'), findsOneWidget);
        expect(find.text('Thadingyut'), findsNothing);
        expect(find.text('1 holiday in 2030'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('holidays-search-all-years')),
          findsOneWidget,
        );
      });

      testWidgets('filters by kind', (tester) async {
        await _pump(tester, style, '/views/holidays?year=2030');
        final chip = find.byKey(const ValueKey('holidays-filter-anniversary'));
        await tester.ensureVisible(chip);
        await tester.pumpAndSettle();
        await tester.tap(chip);
        await tester.pumpAndSettle();
        expect(find.text('Halloween'), findsOneWidget);
        expect(find.text('Thadingyut'), findsNothing);
      });

      testWidgets('detail shows each day, what it marks and other years', (
        tester,
      ) async {
        await _pump(tester, style, '/views/holidays/thadingyut?year=2026');
        expect(find.text('Thadingyut'), findsWidgets);
        expect(find.text('End of Buddhist Lent · Holiday'), findsOneWidget);
        expect(
          find.textContaining('ends the three-month Buddhist Lent'),
          findsOneWidget,
        );
        expect(find.text('Public holiday'), findsOneWidget);
        expect(find.byKey(const ValueKey('holiday-year-2027')), findsOneWidget);
        expect(find.text('14–16 Oct'), findsOneWidget);
      });
    });
  }

  group('reminders', () {
    late HolidayReminders reminders;
    var asked = 0;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      asked = 0;
      reminders = HolidayReminders(
        preferences: await SharedPreferences.getInstance(),
        requestPermission: () async {
          asked++;
          return true;
        },
      );
      GetIt.instance.registerSingleton<HolidayReminders>(reminders);
    });
    tearDown(() => GetIt.instance.reset());

    testWidgets('Remind me follows the holiday and asks permission once on', (
      tester,
    ) async {
      await _pump(
        tester,
        AppStyle.clear,
        '/views/holidays/thadingyut?year=2026',
      );
      await tester.tap(find.byType(AppSwitch));
      await tester.pumpAndSettle();
      expect(reminders.followed, {'thadingyut'});
      expect(asked, 1);
      expect(find.text('The evening before, at 6 pm'), findsOneWidget);
    });

    testWidgets('the sheet sets the time and follows all public holidays', (
      tester,
    ) async {
      await _pump(tester, AppStyle.material, '/views/holidays?year=2030');
      await tester.tap(find.byKey(const ValueKey('holidays-reminders')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('holiday-reminder-time-both')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('holiday-reminder-all-public')),
      );
      await tester.pumpAndSettle();
      expect(reminders.time, HolidayReminderTime.both);
      expect(reminders.allPublic, isTrue);
      expect(reminders.isOn(HolidayCatalog.thingyan), isTrue);
      expect(reminders.isOn(HolidayCatalog.halloween), isFalse);
    });
  });
}
