import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/datasources/widget_local_datasource.dart';
import '../data/repositories/widget_repository_impl.dart';
import '../domain/repositories/widget_repository.dart';
import '../domain/usecases/configure_widget.dart';
import '../domain/usecases/get_widget_data.dart';
import '../domain/usecases/schedule_widget_updates.dart';
import '../domain/usecases/update_widget.dart';
import '../presentation/bloc/widget_bloc.dart';

final getIt = GetIt.instance;

Future<void> initHomeWidgetsDependencies() async {
  // Get SharedPreferences instance
  final sharedPreferences = await SharedPreferences.getInstance();

  // Data Sources
  getIt.registerLazySingleton<WidgetLocalDataSource>(
    () => WidgetLocalDataSource(sharedPreferences),
  );

  // Repositories
  getIt.registerLazySingleton<WidgetRepository>(
    () => WidgetRepositoryImpl(getIt<WidgetLocalDataSource>()),
  );

  // Use Cases
  getIt.registerLazySingleton(() => GetWidgetData(getIt<WidgetRepository>()));
  getIt.registerLazySingleton(() => UpdateWidget(getIt<WidgetRepository>()));
  getIt.registerLazySingleton(() => ConfigureWidget(getIt<WidgetRepository>()));
  getIt.registerLazySingleton(() => ScheduleUpdates(getIt<WidgetRepository>()));

  // BLoC
  getIt.registerFactory(
    () => WidgetBloc(
      getWidgetData: getIt<GetWidgetData>(),
      updateWidget: getIt<UpdateWidget>(),
      configureWidget: getIt<ConfigureWidget>(),
      scheduleUpdates: getIt<ScheduleUpdates>(),
      repository: getIt<WidgetRepository>(),
    ),
  );
}
