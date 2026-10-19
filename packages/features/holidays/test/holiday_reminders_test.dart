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
    HolidayReminderTime time = HolidayReminderTime.evening,
  }) => HolidayReminders.plan(
    now: now,
    followed: followed,
    allPublic: allPublic,
    time: time,
    calendarLanguage: Language.english,
    l10n: l10n,
  );

  test('a followed holiday reminds the evening before at 6 pm', () {
    final r = plan(followed: {'thadingyut'}).single;
    expect(r.at, DateTime(2026, 10, 24, 18));
    expect(r.title, 'Tomorrow: Thadingyut');
    expect(r.body, 'Public holiday · 25–27 Oct');
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

  test('ids fit in 32 bits', () {
    for (final r in plan(allPublic: true, time: HolidayReminderTime.both)) {
      expect(r.id, lessThan(1 << 31));
    }
  });
}
