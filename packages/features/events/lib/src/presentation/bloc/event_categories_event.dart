import 'package:equatable/equatable.dart';

import '../../domain/entities/event_category.dart';

sealed class EventCategoriesEvent extends Equatable {
  const EventCategoriesEvent();

  @override
  List<Object?> get props => [];
}

final class LoadEventCategories extends EventCategoriesEvent {
  const LoadEventCategories();
}

final class CreateCategory extends EventCategoriesEvent {
  final EventCategory category;
  const CreateCategory(this.category);
}

final class RefreshCategories extends EventCategoriesEvent {
  const RefreshCategories();
}
