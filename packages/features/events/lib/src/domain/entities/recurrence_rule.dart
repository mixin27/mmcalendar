import 'package:equatable/equatable.dart';

/// Recurrence rule for recurring events
class RecurrenceRule extends Equatable {
  final RecurrenceType type;
  final int interval; // Every X days/weeks/months/years
  final List<int>? daysOfWeek; // For weekly: [1,3,5] = Mon, Wed, Fri
  final int? dayOfMonth; // For monthly: 15 = 15th of each month
  final int? monthOfYear; // For yearly: 6 = June
  final DateTime? endDate; // When recurrence ends
  final int? occurrenceCount; // Or number of occurrences
  final List<DateTime>? exceptions; // Dates to skip

  const RecurrenceRule({
    required this.type,
    this.interval = 1,
    this.daysOfWeek,
    this.dayOfMonth,
    this.monthOfYear,
    this.endDate,
    this.occurrenceCount,
    this.exceptions,
  });

  /// Check if recurrence is still active
  bool isActive(DateTime currentDate) {
    if (endDate != null && currentDate.isAfter(endDate!)) {
      return false;
    }
    return true;
  }

  /// Check if date is an exception
  bool isException(DateTime date) {
    if (exceptions == null) return false;
    return exceptions!.any(
      (exception) =>
          exception.year == date.year &&
          exception.month == date.month &&
          exception.day == date.day,
    );
  }

  /// Generate occurrence dates within a date range
  List<DateTime> generateOccurrences(
    DateTime originalEventDate,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final occurrences = <DateTime>[];

    // Start from the original event date
    var currentDate = originalEventDate;
    int count = 0;

    // Generate occurrences until we exceed the range
    while (currentDate.isBefore(rangeEnd) ||
        _isSameDay(currentDate, rangeEnd)) {
      // Check occurrence count limit
      if (occurrenceCount != null && count >= occurrenceCount!) {
        break;
      }

      // Check end date
      if (endDate != null && currentDate.isAfter(endDate!)) {
        break;
      }

      // If this occurrence is within or after our range, add it
      if ((currentDate.isAfter(rangeStart) ||
              _isSameDay(currentDate, rangeStart)) &&
          (currentDate.isBefore(rangeEnd) ||
              _isSameDay(currentDate, rangeEnd))) {
        if (!isException(currentDate)) {
          occurrences.add(currentDate);
          count++;
        }
      }

      // Move to next occurrence
      currentDate = _getNextOccurrence(currentDate);

      // Safety check to prevent infinite loops
      if (count > 10000) break;
    }

    return occurrences;
  }

  /// Get next occurrence date based on recurrence type and interval
  DateTime _getNextOccurrence(DateTime currentDate) {
    switch (type) {
      case RecurrenceType.daily:
        return currentDate.add(Duration(days: interval));

      case RecurrenceType.weekly:
        // If specific days of week are set
        if (daysOfWeek != null && daysOfWeek!.isNotEmpty) {
          return _getNextWeekdayOccurrence(currentDate);
        }
        // Otherwise, just add weeks
        return currentDate.add(Duration(days: 7 * interval));

      case RecurrenceType.monthly:
        return _getNextMonthOccurrence(currentDate);

      case RecurrenceType.yearly:
        return _getNextYearOccurrence(currentDate);

      case RecurrenceType.none:
        return currentDate;
    }
  }

  /// Get next occurrence for weekly recurrence with specific days
  DateTime _getNextWeekdayOccurrence(DateTime currentDate) {
    var nextDate = currentDate.add(const Duration(days: 1));

    // Find next day that matches one of the specified weekdays
    for (int i = 0; i < 14; i++) {
      // Check up to 2 weeks ahead
      if (daysOfWeek!.contains(nextDate.weekday)) {
        return nextDate;
      }
      nextDate = nextDate.add(const Duration(days: 1));
    }

    // Fallback: add one week
    return currentDate.add(Duration(days: 7 * interval));
  }

  /// Get next occurrence for monthly recurrence
  DateTime _getNextMonthOccurrence(DateTime currentDate) {
    // Move to next month(s)
    var targetMonth = currentDate.month + interval;
    var targetYear = currentDate.year;

    // Handle year overflow
    while (targetMonth > 12) {
      targetMonth -= 12;
      targetYear++;
    }

    // Use specific day of month if set, otherwise use current day
    var targetDay = dayOfMonth ?? currentDate.day;

    // Handle invalid days (e.g., Feb 31 -> Feb 28/29)
    final daysInTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;
    if (targetDay > daysInTargetMonth) {
      targetDay = daysInTargetMonth;
    }

    return DateTime(
      targetYear,
      targetMonth,
      targetDay,
      currentDate.hour,
      currentDate.minute,
      currentDate.second,
    );
  }

  /// Get next occurrence for yearly recurrence
  DateTime _getNextYearOccurrence(DateTime currentDate) {
    // Move to next year(s)
    var targetYear = currentDate.year + interval;

    // Use specific month/day if set
    var targetMonth = monthOfYear ?? currentDate.month;
    var targetDay = dayOfMonth ?? currentDate.day;

    // Handle leap year edge case (Feb 29)
    if (targetMonth == 2 && targetDay == 29) {
      // Check if target year is leap year
      final isLeapYear =
          (targetYear % 4 == 0 && targetYear % 100 != 0) ||
          (targetYear % 400 == 0);
      if (!isLeapYear) {
        targetDay = 28; // Use Feb 28 in non-leap years
      }
    }

    // Validate day is valid for the target month
    final daysInTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;
    if (targetDay > daysInTargetMonth) {
      targetDay = daysInTargetMonth;
    }

    return DateTime(
      targetYear,
      targetMonth,
      targetDay,
      currentDate.hour,
      currentDate.minute,
      currentDate.second,
    );
  }

  /// Check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  RecurrenceRule copyWith({
    RecurrenceType? type,
    int? interval,
    List<int>? daysOfWeek,
    int? dayOfMonth,
    int? monthOfYear,
    DateTime? endDate,
    int? occurrenceCount,
    List<DateTime>? exceptions,
  }) {
    return RecurrenceRule(
      type: type ?? this.type,
      interval: interval ?? this.interval,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      monthOfYear: monthOfYear ?? this.monthOfYear,
      endDate: endDate ?? this.endDate,
      occurrenceCount: occurrenceCount ?? this.occurrenceCount,
      exceptions: exceptions ?? this.exceptions,
    );
  }

  @override
  List<Object?> get props => [
    type,
    interval,
    daysOfWeek,
    dayOfMonth,
    monthOfYear,
    endDate,
    occurrenceCount,
    exceptions,
  ];
}

/// Recurrence type enum
enum RecurrenceType {
  none,
  daily,
  weekly,
  monthly,
  yearly;

  String get displayName {
    switch (this) {
      case RecurrenceType.none:
        return 'Does not repeat';
      case RecurrenceType.daily:
        return 'Daily';
      case RecurrenceType.weekly:
        return 'Weekly';
      case RecurrenceType.monthly:
        return 'Monthly';
      case RecurrenceType.yearly:
        return 'Yearly';
    }
  }
}
