import 'package:data/data.dart';
import 'package:get_it/get_it.dart';

import '../data/datasources/events_local_datasource.dart';
import '../data/repositories/events_repository_impl.dart';
import '../domain/repositories/events_repository.dart';
import '../domain/usecases/create_category.dart';
import '../domain/usecases/create_event.dart';
import '../domain/usecases/delete_category.dart';
import '../domain/usecases/delete_event.dart';
import '../domain/usecases/get_all_categories.dart';
import '../domain/usecases/get_all_events.dart';
import '../domain/usecases/get_event_by_id.dart';
import '../domain/usecases/get_events_by_category.dart';
import '../domain/usecases/get_events_by_date.dart';
import '../domain/usecases/get_events_by_date_range.dart';
import '../domain/usecases/initialize_default_categories.dart';
import '../domain/usecases/toggle_event_complete.dart';
import '../domain/usecases/update_event.dart';
import '../domain/usecases/watch_all_events.dart';
import '../domain/usecases/watch_event_by_id.dart';
import '../presentation/bloc/events_bloc.dart';

final getIt = GetIt.instance;

Future<void> initEventsFeature() async {
  // Data Source
  getIt.registerLazySingleton<EventsLocalDataSource>(
    () => EventsLocalDataSourceImpl(getIt<AppDatabase>().eventsDao),
  );

  // Repository
  getIt.registerLazySingleton<EventsRepository>(
    () => EventsRepositoryImpl(localDataSource: getIt<EventsLocalDataSource>()),
  );

  // Use Cases
  getIt.registerLazySingleton(() => GetAllEvents(getIt<EventsRepository>()));
  getIt.registerLazySingleton(() => GetEventsByDate(getIt<EventsRepository>()));
  getIt.registerLazySingleton(
    () => GetEventsByDateRange(getIt<EventsRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetEventsByCategory(getIt<EventsRepository>()),
  );
  getIt.registerLazySingleton(() => GetEventById(getIt<EventsRepository>()));
  getIt.registerLazySingleton(() => CreateEvent(getIt<EventsRepository>()));
  getIt.registerLazySingleton(() => UpdateEvent(getIt<EventsRepository>()));
  getIt.registerLazySingleton(() => DeleteEvent(getIt<EventsRepository>()));
  getIt.registerLazySingleton(
    () => ToggleEventComplete(getIt<EventsRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetAllCategories(getIt<EventsRepository>()),
  );
  getIt.registerLazySingleton(() => CreateCategory(getIt<EventsRepository>()));
  getIt.registerLazySingleton(() => DeleteCategory(getIt<EventsRepository>()));
  getIt.registerLazySingleton(() => WatchAllEvents(getIt<EventsRepository>()));
  getIt.registerLazySingleton(() => WatchEventById(getIt<EventsRepository>()));
  getIt.registerLazySingleton(
    () => InitializeDefaultCategories(getIt<EventsRepository>()),
  );

  // BLoC
  getIt.registerFactory<EventsBloc>(
    () => EventsBloc(
      getAllEvents: getIt(),
      getEventsByDate: getIt(),
      getEventsByDateRange: getIt(),
      getEventsByCategory: getIt(),
      getEventById: getIt(),
      createEvent: getIt(),
      updateEvent: getIt(),
      deleteEvent: getIt(),
      toggleEventComplete: getIt(),
      getAllCategories: getIt(),
      createCategory: getIt(),
      deleteCategory: getIt(),
      watchAllEvents: getIt(),
      watchEventById: getIt(),
      initializeDefaultCategories: getIt(),
    ),
  );
}
