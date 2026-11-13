part of 'day_details_bloc.dart';

sealed class DayDetailsEvent extends Equatable {
  const DayDetailsEvent();

  @override
  List<Object> get props => [];
}

/// Load today's details.
final class LoadToday extends DayDetailsEvent {
  const LoadToday();
}

/// Show the day before.
final class NavigateToPreviousDay extends DayDetailsEvent {
  const NavigateToPreviousDay();
}

/// Show the day after.
final class NavigateToNextDay extends DayDetailsEvent {
  const NavigateToNextDay();
}

/// Show [date].
final class LoadSpecificDate extends DayDetailsEvent {
  const LoadSpecificDate(this.date);

  final DateTime date;

  @override
  List<Object> get props => [date];
}

/// Show the same day in another calendar language.
final class ChangeLanguage extends DayDetailsEvent {
  const ChangeLanguage(this.language);

  final Language language;

  @override
  List<Object> get props => [language];
}
