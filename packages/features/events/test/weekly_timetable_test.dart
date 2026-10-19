import 'package:dartz/dartz.dart';
import 'package:events/events.dart';
import 'package:events/src/domain/services/weekly_timetable.dart';
import 'package:events/src/presentation/widgets/repeat_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

// Monday 19 October 2026; the class days are Wednesday and Thursday.
final _monday = DateTime(2026, 10, 19);
const _wedThu = [DateTime.wednesday, DateTime.thursday];

Event _class({
  RecurrenceRule? rule,
  DateTime? time,
  bool allDay = false,
  int? id,
}) => Event(
  id: id,
  title: 'Online class',
  eventDate: _monday,
  eventTime: time ?? DateTime(2026, 10, 19, 19),
  isAllDay: allDay,
  category: EventCategory.personal,
  recurrenceRule:
      rule ??
      const RecurrenceRule(type: RecurrenceType.weekly, daysOfWeek: _wedThu),
  notifications: const [NotificationSetting(minutesBefore: 15)],
  createdAt: _monday,
  updatedAt: _monday,
);

class _Flow implements EventFlowService {
  final saved = <Event>[];

  @override
  Future<Either<Failure, EventFlowResult>> saveEvent(Event event) async {
    saved.add(event);
    return Right(
      EventFlowResult(event: event.copyWith(id: saved.length), isNew: true),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _GetById implements GetEventById {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('WeeklyTimetable', () {
    test('a weekly series starts on its first class day', () {
      final [event] = WeeklyTimetable.eventsToSave(_class());
      expect(event.eventDate, DateTime(2026, 10, 21)); // Wednesday
      expect(event.eventTime, DateTime(2026, 10, 21, 19));
      expect(event.recurrenceRule!.daysOfWeek, _wedThu);
    });

    test('days with their own times become one series per time', () {
      final events = WeeklyTimetable.eventsToSave(
        _class(),
        dayTimes: {
          DateTime.wednesday: DateTime(2026, 10, 19, 19),
          DateTime.thursday: DateTime(2026, 10, 19, 18, 30),
        },
      );
      expect(events, hasLength(2));
      // Earlier time first: Thursday 6:30 pm, then Wednesday 7 pm.
      expect(events[0].recurrenceRule!.daysOfWeek, [DateTime.thursday]);
      expect(events[0].eventDate, DateTime(2026, 10, 22));
      expect(events[0].eventTime, DateTime(2026, 10, 22, 18, 30));
      expect(events[1].recurrenceRule!.daysOfWeek, [DateTime.wednesday]);
      expect(events[1].eventTime, DateTime(2026, 10, 21, 19));
      // Both keep the reminder.
      expect(events.every((e) => e.notifications.length == 1), isTrue);
    });

    test('days at the same time stay one series', () {
      final events = WeeklyTimetable.eventsToSave(
        _class(),
        dayTimes: {
          DateTime.wednesday: DateTime(2026, 10, 19, 19),
          DateTime.thursday: DateTime(2026, 10, 19, 19),
        },
      );
      expect(events, hasLength(1));
      expect(events.single.recurrenceRule!.daysOfWeek, _wedThu);
    });

    test('"after N classes" counts the whole timetable', () {
      final events = WeeklyTimetable.eventsToSave(
        _class(
          rule: const RecurrenceRule(
            type: RecurrenceType.weekly,
            daysOfWeek: _wedThu,
            occurrenceCount: 4,
          ),
        ),
        dayTimes: {
          DateTime.wednesday: DateTime(2026, 10, 19, 19),
          DateTime.thursday: DateTime(2026, 10, 19, 18),
        },
      );
      // Classes: Wed 21, Thu 22, Wed 28, Thu 29 October.
      for (final event in events) {
        expect(event.recurrenceRule!.occurrenceCount, isNull);
        expect(event.recurrenceRule!.endDate, DateTime(2026, 10, 29));
      }
      final all = [
        for (final e in events)
          ...e.recurrenceRule!.generateOccurrences(
            e.eventDate,
            _monday,
            DateTime(2027),
          ),
      ]..sort();
      expect(all, [
        DateTime(2026, 10, 21),
        DateTime(2026, 10, 22),
        DateTime(2026, 10, 28),
        DateTime(2026, 10, 29),
      ]);
    });

    test('all-day events and edits are never split', () {
      expect(
        WeeklyTimetable.eventsToSave(
          _class(allDay: true),
          dayTimes: {DateTime.thursday: DateTime(2026, 10, 19, 6)},
        ),
        hasLength(1),
      );
      expect(
        WeeklyTimetable.eventsToSave(
          _class(id: 3),
          dayTimes: {DateTime.thursday: DateTime(2026, 10, 19, 6)},
        ),
        hasLength(1),
      );
    });
  });

  group('event form', () {
    test('one save creates a weekly event for each time', () async {
      final flow = _Flow();
      final bloc = EventFormBloc(
        eventFlowService: flow,
        getEventById: _GetById(),
      );
      addTearDown(bloc.close);
      bloc
        ..add(InitializeNewEvent(initialDate: _monday))
        ..add(const UpdateEventTitle('Online class'))
        ..add(const ToggleAllDay())
        ..add(UpdateEventTime(DateTime(2026, 10, 19, 19)))
        ..add(
          UpdateRepeat(
            const RecurrenceRule(
              type: RecurrenceType.weekly,
              daysOfWeek: _wedThu,
            ),
            dayTimes: {
              DateTime.wednesday: DateTime(2026, 10, 19, 19),
              DateTime.thursday: DateTime(2026, 10, 19, 18),
            },
          ),
        )
        ..add(const SubmitEventForm());
      final success =
          await bloc.stream.firstWhere((s) => s is EventFormSuccess)
              as EventFormSuccess;
      expect(success.count, 2);
      expect(flow.saved.map((e) => e.recurrenceRule!.daysOfWeek), [
        [DateTime.thursday],
        [DateTime.wednesday],
      ]);
    });

    test('"Never" clears a repeat', () async {
      final bloc = EventFormBloc(
        eventFlowService: _Flow(),
        getEventById: _GetById(),
      );
      addTearDown(bloc.close);
      bloc
        ..add(InitializeNewEvent(initialDate: _monday))
        ..add(const UpdateRepeat(RecurrenceRule(type: RecurrenceType.weekly)))
        ..add(const UpdateRepeat(null));
      final cleared = await bloc.stream.firstWhere(
        (s) =>
            s is EventFormEditing &&
            s.recurrenceRule == null &&
            s.title.isEmpty &&
            bloc.state == s,
      );
      expect((cleared as EventFormEditing).recurrenceRule, isNull);
    });
  });

  testWidgets('the repeat sheet sets up a Wed and Thu timetable', (
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
                      rule: null,
                      dayTimes: const {},
                      startDate: _monday,
                      time: DateTime(2026, 10, 19, 19),
                      allowTimePerDay: true,
                    ),
                  ),
                  child: const Text('open'),
                ),
                Builder(
                  builder: (context) => Text(
                    repeatSummary(
                      context,
                      const RecurrenceRule(
                        type: RecurrenceType.weekly,
                        daysOfWeek: _wedThu,
                        occurrenceCount: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('Every week · Wed, Thu · 24 times'), findsOneWidget);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('repeat-type-weekly')));
    await tester.pumpAndSettle();
    // Monday is the start date's day; the class days are Wed and Thu.
    for (final day in [
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.monday,
    ]) {
      await tester.ensureVisible(find.byKey(ValueKey('repeat-day-$day')));
      await tester.tap(find.byKey(ValueKey('repeat-day-$day')));
      await tester.pumpAndSettle();
    }
    final perDay = find.byKey(const ValueKey('repeat-time-per-day'));
    await tester.ensureVisible(perDay);
    await tester.tap(perDay);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('repeat-day-time-${DateTime.wednesday}')),
      findsOneWidget,
    );
    await tester.ensureVisible(find.byKey(const ValueKey('repeat-done')));
    await tester.tap(find.byKey(const ValueKey('repeat-done')));
    await tester.pumpAndSettle();

    expect(choice!.rule!.type, RecurrenceType.weekly);
    expect(choice!.rule!.daysOfWeek, _wedThu);
    expect(choice!.dayTimes.keys, unorderedEquals(_wedThu));
    expect(tester.takeException(), isNull);
  });
}
