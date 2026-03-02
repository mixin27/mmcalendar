import 'package:flutter_test/flutter_test.dart';
import 'package:holidays/holidays.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

void main() {
  group('RemoteHolidayConfig', () {
    test('parses custom holiday rules and disabled holiday maps', () {
      final json = <String, dynamic>{
        'customHolidayRules': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'new_year',
            'name': 'New Year Day',
            'type': 'public',
            'rule': <String, dynamic>{
              'kind': 'westernDate',
              'month': 1,
              'day': 1,
            },
          },
        ],
        'disabledHolidays': <String>['halloween'],
        'disabledHolidaysByYear': <String, dynamic>{
          '2026': <String>['halloween'],
        },
        'disabledHolidaysByDate': <String, dynamic>{
          '2026-10-31': <String>['halloween'],
        },
      };

      final config = RemoteHolidayConfig.fromJson(json);

      expect(config.customHolidayRules, hasLength(1));
      expect(config.disabledHolidays, <HolidayId>[HolidayId.halloween]);
      expect(config.disabledHolidaysByYear[2026], <HolidayId>[
        HolidayId.halloween,
      ]);
      expect(config.disabledHolidaysByDate['2026-10-31'], <HolidayId>[
        HolidayId.halloween,
      ]);
    });
  });

  group('RemoteCustomHolidayRule', () {
    test('builds western-date custom holiday', () {
      final remote = RemoteCustomHolidayRule.fromJson(<String, dynamic>{
        'id': 'new_year',
        'name': 'New Year Day',
        'type': 'public',
        'rule': <String, dynamic>{'kind': 'westernDate', 'month': 1, 'day': 1},
      });

      final holiday = remote.toCustomHolidayRule();
      expect(holiday, isNotNull);

      final contextTrue = CustomHolidayContext(
        myanmarDate: _myanmarDate(month: 10, day: 1),
        westernDate: _westernDate(month: 1, day: 1),
      );
      final contextFalse = CustomHolidayContext(
        myanmarDate: _myanmarDate(month: 10, day: 1),
        westernDate: _westernDate(month: 1, day: 2),
      );

      expect(holiday!.matches(contextTrue), isTrue);
      expect(holiday.matches(contextFalse), isFalse);
    });

    test('builds myanmar-date custom holiday', () {
      final remote = RemoteCustomHolidayRule.fromJson(<String, dynamic>{
        'id': 'waso_full_moon',
        'name': 'Waso Full Moon',
        'type': 'religious',
        'rule': <String, dynamic>{'kind': 'myanmarDate', 'month': 4, 'day': 15},
      });

      final holiday = remote.toCustomHolidayRule();
      expect(holiday, isNotNull);

      final contextTrue = CustomHolidayContext(
        myanmarDate: _myanmarDate(month: 4, day: 15),
        westernDate: _westernDate(month: 7, day: 19),
      );
      final contextFalse = CustomHolidayContext(
        myanmarDate: _myanmarDate(month: 4, day: 14),
        westernDate: _westernDate(month: 7, day: 18),
      );

      expect(holiday!.matches(contextTrue), isTrue);
      expect(holiday.matches(contextFalse), isFalse);
    });

    test('builds matcher-based custom holiday with localization', () {
      final remote = RemoteCustomHolidayRule.fromJson(<String, dynamic>{
        'id': 'full_moon_friday',
        'name': 'Full Moon Friday',
        'type': 'other',
        'localizedNames': <String, String>{'my': 'လပြည့် သောကြာနေ့'},
        'cacheKey': 'matcher:full_moon_friday',
        'cacheVersion': 2,
        'rule': <String, dynamic>{
          'kind': 'matcher',
          'myanmar': <String, dynamic>{'moonPhase': 1},
          'western': <String, dynamic>{'weekday': 6},
        },
      });

      final holiday = remote.toCustomHolidayRule();
      expect(holiday, isNotNull);
      expect(holiday!.nameFor(Language.myanmar), 'လပြည့် သောကြာနေ့');
      expect(holiday.cacheFingerprint, contains('matcher:full_moon_friday:v2'));

      final contextTrue = CustomHolidayContext(
        myanmarDate: _myanmarDate(month: 8, day: 15, moonPhase: 1),
        westernDate: _westernDate(month: 11, day: 6, weekday: 6),
      );
      final contextFalse = CustomHolidayContext(
        myanmarDate: _myanmarDate(month: 8, day: 14, moonPhase: 0),
        westernDate: _westernDate(month: 11, day: 5, weekday: 5),
      );

      expect(holiday.matches(contextTrue), isTrue);
      expect(holiday.matches(contextFalse), isFalse);
    });
  });
}

MyanmarDate _myanmarDate({
  required int month,
  required int day,
  int moonPhase = 0,
}) {
  return MyanmarDate(
    year: 1388,
    month: month,
    day: day,
    yearType: 0,
    moonPhase: moonPhase,
    fortnightDay: day > 15 ? day - 15 : day,
    weekday: 0,
    julianDayNumber: 0,
    sasanaYear: 2570,
    monthLength: 30,
    monthType: 0,
  );
}

WesternDate _westernDate({
  required int month,
  required int day,
  int weekday = 0,
}) {
  return WesternDate(
    year: 2026,
    month: month,
    day: day,
    weekday: weekday,
    julianDayNumber: 0,
  );
}
