import 'package:bloc/bloc.dart';

import '../../domain/usecases/create_event_category.dart';
import '../../domain/usecases/get_event_categories.dart';
import 'event_categories_event.dart';
import 'event_categories_state.dart';

class EventCategoriesBloc
    extends Bloc<EventCategoriesEvent, EventCategoriesState> {
  final GetEventCategories getEventCategories;
  final CreateEventCategory createEventCategory;

  EventCategoriesBloc({
    required this.getEventCategories,
    required this.createEventCategory,
  }) : super(EventCategoriesInitial()) {
    on<LoadEventCategories>(_onLoadEventCategories);
    on<CreateCategory>(_onCreateCategory);
    on<RefreshCategories>(_onRefreshCategories);
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
