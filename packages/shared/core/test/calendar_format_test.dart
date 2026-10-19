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
