import 'package:equatable/equatable.dart';

sealed class CalendarEvent extends Equatable {
  const CalendarEvent();

  @override
  List<Object?> get props => [];
}

/// Load calendar for a specific month
final class LoadCalendarMonth extends CalendarEvent {
  final DateTime month;

  const LoadCalendarMonth(this.month);

  @override
  List<Object?> get props => [month];
}

/// Navigate to next month
final class NavigateToNextMonth extends CalendarEvent {
  const NavigateToNextMonth();
}

/// Navigate to previous month
final class NavigateToPreviousMonth extends CalendarEvent {
  const NavigateToPreviousMonth();
}

/// Navigate to today
final class NavigateToToday extends CalendarEvent {
  const NavigateToToday();
}

/// Select a date
final class SelectDateEvent extends CalendarEvent {
  final DateTime date;

  const SelectDateEvent(this.date);

  @override
  List<Object?> get props => [date];
}

/// Refresh calendar (after settings change)
final class RefreshCalendar extends CalendarEvent {
  const RefreshCalendar();
}
