import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:myanmar_calendar_wear/features/day_details/models/day_details.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_localizations/shared_localizations.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final my = lookupAppLocalizations(const Locale('my'));

  test('Thadingyut full moon: Sabbath and the holiday, as on the phone', () {
    final day = DayDetails(DateTime(2025, 10, 6), Language.english);
    expect(day.isSabbath, isTrue);
    expect(day.sabbathLabel, 'Sabbath');
    expect(day.moonPhaseName, 'Full Moon');
    expect(day.weekday, 'Monday');
    expect(day.westernDate, '6 October 2025');
    expect(day.holidays(en), contains(startsWith('Thadingyut')));
  });

  test('Myanmar words and digits for a Myanmar calendar', () {
    final day = DayDetails(DateTime(2025, 10, 6), Language.myanmar);
    expect(day.sabbathLabel, 'ဥပုသ်');
    expect(day.monthName, 'သီတင်းကျွတ်');
    expect(day.fortnightDay, '၁၅');
    expect(day.myanmarDate, contains('၁၃၈၇'));
    expect(day.holidays(my), isNotEmpty);
  });

  test('a Shan calendar shows the Shan year', () {
    final day = DayDetails(DateTime(2025, 10, 6), Language.shan);
    final shanYear = translateNumbers(
      '${day.myanmar.shanYear}',
      language: Language.shan,
    );
    expect(day.myanmarDate, contains(shanYear));
  });

  test('astrology follows the app rule for good days', () {
    // Search a month for a day with Yatyaza: it reads as good.
    for (var i = 0; i < 31; i++) {
      final day = DayDetails(DateTime(2025, 10, 1 + i), Language.english);
      if (!day.myanmar.isYatyaza) continue;
      final yatyaza = day.astrology.firstWhere((m) => m.name == 'Yatyaza');
      expect(yatyaza.tone, AstroTone.good);
      return;
    }
    fail('No Yatyaza day in October 2025');
  });

  test('days are equal by date and language only', () {
    expect(
      DayDetails(DateTime(2025, 10, 6, 8), Language.english),
      DayDetails(DateTime(2025, 10, 6, 22), Language.english),
    );
    expect(
      DayDetails(DateTime(2025, 10, 6), Language.english).nextDay.previousDay,
      DayDetails(DateTime(2025, 10, 6), Language.english),
    );
    expect(
      DayDetails(
        DateTime(2025, 10, 6),
        Language.english,
      ).isToday(DateTime(2025, 10, 6, 23, 59)),
      isTrue,
    );
  });
}
