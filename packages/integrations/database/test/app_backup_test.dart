import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integrations_database/integrations_database.dart';

final _t = DateTime(2026, 11, 1, 9);

Future<AppDatabase> _open() async {
  final db = AppDatabase(NativeDatabase.memory());
  await db.customSelect('SELECT 1').get();
  return db;
}

/// Two events (one weekly with a reminder and a skipped day), a category,
/// a custom holiday and a note.
Future<void> _seed(AppDatabase db) async {
  final work = await db
      .into(db.eventCategories)
      .insert(
        EventCategoriesCompanion.insert(
          name: 'Work',
          iconName: 'work',
          colorCode: 1,
          sortOrder: 0,
          createdAt: _t,
        ),
      );
  final standup = await db
      .into(db.calendarEvents)
      .insert(
        CalendarEventsCompanion.insert(
          title: 'Standup',
          eventDate: DateTime(2026, 11, 2),
          categoryId: Value(work),
          createdAt: _t,
          updatedAt: _t,
        ),
      );
  await db
      .into(db.calendarEvents)
      .insert(
        CalendarEventsCompanion.insert(
          title: 'Dentist',
          eventDate: DateTime(2026, 11, 20),
          createdAt: _t,
          updatedAt: _t,
        ),
      );
  await db
      .into(db.eventReminders)
      .insert(
        EventRemindersCompanion.insert(
          eventId: standup,
          minutesBefore: 15,
          createdAt: _t,
        ),
      );
  await db
      .into(db.eventRecurrenceRules)
      .insert(
        EventRecurrenceRulesCompanion.insert(
          eventId: Value(standup),
          recurrenceType: 'weekly',
          recurrenceDays: const Value('[1,3]'),
          createdAt: _t,
          updatedAt: _t,
        ),
      );
  await db
      .into(db.recurringEventExceptions)
      .insert(
        RecurringEventExceptionsCompanion.insert(
          masterEventId: standup,
          occurrenceDate: DateTime(2026, 11, 4),
          exceptionType: 'deleted',
          createdAt: _t,
        ),
      );
  await db
      .into(db.customHolidays)
      .insert(
        CustomHolidaysCompanion.insert(
          name: 'Family day',
          date: DateTime(2026, 12, 1),
          type: 'personal',
        ),
      );
  await db.dayNotesDao.save('2026-11-20', 'Bring X-ray', _t);
}

