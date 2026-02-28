import 'package:events/src/domain/entities/recurrence_rule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecurrenceRule.generateOccurrences', () {
    test('respects weekly interval with selected weekdays', () {
      final rule = RecurrenceRule(
        type: RecurrenceType.weekly,
        interval: 2,
        daysOfWeek: const [DateTime.monday],
      );

      final result = rule.generateOccurrences(
        DateTime(2026, 1, 5), // Monday
        DateTime(2026, 1, 1),
        DateTime(2026, 2, 15),
      );

      expect(
        result,
        equals([
          DateTime(2026, 1, 5),
          DateTime(2026, 1, 19),
          DateTime(2026, 2, 2),
        ]),
      );
    });

    test('applies occurrenceCount from the start of the series', () {
      final rule = RecurrenceRule(
        type: RecurrenceType.daily,
        interval: 1,
        occurrenceCount: 3,
      );

      final result = rule.generateOccurrences(
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 3),
        DateTime(2026, 1, 10),
      );

      expect(result, equals([DateTime(2026, 1, 3)]));
    });

    test('skips explicit exception dates', () {
      final rule = RecurrenceRule(
        type: RecurrenceType.daily,
        interval: 1,
        exceptions: [DateTime(2026, 1, 2)],
      );

      final result = rule.generateOccurrences(
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 3),
      );

      expect(result, equals([DateTime(2026, 1, 1), DateTime(2026, 1, 3)]));
    });
  });
}
