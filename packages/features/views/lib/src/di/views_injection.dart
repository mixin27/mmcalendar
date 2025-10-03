import 'package:get_it/get_it.dart';

import '../data/datasources/views_local_datasource.dart';
import '../data/repositories/views_repository_impl.dart';
import '../domain/repositories/views_repository.dart';
import '../domain/usecases/get_day_view.dart';
import '../domain/usecases/get_week_view.dart';
import '../domain/usecases/get_year_view.dart';
import '../presentation/bloc/views_bloc.dart';

final getIt = GetIt.instance;

/// Register all views feature dependencies
Future<void> initViewsDependencies() async {
  // Data sources
  getIt.registerLazySingleton<ViewsLocalDataSource>(
    () => ViewsLocalDataSourceImpl(),
  );

  // Repositories
  getIt.registerLazySingleton<ViewsRepository>(
    () => ViewsRepositoryImpl(getIt<ViewsLocalDataSource>()),
  );

  // Use cases
  getIt.registerLazySingleton(() => GetYearView(getIt<ViewsRepository>()));
  getIt.registerLazySingleton(() => GetWeekView(getIt<ViewsRepository>()));
  getIt.registerLazySingleton(() => GetDayView(getIt<ViewsRepository>()));

  // BLoC
  getIt.registerFactory(
    () => ViewsBloc(
      getYearView: getIt<GetYearView>(),
      getWeekView: getIt<GetWeekView>(),
      getDayView: getIt<GetDayView>(),
    ),
  );
}
