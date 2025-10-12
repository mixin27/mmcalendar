library;

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

// Presentation
export 'src/presentation/bloc/widget_bloc.dart';
export 'src/presentation/bloc/widget_event.dart';
export 'src/presentation/bloc/widget_state.dart';
export 'src/presentation/pages/widget_settings_page.dart';
export 'src/presentation/widgets/widget_preview.dart';
export 'src/presentation/widgets/widget_add_instructions.dart';

// DI
export 'src/di/home_widgets_injection.dart' hide getIt;
