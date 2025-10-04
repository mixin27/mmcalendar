import 'package:equatable/equatable.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';

import '../../domain/entities/calendar_month.dart';
import '../../domain/entities/date_selection.dart';

sealed class CalendarState extends Equatable {
  const CalendarState();

  @override
  List<Object?> get props => [];
}

/// Initial state
final class CalendarInitial extends CalendarState {
  const CalendarInitial();
}

/// Loading state
final class CalendarLoading extends CalendarState {
  const CalendarLoading();
}

/// Loaded state with calendar data
final class CalendarLoaded extends CalendarState {
  final CalendarMonth calendarMonth;
  final DateSelection? selectedDate;
  final bool isAstrologyExpanded;
  final DateTime today;

  const CalendarLoaded({
    required this.calendarMonth,
    this.selectedDate,
    required this.isAstrologyExpanded,
    required this.today,
  });

  /// Get today's complete date
  CompleteDate? get todayCompleteDate {
    try {
      return calendarMonth.dates.firstWhere(
        (date) =>
            date.western.toDateTime().day == today.day &&
            date.western.toDateTime().month == today.month &&
            date.western.toDateTime().year == today.year,
      );
    } catch (e) {
      return null;
    }
  }

  /// Copy with new values
  CalendarLoaded copyWith({
    CalendarMonth? calendarMonth,
    DateSelection? selectedDate,
    bool? isAstrologyExpanded,
    DateTime? today,
    bool clearSelection = false,
  }) {
    return CalendarLoaded(
      calendarMonth: calendarMonth ?? this.calendarMonth,
      selectedDate: clearSelection ? null : (selectedDate ?? this.selectedDate),
      isAstrologyExpanded: isAstrologyExpanded ?? this.isAstrologyExpanded,
      today: today ?? this.today,
    );
  }

  @override
  List<Object?> get props => [
    calendarMonth,
    selectedDate,
    isAstrologyExpanded,
    today,
  ];
}

/// Error state
final class CalendarError extends CalendarState {
  final String message;

  const CalendarError(this.message);

  @override
  List<Object?> get props => [message];
}
