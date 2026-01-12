library;

// Domain - Entities
export 'src/domain/entities/promo_campaign.dart';
export 'src/domain/entities/promo_interaction.dart';

// Domain - Repositories
export 'src/domain/repositories/promo_repository.dart';

// Domain - Use Cases
export 'src/domain/usecases/get_onboarding_slides.dart';
export 'src/domain/usecases/get_feature_announcements.dart';
export 'src/domain/usecases/should_show_promo.dart';
export 'src/domain/usecases/track_promo_interaction.dart';

// Data - Data Sources
export 'src/data/datasources/promo_local_datasource.dart';

// Data - Repositories
export 'src/data/repositories/promo_repository_impl.dart';

// Presentation - BLoC
export 'src/presentation/bloc/promo_bloc.dart';

// Presentation - Services
export 'src/presentation/services/promo_service.dart';

// Presentation - Slides
export 'src/presentation/slides/contextual_promo_slides.dart';

// Dependency Injection
export 'src/di/promo_injection.dart' hide getIt;

export 'package:promo_carousel/promo_carousel.dart';
