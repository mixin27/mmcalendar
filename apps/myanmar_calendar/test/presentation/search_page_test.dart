import 'package:drift/native.dart';
import 'package:events/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:holidays/holidays.dart';
import 'package:integrations_database/integrations_database.dart'
    show AppDatabase;
import 'package:mmcalendar/presentation/pages/search_page.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:notes/notes.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

final _today = DateTime(2026, 11, 5);

final _dentist = Event(
  id: 7,
  title: 'Dentist',
  eventDate: DateTime(2026, 11, 20),
  category: EventCategory(
    name: 'Health',
    iconName: 'health',
    colorCode: 0xFF2F9E5B,
    createdAt: DateTime(2026),
  ),
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

Future<void> _pump(WidgetTester tester) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(390, 2000);
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => SearchPage(
          today: _today,
          searchEvents: (q) async =>
              'dentist'.contains(q.toLowerCase()) ? [_dentist] : const [],
        ),
      ),
      GoRoute(
        path: '/home/day-details',
        builder: (_, state) => Text('day ${state.uri.queryParameters['date']}'),
      ),
      GoRoute(
        path: '/home/holiday/:id',
        builder: (_, state) => Text('holiday ${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: '/events/:id/detail',
        builder: (_, state) => Text('event ${state.pathParameters['id']}'),
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

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(EditableText), text);
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 60)),
  );
  await tester.pumpAndSettle();
}

Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(Duration.zero);
}

void main() {
  late AppDatabase database;

  setUpAll(() async {
    database = AppDatabase(NativeDatabase.memory());
    final notes = DayNotesRepository(database.dayNotesDao);
    GetIt.instance.registerSingleton<DayNotesRepository>(notes);
    await notes.save(DateTime(2026, 11, 20), 'Dentist at 9, bring the X-ray');
  });
  setUp(HolidayYears.clearCache);

  testWidgets('before typing, the page says what it finds', (tester) async {
    await _pump(tester);
    expect(find.textContaining('Tabaung full moon'), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('a Myanmar date finds the day and opens it', (tester) async {
    await _pump(tester);
    await _type(tester, 'Tabaung full moon');
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('search-date')),
        matching: find.text('Mon 22 Mar 2027'),
      ),
      findsOneWidget,
    );
    // The holiday on that day.
    expect(
      find.byKey(const ValueKey('search-holiday-tabaung')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('search-date')));
    await tester.pumpAndSettle();
    expect(find.text('day 2027-03-22T00:00:00.000'), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('text finds events and notes', (tester) async {
    await _pump(tester);
    await _type(tester, 'dentist');
    expect(find.byKey(const ValueKey('search-event-7')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('search-note-2026-11-20')),
      findsOneWidget,
    );
    expect(find.text('Dentist at 9, bring the X-ray'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('search-event-7')));
    await tester.pumpAndSettle();
    expect(find.text('event 7'), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('a holiday name opens the holiday', (tester) async {
    await _pump(tester);
    await _type(tester, 'thingyan');
    expect(find.byKey(const ValueKey('search-date')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('search-holiday-thingyan')));
    await tester.pumpAndSettle();
    expect(find.text('holiday thingyan'), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('nothing found says so', (tester) async {
    await _pump(tester);
    await _type(tester, 'zzzz');
    expect(find.text('Nothing found for “zzzz”.'), findsOneWidget);
    await _unmount(tester);
  });
}
