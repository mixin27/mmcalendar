import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integrations_database/integrations_database.dart';

String _crlf(String s) => s.trim().split('\n').join('\r\n');

// As Google Calendar exports: a time zone block, a weekly class with a
// deleted day and a reminder, a folded and escaped description.
final _google = _crlf('''
BEGIN:VCALENDAR
PRODID:-//Google Inc//Google Calendar 70.9054//EN
VERSION:2.0
BEGIN:VTIMEZONE
TZID:Asia/Yangon
BEGIN:STANDARD
TZOFFSETFROM:+0630
TZOFFSETTO:+0630
DTSTART:19700101T000000
END:STANDARD
END:VTIMEZONE
BEGIN:VEVENT
DTSTART;TZID=Asia/Yangon:20261102T090000
DTEND;TZID=Asia/Yangon:20261102T100000
RRULE:FREQ=WEEKLY;WKST=SU;UNTIL=20261231T000000Z;BYDAY=MO,WE
EXDATE;TZID=Asia/Yangon:20261104T090000
UID:abc@google.com
SUMMARY:Pali class
DESCRIPTION:Bring the book\\, a pen\\nand notes; room 3 on the second fl
 oor
LOCATION:Yangon
BEGIN:VALARM
ACTION:DISPLAY
DESCRIPTION:This is an event reminder
TRIGGER:-P0DT0H30M0S
END:VALARM
END:VEVENT
BEGIN:VEVENT
DTSTART;VALUE=DATE:19900311
DTEND;VALUE=DATE:19900312
RRULE:FREQ=YEARLY
SUMMARY:Grandma's birthday
END:VEVENT
BEGIN:VEVENT
DTSTART:20261109T020000Z
RRULE:FREQ=MONTHLY;BYDAY=2MO
SUMMARY:Committee
END:VEVENT
BEGIN:VEVENT
DTSTART;VALUE=DATE:20261120
SUMMARY:Cancelled trip
STATUS:CANCELLED
END:VEVENT
BEGIN:VEVENT
DTSTART;TZID=Asia/Yangon:20261109T100000
RECURRENCE-ID;TZID=Asia/Yangon:20261109T090000
SUMMARY:Pali class (moved)
END:VEVENT
END:VCALENDAR
''');

void main() {
  test('reads Google Calendar events', () {
    final cal = IcsImport.parse(_google);
    expect(cal.events.map((e) => e.title), [
      'Pali class',
      "Grandma's birthday",
      'Committee',
    ]);
    expect(cal.simplified, 1);
    expect(cal.skipped, 2);

    final pali = cal.events[0];
    expect(pali.start, DateTime(2026, 11, 2, 9));
    expect(pali.allDay, isFalse);
    expect(pali.repeat, 'weekly');
    expect(pali.weekdays, [DateTime.monday, DateTime.wednesday]);
    expect(pali.deleted, [DateTime(2026, 11, 4)]);
    expect(pali.until, isNotNull);
    expect(
      pali.description,
      'Bring the book, a pen\nand notes; room 3 on the second floor',
    );
    expect(pali.location, 'Yangon');

    final birthday = cal.events[1];
    expect(birthday.allDay, isTrue);
    expect(birthday.start, DateTime(1990, 3, 11));
    expect(birthday.repeat, 'yearly');

    // "The 2nd Monday" can't be said: a single event.
    final committee = cal.events[2];
    expect(committee.repeat, isNull);
    expect(committee.start, DateTime.utc(2026, 11, 9, 2).toLocal());
  });

  test('picked dates come in as a "dates" repeat', () {
    final cal = IcsImport.parse(
      _crlf('''
BEGIN:VCALENDAR
BEGIN:VEVENT
DTSTART;VALUE=DATE:20261021
RDATE;VALUE=DATE:20261028,20261102
SUMMARY:Exam
END:VEVENT
END:VCALENDAR
'''),
    );
    final exam = cal.events.single;
    expect(exam.repeat, 'dates');
    expect(exam.dates, [
      DateTime(2026, 10, 21),
      DateTime(2026, 10, 28),
      DateTime(2026, 11, 2),
    ]);
  });

  test('other files are refused', () {
    expect(() => IcsImport.parse('hello'), throwsFormatException);
  });

  test('importing adds events with their repeats, once', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db
        .into(db.eventCategories)
        .insert(
          EventCategoriesCompanion.insert(
            name: 'Personal',
            iconName: 'person',
            colorCode: 1,
            sortOrder: 0,
            createdAt: DateTime(2026),
          ),
        );
    final cal = IcsImport.parse(_google);
    expect(await IcsImport.importInto(db, cal), 3);
    final events = await db.select(db.calendarEvents).get();
    final pali = events.firstWhere((e) => e.title == 'Pali class');
    expect(pali.eventTime, DateTime(2026, 11, 2, 9));
    expect(pali.isAllDay, isFalse);
    expect(pali.categoryName, 'Personal');
    expect(pali.categoryId, isNotNull);
    final rule = (await (db.select(
      db.eventRecurrenceRules,
    )..where((r) => r.eventId.equals(pali.id))).getSingle());
    expect(rule.recurrenceType, 'weekly');
    expect(rule.recurrenceDays, '[1,3]');
    final skipped = await db.select(db.recurringEventExceptions).get();
    expect(skipped.single.occurrenceDate, DateTime(2026, 11, 4));
    expect(skipped.single.masterEventId, pali.id);

    // Again: nothing new.
    expect(await IcsImport.importInto(db, cal), 0);
    expect(await db.select(db.calendarEvents).get(), hasLength(3));
  });

  test("the app's own export comes back the same", () async {
    final from = AppDatabase(NativeDatabase.memory());
    final t = DateTime(2026, 11, 1);
    final id = await from
        .into(from.calendarEvents)
        .insert(
          CalendarEventsCompanion.insert(
            title: 'Standup',
            eventDate: DateTime(2026, 11, 2),
            createdAt: t,
            updatedAt: t,
          ),
        );
    await from
        .into(from.eventRecurrenceRules)
        .insert(
          EventRecurrenceRulesCompanion.insert(
            eventId: Value(id),
            recurrenceType: 'weekly',
            recurrenceDays: const Value('[1,3]'),
            recurrenceCount: const Value(10),
            createdAt: t,
            updatedAt: t,
          ),
        );
    final ics = await EventsIcs.fromDatabase(from, now: t);
    await from.close();

    final to = AppDatabase(NativeDatabase.memory());
    addTearDown(to.close);
    expect(await IcsImport.importInto(to, IcsImport.parse(ics)), 1);
    final event = (await to.select(to.calendarEvents).get()).single;
    expect(event.title, 'Standup');
    expect(event.isAllDay, isTrue);
    final rule = (await to.select(to.eventRecurrenceRules).get()).single;
    expect(rule.recurrenceType, 'weekly');
    expect(rule.recurrenceDays, '[1,3]');
    expect(rule.recurrenceCount, 10);
  });
}
