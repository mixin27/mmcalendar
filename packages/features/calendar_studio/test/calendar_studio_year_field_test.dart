import 'package:calendar_studio/src/presentation/calendar_studio_year_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the year field offers 1900 to 2100 and returns the pick', (
    tester,
  ) async {
    var year = 2040;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => CalendarStudioYearField(
              year: year,
              onChanged: (value) => setState(() => year = value),
            ),
          ),
        ),
      ),
    );
    // A year far outside the old ±5 range still shows.
    expect(find.text('2040'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('calendar-studio-year-field')));
    await tester.pumpAndSettle();
    // Opens scrolled to the current year.
    expect(
      find.byKey(const ValueKey('calendar-studio-year-2040')),
      findsOneWidget,
    );

    final grid = find.byType(Scrollable).last;
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('calendar-studio-year-2100')),
      400,
      scrollable: grid,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('calendar-studio-year-1900')),
      -400,
      scrollable: grid,
    );
    await tester.tap(find.byKey(const ValueKey('calendar-studio-year-1900')));
    await tester.pumpAndSettle();
    expect(year, 1900);
    expect(find.text('1900'), findsOneWidget);
  });
}
