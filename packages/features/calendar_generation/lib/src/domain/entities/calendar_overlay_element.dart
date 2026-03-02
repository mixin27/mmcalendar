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
    this.fontWeightValue = 700,
    this.italic = false,
    this.letterSpacing = 0,
    this.backgroundColorValue,
    this.shadowColorValue,
    this.shadowBlur = 0,
    this.shadowOffsetX = 0,
    this.shadowOffsetY = 0,
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
  final int fontWeightValue;
  final bool italic;
  final double letterSpacing;
  final int? backgroundColorValue;
  final int? shadowColorValue;
  final double shadowBlur;
  final double shadowOffsetX;
  final double shadowOffsetY;
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
    Object? text = _sentinel,
    Object? stickerKey = _sentinel,
    Object? imageSource = _sentinel,
    Object? backgroundColorValue = _sentinel,
    Object? shadowColorValue = _sentinel,
    int? colorValue,
    int? fontWeightValue,
    bool? italic,
    double? letterSpacing,
    double? shadowBlur,
    double? shadowOffsetX,
    double? shadowOffsetY,
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
      text: text == _sentinel ? this.text : text as String?,
      stickerKey: stickerKey == _sentinel
          ? this.stickerKey
          : stickerKey as String?,
      imageSource: imageSource == _sentinel
          ? this.imageSource
          : imageSource as String?,
      backgroundColorValue: backgroundColorValue == _sentinel
          ? this.backgroundColorValue
          : backgroundColorValue as int?,
      shadowColorValue: shadowColorValue == _sentinel
          ? this.shadowColorValue
          : shadowColorValue as int?,
      colorValue: colorValue ?? this.colorValue,
      fontWeightValue: fontWeightValue ?? this.fontWeightValue,
      italic: italic ?? this.italic,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      shadowBlur: shadowBlur ?? this.shadowBlur,
      shadowOffsetX: shadowOffsetX ?? this.shadowOffsetX,
      shadowOffsetY: shadowOffsetY ?? this.shadowOffsetY,
      baseSize: baseSize ?? this.baseSize,
      opacity: opacity ?? this.opacity,
      locked: locked ?? this.locked,
    );
  }

  static const Object _sentinel = Object();

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
    fontWeightValue,
    italic,
    letterSpacing,
    backgroundColorValue,
    shadowColorValue,
    shadowBlur,
    shadowOffsetX,
    shadowOffsetY,
    baseSize,
    opacity,
    locked,
  ];
}
