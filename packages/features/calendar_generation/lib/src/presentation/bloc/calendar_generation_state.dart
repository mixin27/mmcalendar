import 'package:equatable/equatable.dart';

import '../../domain/entities/calendar_generation_request.dart';
import '../../domain/entities/calendar_generation_template.dart';
import '../../domain/entities/calendar_page_model.dart';

sealed class CalendarGenerationState extends Equatable {
  const CalendarGenerationState();

  @override
  List<Object?> get props => [];
}

final class CalendarGenerationInitial extends CalendarGenerationState {
  const CalendarGenerationInitial();
}

final class CalendarGenerationLoading extends CalendarGenerationState {
  const CalendarGenerationLoading();
}

final class CalendarGenerationLoaded extends CalendarGenerationState {
  const CalendarGenerationLoaded({
    required this.request,
    required this.pages,
    required this.templates,
  });

  final CalendarGenerationRequest request;
  final List<CalendarPageModel> pages;
  final List<CalendarGenerationTemplate> templates;

  CalendarGenerationLoaded copyWith({
    CalendarGenerationRequest? request,
    List<CalendarPageModel>? pages,
    List<CalendarGenerationTemplate>? templates,
  }) {
    return CalendarGenerationLoaded(
      request: request ?? this.request,
      pages: pages ?? this.pages,
      templates: templates ?? this.templates,
    );
  }

  @override
  List<Object?> get props => [request, pages, templates];
}

final class CalendarGenerationError extends CalendarGenerationState {
  const CalendarGenerationError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
