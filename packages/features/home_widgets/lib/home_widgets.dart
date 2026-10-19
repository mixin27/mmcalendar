library;

export 'src/widget_links.dart';
export 'src/home_widget_configuration.dart';

// Domain
export 'src/domain/entities/widget_config.dart';
export 'src/domain/entities/widget_data.dart';
export 'src/domain/repositories/widget_repository.dart';
export 'src/domain/usecases/configure_widget.dart';
export 'src/domain/usecases/get_widget_data.dart';
export 'src/domain/usecases/schedule_widget_updates.dart';
export 'src/domain/usecases/update_widget.dart';
export 'src/domain/usecases/get_is_widget_active.dart';

// Data
export 'src/data/datasources/widget_local_datasource.dart';
export 'src/data/repositories/widget_repository_impl.dart';
export 'src/data/services/widget_background_service.dart';
export 'src/data/services/widget_update_service.dart';
export 'src/data/services/widget_sync.dart';
export 'src/data/payload/widget_palettes.dart';
export 'src/data/payload/widget_payload_builder.dart';

// Presentation
export 'src/presentation/bloc/widget_bloc.dart';
export 'src/presentation/bloc/widget_event.dart';
export 'src/presentation/bloc/widget_state.dart';
export 'src/presentation/pages/widget_settings_page.dart';

// DI
export 'src/di/home_widgets_injection.dart' hide getIt;
