import 'package:equatable/equatable.dart';

import '../../domain/entities/widget_config.dart';
import '../../domain/entities/widget_data.dart';

sealed class WidgetState extends Equatable {
  const WidgetState();

  @override
  List<Object?> get props => [];
}

final class WidgetInitial extends WidgetState {}

final class WidgetLoading extends WidgetState {
  const WidgetLoading();
}

final class WidgetLoaded extends WidgetState {
  final WidgetConfig config;
  final WidgetData? currentData;
  final bool isActive;
  final bool isScheduled;

  const WidgetLoaded({
    required this.config,
    this.currentData,
    required this.isActive,
    required this.isScheduled,
  });

  @override
  List<Object?> get props => [config, currentData, isActive, isScheduled];

  WidgetLoaded copyWith({
    WidgetConfig? config,
    WidgetData? currentData,
    bool? isActive,
    bool? isScheduled,
  }) {
    return WidgetLoaded(
      config: config ?? this.config,
      currentData: currentData ?? this.currentData,
      isActive: isActive ?? this.isActive,
      isScheduled: isScheduled ?? this.isScheduled,
    );
  }
}

final class WidgetError extends WidgetState {
  final String message;

  const WidgetError(this.message);

  @override
  List<Object?> get props => [message];
}

final class WidgetUpdating extends WidgetState {
  const WidgetUpdating();
}

final class WidgetUpdated extends WidgetState {
  final WidgetData data;

  const WidgetUpdated(this.data);

  @override
  List<Object?> get props => [data];
}
