import '../app_event.dart';

/// Fired when a date is selected
class DateSelectedEvent extends AppEvent {
  final DateTime date;

  DateSelectedEvent(this.date);
}

/// Fired when the current month is changed
class MonthChangedEvent extends AppEvent {
  final DateTime month;

  MonthChangedEvent(this.month);
}

/// Fired when calendar needs to be refreshed
class CalendarRefreshEvent extends AppEvent {
  CalendarRefreshEvent();
}
