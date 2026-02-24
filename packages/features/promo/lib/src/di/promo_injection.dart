import 'package:integrations_firebase/integrations_firebase.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/datasources/promo_local_datasource.dart';
import '../data/repositories/promo_repository_impl.dart';
import '../domain/repositories/promo_repository.dart';
import '../domain/usecases/get_feature_announcements.dart';
import '../domain/usecases/get_onboarding_slides.dart';
import '../domain/usecases/should_show_promo.dart';
import '../domain/usecases/track_promo_interaction.dart';
import '../presentation/bloc/promo_bloc.dart';
import '../presentation/services/promo_service.dart';

final getIt = GetIt.instance;

/// Initialize promo feature dependencies
Future<void> initializePromoDependencies() async {
  // External dependencies (should already be registered in main app)
  // - SharedPreferences
  // - AnalyticsService

  // Data sources
  getIt.registerLazySingleton<PromoLocalDataSource>(
    () => PromoLocalDataSource(getIt<SharedPreferences>()),
  );

  // Repositories
  getIt.registerLazySingleton<PromoRepository>(
    () => PromoRepositoryImpl(getIt<PromoLocalDataSource>()),
  );

  // Use cases
  getIt.registerLazySingleton<GetOnboardingSlides>(
    () => GetOnboardingSlides(getIt<PromoRepository>()),
  );

  getIt.registerLazySingleton<GetFeatureAnnouncements>(
    () => GetFeatureAnnouncements(getIt<PromoRepository>()),
  );

  getIt.registerLazySingleton<ShouldShowPromo>(
    () => ShouldShowPromo(getIt<PromoRepository>()),
  );

  getIt.registerLazySingleton<TrackPromoInteraction>(
    () => TrackPromoInteraction(getIt<PromoRepository>()),
  );

  // BLoC
  getIt.registerFactory<PromoBloc>(
    () => PromoBloc(
      getOnboardingSlides: getIt<GetOnboardingSlides>(),
      getFeatureAnnouncements: getIt<GetFeatureAnnouncements>(),
    ),
  );

  // Services
  getIt.registerLazySingleton<PromoService>(
    () => PromoService(
      repository: getIt<PromoRepository>(),
      getOnboardingSlides: getIt<GetOnboardingSlides>(),
      getFeatureAnnouncements: getIt<GetFeatureAnnouncements>(),
      analyticsService: getIt.isRegistered<AnalyticsService>()
          ? getIt<AnalyticsService>()
          : null,
    ),
  );
}
