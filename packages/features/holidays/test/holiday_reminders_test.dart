import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holidays/holidays.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_localizations/shared_localizations.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));
  final now = DateTime(2026, 10, 18, 9);

  List<PlannedHolidayReminder> plan({
    Set<String> followed = const {},
    bool allPublic = false,
    bool sabbath = false,
    HolidayReminderTime time = HolidayReminderTime.evening,
  }) => HolidayReminders.plan(
    now: now,
    followed: followed,
    allPublic: allPublic,
    sabbath: sabbath,
    time: time,
    calendarLanguage: Language.english,
    l10n: l10n,
  );

  test('a followed holiday reminds the evening before at 6 pm', () {
    final r = plan(followed: {'thadingyut'}).single;
    expect(r.at, DateTime(2026, 10, 24, 18));
    expect(r.title, 'Tomorrow: Thadingyut');
    expect(
      r.body,
      'Public holiday · 25–27 Oct\n${HolidayCatalog.thadingyut.about(l10n)}',
    );
    expect(r.payload, startsWith(HolidayReminders.payloadPrefix));
    expect(r.id, greaterThanOrEqualTo(HolidayReminders.idBase));
  });

  test(
    'both times give an evening and a morning reminder with distinct ids',
    () {
      final r = plan(followed: {'thadingyut'}, time: HolidayReminderTime.both);
      expect(r.map((e) => e.at), [
        DateTime(2026, 10, 24, 18),
        DateTime(2026, 10, 25, 8),
      ]);
      expect(r[1].title, 'Today: Thadingyut');
      expect(r.map((e) => e.id).toSet().length, 2);
    },
  );

  test('all public holidays covers days off in the next 60 days only', () {
    final ids = plan(allPublic: true).map((r) => r.payload).toList();
    expect(ids, [
      'holiday_thadingyut_2026',
      'holiday_diwali_2026',
      'holiday_tazaungdaing_2026',
      'holiday_nationalDay_2026',
    ]);
  });

  test('nothing followed, nothing planned', () {
    expect(plan(), isEmpty);
  });

  test('Sabbath days remind on every Sabbath in the next 60 days', () {
    final r = plan(sabbath: true);
    expect(r.map((e) => e.at.add(const Duration(hours: 6))), [
      DateTime(2026, 10, 19),
      DateTime(2026, 10, 26),
      DateTime(2026, 11, 3),
      DateTime(2026, 11, 9),
      DateTime(2026, 11, 17),
      DateTime(2026, 11, 24),
      DateTime(2026, 12, 2),
      DateTime(2026, 12, 9),
      DateTime(2026, 12, 17),
    ]);
    expect(r.first.title, 'Tomorrow: Sabbath day');
    expect(r.first.body, 'Thadingyut Waxing 8 · 19 Oct');
    expect(r[1].body, 'Thadingyut Full Moon 15 · 26 Oct');
    expect(r.every((e) => e.payload.startsWith('holiday_sabbath_')), isTrue);
  });

  test('a Sabbath morning reminder says today', () {
    final r = plan(sabbath: true, time: HolidayReminderTime.morning).first;
    expect(r.at, DateTime(2026, 10, 19, 8));
    expect(r.title, 'Today: Sabbath day');
  });

  test('a Sabbath on a reminded holiday shares its notification', () {
    // The start of Lent is the Waso full moon, 29 Jul 2026.
    final r = HolidayReminders.plan(
      now: DateTime(2026, 7, 20, 9),
      followed: {'lentStart'},
      allPublic: false,
      sabbath: true,
      time: HolidayReminderTime.evening,
      calendarLanguage: Language.english,
      l10n: l10n,
    );
    final evening = r.where((e) => e.at == DateTime(2026, 7, 28, 18));
    expect(evening.single.title, contains(' · Sabbath day'));
    expect(evening.single.payload, contains('lentStart'));
  });

  test('ids fit in 32 bits and never repeat', () {
    final r = plan(
      allPublic: true,
      sabbath: true,
      time: HolidayReminderTime.both,
    );
    for (final e in r) {
      expect(e.id, lessThan(1 << 31));
    }
    expect(r.map((e) => e.id).toSet(), hasLength(r.length));
  });
}
