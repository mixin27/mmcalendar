import 'package:integrations_database/integrations_database.dart';
import 'package:events/events.dart';
import 'package:get_it/get_it.dart';
import 'package:holidays/holidays.dart';

import '../data/datasources/calendar_local_datasource.dart';
import '../data/repositories/calendar_repository_impl.dart';
import '../domain/repositories/calendar_repository.dart';
import '../domain/usecases/get_calendar_month.dart';
import '../domain/usecases/get_date_details.dart';
import '../domain/usecases/navigate_month.dart';
import '../domain/usecases/select_date.dart';
import '../domain/usecases/toggle_astrology.dart';
import '../presentation/bloc/calendar_bloc.dart';

final getIt = GetIt.instance;

/// Register all calendar feature dependencies
Future<void> initCalendarDependencies() async {
  // Data sources
  getIt.registerLazySingleton<CalendarLocalDataSource>(
    () => CalendarLocalDataSourceImpl(
      getIt<AppDatabase>(),
      getIt<HolidayService>(),
    ),
  );

  // Repositories
  getIt.registerLazySingleton<CalendarRepository>(
    () => CalendarRepositoryImpl(getIt<CalendarLocalDataSource>()),
  );

  // Use cases
  getIt.registerLazySingleton(
    () => GetCalendarMonth(getIt<CalendarRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetDateDetails(getIt<CalendarRepository>()),
  );
  getIt.registerLazySingleton(() => NavigateMonth(getIt<CalendarRepository>()));
  getIt.registerLazySingleton(() => SelectDate(getIt<CalendarRepository>()));
  getIt.registerLazySingleton(
    () => ToggleAstrology(getIt<CalendarRepository>()),
  );

  // BLoC
  getIt.registerFactory(
    () => CalendarBloc(
      getCalendarMonth: getIt<GetCalendarMonth>(),
      navigateMonth: getIt<NavigateMonth>(),
      selectDateUseCase: getIt<SelectDate>(),
      toggleAstrology: getIt<ToggleAstrology>(),
      getEventsByDateRange: getIt<GetEventsByDateRange>(),
    ),
  );
}
