import 'package:converter/converter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 11, 5);
  BirthDetails of(DateTime d, {bool afternoon = false}) =>
      BirthDetails.of(d, today: today, afternoon: afternoon);

  group('age', () {
    test('whole years, months and days', () {
      expect(of(DateTime(1999, 11, 8)).age, const Age(26, 11, 28));
      expect(of(DateTime(2000, 1, 1)).age, const Age(26, 10, 4));
      expect(of(DateTime(2026, 11, 5)).age, const Age(0, 0, 0));
    });

    test('borrowing days uses the length of the month before', () {
      expect(
        Age.between(DateTime(2000, 1, 31), DateTime(2000, 3, 1)),
        const Age(0, 1, 1),
      );
    });
  });

  group('signs', () {
    test('one per weekday, Wednesday split at noon', () {
      expect(of(DateTime(1990, 3, 11)).sign, BirthSign.sunday);
      expect(of(DateTime(2023, 12, 12)).sign, BirthSign.tuesday);
      expect(of(DateTime(2026, 11, 4)).sign, BirthSign.wednesday);
      expect(of(DateTime(2026, 11, 4), afternoon: true).sign, BirthSign.rahu);
      // Afternoon only matters on Wednesday.
      expect(
        of(DateTime(2000, 1, 1), afternoon: true).sign,
        BirthSign.saturday,
      );
    });
  });

  group('next Western birthday', () {
    test('this year when still ahead, today included', () {
      expect(of(DateTime(1999, 11, 8)).nextBirthday, DateTime(2026, 11, 8));
      expect(of(DateTime(1990, 11, 5)).nextBirthday, today);
      expect(of(DateTime(2000, 1, 1)).nextBirthday, DateTime(2027, 1, 1));
    });

    test('29 February is 28 February in other years', () {
      expect(of(DateTime(1988, 2, 29)).nextBirthday, DateTime(2027, 2, 28));
    });
  });

  group('next Myanmar birthday', () {
    test('the same Myanmar month and day', () {
      // 1351 Tabaung waning 1 → 1388 Tabaung waning 1.
      expect(
        of(DateTime(1990, 3, 11)).nextMyanmarBirthday,
        DateTime(2027, 3, 23),
      );
      // 1361 Tazaungmon waxing 1 → 1388 Tazaungmon waxing 1.
      expect(
        of(DateTime(1999, 11, 8)).nextMyanmarBirthday,
        DateTime(2026, 11, 10),
      );
    });

    test('a new-moon birthday is the new moon', () {
      // 1385 Tazaungmon new moon → 1388 Tazaungmon new moon.
      expect(
        of(DateTime(2023, 12, 12)).nextMyanmarBirthday,
        DateTime(2026, 12, 9),
      );
    });

    test('First Waso is Waso, Late Tagu is Tagu', () {
      // 1363 First Waso new moon → 1389 Waso new moon.
      expect(
        of(DateTime(2001, 7, 20)).nextMyanmarBirthday,
        DateTime(2027, 8, 2),
      );
      // 1356 Late Tagu waxing 11 → 1389 Tagu waxing 11.
      expect(
        of(DateTime(1995, 4, 10)).nextMyanmarBirthday,
        DateTime(2027, 4, 17),
      );
    });
  });
}
