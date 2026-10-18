import 'package:get_it/get_it.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/datasources/widget_local_datasource.dart';
import '../data/payload/widget_payload_builder.dart';
import '../data/repositories/widget_repository_impl.dart';
import '../data/services/widget_sync.dart';
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
    () => WidgetLocalDataSource(sharedPreferences, loadEvents: _loadEvents),
  );

  getIt.registerLazySingleton<WidgetSync>(
    () => WidgetSync(
      getIt<WidgetLocalDataSource>(),
      events: getIt.isRegistered<EventMarkersPort>()
          ? getIt<EventMarkersPort>()
          : null,
    ),
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

/// The next two weeks of events, when the events feature is registered.
Future<List<WidgetAgendaEvent>> _loadEvents(
  DateTime start,
  DateTime end,
) async {
  if (!getIt.isRegistered<EventMarkersPort>()) return const [];
  final byDay = await getIt<EventMarkersPort>()
      .watchEventMarkers(startDate: start, endDate: end)
      .first
      .timeout(const Duration(seconds: 3));
  final days = byDay.keys.toList()..sort();
  return [
    for (final day in days)
      for (final item in byDay[day]!) WidgetAgendaEvent.fromItem(item, day),
  ]..sort((a, b) {
    final byDate = a.date.compareTo(b.date);
    if (byDate != 0) return byDate;
    if (a.time == null) return -1;
    if (b.time == null) return 1;
    return a.time!.compareTo(b.time!);
  });
}
