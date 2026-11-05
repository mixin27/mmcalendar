import 'package:flutter_test/flutter_test.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  MyanmarDate my(DateTime d) => MyanmarRecurrence.myanmarOf(d);

  test('monthly: every full moon from the Thadingyut full moon', () {
    expect(
      MyanmarRecurrence.occurrences(
        DateTime(2026, 10, 26),
        MyanmarRepeat.monthly,
        from: DateTime(2026, 10, 1),
        to: DateTime(2027, 3, 31),
      ),
      [
        DateTime(2026, 10, 26),
        DateTime(2026, 11, 24),
        DateTime(2026, 12, 24),
        DateTime(2027, 1, 22),
        DateTime(2027, 2, 21),
        DateTime(2027, 3, 22),
      ],
    );
  });

  test('yearly: once a year, same Myanmar month and day', () {
    final days = MyanmarRecurrence.occurrences(
      DateTime(1990, 3, 11), // 1351 Tabaung waning 1
      MyanmarRepeat.yearly,
      from: DateTime(2026),
      to: DateTime(2028, 12, 31),
    );
    expect(days, hasLength(3));
    expect(days, contains(DateTime(2027, 3, 23)));
    for (final d in days) {
      expect(my(d).month, 12);
      expect(my(d).day, 16);
    }
  });

  test('Tagu and Late Tagu are one month, a year apart', () {
    final days = MyanmarRecurrence.occurrences(
      DateTime(2020, 4, 9), // 1381 Late Tagu waning 2
      MyanmarRepeat.yearly,
      from: DateTime(2020),
      to: DateTime(2028, 12, 31),
    );
    expect(days, hasLength(9));
    for (var i = 1; i < days.length; i++) {
      final gap = days[i].difference(days[i - 1]).inDays;
      expect(gap, inInclusiveRange(350, 390));
    }
  });

  test('a new-moon start repeats on each new moon', () {
    final days = MyanmarRecurrence.occurrences(
      DateTime(2026, 11, 9), // Thadingyut new moon
      MyanmarRepeat.monthly,
      from: DateTime(2026, 11, 1),
      to: DateTime(2027, 2, 28),
    );
    expect(days, hasLength(4));
    for (final d in days) {
      expect(my(d).moonPhase, 3);
    }
  });

  test('interval, count, end date and skipped days', () {
    final anchor = DateTime(2026, 10, 26);
    List<DateTime> monthly({
      int interval = 1,
      int? count,
      DateTime? until,
      bool Function(DateTime)? skip,
    }) => MyanmarRecurrence.occurrences(
      anchor,
      MyanmarRepeat.monthly,
      from: anchor,
      to: DateTime(2027, 12, 31),
      interval: interval,
      count: count,
      until: until,
      skip: skip,
    );
    expect(monthly(interval: 2).take(3), [
      DateTime(2026, 10, 26),
      DateTime(2026, 12, 24),
      DateTime(2027, 2, 21),
    ]);
    expect(monthly(count: 2), [DateTime(2026, 10, 26), DateTime(2026, 11, 24)]);
    expect(monthly(until: DateTime(2026, 12, 1)), hasLength(2));
    // A skipped day doesn't count towards the total.
    expect(monthly(count: 2, skip: (d) => d == DateTime(2026, 11, 24)), [
      DateTime(2026, 10, 26),
      DateTime(2026, 12, 24),
    ]);
  });

  test('a range in the middle of a long series', () {
    expect(
      MyanmarRecurrence.occurrences(
        DateTime(1990, 3, 11),
        MyanmarRepeat.yearly,
        from: DateTime(2027, 3, 1),
        to: DateTime(2027, 3, 31),
      ),
      [DateTime(2027, 3, 23)],
    );
  });
}
