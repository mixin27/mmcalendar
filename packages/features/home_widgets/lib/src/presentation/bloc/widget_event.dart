import 'package:equatable/equatable.dart';

import '../../domain/entities/widget_config.dart';

sealed class WidgetEvent extends Equatable {
  const WidgetEvent();

  @override
  List<Object?> get props => [];
}

final class LoadWidgetConfig extends WidgetEvent {
  const LoadWidgetConfig();
}

final class UpdateWidgetConfig extends WidgetEvent {
  final WidgetConfig config;

  const UpdateWidgetConfig(this.config);

  @override
  List<Object?> get props => [config];
}

final class RefreshWidget extends WidgetEvent {
  const RefreshWidget();
}

final class ScheduleWidgetUpdates extends WidgetEvent {
  const ScheduleWidgetUpdates();
}

final class CancelWidgetUpdates extends WidgetEvent {
  const CancelWidgetUpdates();
}

final class CheckWidgetStatus extends WidgetEvent {
  const CheckWidgetStatus();
}
