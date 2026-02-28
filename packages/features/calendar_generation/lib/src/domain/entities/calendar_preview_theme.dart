import 'package:equatable/equatable.dart';

enum CalendarBackgroundImageFit { cover, contain, fill }

extension CalendarBackgroundImageFitX on CalendarBackgroundImageFit {
  String get label => switch (this) {
    CalendarBackgroundImageFit.cover => 'Cover',
    CalendarBackgroundImageFit.contain => 'Contain',
    CalendarBackgroundImageFit.fill => 'Fill',
  };
}

enum CalendarBackgroundImageAlignment { top, center, bottom }

extension CalendarBackgroundImageAlignmentX
    on CalendarBackgroundImageAlignment {
  String get label => switch (this) {
    CalendarBackgroundImageAlignment.top => 'Top',
    CalendarBackgroundImageAlignment.center => 'Center',
    CalendarBackgroundImageAlignment.bottom => 'Bottom',
  };
}

class CalendarPreviewTheme extends Equatable {
  const CalendarPreviewTheme({
    required this.backgroundColorValue,
    required this.foregroundColorValue,
    required this.accentColorValue,
    this.backgroundImageUrl,
    this.backgroundImageUrlsByMonth = const <int, String>{},
    this.backgroundImageOpacity = 0.18,
    this.backgroundImageFit = CalendarBackgroundImageFit.cover,
    this.backgroundImageAlignment = CalendarBackgroundImageAlignment.center,
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
  final double backgroundImageOpacity;
  final CalendarBackgroundImageFit backgroundImageFit;
  final CalendarBackgroundImageAlignment backgroundImageAlignment;

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
    double? backgroundImageOpacity,
    CalendarBackgroundImageFit? backgroundImageFit,
    CalendarBackgroundImageAlignment? backgroundImageAlignment,
  }) {
    return CalendarPreviewTheme(
      backgroundColorValue: backgroundColorValue ?? this.backgroundColorValue,
      foregroundColorValue: foregroundColorValue ?? this.foregroundColorValue,
      accentColorValue: accentColorValue ?? this.accentColorValue,
      backgroundImageUrl: backgroundImageUrl ?? this.backgroundImageUrl,
      backgroundImageUrlsByMonth:
          backgroundImageUrlsByMonth ?? this.backgroundImageUrlsByMonth,
      backgroundImageOpacity:
          backgroundImageOpacity ?? this.backgroundImageOpacity,
      backgroundImageFit: backgroundImageFit ?? this.backgroundImageFit,
      backgroundImageAlignment:
          backgroundImageAlignment ?? this.backgroundImageAlignment,
    );
  }

  @override
  List<Object?> get props => [
    backgroundColorValue,
    foregroundColorValue,
    accentColorValue,
    _backgroundImageSignature,
    backgroundImageOpacity,
    backgroundImageFit,
    backgroundImageAlignment,
    _monthlyImagesFingerprint,
  ];

  Object? get _backgroundImageSignature {
    final source = backgroundImageUrl;
    if (source == null) {
      return null;
    }
    return _stringSignature(source);
  }

  int get _monthlyImagesFingerprint {
    final entries = backgroundImageUrlsByMonth.entries.toList(growable: false)
      ..sort((left, right) => left.key.compareTo(right.key));
    return Object.hashAll(
      entries.map(
        (entry) => Object.hash(entry.key, _stringSignature(entry.value)),
      ),
    );
  }

  Object _stringSignature(String value) {
    if (value.length <= 2048) {
      return Object.hash(value.length, value.hashCode);
    }

    return Object.hash(
      value.length,
      _slice(value, 0),
      _slice(value, value.length ~/ 2),
      _slice(value, value.length - 32),
    );
  }

  String _slice(String source, int centerIndex) {
    if (source.isEmpty) {
      return '';
    }
    const window = 24;
    var start = centerIndex - (window ~/ 2);
    if (start < 0) {
      start = 0;
    }
    var end = start + window;
    if (end > source.length) {
      end = source.length;
      start = (end - window).clamp(0, source.length);
    }
    return source.substring(start, end);
  }
}
