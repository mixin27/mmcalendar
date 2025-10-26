import 'package:data/data.dart';
import 'package:get_it/get_it.dart';

import '../data/datasources/events_local_datasource.dart';
import '../data/repositories/events_repository_impl.dart';
import '../domain/repositories/events_repository.dart';
import '../domain/usecases/create_event_category.dart';
import '../domain/usecases/create_user_event.dart';
import '../domain/usecases/delete_user_event.dart';
import '../domain/usecases/get_event_categories.dart';
import '../domain/usecases/get_events_by_date.dart';
import '../domain/usecases/get_events_by_date_range.dart';
import '../domain/usecases/get_upcoming_events.dart';
import '../domain/usecases/search_user_events.dart';
import '../domain/usecases/toggle_event_completion.dart';
import '../domain/usecases/update_user_event.dart';
import '../domain/usecases/watch_user_events.dart';
import '../presentation/bloc/event_categories_bloc.dart';
import '../presentation/bloc/event_form_bloc.dart';
import '../presentation/bloc/user_events_bloc.dart';
import '../services/event_notification_manager.dart';
import '../services/notification_service.dart';

final getIt = GetIt.instance;

Future<void> initEventsDependencies() async {
  // ============================================================================
  // SERVICES
  // ============================================================================

  getIt.registerLazySingleton<NotificationService>(
    () => NotificationServiceImpl(),
  );

  getIt.registerLazySingleton<EventNotificationManager>(
    () => EventNotificationManager(
      notificationService: getIt<NotificationService>(),
    ),
  );

  // ============================================================================
  // DATA SOURCES
  // ============================================================================

  getIt.registerLazySingleton<EventsLocalDataSource>(
    () => EventsLocalDataSourceImpl(getIt<AppDatabase>()),
  );

  // ============================================================================
  // REPOSITORIES
  // ============================================================================

  getIt.registerLazySingleton<EventsRepository>(
    () => EventsRepositoryImpl(getIt<EventsLocalDataSource>()),
  );

  // ============================================================================
  // USE CASES
  // ============================================================================

  // Event operations
  getIt.registerLazySingleton(() => CreateUserEvent(getIt<EventsRepository>()));

  getIt.registerLazySingleton(() => UpdateUserEvent(getIt<EventsRepository>()));

  getIt.registerLazySingleton(() => DeleteUserEvent(getIt<EventsRepository>()));

  getIt.registerLazySingleton(() => GetEventsByDate(getIt<EventsRepository>()));

  getIt.registerLazySingleton(
    () => GetEventsByDateRange(getIt<EventsRepository>()),
  );

  getIt.registerLazySingleton(
    () => GetUpcomingEvents(getIt<EventsRepository>()),
  );

  getIt.registerLazySingleton(
    () => SearchUserEvents(getIt<EventsRepository>()),
  );

  getIt.registerLazySingleton(
    () => ToggleEventCompletion(getIt<EventsRepository>()),
  );

  getIt.registerLazySingleton(() => WatchUserEvents(getIt<EventsRepository>()));

  getIt.registerLazySingleton(
    () => WatchEventsByDateRange(getIt<EventsRepository>()),
  );

  // Category operations
  getIt.registerLazySingleton(
    () => GetEventCategories(getIt<EventsRepository>()),
  );

  getIt.registerLazySingleton(
    () => CreateEventCategory(getIt<EventsRepository>()),
  );

  // ============================================================================
  // BLOCS
  // ============================================================================

  getIt.registerFactory(
    () => UserEventsBloc(
      getEventsByDate: getIt<GetEventsByDate>(),
      getEventsByDateRange: getIt<GetEventsByDateRange>(),
      getUpcomingEvents: getIt<GetUpcomingEvents>(),
      searchEvents: getIt<SearchUserEvents>(),
      toggleEventCompletion: getIt<ToggleEventCompletion>(),
      deleteEvent: getIt<DeleteUserEvent>(),
      watchEvents: getIt<WatchUserEvents>(),
      watchEventsByDateRange: getIt<WatchEventsByDateRange>(),
      eventsRepository: getIt<EventsRepository>(),
    ),
  );

  getIt.registerFactory(
    () => EventFormBloc(
      createEvent: getIt<CreateUserEvent>(),
      updateEvent: getIt<UpdateUserEvent>(),
    ),
  );

  getIt.registerFactory(
    () => EventCategoriesBloc(
      getEventCategories: getIt<GetEventCategories>(),
      createEventCategory: getIt<CreateEventCategory>(),
    ),
  );

  // ============================================================================
  // INITIALIZE DEFAULT DATA
  // ============================================================================

  // Initialize default categories
  await getIt<EventsRepository>().initializeDefaultCategories();

  // Initialize notification service
  await getIt<NotificationService>().initialize();

  // Start notification manager
  getIt<EventNotificationManager>().startMonitoring();
}
