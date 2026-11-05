import 'package:drift/native.dart';
import 'package:events/events.dart';
import 'package:events/src/data/datasources/events_local_datasource.dart';
import 'package:events/src/data/datasources/recurring_exceptions_datasource.dart';
import 'package:events/src/presentation/widgets/repeat_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integrations_database/integrations_database.dart' as db;
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart' show Language;
import 'package:shared_core/shared_core.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

// Grandma's birthday: 11 Mar 1990, 1351 Tabaung waning 1.
final _born = DateTime(1990, 3, 11);

Event _birthday() => Event(
  title: "Grandma's birthday",
  eventDate: _born,
  category: EventCategory.personal,
  recurrenceRule: const RecurrenceRule(type: RecurrenceType.myanmarYearly),
  createdAt: DateTime(2026, 11, 1),
  updatedAt: DateTime(2026, 11, 1),
);

void main() {
  test('a Myanmar yearly event falls on each Tabaung waning 1', () {
    final days = _birthday().recurrenceRule!.generateOccurrences(
      _born,
      DateTime(2026, 11, 1),
      DateTime(2027, 12, 31),
    );
    expect(days, [DateTime(2027, 3, 23)]);
  });

  test('monthly by Myanmar day, skipping a deleted occurrence', () {
    final rule = RecurrenceRule(
      type: RecurrenceType.myanmarMonthly,
      exceptions: [DateTime(2026, 11, 24)],
    );
    expect(
      rule.generateOccurrences(
        DateTime(2026, 10, 26),
        DateTime(2026, 10, 1),
        DateTime(2026, 12, 31),
      ),
      [DateTime(2026, 10, 26), DateTime(2026, 12, 24)],
    );
  });

  test('the rule survives a save and shows on its Myanmar day', () async {
    final database = db.AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final local = EventsLocalDataSourceImpl(database);
    await local.initializeDefaultCategories();
    final repository = EventsRepositoryImpl(
      local,
      RecurringExceptionsDataSourceImpl(database),
    );
    final created = (await repository.createEvent(
      _birthday(),
    )).fold((f) => throw StateError('not saved: ${f.message}'), (e) => e);
    final loaded = (await repository.getEventById(
      created.id!,
    )).getOrElse(() => throw StateError('not loaded'));
    expect(loaded.recurrenceRule!.type, RecurrenceType.myanmarYearly);
    final march = (await repository.getEventsByDateRange(
      DateTime(2027, 3, 1),
      DateTime(2027, 3, 31),
    )).getOrElse(() => throw StateError('no range'));
    expect(march.map((e) => DateUtils.dateOnly(e.eventDate)), [
      DateTime(2027, 3, 23),
    ]);
  });

  testWidgets('the repeat sheet names the Myanmar day', (tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 1400);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.build(
          style: AppStyle.clear,
          colorScheme: AppColorSchemes.modernLight,
        ),
        builder: (context, child) =>
            CalendarLanguageScope(language: Language.english, child: child!),
        home: Scaffold(
          body: RepeatSheet(
            rule: null,
            dayTimes: const {},
            startDate: DateTime(2026, 10, 26),
            time: null,
            allowTimePerDay: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Yearly by Myanmar date'), findsOneWidget);
    expect(find.text('Every Thadingyut Full Moon 15'), findsOneWidget);
    expect(find.text('Monthly by Myanmar date'), findsOneWidget);
    expect(find.text('Every Full Moon 15'), findsOneWidget);
  });
}
