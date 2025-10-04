import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() async => getIt.init();

/// Register a singleton
void registerSingleton<T extends Object>(T instance) {
  if (!getIt.isRegistered<T>()) {
    getIt.registerSingleton<T>(instance);
  }
}

/// Register a lazy singleton
void registerLazySingleton<T extends Object>(T Function() factory) {
  if (!getIt.isRegistered<T>()) {
    getIt.registerLazySingleton<T>(factory);
  }
}

/// Register a factory
void registerFactory<T extends Object>(T Function() factory) {
  if (!getIt.isRegistered<T>()) {
    getIt.registerFactory<T>(factory);
  }
}

/// Get instance
T get<T extends Object>() => getIt<T>();

/// Check if registered
bool isRegistered<T extends Object>() => getIt.isRegistered<T>();

/// Reset all registrations (for testing)
Future<void> resetDependencies() async {
  await getIt.reset();
}
