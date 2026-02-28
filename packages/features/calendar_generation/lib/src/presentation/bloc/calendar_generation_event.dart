import 'package:equatable/equatable.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

import '../../domain/entities/calendar_image_quality.dart';
import '../../domain/entities/calendar_generation_mode.dart';
import '../../domain/entities/calendar_page_orientation.dart';
import '../../domain/entities/calendar_paper_size.dart';

sealed class CalendarGenerationEvent extends Equatable {
  const CalendarGenerationEvent();

  @override
  List<Object?> get props => [];
}

final class InitializeCalendarGeneration extends CalendarGenerationEvent {
  const InitializeCalendarGeneration();
}

final class ChangeGenerationMode extends CalendarGenerationEvent {
  const ChangeGenerationMode(this.mode);

  final CalendarGenerationMode mode;

  @override
  List<Object?> get props => [mode];
}

final class ChangeGenerationYear extends CalendarGenerationEvent {
  const ChangeGenerationYear(this.year);

  final int year;

  @override
  List<Object?> get props => [year];
}

final class ChangeGenerationMonth extends CalendarGenerationEvent {
  const ChangeGenerationMonth(this.month);

  final int month;

  @override
  List<Object?> get props => [month];
}

final class ChangeGenerationLanguage extends CalendarGenerationEvent {
  const ChangeGenerationLanguage(this.language);

  final Language language;

  @override
  List<Object?> get props => [language];
}

final class ChangeBackgroundColor extends CalendarGenerationEvent {
  const ChangeBackgroundColor(this.colorValue);

  final int colorValue;

  @override
  List<Object?> get props => [colorValue];
}

final class ChangeForegroundColor extends CalendarGenerationEvent {
  const ChangeForegroundColor(this.colorValue);

  final int colorValue;

  @override
  List<Object?> get props => [colorValue];
}

final class ChangeAccentColor extends CalendarGenerationEvent {
  const ChangeAccentColor(this.colorValue);

  final int colorValue;

  @override
  List<Object?> get props => [colorValue];
}

final class ChangeBackgroundImageUrl extends CalendarGenerationEvent {
  const ChangeBackgroundImageUrl(this.url);

  final String url;

  @override
  List<Object?> get props => [url];
}

final class ChangeMonthBackgroundImageUrl extends CalendarGenerationEvent {
  const ChangeMonthBackgroundImageUrl({required this.month, required this.url});

  final int month;
  final String url;

  @override
  List<Object?> get props => [month, url];
}

final class ToggleGenerationHolidays extends CalendarGenerationEvent {
  const ToggleGenerationHolidays(this.value);

  final bool value;

  @override
  List<Object?> get props => [value];
}

final class ToggleGenerationAstrology extends CalendarGenerationEvent {
  const ToggleGenerationAstrology(this.value);

  final bool value;

  @override
  List<Object?> get props => [value];
}

final class ToggleGenerationWesternDates extends CalendarGenerationEvent {
  const ToggleGenerationWesternDates(this.value);

  final bool value;

  @override
  List<Object?> get props => [value];
}

final class ToggleGenerationMyanmarDates extends CalendarGenerationEvent {
  const ToggleGenerationMyanmarDates(this.value);

  final bool value;

  @override
  List<Object?> get props => [value];
}

final class ChangePaperSize extends CalendarGenerationEvent {
  const ChangePaperSize(this.paperSize);

  final CalendarPaperSize paperSize;

  @override
  List<Object?> get props => [paperSize];
}

final class ChangePageOrientation extends CalendarGenerationEvent {
  const ChangePageOrientation(this.orientation);

  final CalendarPageOrientation orientation;

  @override
  List<Object?> get props => [orientation];
}

final class ChangeImageQuality extends CalendarGenerationEvent {
  const ChangeImageQuality(this.quality);

  final CalendarImageQuality quality;

  @override
  List<Object?> get props => [quality];
}

final class SaveGenerationTemplate extends CalendarGenerationEvent {
  const SaveGenerationTemplate(this.name);

  final String name;

  @override
  List<Object?> get props => [name];
}

final class ApplyGenerationTemplate extends CalendarGenerationEvent {
  const ApplyGenerationTemplate(this.templateId);

  final String templateId;

  @override
  List<Object?> get props => [templateId];
}

final class DeleteGenerationTemplate extends CalendarGenerationEvent {
  const DeleteGenerationTemplate(this.templateId);

  final String templateId;

  @override
  List<Object?> get props => [templateId];
}

final class RenameGenerationTemplate extends CalendarGenerationEvent {
  const RenameGenerationTemplate({
    required this.templateId,
    required this.name,
  });

  final String templateId;
  final String name;

  @override
  List<Object?> get props => [templateId, name];
}
