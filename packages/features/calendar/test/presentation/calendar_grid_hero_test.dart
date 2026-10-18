import 'package:calendar/calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

void main() {
  testWidgets('many grids of one month can share a route while navigating', (
    tester,
  ) async {
    final month = DateTime(2026, 10);
    final dates = AppDateUtils.getCalendarGridDates(
      month,
      firstDayOfWeek: 1,
    ).map(MyanmarCalendar.getCompleteDate).toList();
    Widget grid() => SizedBox(
      height: 300,
      child: CalendarGrid(
        gridDates: dates,
        currentMonth: month,
        today: DateTime(2026, 10, 17),
        onDateTap: (_) {},
      ),
    );
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        theme: AppTheme.build(
          style: AppStyle.clear,
          colorScheme: AppColorSchemes.modernLight,
        ),
        // Like the Settings grid picker: previews of the same month.
        home: Scaffold(body: ListView(children: [grid(), grid(), grid()])),
      ),
    );
    navigator.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const Scaffold()),
    );
    await tester.pumpAndSettle();
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
