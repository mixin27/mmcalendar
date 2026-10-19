import 'package:bloc/bloc.dart';

import '../../domain/repositories/events_repository.dart';
import '../../domain/usecases/create_event_category.dart';
import '../../domain/usecases/get_event_categories.dart';
import 'event_categories_event.dart';
import 'event_categories_state.dart';

class EventCategoriesBloc
    extends Bloc<EventCategoriesEvent, EventCategoriesState> {
  final GetEventCategories getEventCategories;
  final CreateEventCategory createEventCategory;

  /// Renames, recolours and deletes custom categories.
  final EventsRepository repository;

  EventCategoriesBloc({
    required this.getEventCategories,
    required this.createEventCategory,
    required this.repository,
  }) : super(EventCategoriesInitial()) {
    on<LoadEventCategories>(_onLoadEventCategories);
    on<CreateCategory>(_onCreateCategory);
    on<UpdateCategory>(_onUpdateCategory);
    on<DeleteCategory>(_onDeleteCategory);
    on<RefreshCategories>(_onRefreshCategories);
  }

  Future<void> _onUpdateCategory(
    UpdateCategory event,
    Emitter<EventCategoriesState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EventCategoriesLoaded) return;
    final result = await repository.updateCategory(event.category);
    result.fold(
      (failure) => emit(EventCategoriesError(failure)),
      (updated) => emit(
        EventCategoriesLoaded([
          for (final c in currentState.categories)
            c.id == updated.id ? updated : c,
        ]),
      ),
    );
  }

  Future<void> _onDeleteCategory(
    DeleteCategory event,
    Emitter<EventCategoriesState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EventCategoriesLoaded) return;
    final result = await repository.deleteCategory(event.categoryId);
    result.fold(
      (failure) => emit(EventCategoriesError(failure)),
      (_) => emit(
        EventCategoriesLoaded([
          for (final c in currentState.categories)
            if (c.id != event.categoryId) c,
        ]),
      ),
    );
  }

  Future<void> _onLoadEventCategories(
    LoadEventCategories event,
    Emitter<EventCategoriesState> emit,
  ) async {
    emit(const EventCategoriesLoading());

    final result = await getEventCategories();

    result.fold(
      (failure) => emit(EventCategoriesError(failure)),
      (categories) => emit(EventCategoriesLoaded(categories)),
    );
  }

  Future<void> _onCreateCategory(
    CreateCategory event,
    Emitter<EventCategoriesState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EventCategoriesLoaded) return;

    final result = await createEventCategory(
      CreateEventCategoryParams(event.category),
    );

    result.fold((failure) => emit(EventCategoriesError(failure)), (category) {
      final updatedCategories = [...currentState.categories, category];
      emit(EventCategoriesLoaded(updatedCategories));
    });
  }

  Future<void> _onRefreshCategories(
    RefreshCategories event,
    Emitter<EventCategoriesState> emit,
  ) async {
    add(const LoadEventCategories());
  }
}
