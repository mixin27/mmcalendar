import 'package:calendar/calendar.dart';
import 'package:calendar/src/presentation/widgets/calendar_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_core/shared_core.dart' show translateNumbers;
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

void main() {
  group('calendar labels', () {
    test('follow the calendar language', () {
      expect(
        CalendarLabels.of('Sasana Year', Language.myanmar, 'x'),
        'သာသနာနှစ်',
      );
      expect(
        CalendarLabels.of('Buddhist Era', Language.myanmar, 'x'),
        'ဗုဒ္ဓသက္ကရာဇ်',
      );
      expect(CalendarLabels.day(Language.myanmar, 'x'), 'ရက်');
      expect(CalendarLabels.of('Month', Language.english, 'x'), 'Month');
    });

    test('fall back to the app label where there is no word', () {
      expect(CalendarLabels.of('Buddhist Era', Language.mon, 'BE'), 'BE');
      expect(CalendarLabels.of('Sasana Year', Language.mon, 'x'), isNot('x'));
    });
  });

  group('Prefer Shan year', () {
    // October 2026: Myanmar year 1388, Shan year 2120.
    final dates = [
      for (var d = 1; d <= 31; d++)
        MyanmarCalendar.getCompleteDate(DateTime(2026, 10, d)),
    ];

    Future<void> pump(WidgetTester tester, {required bool preferShan}) =>
        tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.build(
              style: AppStyle.clear,
              colorScheme: AppColorSchemes.modernLight,
            ),
            home: Scaffold(
              body: CalendarHeader(
                currentMonth: DateTime(2026, 10),
                monthDates: dates,
                language: Language.shan,
                showShanCalendar: preferShan,
                onPreviousMonth: () {},
                onNextMonth: () {},
                onMonthYearTap: () {},
              ),
            ),
          ),
        );

    String digits(int n) => translateNumbers('$n', language: Language.shan);

    testWidgets('on: the header shows the Shan year', (tester) async {
      await pump(tester, preferShan: true);
      expect(find.textContaining(digits(2120)), findsWidgets);
      expect(find.textContaining(digits(1388)), findsNothing);
    });

    testWidgets('off: the header shows the Myanmar year', (tester) async {
      await pump(tester, preferShan: false);
      expect(find.textContaining(digits(1388)), findsWidgets);
      expect(find.textContaining(digits(2120)), findsNothing);
    });
  });
}
