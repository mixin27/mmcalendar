import 'package:equatable/equatable.dart';

import '../../domain/entities/day_data.dart';
import '../../domain/entities/week_data.dart';
import '../../domain/entities/year_data.dart';

sealed class ViewsState extends Equatable {
  const ViewsState();

  @override
  List<Object?> get props => [];
}

final class ViewsInitial extends ViewsState {
  const ViewsInitial();
}

final class ViewsLoading extends ViewsState {
  const ViewsLoading();
}

final class YearViewLoaded extends ViewsState {
  final YearData yearData;

  const YearViewLoaded(this.yearData);

  @override
  List<Object?> get props => [yearData];
}

final class WeekViewLoaded extends ViewsState {
  final WeekData weekData;

  const WeekViewLoaded(this.weekData);

  @override
  List<Object?> get props => [weekData];
}

final class DayViewLoaded extends ViewsState {
  final DayData dayData;

  const DayViewLoaded(this.dayData);

  @override
  List<Object?> get props => [dayData];
}

final class ViewsError extends ViewsState {
  final String message;

  const ViewsError(this.message);

  @override
  List<Object?> get props => [message];
}
