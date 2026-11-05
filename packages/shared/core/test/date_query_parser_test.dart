import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  final today = DateTime(2026, 11, 5);
  DateQueryMatch? parse(String q) => DateQueryParser.parse(q, today: today);

  void expectDay(String query, DateTime day, DateQueryKind kind) =>
      expect(parse(query), DateQueryMatch(day, kind), reason: query);

  group('Western dates', () {
    final april13 = DateTime(2027, 4, 13);
    for (final q in [
      '2027-04-13',
      '2027/4/13',
      '13/4/2027',
      '13-04-2027',
      '13 Apr 2027',
      'April 13, 2027',
      'apr 13 2027',
      '၁၃ ဧပြီ ၂၀၂၇',
      '၁၃/၄/၂၀၂၇',
    ]) {
      test(q, () => expectDay(q, april13, DateQueryKind.western));
    }

    test('without a year: the next one, today included', () {
      expectDay('April 13', april13, DateQueryKind.western);
      expectDay('ဧပြီ ၁၃', april13, DateQueryKind.western);
      expectDay('13.4', april13, DateQueryKind.western);
      expectDay('5 Nov', today, DateQueryKind.western);
      expectDay('29 Feb', DateTime(2028, 2, 29), DateQueryKind.western);
    });

    test('impossible days are nothing', () {
      expect(parse('30/2/2027'), isNull);
      expect(parse('31 April 2027'), isNull);
      expect(parse('13/13/2027'), isNull);
    });
  });

  group('Myanmar dates', () {
    test('with a Myanmar year', () {
      expectDay(
        'Tabaung full moon 1387',
        DateTime(2026, 3, 2),
        DateQueryKind.myanmar,
      );
      expectDay(
        'Thadingyut full moon 1388',
        DateTime(2026, 10, 26),
        DateQueryKind.myanmar,
      );
      expectDay(
        'တပေါင်းလပြည့် ၁၃၈၈',
        DateTime(2027, 3, 22),
        DateQueryKind.myanmar,
      );
    });

    test('with a Western year', () {
      expectDay(
        'Thadingyut fullmoon 2026',
        DateTime(2026, 10, 26),
        DateQueryKind.myanmar,
      );
    });

    test('without a year: the next one', () {
      expectDay(
        'tabaung full moon',
        DateTime(2027, 3, 22),
        DateQueryKind.myanmar,
      );
      expectDay(
        'သီတင်းကျွတ်လပြည့်',
        DateTime(2027, 10, 15),
        DateQueryKind.myanmar,
      );
      expectDay(
        'Tazaungmon new moon',
        DateTime(2026, 12, 9),
        DateQueryKind.myanmar,
      );
    });

    test('Tagu before the new year is the old year Late Tagu', () {
      expectDay('Tagu waxing 5', DateTime(2027, 4, 11), DateQueryKind.myanmar);
      expectDay('တန်ခူးလဆန်း ၅', DateTime(2027, 4, 11), DateQueryKind.myanmar);
      expectDay(
        'Tagu waning 3 1388',
        DateTime(2026, 4, 4),
        DateQueryKind.myanmar,
      );
    });

    test('the waning day counts from the full moon', () {
      final full = parse('Thadingyut full moon 1388')!.date;
      expect(
        parse('Thadingyut waning 1 1388')!.date,
        full.add(const Duration(days: 1)),
      );
    });

    test('a month name alone is not a date', () {
      expect(parse('Tabaung'), isNull);
      expect(parse('တပေါင်း'), isNull);
    });
  });

  group('words', () {
    test('today, tomorrow, yesterday', () {
      expectDay('today', today, DateQueryKind.relative);
      expectDay('ယနေ့', today, DateQueryKind.relative);
      expectDay('Tomorrow', DateTime(2026, 11, 6), DateQueryKind.relative);
      expectDay('yesterday', DateTime(2026, 11, 4), DateQueryKind.relative);
    });

    test('the next Sabbath, full moon and new moon', () {
      expectDay('next Sabbath', DateTime(2026, 11, 9), DateQueryKind.relative);
      expectDay('ဥပုသ်', DateTime(2026, 11, 9), DateQueryKind.relative);
      expectDay(
        'next full moon',
        DateTime(2026, 11, 24),
        DateQueryKind.relative,
      );
      expectDay('လကွယ်', DateTime(2026, 11, 9), DateQueryKind.relative);
    });
  });

  test('other searches are not dates', () {
    for (final q in ['', 'hello', 'Thingyan', '2027', '13', 'may']) {
      expect(parse(q), isNull, reason: q);
    }
  });
}
