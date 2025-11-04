import 'package:data/data.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../data/datasources/events_local_datasource.dart';
import '../data/datasources/recurring_exceptions_datasource.dart';
import '../data/repositories/events_repository_impl.dart';
import '../domain/repositories/events_repository.dart';
import '../domain/usecases/complete_recurring_instance.dart';
import '../domain/usecases/create_event_category.dart';
import '../domain/usecases/create_user_event.dart';
import '../domain/usecases/delete_recurring_instance.dart';
import '../domain/usecases/delete_user_event.dart';
import '../domain/usecases/get_event_by_id.dart';
import '../domain/usecases/get_event_categories.dart';
import '../domain/usecases/get_events_by_date.dart';
import '../domain/usecases/get_events_by_date_range.dart';
import '../domain/usecases/get_upcoming_events.dart';
import '../domain/usecases/modify_recurring_instance.dart';
import '../domain/usecases/search_user_events.dart';
import '../domain/usecases/toggle_event_completion.dart';
import '../domain/usecases/update_user_event.dart';
import '../domain/usecases/watch_user_events.dart';
import '../presentation/bloc/event_categories_bloc.dart';
import '../presentation/bloc/event_form_bloc.dart';
import '../presentation/bloc/user_events_bloc.dart';
import '../services/event_notification_manager.dart';
import '../services/notification_service.dart';
import '../services/smart_notification_scheduler.dart';

final getIt = GetIt.instance;

Future<void> initEventsDependencies() async {
  // ============================================================================
  // SERVICES (Notification Layer)
  // ============================================================================

  // Low-level notification service (handles actual OS notifications)
  getIt.registerLazySingleton<NotificationService>(
    () => NotificationServiceImpl(),
  );

  // Mid-level notification manager (handles event-specific logic)
  getIt.registerLazySingleton<EventNotificationManager>(
    () => EventNotificationManager(
      notificationService: getIt<NotificationService>(),
    ),
  );

  // High-level smart scheduler (handles recurring events & auto-refresh)
  getIt.registerLazySingleton<SmartNotificationScheduler>(
    () => SmartNotificationScheduler(
      notificationManager: getIt<EventNotificationManager>(),
      eventsRepository: getIt<EventsRepository>(),
    ),
  );

  // ============================================================================
  // DATA SOURCES
  // ============================================================================

  getIt.registerLazySingleton<EventsLocalDataSource>(
    () => EventsLocalDataSourceImpl(getIt<AppDatabase>()),
  );

  getIt.registerLazySingleton<RecurringExceptionsDataSource>(
    () => RecurringExceptionsDataSourceImpl(getIt<AppDatabase>()),
  );

  // ============================================================================
  // REPOSITORIES
  // ============================================================================

  getIt.registerLazySingleton<EventsRepository>(
    () => EventsRepositoryImpl(
      getIt<EventsLocalDataSource>(),
      getIt<RecurringExceptionsDataSource>(),
    ),
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
  getIt.registerLazySingleton(() => GetEventById(getIt<EventsRepository>()));

  // Category operations
  getIt.registerLazySingleton(
    () => GetEventCategories(getIt<EventsRepository>()),
  );
  getIt.registerLazySingleton(
    () => CreateEventCategory(getIt<EventsRepository>()),
  );

  // Recurring instance operations (NEW)
  getIt.registerLazySingleton(
    () => CompleteRecurringInstance(getIt<EventsRepository>()),
  );
  getIt.registerLazySingleton(
    () => DeleteRecurringInstance(getIt<EventsRepository>()),
  );
  getIt.registerLazySingleton(
    () => ModifyRecurringInstance(getIt<EventsRepository>()),
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
      smartScheduler: getIt<SmartNotificationScheduler>(),
    ),
  );

  getIt.registerFactory(
    () => EventFormBloc(
      createEvent: getIt<CreateUserEvent>(),
      updateEvent: getIt<UpdateUserEvent>(),
      getEventById: getIt<GetEventById>(),
      smartScheduler: getIt<SmartNotificationScheduler>(),
    ),
  );

  getIt.registerFactory(
    () => EventCategoriesBloc(
      getEventCategories: getIt<GetEventCategories>(),
      createEventCategory: getIt<CreateEventCategory>(),
    ),
  );

  // ============================================================================
  // INITIALIZE SERVICES
  // ============================================================================

  // Initialize default categories
  await getIt<EventsRepository>().initializeDefaultCategories();

  // Initialize notification service
  await getIt<NotificationService>().initialize();

  // Initialize smart scheduler (this also schedules initial notifications)
  await getIt<SmartNotificationScheduler>().initialize();

  debugPrint('✅ Events module initialized successfully');
}

// ============================================================================
// CLEANUP ON APP DISPOSE
// ============================================================================

Future<void> disposeEventsDependencies() async {
  // Stop the smart scheduler
  getIt<SmartNotificationScheduler>().dispose();

  // Cancel all notifications
  await getIt<NotificationService>().cancelAllNotifications();

  debugPrint('✅ Events module disposed');
}
