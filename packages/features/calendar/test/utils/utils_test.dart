import 'package:calendar/src/utils/utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

void main() {
  group('getShortWesternMonthName', () {
    test('uses the 1-based month contract from myanmar_calendar_dart 2.x', () {
      expect(getShortWesternMonthName(1, Language.english), 'Jan');
      expect(getShortWesternMonthName(12, Language.english), 'Dec');
      expect(getShortWesternMonthName(1, Language.myanmar), 'ဇန်');
      expect(getShortWesternMonthName(12, Language.myanmar), 'ဒီ');
    });

    test('rejects values outside the calendar month range', () {
      expect(
        () => getShortWesternMonthName(0, Language.english),
        throwsRangeError,
      );
      expect(
        () => getShortWesternMonthName(13, Language.english),
        throwsRangeError,
      );
    });
  });
}
