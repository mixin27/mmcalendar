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
    if (rangeEnd.isBefore(rangeStart)) return occurrences;

    final start = _dateOnly(rangeStart);
    final end = _dateOnly(rangeEnd);
    final anchor = _dateOnly(originalEventDate);

    if (type == RecurrenceType.none) {
      if (!_isDateBefore(anchor, start) &&
          !_isDateAfter(anchor, end) &&
          !isException(anchor)) {
        occurrences.add(anchor);
      }
      return occurrences;
    }

    // Generate from the series anchor so occurrenceCount and endDate are correct
    // even when rangeStart is in the middle of the series.
    var currentDate = anchor;
    int count = 0;
    int safety = 0;
    final maxIterations = 20000;

    while (!_isDateAfter(currentDate, end) && safety < maxIterations) {
      // Check occurrence count limit
      if (occurrenceCount != null && count >= occurrenceCount!) {
        break;
      }

      // Check end date
      if (endDate != null && _isDateAfter(currentDate, _dateOnly(endDate!))) {
        break;
      }

      final isExceptionDate = isException(currentDate);
      if (!isExceptionDate &&
          !_isDateBefore(currentDate, start) &&
          !_isDateAfter(currentDate, end)) {
        occurrences.add(currentDate);
      }

      // Count real series occurrences (excluding exceptions) from anchor date.
      if (!isExceptionDate) {
        count++;
      }

      final nextDate = _getNextOccurrence(currentDate, anchor);
      if (!nextDate.isAfter(currentDate)) {
        break;
      }
      currentDate = nextDate;
      safety++;

      // If series starts beyond the target range, we can stop.
      if (_isDateAfter(currentDate, end) && _isDateAfter(anchor, end)) {
        break;
      }
    }

    return occurrences;
  }

  /// Get next occurrence date based on recurrence type and interval
  DateTime _getNextOccurrence(DateTime currentDate, DateTime anchorDate) {
    switch (type) {
      case RecurrenceType.daily:
        return currentDate.add(Duration(days: interval));

      case RecurrenceType.weekly:
        // If specific days of week are set
        if (daysOfWeek != null && daysOfWeek!.isNotEmpty) {
          return _getNextWeekdayOccurrence(currentDate, anchorDate);
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
  DateTime _getNextWeekdayOccurrence(
    DateTime currentDate,
    DateTime anchorDate,
  ) {
    final validDays = daysOfWeek!
        .where((day) => day >= DateTime.monday && day <= DateTime.sunday)
        .toSet();
    if (validDays.isEmpty) {
      return currentDate.add(Duration(days: 7 * interval));
    }

    final anchorWeekStart = _startOfWeek(anchorDate);
    var nextDate = currentDate.add(const Duration(days: 1));

    // Find next matching weekday in the correct interval week bucket.
    for (int i = 0; i < 3650; i++) {
      final candidateWeekStart = _startOfWeek(nextDate);
      final weekOffset =
          candidateWeekStart.difference(anchorWeekStart).inDays ~/ 7;
      final isCorrectWeek = weekOffset >= 0 && weekOffset % interval == 0;

      if (isCorrectWeek && validDays.contains(nextDate.weekday)) {
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

  bool _isDateBefore(DateTime date1, DateTime date2) =>
      _dateOnly(date1).isBefore(_dateOnly(date2));

  bool _isDateAfter(DateTime date1, DateTime date2) =>
      _dateOnly(date1).isAfter(_dateOnly(date2));

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime _startOfWeek(DateTime date) {
    final dayOnly = _dateOnly(date);
    return dayOnly.subtract(Duration(days: dayOnly.weekday - DateTime.monday));
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

enum ExceptionType { modified, deleted, completed }

class RecurringEventException {
  final int id;
  final int masterEventId;
  final DateTime occurrenceDate;
  final ExceptionType exceptionType;
  final String? modifiedTitle;
  final String? modifiedDescription;
  final DateTime? modifiedDate;
  final DateTime? modifiedTime;
  final String? modifiedLocation;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;

  const RecurringEventException({
    required this.id,
    required this.masterEventId,
    required this.occurrenceDate,
    required this.exceptionType,
    this.modifiedTitle,
    this.modifiedDescription,
    this.modifiedDate,
    this.modifiedTime,
    this.modifiedLocation,
    this.isCompleted = false,
    this.completedAt,
    required this.createdAt,
  });
}
