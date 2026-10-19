import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'moon_phase_state.dart';

/// How far the lit limb is turned from the textbook "lit on the right".
abstract final class MoonTilt {
  /// Near 20°N the moon lies like a boat: lit toward the lower right while
  /// waxing and the upper left while waning.
  static const double myanmar = 40 * math.pi / 180;
  static const double upright = 0;
}

@immutable
class MoonColors {
  const MoonColors({required this.lit, required this.shade, required this.rim});

  static const light = MoonColors(
    lit: Color(0xFFF2A900),
    shade: Color(0x33767680),
    rim: Color(0x383C3C43),
  );
  static const dark = MoonColors(
    lit: Color(0xFFFFC530),
    shade: Color(0x1AFFFFFF),
    rim: Color(0x33FFFFFF),
  );

  /// White moon on a dark disc, for widgets and photos.
  static const night = MoonColors(
    lit: Color(0xFFF5F1E3),
    shade: Color(0xFF2C2F38),
    rim: Color(0x40FFFFFF),
  );

  final Color lit;
  final Color shade;
  final Color rim;

  @override
  bool operator ==(Object other) =>
      other is MoonColors &&
      other.lit == lit &&
      other.shade == shade &&
      other.rim == rim;

  @override
  int get hashCode => Object.hash(lit, shade, rim);
}

/// The one moon drawing: a lit half disc plus a terminator ellipse whose
/// half-width is r·|1 − 2k| (k = lit fraction). The ellipse bulges toward
/// the lit side for a crescent and away from it for a gibbous moon, so
/// quarters are exact half discs and the lit area always matches k.
class MoonPainter extends CustomPainter {
  const MoonPainter({
    required this.state,
    this.colors = MoonColors.light,
    this.tilt = MoonTilt.myanmar,
    this.texture = false,
  });

  final MoonPhaseState state;
  final MoonColors colors;
  final double tilt;

  /// Faint maria; only worth it from about 48 px.
  final bool texture;

  /// Below this the lit sliver is invisible, above it the gap is.
  static const _threshold = 0.015;

  @override
  void paint(Canvas canvas, Size size) {
    final diameter = size.shortestSide;
    if (diameter <= 0) return;
    final rimWidth = diameter < 16 ? 1.0 : diameter / 32;
    final radius = diameter / 2 - rimWidth / 2;
    final center = size.center(Offset.zero);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.drawCircle(Offset.zero, radius, Paint()..color = colors.shade);

    final lit = litPath(state, radius, tilt: tilt);
    if (lit != null) {
      canvas.drawPath(lit, Paint()..color = colors.lit);
      if (texture) _paintMaria(canvas, lit, radius);
    }

    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..color = colors.rim
        ..style = PaintingStyle.stroke
        ..strokeWidth = rimWidth,
    );
    canvas.restore();
  }

  /// The lit region centred on the origin, or null at new moon.
  static Path? litPath(
    MoonPhaseState state,
    double radius, {
    double tilt = MoonTilt.myanmar,
  }) {
    final k = state.illumination;
    if (k < _threshold) return null;
    final disc = Rect.fromCircle(center: Offset.zero, radius: radius);
    if (k > 1 - _threshold) return Path()..addOval(disc);

    final terminator = radius * (1 - 2 * k).abs();
    // Waxing: lit on the right before tilting. Arcs run top → bottom along
    // the limb, then back up along the terminator.
    final path = Path()
      ..moveTo(0, -radius)
      ..arcToPoint(
        Offset(0, radius),
        radius: Radius.circular(radius),
        clockwise: true,
      )
      ..arcToPoint(
        Offset(0, -radius),
        radius: Radius.elliptical(math.max(terminator, 0.001), radius),
        clockwise: k >= 0.5,
      )
      ..close();

    final transform = Matrix4.rotationZ(tilt);
    if (!state.isWaxing) transform.scaleByDouble(-1, 1, 1, 1);
    return path.transform(transform.storage);
  }

  void _paintMaria(Canvas canvas, Path lit, double radius) {
    canvas.save();
    canvas.clipPath(lit);
    final paint = Paint()..color = colors.shade.withValues(alpha: .16);
    for (final (dx, dy, r) in const [
      (-.28, -.22, .2),
      (.12, -.34, .14),
      (.26, .1, .17),
      (-.06, .3, .12),
      (-.34, .16, .09),
    ]) {
      canvas.drawCircle(Offset(dx * radius, dy * radius), r * radius, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(MoonPainter oldDelegate) =>
      oldDelegate.state != state ||
      oldDelegate.colors != colors ||
      oldDelegate.tilt != tilt ||
      oldDelegate.texture != texture;
}

/// The moon for a date (or a precomputed [state]) at [size].
///
/// Colours follow the theme's brightness unless [colors] is given.
class MoonGlyph extends StatelessWidget {
  MoonGlyph({
    super.key,
    DateTime? date,
    MoonPhaseState? state,
    this.size = 24,
    this.colors,
    this.tilt = MoonTilt.myanmar,
    this.texture,
    this.semanticLabel,
  }) : assert(date != null || state != null, 'Pass a date or a state'),
       state = state ?? MoonPhaseState.evening(date!);

  final MoonPhaseState state;
  final double size;
  final MoonColors? colors;
  final double tilt;
  final bool? texture;

  /// Overrides the default "N% lit, waxing" description.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Semantics(
      image: true,
      label:
          semanticLabel ??
          'Moon ${state.percentLit}% lit, ${state.isWaxing ? 'waxing' : 'waning'}',
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: MoonPainter(
            state: state,
            colors:
                colors ??
                (brightness == Brightness.dark
                    ? MoonColors.dark
                    : MoonColors.light),
            tilt: tilt,
            texture: texture ?? size >= 48,
          ),
        ),
      ),
    );
  }
}
