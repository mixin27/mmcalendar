import 'package:equatable/equatable.dart';

class CalendarPreviewTheme extends Equatable {
  const CalendarPreviewTheme({
    required this.backgroundColorValue,
    required this.foregroundColorValue,
    required this.accentColorValue,
    this.backgroundImageUrl,
    this.backgroundImageUrlsByMonth = const <int, String>{},
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
  final Map<int, String> backgroundImageUrlsByMonth;

  String? backgroundImageUrlForMonth(int month) {
    final monthUrl = backgroundImageUrlsByMonth[month]?.trim();
    if (monthUrl != null && monthUrl.isNotEmpty) {
      return monthUrl;
    }

    final baseUrl = backgroundImageUrl?.trim();
    if (baseUrl == null || baseUrl.isEmpty) {
      return null;
    }
    return baseUrl;
  }

  CalendarPreviewTheme copyWith({
    int? backgroundColorValue,
    int? foregroundColorValue,
    int? accentColorValue,
    String? backgroundImageUrl,
    Map<int, String>? backgroundImageUrlsByMonth,
  }) {
    return CalendarPreviewTheme(
      backgroundColorValue: backgroundColorValue ?? this.backgroundColorValue,
      foregroundColorValue: foregroundColorValue ?? this.foregroundColorValue,
      accentColorValue: accentColorValue ?? this.accentColorValue,
      backgroundImageUrl: backgroundImageUrl ?? this.backgroundImageUrl,
      backgroundImageUrlsByMonth:
          backgroundImageUrlsByMonth ?? this.backgroundImageUrlsByMonth,
    );
  }

  @override
  List<Object?> get props => [
    backgroundColorValue,
    foregroundColorValue,
    accentColorValue,
    backgroundImageUrl,
    _encodedMonthlyImages,
  ];

  String get _encodedMonthlyImages {
    final entries = backgroundImageUrlsByMonth.entries.toList(growable: false)
      ..sort((left, right) => left.key.compareTo(right.key));
    return entries.map((entry) => '${entry.key}=${entry.value}').join('|');
  }
}
