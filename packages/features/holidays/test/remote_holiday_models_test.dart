import 'package:flutter_test/flutter_test.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:holidays/holidays.dart';

void main() {
  group('RemoteHolidayConfig', () {
    test('should parse valid JSON correctly', () {
      final json = {
        "customHolidays": [
          {
            "id": "test_holiday",
            "name": "Test Holiday",
            "type": "public",
            "rule": {"type": "western", "month": 1, "day": 1},
          },
        ],
        "disabledHolidays": ["halloween"],
      };

      final config = RemoteHolidayConfig.fromJson(json);

      expect(config.customHolidays.length, 1);
      expect(config.customHolidays[0].id, "test_holiday");
      expect(config.customHolidays[0].name, "Test Holiday");
      expect(config.customHolidays[0].type, HolidayType.public);
      expect(config.disabledHolidays, [HolidayId.halloween]);
    });

    test('should return empty list for missing fields', () {
      final json = <String, dynamic>{};
      final config = RemoteHolidayConfig.fromJson(json);

      expect(config.customHolidays, isEmpty);
      expect(config.disabledHolidays, isEmpty);
    });
  });

  group('RemoteHolidayRule', () {
    test('western rule predicate should work', () {
      final rule = RemoteHolidayRule(type: "western", month: 12, day: 25);
      final predicate = rule.toPredicate();

      final wdTrue = WesternDate(
        year: 2024,
        month: 12,
        day: 25,
        weekday: 3,
        julianDayNumber: 0,
      );
      final wdFalse = WesternDate(
        year: 2024,
        month: 12,
        day: 24,
        weekday: 2,
        julianDayNumber: 0,
      );
      final mm = MyanmarDate(
        year: 1386,
        month: 9,
        day: 10,
        yearType: 0,
        moonPhase: 0,
        fortnightDay: 10,
        weekday: 3,
        julianDayNumber: 0,
        sasanaYear: 2568,
        monthLength: 30,
        monthType: 0,
      );

      expect(predicate(mm, wdTrue), isTrue);
      expect(predicate(mm, wdFalse), isFalse);
    });

    test('myanmar rule predicate should work', () {
      final rule = RemoteHolidayRule(
        type: "myanmar",
        month: 2,
        moonPhase: 1,
      ); // Kason Full Moon
      final predicate = rule.toPredicate();

      final mmTrue = MyanmarDate(
        year: 1386,
        month: 2,
        day: 15,
        yearType: 0,
        moonPhase: 1,
        fortnightDay: 15,
        weekday: 3,
        julianDayNumber: 0,
        sasanaYear: 2568,
        monthLength: 30,
        monthType: 0,
      );
      final mmFalse = MyanmarDate(
        year: 1386,
        month: 2,
        day: 14,
        yearType: 0,
        moonPhase: 0,
        fortnightDay: 14,
        weekday: 2,
        julianDayNumber: 0,
        sasanaYear: 2568,
        monthLength: 30,
        monthType: 0,
      );
      final wd = WesternDate(
        year: 2024,
        month: 5,
        day: 22,
        weekday: 3,
        julianDayNumber: 0,
      );

      expect(predicate(mmTrue, wd), isTrue);
      expect(predicate(mmFalse, wd), isFalse);
    });
  });
}