void main() {
  late List<int> backup;

  setUpAll(() async {
    final db = await _open();
    await _seed(db);
    backup = await AppBackup(
      db,
    ).export(settings: {'holiday_reminders_sabbath': true}, now: _t);
    await db.close();
  });

  test('a backup says what it holds', () {
    final file = AppBackup.read(backup);
    expect(file.summary.events, 2);
    expect(file.summary.categories, 1);
    expect(file.summary.notes, 1);
    expect(file.summary.customHolidays, 1);
    expect(file.settings, {'holiday_reminders_sabbath': true});
    expect(file.createdAt, _t);
  });

  test('restoring into an empty app brings everything back', () async {
    final db = await _open();
    addTearDown(db.close);
    final added = await AppBackup(db).restore(AppBackup.read(backup));
    expect(added.events, 2);
    final standup = (await db.select(db.calendarEvents).get()).firstWhere(
      (e) => e.title == 'Standup',
    );
    final work = (await db.select(db.eventCategories).get()).single;
    expect(standup.categoryId, work.id);
    expect(
      (await db.select(db.eventReminders).get()).single.eventId,
      standup.id,
    );
    expect(
      (await db.select(db.eventRecurrenceRules).get()).single.eventId,
      standup.id,
    );
    expect(
      (await db.select(db.recurringEventExceptions).get()).single.masterEventId,
      standup.id,
    );
    expect((await db.dayNotesDao.all()).single.body, 'Bring X-ray');
    expect(
      (await db.select(db.customHolidays).get()).single.name,
      'Family day',
    );
  });

  test('merging keeps what is here and skips what is already here', () async {
    final db = await _open();
    addTearDown(db.close);
    // Here already: a different event that takes id 1, and the same Work
    // category, and a newer note on the same day.
    await db
        .into(db.eventCategories)
        .insert(
          EventCategoriesCompanion.insert(
            name: 'Work',
            iconName: 'briefcase',
            colorCode: 2,
            sortOrder: 0,
            createdAt: _t,
          ),
        );
    await db
        .into(db.calendarEvents)
        .insert(
          CalendarEventsCompanion.insert(
            title: 'Gym',
            eventDate: DateTime(2026, 11, 3),
            createdAt: _t,
            updatedAt: _t,
          ),
        );
    await db.dayNotesDao.save(
      '2026-11-20',
      'Newer note',
      _t.add(const Duration(days: 1)),
    );

    final restore = AppBackup(db).restore;
    final added = await restore(AppBackup.read(backup));
    expect(added.events, 2);
    expect(added.categories, 0);
    expect(added.notes, 0);
    final titles = (await db.select(db.calendarEvents).get())
        .map((e) => e.title)
        .toList();
    expect(titles, unorderedEquals(['Gym', 'Standup', 'Dentist']));
    expect((await db.select(db.eventCategories).get()), hasLength(1));
    expect((await db.dayNotesDao.all()).single.body, 'Newer note');

    // Restoring the same file again adds nothing.
    final again = await restore(AppBackup.read(backup));
    expect(again.isEmpty, isTrue);
    expect(await db.select(db.calendarEvents).get(), hasLength(3));
    expect(await db.select(db.eventReminders).get(), hasLength(1));
  });

  test('replacing wipes what is here first', () async {
    final db = await _open();
    addTearDown(db.close);
    await db
        .into(db.calendarEvents)
        .insert(
          CalendarEventsCompanion.insert(
            title: 'Gym',
            eventDate: DateTime(2026, 11, 3),
            createdAt: _t,
            updatedAt: _t,
          ),
        );
    await AppBackup(db).restore(AppBackup.read(backup), replace: true);
    expect(
      (await db.select(db.calendarEvents).get()).map((e) => e.title),
      unorderedEquals(['Standup', 'Dentist']),
    );
  });

  test('other files and newer backups are refused', () {
    expect(
      () => AppBackup.read(utf8.encode('hello')),
      throwsA(isA<BackupFormatException>()),
    );
    expect(
      () => AppBackup.read(utf8.encode('{"format":"other","tables":{}}')),
      throwsA(isA<BackupFormatException>()),
    );
    expect(
      () => AppBackup.read(
        utf8.encode(
          jsonEncode({'format': AppBackup.format, 'version': 99, 'tables': {}}),
        ),
      ),
      throwsA(
        isA<BackupFormatException>().having(
          (e) => e.newerVersion,
          'newerVersion',
          isTrue,
        ),
      ),
    );
  });

  test('events export as iCalendar', () async {
    final db = await _open();
    addTearDown(db.close);
    await _seed(db);
    await db
        .into(db.calendarEvents)
        .insert(
          CalendarEventsCompanion.insert(
            title: 'Call; Mum, then Dad',
            eventDate: DateTime(2026, 11, 7),
            isAllDay: const Value(false),
            eventTime: Value(DateTime(2026, 11, 7, 18, 30)),
            createdAt: _t,
            updatedAt: _t,
          ),
        );
    final ics = await EventsIcs.fromDatabase(
      db,
      now: DateTime.utc(2026, 11, 5),
    );
    expect(ics, startsWith('BEGIN:VCALENDAR\r\n'));
    expect(ics, endsWith('END:VCALENDAR\r\n'));
    expect('BEGIN:VEVENT'.allMatches(ics), hasLength(3));
    expect(ics, contains('SUMMARY:Standup\r\n'));
    expect(ics, contains('DTSTART;VALUE=DATE:20261102\r\n'));
    expect(ics, contains('DTEND;VALUE=DATE:20261103\r\n'));
    expect(ics, contains('RRULE:FREQ=WEEKLY;BYDAY=MO,WE\r\n'));
    expect(ics, contains('EXDATE;VALUE=DATE:20261104\r\n'));
    expect(ics, contains(r'SUMMARY:Call\; Mum\, then Dad'));
    expect(ics, contains('DTSTART:20261107T183000\r\n'));
    expect(ics, contains('DTEND:20261107T193000\r\n'));
  });
}
