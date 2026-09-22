import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Myanmar data provider returns canonical data for every Gregorian day',
    () async {
      const provider = MyanmarCalendarStudioDataProvider();
      final days = await provider.daysFor(
        const CalendarStudioSource(year: 2027),
        month: 1,
      );

      expect(days, hasLength(31));
      expect(days.first.myanmarLabel, isNotEmpty);
    },
  );
}
