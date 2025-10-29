import 'package:core/core.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/event_category.dart';

sealed class EventCategoriesState extends Equatable {
  const EventCategoriesState();

  @override
  List<Object?> get props => [];
}

final class EventCategoriesInitial extends EventCategoriesState {}

final class EventCategoriesLoading extends EventCategoriesState {
  const EventCategoriesLoading();
}

final class EventCategoriesLoaded extends EventCategoriesState {
  final List<EventCategory> categories;
  const EventCategoriesLoaded(this.categories);
}

final class EventCategoriesError extends EventCategoriesState {
  final Failure failure;
  const EventCategoriesError(this.failure);
}
