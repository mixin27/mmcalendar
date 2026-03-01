import 'package:equatable/equatable.dart';

/// Normalized layer model used by the reusable overlay editor.
class OverlayEditorItem extends Equatable {
  const OverlayEditorItem({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.scale,
    required this.rotation,
    required this.baseSize,
    this.locked = false,
    this.opacity = 1,
    this.text,
    this.stickerKey,
    this.imageSource,
    this.colorValue = 0xFF1F2937,
  });

  final String id;
  final OverlayEditorItemType type;
  final double x;
  final double y;
  final double scale;
  final double rotation;
  final bool locked;
  final double opacity;
  final String? text;
  final String? stickerKey;
  final String? imageSource;
  final int colorValue;
  final double baseSize;

  OverlayEditorItem copyWith({
    String? id,
    OverlayEditorItemType? type,
    double? x,
    double? y,
    double? scale,
    double? rotation,
    bool? locked,
    double? opacity,
    Object? text = _sentinel,
    Object? stickerKey = _sentinel,
    Object? imageSource = _sentinel,
    int? colorValue,
    double? baseSize,
  }) {
    return OverlayEditorItem(
      id: id ?? this.id,
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      locked: locked ?? this.locked,
      opacity: opacity ?? this.opacity,
      text: text == _sentinel ? this.text : text as String?,
      stickerKey: stickerKey == _sentinel
          ? this.stickerKey
          : stickerKey as String?,
      imageSource: imageSource == _sentinel
          ? this.imageSource
          : imageSource as String?,
      colorValue: colorValue ?? this.colorValue,
      baseSize: baseSize ?? this.baseSize,
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
    locked,
    opacity,
    text,
    stickerKey,
    imageSource,
    colorValue,
    baseSize,
  ];
}

enum OverlayEditorItemType { text, emoji, sticker, image }
