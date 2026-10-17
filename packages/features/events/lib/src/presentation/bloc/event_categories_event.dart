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

final class UpdateCategory extends EventCategoriesEvent {
  final EventCategory category;
  const UpdateCategory(this.category);

  @override
  List<Object?> get props => [category];
}

final class DeleteCategory extends EventCategoriesEvent {
  final int categoryId;
  const DeleteCategory(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

final class RefreshCategories extends EventCategoriesEvent {
  const RefreshCategories();
}
