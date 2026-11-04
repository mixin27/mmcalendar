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

late AppDatabase _database;
late DayNotesRepository _notes;

Widget _app(Widget home, {AppStyle style = AppStyle.clear}) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => home),
      GoRoute(
        path: '/views/day',
        builder: (_, state) =>
            Text('day ${DayNotesRepository.keyOf(state.extra! as DateTime)}'),
      ),
    ],
  );
  return MaterialApp.router(
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
  );
}

/// Unmounts everything so drift's stream timers finish inside the test.
Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(Duration.zero);
}

void main() {
  setUpAll(() {
    _database = AppDatabase(NativeDatabase.memory());
    _notes = DayNotesRepository(
      _database.dayNotesDao,
      clock: () => DateTime(2027, 1, 1),
    );
    GetIt.instance.registerSingleton<DayNotesRepository>(_notes);
  });
  setUp(() => _database.delete(_database.dayNotes).go());

  group('repository', () {
    test('days are stored as yyyy-MM-dd and read back at midnight', () {
      expect(
        DayNotesRepository.keyOf(DateTime(2027, 3, 5, 23, 59)),
        '2027-03-05',
      );
      expect(DayNotesRepository.dayOf('2027-03-05'), DateTime(2027, 3, 5));
    });

    test('blank text deletes the note', () async {
      final day = DateTime(2027, 3, 5);
      await _notes.save(day, '  Visit grandma  ');
      expect((await _notes.watchDay(day).first)!.text, 'Visit grandma');
      await _notes.save(day, '   ');
      expect(await _notes.watchDay(day).first, isNull);
    });

    test('watchDays and search', () async {
      await _notes.save(DateTime(2027, 3, 5), 'Pagoda');
      await _notes.save(DateTime(2027, 3, 20), 'Monks');
      await _notes.save(DateTime(2027, 4, 2), 'Trip');
      expect(
        await _notes.watchDays(DateTime(2027, 3), DateTime(2027, 3, 31)).first,
        {DateTime(2027, 3, 5), DateTime(2027, 3, 20)},
      );
      expect((await _notes.search('monk')).single.date, DateTime(2027, 3, 20));
      expect(await _notes.search(''), hasLength(3));
    });

    test('preview keeps the first three lines', () {
      final note = DayNote(
        date: DateTime(2027),
        text: 'a\n\nb\nc\nd',
        updatedAt: DateTime(2027),
      );
      expect(note.preview, 'a\nb\nc…');
    });
  });

  for (final style in [AppStyle.clear, AppStyle.material]) {
    testWidgets('${style.name}: add a note from a day, then edit it', (
      tester,
    ) async {
      final day = DateTime(2027, 3, 5);
      await tester.runAsync(() async {
        await tester.pumpWidget(
          _app(
            Scaffold(body: DayNoteGroup(date: day)),
            style: style,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(find.text('Add a note'), findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('day-note')));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('day-note-field')),
        'Offer food to monks',
      );
      if (style == AppStyle.clear) {
        await tester.tap(find.text('Close'));
      } else {
        Navigator.of(tester.element(find.byType(TextField))).pop();
      }
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(
        (await tester.runAsync(() => _notes.watchDay(day).first))!.text,
        'Offer food to monks',
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Note'), findsOneWidget);
      expect(find.text('Offer food to monks'), findsOneWidget);
      await _unmount(tester);
    });
  }

  testWidgets('the Notes page groups by month, searches and opens a day', (
    tester,
  ) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 1600);
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await _notes.save(DateTime(2027, 3, 5), 'Pagoda festival');
      await _notes.save(DateTime(2027, 4, 2), 'Thingyan trip');
      await tester.pumpWidget(_app(const NotesPage()));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    // Clear shows group labels in capitals.
    expect(find.text('APRIL 2027'), findsOneWidget);
    expect(find.text('MARCH 2027'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Thingyan trip')).dy,
      lessThan(tester.getTopLeft(find.text('Pagoda festival')).dy),
    );

    await tester.enterText(find.byType(EditableText), 'pagoda');
    await tester.pumpAndSettle();
    expect(find.text('Thingyan trip'), findsNothing);
    expect(find.text('Pagoda festival'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('note-2027-03-05')));
    await tester.pumpAndSettle();
    expect(find.text('day 2027-03-05'), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('no notes: the page says how to add one', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(_app(const NotesPage()));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(find.textContaining('No notes yet'), findsOneWidget);
    await _unmount(tester);
  });
}
