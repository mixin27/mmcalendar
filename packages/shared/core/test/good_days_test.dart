import 'package:flutter_test/flutter_test.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  CompleteDate day(int y, int m, int d) =>
      MyanmarCalendar.getCompleteDateFor(y, m, d);

  test('tones', () {
    expect(GoodDays.tone('Yatyaza'), AstroTone.good);
    expect(GoodDays.tone('Amyeittasote'), AstroTone.good);
    expect(GoodDays.tone('Thamaphyu'), AstroTone.good);
    expect(GoodDays.tone('Pyathada'), AstroTone.caution);
    expect(GoodDays.tone('Afternoon Pyathada'), AstroTone.caution);
    expect(GoodDays.tone('Thamanyo'), AstroTone.caution);
    expect(GoodDays.tone('Nagapor'), AstroTone.caution);
    expect(GoodDays.tone('Sabbath'), AstroTone.sabbath);
    expect(GoodDays.tone('Sabbath Eve'), AstroTone.sabbath);
  });

  test('a good mark with nothing calling for care is a good day', () {
    // 30 Nov 2026: Thamaphyu only.
    expect(GoodDays.marks(day(2026, 11, 30)), ['Thamaphyu']);
    expect(GoodDays.isGood(day(2026, 11, 30)), isTrue);
    // 5 Nov 2026: Yatyaza, but also Thamanyo.
    expect(GoodDays.marks(day(2026, 11, 5)), ['Yatyaza', 'Thamanyo']);
    expect(GoodDays.isGood(day(2026, 11, 5)), isFalse);
    // 2 Dec 2026: Sabbath and Yatyaza, but Afternoon Pyathada.
    expect(GoodDays.isGood(day(2026, 12, 2)), isFalse);
  });

  test('between lists every good day and can keep chosen weekdays', () {
    final from = DateTime(2026, 11, 5);
    final to = DateTime(2027, 2, 4);
    final all = GoodDays.between(from, to);
    expect(all, hasLength(13));
    for (final d in all) {
      expect(GoodDays.isGood(d), isTrue);
    }
    final mondays = GoodDays.between(from, to, weekdays: {DateTime.monday});
    expect(mondays, isNotEmpty);
    expect(
      mondays.every(
        (d) =>
            DateTime(d.westernYear, d.westernMonth, d.westernDay).weekday ==
            DateTime.monday,
      ),
      isTrue,
    );
    expect(mondays.length, lessThan(all.length));
  });
}
