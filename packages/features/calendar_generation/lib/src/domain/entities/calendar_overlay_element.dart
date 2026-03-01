import 'package:equatable/equatable.dart';

enum CalendarOverlayElementType { text, emoji, sticker, image }

class CalendarOverlayElement extends Equatable {
  const CalendarOverlayElement({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.scale,
    required this.rotation,
    this.text,
    this.stickerKey,
    this.imageSource,
    this.colorValue = 0xFF1F2937,
    this.baseSize = 28,
    this.opacity = 1.0,
    this.locked = false,
  });

  final String id;
  final CalendarOverlayElementType type;
  final double x;
  final double y;
  final double scale;
  final double rotation;
  final String? text;
  final String? stickerKey;
  final String? imageSource;
  final int colorValue;
  final double baseSize;
  final double opacity;
  final bool locked;

  CalendarOverlayElement copyWith({
    String? id,
    CalendarOverlayElementType? type,
    double? x,
    double? y,
    double? scale,
    double? rotation,
    String? text,
    String? stickerKey,
    String? imageSource,
    int? colorValue,
    double? baseSize,
    double? opacity,
    bool? locked,
  }) {
    return CalendarOverlayElement(
      id: id ?? this.id,
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      text: text ?? this.text,
      stickerKey: stickerKey ?? this.stickerKey,
      imageSource: imageSource ?? this.imageSource,
      colorValue: colorValue ?? this.colorValue,
      baseSize: baseSize ?? this.baseSize,
      opacity: opacity ?? this.opacity,
      locked: locked ?? this.locked,
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    x,
    y,
    scale,
    rotation,
    text,
    stickerKey,
    imageSource,
    colorValue,
    baseSize,
    opacity,
    locked,
  ];
}
