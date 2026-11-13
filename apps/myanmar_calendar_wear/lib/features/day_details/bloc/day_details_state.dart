part of 'day_details_bloc.dart';

sealed class DayDetailsState extends Equatable {
  const DayDetailsState();

  @override
  List<Object> get props => [];
}

final class DayDetailsInitial extends DayDetailsState {
  const DayDetailsInitial();
}

final class DayDetailsLoaded extends DayDetailsState {
  const DayDetailsLoaded(this.dayDetails);

  final DayDetails dayDetails;

  @override
  List<Object> get props => [dayDetails];
}

final class DayDetailsError extends DayDetailsState {
  const DayDetailsError(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}
