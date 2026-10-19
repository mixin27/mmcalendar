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
      expect(days.first.moonPhase, inInclusiveRange(0, 3));
      expect(days.first.fortnightDay, inInclusiveRange(1, 15));
      expect(days.where((day) => day.moonLabel == '0'), isEmpty);
      expect(days.where((day) => day.astrologyLabel == '0'), isEmpty);
    },
  );
}
