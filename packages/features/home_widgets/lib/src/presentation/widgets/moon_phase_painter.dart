import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Custom painter for realistic moon phases
class MoonPhasePainter extends CustomPainter {
  final int moonPhase; // 0=Waxing, 1=Full, 2=Waning, 3=New
  final Color moonColor;
  final Color shadowColor;
  final Color backgroundColor;
  final bool showGlow;

  MoonPhasePainter({
    required this.moonPhase,
    this.moonColor = const Color(0xFFF5F5DC),
    this.shadowColor = const Color(0xFF1A1A1A),
    this.backgroundColor = Colors.transparent,
    this.showGlow = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2.2;

    // Draw glow effect (except for new moon)
    if (showGlow && moonPhase != 3) {
      _drawGlow(canvas, center, radius);
    }

    // Draw moon based on phase
    switch (moonPhase) {
      case 0: // Waxing (right side lit)
        _drawWaxingMoon(canvas, center, radius);
        break;
      case 1: // Full Moon
        _drawFullMoon(canvas, center, radius);
        break;
      case 2: // Waning (left side lit)
        _drawWaningMoon(canvas, center, radius);
        break;
      case 3: // New Moon (all dark)
        _drawNewMoon(canvas, center, radius);
        break;
    }
  }

  void _drawGlow(Canvas canvas, Offset center, double radius) {
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          moonColor.withValues(alpha: 0.5),
          moonColor.withValues(alpha: 0.3),
          moonColor.withValues(alpha: 0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 0.8, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.5));

    canvas.drawCircle(center, radius * 1.5, glowPaint);
  }

  void _drawFullMoon(Canvas canvas, Offset center, double radius) {
    // Draw main moon circle
    final moonPaint = Paint()
      ..color = moonColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius, moonPaint);

    // Add craters for texture
    _drawCraters(canvas, center, radius, moonColor, shadowColor);

    // Add rim highlight
    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius - 1, rimPaint);
  }

  void _drawWaxingMoon(Canvas canvas, Offset center, double radius) {
    // Waxing = Right side is lit (crescent to full on right)

    // Draw dark left half first
    final shadowPaint = Paint()
      ..color = shadowColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius, shadowPaint);

    // Draw lit right side with 3D curve
    final litPaint = Paint()
      ..color = moonColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = Path();

    // Create crescent shape - lit on right side
    // Start from top
    path.moveTo(center.dx, center.dy - radius);

    // Curve along right edge (always lit)
    path.arcTo(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start at top
      math.pi, // Sweep through right side
      false,
    );

    // Draw curved shadow boundary (waxing crescent to gibbous)
    // For waxing crescent, curve bows to the left
    final curveControlX = center.dx - radius * 0.5; // Curve depth

    path.quadraticBezierTo(
      curveControlX,
      center.dy,
      center.dx,
      center.dy - radius,
    );

    path.close();
    canvas.drawPath(path, litPaint);

    // Add craters on lit side only
    _drawPartialCraters(canvas, center, radius, moonColor, shadowColor, true);

    // Add rim
    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius - 1, rimPaint);
  }

  void _drawWaningMoon(Canvas canvas, Offset center, double radius) {
    // Waning = Left side is lit (full to crescent on left)

    // Draw dark base
    final shadowPaint = Paint()
      ..color = shadowColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius, shadowPaint);

    // Draw lit left side
    final litPaint = Paint()
      ..color = moonColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = Path();

    // Create crescent shape - lit on left side
    path.moveTo(center.dx, center.dy - radius);

    // Curve along left edge (always lit)
    path.arcTo(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start at top
      -math.pi, // Sweep through left side (negative = counterclockwise)
      false,
    );

    // Draw curved shadow boundary
    final curveControlX = center.dx + radius * 0.5; // Curve to right

    path.quadraticBezierTo(
      curveControlX,
      center.dy,
      center.dx,
      center.dy - radius,
    );

    path.close();
    canvas.drawPath(path, litPaint);

    // Add craters on lit side
    _drawPartialCraters(canvas, center, radius, moonColor, shadowColor, false);

    // Add rim
    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius - 1, rimPaint);
  }

  void _drawNewMoon(Canvas canvas, Offset center, double radius) {
    // Draw completely dark moon
    final shadowPaint = Paint()
      ..color = shadowColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius, shadowPaint);

    // Add very subtle rim
    final rimPaint = Paint()
      ..color = moonColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius - 1, rimPaint);
  }

  void _drawCraters(
    Canvas canvas,
    Offset center,
    double radius,
    Color baseColor,
    Color darkColor,
  ) {
    final craterPaint = Paint()
      ..color = darkColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Define crater positions and sizes (relative to radius)
    final craters = [
      (
        Offset(center.dx - radius * 0.35, center.dy - radius * 0.30),
        radius * 0.20,
      ),
      (
        Offset(center.dx + radius * 0.30, center.dy - radius * 0.35),
        radius * 0.15,
      ),
      (
        Offset(center.dx + radius * 0.35, center.dy + radius * 0.25),
        radius * 0.18,
      ),
      (
        Offset(center.dx - radius * 0.20, center.dy + radius * 0.40),
        radius * 0.12,
      ),
      (
        Offset(center.dx + radius * 0.05, center.dy - radius * 0.10),
        radius * 0.10,
      ),
    ];

    for (final crater in craters) {
      // Draw crater shadow
      canvas.drawCircle(crater.$1, crater.$2, craterPaint);

      // Add highlight to crater rim
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.1)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      final highlightOffset = Offset(
        crater.$1.dx - crater.$2 * 0.3,
        crater.$1.dy - crater.$2 * 0.3,
      );
      canvas.drawCircle(highlightOffset, crater.$2 * 0.4, highlightPaint);
    }
  }

  void _drawPartialCraters(
    Canvas canvas,
    Offset center,
    double radius,
    Color baseColor,
    Color darkColor,
    bool rightSide, // true for waxing (right lit), false for waning (left lit)
  ) {
    final craterPaint = Paint()
      ..color = darkColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Only draw craters on the lit side
    final craters = rightSide
        ? [
            // Right side craters for waxing
            (
              Offset(center.dx + radius * 0.30, center.dy - radius * 0.35),
              radius * 0.15,
            ),
            (
              Offset(center.dx + radius * 0.35, center.dy + radius * 0.25),
              radius * 0.18,
            ),
          ]
        : [
            // Left side craters for waning
            (
              Offset(center.dx - radius * 0.35, center.dy - radius * 0.30),
              radius * 0.20,
            ),
            (
              Offset(center.dx - radius * 0.20, center.dy + radius * 0.40),
              radius * 0.12,
            ),
          ];

    for (final crater in craters) {
      canvas.drawCircle(crater.$1, crater.$2, craterPaint);

      // Highlight
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      final highlightOffset = Offset(
        crater.$1.dx - crater.$2 * 0.3,
        crater.$1.dy - crater.$2 * 0.3,
      );
      canvas.drawCircle(highlightOffset, crater.$2 * 0.4, highlightPaint);
    }
  }

  @override
  bool shouldRepaint(MoonPhasePainter oldDelegate) {
    return oldDelegate.moonPhase != moonPhase ||
        oldDelegate.moonColor != moonColor ||
        oldDelegate.shadowColor != shadowColor ||
        oldDelegate.showGlow != showGlow;
  }
}
