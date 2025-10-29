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
  List<DateTime> generateOccurrences(DateTime start, DateTime end) {
    final occurrences = <DateTime>[];
    var currentDate = start;
    int count = 0;

    while (!currentDate.isAfter(end)) {
      // Check occurrence count limit
      if (occurrenceCount != null && count >= occurrenceCount!) {
        break;
      }

      // Check end date
      if (endDate != null && currentDate.isAfter(endDate!)) {
        break;
      }

      // Check if date matches recurrence pattern
      if (_matchesPattern(currentDate) && !isException(currentDate)) {
        occurrences.add(currentDate);
        count++;
      }

      // Move to next potential date
      currentDate = _getNextDate(currentDate);
    }

    return occurrences;
  }

  /// Check if date matches recurrence pattern
  bool _matchesPattern(DateTime date) {
    switch (type) {
      case RecurrenceType.daily:
        return true;
      case RecurrenceType.weekly:
        if (daysOfWeek == null) return true;
        return daysOfWeek!.contains(date.weekday);
      case RecurrenceType.monthly:
        if (dayOfMonth == null) return true;
        return date.day == dayOfMonth;
      case RecurrenceType.yearly:
        if (monthOfYear == null || dayOfMonth == null) return true;
        return date.month == monthOfYear && date.day == dayOfMonth;
      case RecurrenceType.none:
        return false;
    }
  }

  /// Get next potential date based on interval
  DateTime _getNextDate(DateTime currentDate) {
    switch (type) {
      case RecurrenceType.daily:
        return currentDate.add(Duration(days: interval));
      case RecurrenceType.weekly:
        return currentDate.add(Duration(days: 7 * interval));
      case RecurrenceType.monthly:
        return DateTime(
          currentDate.year,
          currentDate.month + interval,
          currentDate.day,
        );
      case RecurrenceType.yearly:
        return DateTime(
          currentDate.year + interval,
          currentDate.month,
          currentDate.day,
        );
      case RecurrenceType.none:
        return currentDate;
    }
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
