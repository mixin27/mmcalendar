import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  final day = DateTime(2026, 10, 22); // A Thursday.

  test('Gregorian dates in English', () {
    const format = CalendarFormat(Language.english);
    expect(format.monthYear(day), 'October 2026');
    expect(format.shortMonthYear(day), 'Oct 2026');
    expect(format.shortDate(day), 'Thu 22 Oct');
    expect(format.fullDate(day), 'Thursday 22 October 2026');
    expect(format.weekdayOf(DateTime.sunday, short: true), 'Sun');
    expect(format.weekdayOf(DateTime.saturday, short: true), 'Sat');
  });

  test('Gregorian dates in Myanmar use Myanmar names and digits', () {
    const format = CalendarFormat(Language.myanmar);
    expect(format.monthYear(day), 'အောက်တိုဘာ ၂၀၂၆');
    expect(format.shortDate(day), 'ကြာ ၂၂ အောက်');
    expect(format.number(17), '၁၇');
  });

  test('every calendar language has its own month and weekday names', () {
    final names = {
      for (final language in Language.values)
        language: CalendarFormat(language).monthYear(day),
    };
    expect(names.values.toSet(), hasLength(Language.values.length));
  });

  group('Prefer Shan Year', () {
    // Shan New Year falls around Nadaw, so October and December 2026 sit
    // in different Shan years but the same Myanmar year (1388).
    final october = MyanmarCalendar.fromDateTime(day).myanmarDate;
    final december = MyanmarCalendar.fromDateTime(
      DateTime(2026, 12, 31),
    ).myanmarDate;

    test('a Shan calendar shows the Shan year when preferred', () {
      expect(
        formatMyanmarDate(
          october,
          pattern: '&y &M',
          language: Language.shan,
          preferShanYear: true,
        ),
        startsWith('2120 '),
      );
      expect(
        formatMyanmarDate(
          december,
          pattern: '&y',
          language: Language.shan,
          preferShanYear: true,
        ),
        '2121',
      );
      expect(
        const CalendarFormat(
          Language.shan,
        ).myanmar(october, '&y', preferShanYear: true),
        '2120',
      );
    });

    test('otherwise the Myanmar year', () {
      expect(
        formatMyanmarDate(
          october,
          pattern: '&y &M',
          language: Language.shan,
          preferShanYear: false,
        ),
        startsWith('1388 '),
      );
      expect(
        formatMyanmarDate(
          december,
          pattern: '&y',
          language: Language.myanmar,
          preferShanYear: true,
        ),
        '၁၃၈၈',
        reason: 'only a Shan calendar uses the Shan year',
      );
      expect(
        const CalendarFormat(Language.shan).myanmar(october, '&y'),
        '1388',
      );
    });
  });

  testWidgets('the scope hands the calendar language down', (tester) async {
    late Language seen;
    await tester.pumpWidget(
      CalendarLanguageScope(
        language: Language.shan,
        child: Builder(
          builder: (context) {
            seen = context.calendarLanguage;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(seen, Language.shan);
  });
}
