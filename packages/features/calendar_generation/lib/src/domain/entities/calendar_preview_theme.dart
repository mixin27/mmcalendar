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

enum CalendarBorderDesign { soft, solid, bold, doubleLine }

extension CalendarBorderDesignX on CalendarBorderDesign {
  String get label => switch (this) {
    CalendarBorderDesign.soft => 'Soft',
    CalendarBorderDesign.solid => 'Solid',
    CalendarBorderDesign.bold => 'Bold',
    CalendarBorderDesign.doubleLine => 'Double',
  };
}

class CalendarFreeSpaceBox extends Equatable {
  const CalendarFreeSpaceBox({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.fillColorValue = 0x00FFFFFF,
    this.borderColorValue = 0x4D1E293B,
    this.borderWidth = 1.0,
    this.cornerRadius = 6.0,
    this.borderDesign = CalendarBorderDesign.soft,
    this.visible = true,
  });

  final String id;
  final double x;
  final double y;
  final double width;
  final double height;
  final int fillColorValue;
  final int borderColorValue;
  final double borderWidth;
  final double cornerRadius;
  final CalendarBorderDesign borderDesign;
  final bool visible;

  CalendarFreeSpaceBox copyWith({
    String? id,
    double? x,
    double? y,
    double? width,
    double? height,
    int? fillColorValue,
    int? borderColorValue,
    double? borderWidth,
    double? cornerRadius,
    CalendarBorderDesign? borderDesign,
    bool? visible,
  }) {
    return CalendarFreeSpaceBox(
      id: id ?? this.id,
      x: (x ?? this.x).clamp(0.0, 1.0).toDouble(),
      y: (y ?? this.y).clamp(0.0, 1.0).toDouble(),
      width: (width ?? this.width).clamp(0.05, 1.0).toDouble(),
      height: (height ?? this.height).clamp(0.05, 1.0).toDouble(),
      fillColorValue: fillColorValue ?? this.fillColorValue,
      borderColorValue: borderColorValue ?? this.borderColorValue,
      borderWidth: (borderWidth ?? this.borderWidth).clamp(0.0, 6.0).toDouble(),
      cornerRadius: (cornerRadius ?? this.cornerRadius)
          .clamp(0.0, 32.0)
          .toDouble(),
      borderDesign: borderDesign ?? this.borderDesign,
      visible: visible ?? this.visible,
    );
  }

  @override
  List<Object?> get props => [
    id,
    x,
    y,
    width,
    height,
    fillColorValue,
    borderColorValue,
    borderWidth,
    cornerRadius,
    borderDesign,
    visible,
  ];
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
    this.calendarContentOffsetX = 0.0,
    this.calendarContentOffsetY = 0.0,
    this.monthYearFontScale = 1.08,
    this.weekdayFontScale = 1.14,
    this.gridBorderDesign = CalendarBorderDesign.soft,
    this.gridBorderWidth = 0.7,
    this.gridCornerRadius = 4.0,
    this.freeSpaceBoxes = const <CalendarFreeSpaceBox>[
      CalendarFreeSpaceBox(
        id: 'default_box',
        x: 0.0,
        y: 0.0,
        width: 1.0,
        height: 1.0,
        fillColorValue: 0x8AFFFFFF,
        borderColorValue: 0x401E293B,
        borderWidth: 1.0,
        cornerRadius: 6.0,
        borderDesign: CalendarBorderDesign.soft,
      ),
    ],
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
  final double calendarContentOffsetX;
  final double calendarContentOffsetY;
  final double monthYearFontScale;
  final double weekdayFontScale;
  final CalendarBorderDesign gridBorderDesign;
  final double gridBorderWidth;
  final double gridCornerRadius;
  final List<CalendarFreeSpaceBox> freeSpaceBoxes;

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
    double? calendarContentOffsetX,
    double? calendarContentOffsetY,
    double? monthYearFontScale,
    double? weekdayFontScale,
    CalendarBorderDesign? gridBorderDesign,
    double? gridBorderWidth,
    double? gridCornerRadius,
    List<CalendarFreeSpaceBox>? freeSpaceBoxes,
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
      calendarContentOffsetX:
          (calendarContentOffsetX ?? this.calendarContentOffsetX)
              .clamp(-0.5, 0.5)
              .toDouble(),
      calendarContentOffsetY:
          (calendarContentOffsetY ?? this.calendarContentOffsetY)
              .clamp(-0.5, 0.5)
              .toDouble(),
      monthYearFontScale: (monthYearFontScale ?? this.monthYearFontScale)
          .clamp(0.7, 1.8)
          .toDouble(),
      weekdayFontScale: (weekdayFontScale ?? this.weekdayFontScale)
          .clamp(0.7, 1.8)
          .toDouble(),
      gridBorderDesign: gridBorderDesign ?? this.gridBorderDesign,
      gridBorderWidth: (gridBorderWidth ?? this.gridBorderWidth)
          .clamp(0.0, 4.0)
          .toDouble(),
      gridCornerRadius: (gridCornerRadius ?? this.gridCornerRadius)
          .clamp(0.0, 20.0)
          .toDouble(),
      freeSpaceBoxes: freeSpaceBoxes ?? this.freeSpaceBoxes,
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
    calendarContentOffsetX,
    calendarContentOffsetY,
    monthYearFontScale,
    weekdayFontScale,
    gridBorderDesign,
    gridBorderWidth,
    gridCornerRadius,
    _freeSpaceBoxesFingerprint,
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

  int get _freeSpaceBoxesFingerprint => Object.hashAll(freeSpaceBoxes);

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
