import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Custom painter for drawing moon phases
class MoonPhasePainter extends CustomPainter {
  final int moonPhase; // 0=Waxing, 1=Full, 2=Waning, 3=New
  final Color moonColor;
  final Color shadowColor;
  final Color backgroundColor;
  final bool showGlow;

  MoonPhasePainter({
    required this.moonPhase,
    this.moonColor = const Color(0xFFF5F5DC), // Beige/Cream
    this.shadowColor = const Color(0xFF2C2C2C),
    this.backgroundColor = Colors.transparent,
    this.showGlow = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius =
        math.min(size.width, size.height) / 2.5; // Slightly smaller for padding

    canvas.save();

    // Clip to circle to prevent overflow
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );

    // Draw background (transparent for widget)
    if (backgroundColor != Colors.transparent) {
      final bgPaint = Paint()..color = backgroundColor;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
    }

    // Draw glow effect
    if (showGlow && moonPhase != 3) {
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            moonColor.withValues(alpha: 0.4),
            moonColor.withValues(alpha: 0.2),
            moonColor.withValues(alpha: 0.05),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 0.8, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 1.4));

      canvas.drawCircle(center, radius * 1.4, glowPaint);
    }

    // Draw moon base circle
    final moonPaint = Paint()
      ..color = moonColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius, moonPaint);

    // Draw moon phase shadow
    switch (moonPhase) {
      case 0: // Waxing
        _drawWaxingMoon(canvas, center, radius);
        break;
      case 1: // Full Moon
        _drawCraters(canvas, center, radius);
        break;
      case 2: // Waning
        _drawWaningMoon(canvas, center, radius);
        break;
      case 3: // New Moon
        _drawNewMoon(canvas, center, radius);
        break;
    }

    // Add moon surface texture (except for new moon)
    if (moonPhase != 3) {
      _drawCraters(canvas, center, radius);
    }

    canvas.restore();

    // Add rim highlight
    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius, rimPaint);
  }

  void _drawWaxingMoon(Canvas canvas, Offset center, double radius) {
    final shadowPaint = Paint()
      ..color = shadowColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = Path();
    // Left half shadow
    path.addArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi,
    );

    // Ellipse for 3D effect
    path.addOval(
      Rect.fromCenter(
        center: Offset(center.dx - radius * 0.4, center.dy),
        width: radius * 1.0,
        height: radius * 2,
      ),
    );

    path.fillType = PathFillType.evenOdd;
    canvas.drawPath(path, shadowPaint);
  }

  void _drawWaningMoon(Canvas canvas, Offset center, double radius) {
    final shadowPaint = Paint()
      ..color = shadowColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = Path();
    // Right half shadow
    path.addArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi / 2,
      math.pi,
    );

    // Ellipse for 3D effect
    path.addOval(
      Rect.fromCenter(
        center: Offset(center.dx + radius * 0.4, center.dy),
        width: radius * 1.0,
        height: radius * 2,
      ),
    );

    path.fillType = PathFillType.evenOdd;
    canvas.drawPath(path, shadowPaint);
  }

  void _drawNewMoon(Canvas canvas, Offset center, double radius) {
    final shadowPaint = Paint()
      ..color = shadowColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius, shadowPaint);

    // Subtle rim
    final rimPaint = Paint()
      ..color = moonColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius - 1, rimPaint);
  }

  void _drawCraters(Canvas canvas, Offset center, double radius) {
    final craterPaint = Paint()
      ..color = shadowColor.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Multiple craters for realistic texture
    final craters = [
      (
        Offset(center.dx - radius * 0.35, center.dy - radius * 0.25),
        radius * 0.18,
      ),
      (
        Offset(center.dx + radius * 0.25, center.dy - radius * 0.35),
        radius * 0.12,
      ),
      (
        Offset(center.dx + radius * 0.35, center.dy + radius * 0.20),
        radius * 0.15,
      ),
      (
        Offset(center.dx - radius * 0.15, center.dy + radius * 0.35),
        radius * 0.10,
      ),
      (Offset(center.dx, center.dy - radius * 0.10), radius * 0.08),
    ];

    for (final crater in craters) {
      canvas.drawCircle(crater.$1, crater.$2, craterPaint);

      // Add highlight to crater
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.05)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(crater.$1.dx - crater.$2 * 0.3, crater.$1.dy - crater.$2 * 0.3),
        crater.$2 * 0.5,
        highlightPaint,
      );
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
