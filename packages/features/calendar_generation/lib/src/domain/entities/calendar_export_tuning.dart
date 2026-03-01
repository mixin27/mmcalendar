import 'package:equatable/equatable.dart';

class CalendarExportTuning extends Equatable {
  const CalendarExportTuning({
    required this.dpi,
    required this.jpegQuality,
    required this.targetSizeKb,
    required this.enableAdaptiveCompression,
  });

  final int dpi;
  final int jpegQuality;
  final int targetSizeKb;
  final bool enableAdaptiveCompression;

  static const int minDpi = 96;
  static const int maxDpi = 600;
  static const int minJpegQuality = 55;
  static const int maxJpegQuality = 100;
  static const int minTargetSizeKb = 256;
  static const int maxTargetSizeKb = 8192;

  factory CalendarExportTuning.defaults() {
    return const CalendarExportTuning(
      dpi: 300,
      jpegQuality: 88,
      targetSizeKb: 2600,
      enableAdaptiveCompression: true,
    );
  }

  CalendarExportTuning copyWith({
    int? dpi,
    int? jpegQuality,
    int? targetSizeKb,
    bool? enableAdaptiveCompression,
  }) {
    return CalendarExportTuning(
      dpi: (dpi ?? this.dpi).clamp(minDpi, maxDpi).toInt(),
      jpegQuality: (jpegQuality ?? this.jpegQuality)
          .clamp(minJpegQuality, maxJpegQuality)
          .toInt(),
      targetSizeKb: (targetSizeKb ?? this.targetSizeKb)
          .clamp(minTargetSizeKb, maxTargetSizeKb)
          .toInt(),
      enableAdaptiveCompression:
          enableAdaptiveCompression ?? this.enableAdaptiveCompression,
    );
  }

  @override
  List<Object?> get props => [
    dpi,
    jpegQuality,
    targetSizeKb,
    enableAdaptiveCompression,
  ];
}
