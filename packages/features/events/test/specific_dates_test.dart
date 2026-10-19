import 'package:drift/native.dart';
import 'package:events/events.dart';
import 'package:events/src/data/datasources/events_local_datasource.dart';
import 'package:events/src/data/datasources/recurring_exceptions_datasource.dart';
import 'package:events/src/domain/services/weekly_timetable.dart';
import 'package:events/src/presentation/widgets/repeat_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integrations_database/integrations_database.dart' as db;
import 'package:shared_ui_kit/shared_ui_kit.dart';

// Exam days: three scattered days in October and November 2026.
final _exams = [
  DateTime(2026, 11, 2),
  DateTime(2026, 10, 21),
  DateTime(2026, 10, 28),
];

RecurrenceRule get _rule =>
    RecurrenceRule(type: RecurrenceType.dates, dates: _exams);

Event _exam() => Event(
  title: 'Exam',
  eventDate: DateTime(2026, 10, 19),
  eventTime: DateTime(2026, 10, 19, 9),
  isAllDay: false,
  category: EventCategory.personal,
  recurrenceRule: _rule,
  notifications: const [NotificationSetting(minutesBefore: 60)],
  createdAt: DateTime(2026, 10, 19),
  updatedAt: DateTime(2026, 10, 19),
);

void main() {
  test('specific dates occur on those days only, earliest first', () {
    expect(
      _rule.generateOccurrences(
        DateTime(2026, 10, 21),
        DateTime(2026, 10, 1),
        DateTime(2026, 12, 31),
      ),
      [DateTime(2026, 10, 21), DateTime(2026, 10, 28), DateTime(2026, 11, 2)],
    );
    // A range and a skipped day.
    final skipped = _rule.copyWith(exceptions: [DateTime(2026, 10, 28)]);
    expect(
      skipped.generateOccurrences(
        DateTime(2026, 10, 21),
        DateTime(2026, 10, 22),
        DateTime(2026, 12, 31),
      ),
      [DateTime(2026, 11, 2)],
    );
  });

  test('the event starts on the earliest date, at its time', () {
    final [event] = WeeklyTimetable.eventsToSave(_exam());
    expect(event.eventDate, DateTime(2026, 10, 21));
    expect(event.eventTime, DateTime(2026, 10, 21, 9));
  });

  test('an event needs at least one date', () {
    final empty = _exam().copyWith(
      recurrenceRule: const RecurrenceRule(type: RecurrenceType.dates),
    );
    expect(
      EventValidationService.validateEvent(empty, isUpdate: false).isValid,
      isFalse,
    );
    expect(
      EventValidationService.validateEvent(_exam(), isUpdate: false).isValid,
      isTrue,
    );
  });

  test('the dates survive a save and show on each day', () async {
    final database = db.AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final local = EventsLocalDataSourceImpl(database);
    await local.initializeDefaultCategories();
    final repository = EventsRepositoryImpl(
      local,
      RecurringExceptionsDataSourceImpl(database),
    );
    final [toSave] = WeeklyTimetable.eventsToSave(_exam());
    final created = (await repository.createEvent(
      toSave,
    )).fold((f) => throw StateError('not saved: $f ${f.message}'), (e) => e);
    final loaded = (await repository.getEventById(
      created.id!,
    )).getOrElse(() => throw StateError('not loaded'));
    expect(loaded.recurrenceRule!.type, RecurrenceType.dates);
    expect([...loaded.recurrenceRule!.dates!]..sort(), [
      DateTime(2026, 10, 21),
      DateTime(2026, 10, 28),
      DateTime(2026, 11, 2),
    ]);
    final october = (await repository.getEventsByDateRange(
      DateTime(2026, 10, 1),
      DateTime(2026, 11, 30),
    )).getOrElse(() => throw StateError('no range'));
    expect(october.map((e) => DateUtils.dateOnly(e.eventDate)).toSet(), {
      DateTime(2026, 10, 21),
      DateTime(2026, 10, 28),
      DateTime(2026, 11, 2),
    });
  });

  testWidgets('the repeat sheet lists chosen dates and sums them up', (
    tester,
  ) async {
    RepeatChoice? choice;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(
          style: AppStyle.clear,
          colorScheme: AppColorSchemes.modernLight,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                TextButton(
                  onPressed: () async => choice = await showAppSheet(
                    context: context,
                    title: 'Repeat',
                    builder: (_) => RepeatSheet(
                      rule: _rule,
                      dayTimes: const {},
                      startDate: DateTime(2026, 10, 19),
                      time: DateTime(2026, 10, 19, 9),
                      allowTimePerDay: true,
                    ),
                  ),
                  child: const Text('open'),
                ),
                Builder(
                  builder: (context) => Text(repeatSummary(context, _rule)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(
      find.text('3 dates · Wed 21 Oct, Wed 28 Oct, Mon 2 Nov'),
      findsOneWidget,
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(InputChip), findsNWidgets(3));
    // Drop 28 October.
    final chip = find.byKey(
      ValueKey('repeat-date-${DateTime(2026, 10, 28).toIso8601String()}'),
    );
    tester.widget<InputChip>(chip).onDeleted!();
    await tester.pumpAndSettle();
    expect(find.byType(InputChip), findsNWidgets(2));
    await tester.ensureVisible(find.byKey(const ValueKey('repeat-done')));
    await tester.tap(find.byKey(const ValueKey('repeat-done')));
    await tester.pumpAndSettle();
    expect(choice!.rule!.dates, [
      DateTime(2026, 10, 21),
      DateTime(2026, 11, 2),
    ]);
  });
}
