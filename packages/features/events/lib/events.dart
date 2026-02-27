library;

// Domain
export 'src/domain/entities/event.dart';
export 'src/domain/entities/event_category.dart';
export 'src/domain/entities/recurrence_rule.dart';
export 'src/domain/entities/notification_setting.dart';
export 'src/domain/repositories/events_repository.dart';
export 'src/domain/services/event_validation_service.dart';

// Use Cases
export 'src/domain/usecases/create_user_event.dart';
export 'src/domain/usecases/update_user_event.dart';
export 'src/domain/usecases/delete_user_event.dart';
export 'src/domain/usecases/get_events_by_date.dart';
export 'src/domain/usecases/get_events_by_date_range.dart';
export 'src/domain/usecases/get_upcoming_events.dart';
export 'src/domain/usecases/search_user_events.dart';
export 'src/domain/usecases/toggle_event_completion.dart';
export 'src/domain/usecases/watch_user_events.dart';
export 'src/domain/usecases/get_event_categories.dart';
export 'src/domain/usecases/create_event_category.dart';
export 'src/domain/usecases/get_event_by_id.dart';

// Presentation
export 'src/presentation/bloc/user_events_bloc.dart';
export 'src/presentation/bloc/user_events_event.dart';
export 'src/presentation/bloc/user_events_state.dart';
export 'src/presentation/bloc/event_form_bloc.dart';
export 'src/presentation/bloc/event_form_event.dart';
export 'src/presentation/bloc/event_form_state.dart';
export 'src/presentation/bloc/event_categories_bloc.dart';
export 'src/presentation/bloc/event_categories_event.dart';

// Pages
export 'src/presentation/pages/events_list_page.dart';
export 'src/presentation/pages/event_form_page.dart';
export 'src/presentation/pages/event_detail_page.dart';
export 'src/presentation/pages/categories_page.dart';

// Widgets
export 'src/presentation/widgets/event_calendar_indicator.dart';
export 'src/presentation/widgets/event_list_tile.dart';
export 'src/presentation/widgets/category_chip.dart';
export 'src/presentation/widgets/priority_badge.dart';
export 'src/presentation/widgets/recurrence_badge.dart';
export 'src/presentation/widgets/animated_event_card.dart';

// Services
export 'src/services/notification_service.dart';
export 'src/services/event_notification_manager.dart';
export 'src/services/smart_notification_scheduler.dart';
export 'src/application/services/event_flow_service.dart';

// DI
export 'src/di/events_injection.dart' hide getIt;

// Data (for repository access in calendar feature)
export 'src/data/repositories/events_repository_impl.dart';
