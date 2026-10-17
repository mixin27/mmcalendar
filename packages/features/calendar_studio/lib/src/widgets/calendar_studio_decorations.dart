import 'package:flutter/widgets.dart';
import 'package:shared_motifs/shared_motifs.dart';

import '../models/calendar_studio_document.dart';

/// Decoration blocks for the round-2 presets, drawn by the shared
/// [MotifPainter]. Reads `style.color`, `style.accent` and `style.opacity`.
abstract final class CalendarStudioDecorations {
  static const kinds = {
    'ringsLinked',
    'frame',
    'paperLantern',
    'halftoneBurst',
    'leafSprig',
    'crescent',
    'ghostWisp',
    'horizonWave',
    'diamondWeave',
    'starField',
    'zodiacWheel',
    'stupa',
    'sunRays',
    'steamCurl',
    'compassStar',
  };

  /// The decoration for [block], or null when its kind isn't one of [kinds].
  static Widget? build(CalendarStudioBlock block) {
    final kind = block.content['kind'];
    if (kind is! String || !kinds.contains(kind)) return null;
    final opacity = ((block.style['opacity'] as num?)?.toDouble() ?? 1).clamp(
      0.0,
      1.0,
    );
    Color read(String key, int fallback) =>
        Color(block.style[key] as int? ?? fallback).withValues(
          alpha: Color(block.style[key] as int? ?? fallback).a * opacity,
        );
    return CustomPaint(
      painter: MotifPainter(
        kind,
        color: read('color', 0xFF15201D),
        accent: read('accent', 0xFFB98A25),
        seed: block.content['seed'] as int? ?? 7,
        avoid: _avoidRect(block.content['avoid']),
      ),
      size: Size.infinite,
    );
  }

  static Rect? _avoidRect(Object? value) {
    if (value is! List || value.length != 4) return null;
    final v = [for (final item in value) (item as num).toDouble()];
    return Rect.fromLTWH(v[0], v[1], v[2], v[3]);
  }
}
