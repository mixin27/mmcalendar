import 'package:equatable/equatable.dart';

sealed class ViewsEvent extends Equatable {
  const ViewsEvent();

  @override
  List<Object?> get props => [];
}

final class LoadViews extends ViewsEvent {
  final DateTime date;

  const LoadViews(this.date);

  @override
  List<Object?> get props => [date];
}

final class LoadYearView extends ViewsEvent {
  final int year;

  const LoadYearView(this.year);

  @override
  List<Object?> get props => [year];
}

final class LoadWeekView extends ViewsEvent {
  final DateTime date;

  const LoadWeekView(this.date);

  @override
  List<Object?> get props => [date];
}

final class LoadDayView extends ViewsEvent {
  final DateTime date;

  const LoadDayView(this.date);

  @override
  List<Object?> get props => [date];
}

final class NavigateYearNext extends ViewsEvent {
  const NavigateYearNext();
}

final class NavigateYearPrevious extends ViewsEvent {
  const NavigateYearPrevious();
}

final class NavigateWeekNext extends ViewsEvent {
  const NavigateWeekNext();
}

final class NavigateWeekPrevious extends ViewsEvent {
  const NavigateWeekPrevious();
}

final class NavigateDayNext extends ViewsEvent {
  const NavigateDayNext();
}

final class NavigateDayPrevious extends ViewsEvent {
  const NavigateDayPrevious();
}
