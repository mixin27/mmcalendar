import 'package:bloc/bloc.dart';

import '../../domain/repositories/widget_repository.dart';
import '../../domain/usecases/configure_widget.dart';
import '../../domain/usecases/get_widget_data.dart';
import '../../domain/usecases/update_widget.dart';
import '../../domain/usecases/schedule_widget_updates.dart' as scw;

import 'widget_event.dart';
import 'widget_state.dart';

class WidgetBloc extends Bloc<WidgetEvent, WidgetState> {
  final GetWidgetData getWidgetData;
  final UpdateWidget updateWidget;
  final ConfigureWidget configureWidget;
  final scw.ScheduleUpdates scheduleUpdates;
  final WidgetRepository repository;

  WidgetBloc({
    required this.getWidgetData,
    required this.updateWidget,
    required this.configureWidget,
    required this.scheduleUpdates,
    required this.repository,
  }) : super(WidgetInitial()) {
    on<LoadWidgetConfig>(_onLoadWidgetConfig);
    on<UpdateWidgetConfig>(_onUpdateWidgetConfig);
    on<RefreshWidget>(_onRefreshWidget);
    on<ScheduleWidgetUpdates>(_onScheduleUpdates);
    on<CancelWidgetUpdates>(_onCancelUpdates);
    on<CheckWidgetStatus>(_onCheckWidgetStatus);
  }

  Future<void> _onLoadWidgetConfig(
    LoadWidgetConfig event,
    Emitter<WidgetState> emit,
  ) async {
    emit(const WidgetLoading());

    try {
      // Load configuration
      final config = await configureWidget.getConfig();

      // Get current widget data
      final today = DateTime.now();
      final data = await getWidgetData(today);

      // Check if widget is active
      final isActive = await repository.isWidgetActive();

      // Check if updates are scheduled
      final isScheduled = await repository.isUpdateScheduled();

      emit(
        WidgetLoaded(
          config: config,
          currentData: data,
          isActive: isActive,
          isScheduled: isScheduled,
        ),
      );
    } catch (e) {
      emit(WidgetError('Failed to load widget configuration: $e'));
    }
  }

  Future<void> _onUpdateWidgetConfig(
    UpdateWidgetConfig event,
    Emitter<WidgetState> emit,
  ) async {
    if (state is! WidgetLoaded) return;

    final currentState = state as WidgetLoaded;

    // Show updating state briefly
    emit(const WidgetUpdating());

    try {
      // Save new configuration
      await configureWidget.saveConfig(event.config);

      // Refresh widget with new config
      await repository.refreshWidget();

      // Get updated data
      final today = DateTime.now();
      final data = await getWidgetData(today);

      // Emit updated state
      emit(currentState.copyWith(config: event.config, currentData: data));

      // Brief success state
      emit(WidgetUpdated(data));

      // Return to loaded state after 1 second
      await Future.delayed(const Duration(seconds: 1));
      emit(currentState.copyWith(config: event.config, currentData: data));
    } catch (e) {
      emit(WidgetError('Failed to update configuration: $e'));
      // Return to previous state
      emit(currentState);
    }
  }

  Future<void> _onRefreshWidget(
    RefreshWidget event,
    Emitter<WidgetState> emit,
  ) async {
    if (state is! WidgetLoaded) return;

    final currentState = state as WidgetLoaded;
    emit(const WidgetUpdating());

    try {
      // Refresh widget
      await repository.refreshWidget();

      // Get updated data
      final today = DateTime.now();
      final data = await getWidgetData(today);

      // Show success state
      emit(WidgetUpdated(data));

      // Return to loaded state after 1 second
      await Future.delayed(const Duration(seconds: 1));
      emit(currentState.copyWith(currentData: data));
    } catch (e) {
      emit(WidgetError('Failed to refresh widget: $e'));
      // Return to previous state after 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      emit(currentState);
    }
  }

  Future<void> _onScheduleUpdates(
    ScheduleWidgetUpdates event,
    Emitter<WidgetState> emit,
  ) async {
    if (state is! WidgetLoaded) return;

    final currentState = state as WidgetLoaded;

    try {
      await scheduleUpdates();
      emit(currentState.copyWith(isScheduled: true));
    } catch (e) {
      emit(WidgetError('Failed to schedule updates: $e'));
      await Future.delayed(const Duration(seconds: 2));
      emit(currentState);
    }
  }

  Future<void> _onCancelUpdates(
    CancelWidgetUpdates event,
    Emitter<WidgetState> emit,
  ) async {
    if (state is! WidgetLoaded) return;

    final currentState = state as WidgetLoaded;

    try {
      await repository.cancelWidgetUpdates();
      emit(currentState.copyWith(isScheduled: false));
    } catch (e) {
      emit(WidgetError('Failed to cancel updates: $e'));
      await Future.delayed(const Duration(seconds: 2));
      emit(currentState);
    }
  }

  Future<void> _onCheckWidgetStatus(
    CheckWidgetStatus event,
    Emitter<WidgetState> emit,
  ) async {
    if (state is! WidgetLoaded) return;

    final currentState = state as WidgetLoaded;

    try {
      final isActive = await repository.isWidgetActive();
      final isScheduled = await repository.isUpdateScheduled();

      emit(currentState.copyWith(isActive: isActive, isScheduled: isScheduled));
    } catch (e) {
      emit(WidgetError('Failed to check widget status: $e'));
      await Future.delayed(const Duration(seconds: 2));
      emit(currentState);
    }
  }
}
