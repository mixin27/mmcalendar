import 'package:get_it/get_it.dart';

import '../data/repositories/converter_repository_impl.dart';
import '../domain/repositories/converter_repository.dart';
import '../domain/usecases/add_subtract_dates.dart';
import '../domain/usecases/calculate_date_difference.dart';
import '../domain/usecases/convert_myanmar_to_western.dart';
import '../domain/usecases/convert_western_to_myanmar.dart';
import '../domain/usecases/find_next_moon_phase.dart';
import '../presentation/bloc/converter_bloc.dart';

final getIt = GetIt.instance;

/// Register all calendar feature dependencies
Future<void> initConverterDependencies() async {
  // Repositories
  getIt.registerLazySingleton<ConverterRepository>(
    () => ConverterRepositoryImpl(),
  );

  // Use cases
  getIt.registerLazySingleton(
    () => AddSubtractDates(getIt<ConverterRepository>()),
  );
  getIt.registerLazySingleton(
    () => CalculateDateDifference(getIt<ConverterRepository>()),
  );
  getIt.registerLazySingleton(
    () => ConvertMyanmarToWestern(getIt<ConverterRepository>()),
  );
  getIt.registerLazySingleton(
    () => ConvertWesternToMyanmar(getIt<ConverterRepository>()),
  );
  getIt.registerLazySingleton(
    () => FindNextMoonPhase(getIt<ConverterRepository>()),
  );

  // BLoC
  getIt.registerFactory(
    () => ConverterBloc(
      convertWesternToMyanmar: getIt<ConvertWesternToMyanmar>(),
      convertMyanmarToWestern: getIt<ConvertMyanmarToWestern>(),
      calculateDateDifference: getIt<CalculateDateDifference>(),
      addSubtractDates: getIt<AddSubtractDates>(),
      findNextMoonPhase: getIt<FindNextMoonPhase>(),
    ),
  );
}
