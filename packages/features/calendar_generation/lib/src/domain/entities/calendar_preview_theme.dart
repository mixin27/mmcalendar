import 'package:equatable/equatable.dart';

class CalendarPreviewTheme extends Equatable {
  const CalendarPreviewTheme({
    required this.backgroundColorValue,
    required this.foregroundColorValue,
    required this.accentColorValue,
    this.backgroundImageUrl,
  });

  factory CalendarPreviewTheme.defaults() {
    return const CalendarPreviewTheme(
      backgroundColorValue: 0xFFFFFFFF,
      foregroundColorValue: 0xFF1E293B,
      accentColorValue: 0xFF2563EB,
    );
  }

  final int backgroundColorValue;
  final int foregroundColorValue;
  final int accentColorValue;
  final String? backgroundImageUrl;

  CalendarPreviewTheme copyWith({
    int? backgroundColorValue,
    int? foregroundColorValue,
    int? accentColorValue,
    String? backgroundImageUrl,
  }) {
    return CalendarPreviewTheme(
      backgroundColorValue: backgroundColorValue ?? this.backgroundColorValue,
      foregroundColorValue: foregroundColorValue ?? this.foregroundColorValue,
      accentColorValue: accentColorValue ?? this.accentColorValue,
      backgroundImageUrl: backgroundImageUrl ?? this.backgroundImageUrl,
    );
  }

  @override
  List<Object?> get props => [
    backgroundColorValue,
    foregroundColorValue,
    accentColorValue,
    backgroundImageUrl,
  ];
}
