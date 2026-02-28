import 'package:events/src/domain/entities/event.dart';
import 'package:events/src/domain/entities/event_category.dart';
import 'package:events/src/domain/entities/notification_setting.dart';
import 'package:events/src/domain/entities/recurrence_rule.dart';
import 'package:events/src/domain/services/event_validation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final category = EventCategory(
    id: 99,
    name: 'Test',
    iconName: 'event',
    colorCode: 0xFF000000,
    createdAt: DateTime(2026, 1, 1),
  );

  Event makeBaseEvent() {
    return Event(
      id: 1,
      title: '  Team Sync  ',
      eventDate: DateTime(2026, 3, 15),
      category: category,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 2),
    );
  }

  group('EventValidationService.validateEvent', () {
    test('rejects duplicate reminder configuration', () {
      final event = makeBaseEvent().copyWith(
        notifications: const [
          NotificationSetting(minutesBefore: 30),
          NotificationSetting(minutesBefore: 30),
        ],
      );

      final result = EventValidationService.validateEvent(
        event,
        isUpdate: true,
      );

      expect(result.isValid, isFalse);
      expect(result.message, contains('Duplicate reminder'));
    });

    test('rejects recurrence end date before event date', () {
      final event = makeBaseEvent().copyWith(
        recurrenceRule: RecurrenceRule(
          type: RecurrenceType.daily,
          endDate: DateTime(2026, 3, 14),
        ),
      );

      final result = EventValidationService.validateEvent(
        event,
        isUpdate: true,
      );

      expect(result.isValid, isFalse);
      expect(result.message, contains('end date'));
    });
  });

  group('EventValidationService.sanitizeForPersist', () {
    test('normalizes all-day time, tags and title', () {
      final event = makeBaseEvent().copyWith(
        isAllDay: true,
        eventTime: DateTime(2026, 3, 15, 10, 30),
        tags: const ['  Work  ', 'work', ''],
        notifications: const [
          NotificationSetting(minutesBefore: 30),
          NotificationSetting(minutesBefore: 15),
          NotificationSetting(minutesBefore: 30),
        ],
      );

      final sanitized = EventValidationService.sanitizeForPersist(
        event,
        now: DateTime(2026, 2, 1),
        isUpdate: true,
      );

      expect(sanitized.title, 'Team Sync');
      expect(sanitized.eventTime, isNull);
      expect(sanitized.tags, equals(['Work', 'work']));
      expect(sanitized.notifications.length, 2);
      expect(sanitized.notifications.first.minutesBefore, 30);
    });
  });
}
