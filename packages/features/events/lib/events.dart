library;

// Domain
export 'src/domain/entities/event.dart';
export 'src/domain/usecases/get_events_by_date_range.dart';
export 'src/domain/repositories/events_repository.dart';

// Data
export 'src/data/models/event_model.dart';
export 'src/data/datasources/events_local_datasource.dart';
export 'src/data/repositories/events_repository_impl.dart';

// Presentation
export 'src/presentation/bloc/events_bloc.dart';
export 'src/presentation/bloc/events_event.dart';
export 'src/presentation/bloc/events_state.dart';
export 'src/presentation/pages/events_list_page.dart';
export 'src/presentation/pages/event_form_page.dart';
export 'src/presentation/pages/event_detail_page.dart';
export 'src/presentation/pages/categories_page.dart';
export 'src/presentation/widgets/event_card.dart';
export 'src/presentation/widgets/event_date_group.dart';
export 'src/presentation/widgets/category_filter_chips.dart';
export 'src/presentation/widgets/date_range_selector.dart';
export 'src/presentation/widgets/category_selector_field.dart';
export 'src/presentation/widgets/priority_selector.dart';

// DI
export 'src/di/events_injection.dart' hide getIt;
