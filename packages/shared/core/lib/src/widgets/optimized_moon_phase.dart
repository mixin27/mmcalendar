import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Optimized moon phase painter for Android home widgets
/// Works with moonPhase (0=Waxing, 1=Full, 2=Waning, 3=New) and fortnightDay (0-15)
class OptimizedMoonPhasePainter extends CustomPainter {
  final int moonPhase;
  final int fortnightDay;
  final Color moonColor;
  final Color shadowColor;
  final bool showGlow;
  final bool isWidget; // Simplified rendering for widgets

  OptimizedMoonPhasePainter({
    required this.moonPhase,
    required this.fortnightDay,
    this.moonColor = const Color(0xFFF5F5DC),
    this.shadowColor = const Color(0xFF1A1A1A),
    this.showGlow = false, // Default off for widgets
    this.isWidget = true, // Default on for widget optimization
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2.2;

    // Optional glow (usually disabled for widgets)
    if (showGlow && moonPhase != 3) {
      _drawGlow(canvas, center, radius);
    }

    // Draw moon based on phase and day
    _drawMoonPhase(canvas, center, radius);
  }

  void _drawGlow(Canvas canvas, Offset center, double radius) {
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          moonColor.withValues(alpha: 0.3),
          moonColor.withValues(alpha: 0.15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.4));

    canvas.drawCircle(center, radius * 1.4, glowPaint);
  }

  void _drawMoonPhase(Canvas canvas, Offset center, double radius) {
    switch (moonPhase) {
      case 0: // Waxing (0-15 days)
        _drawWaxingMoon(canvas, center, radius);
        break;
      case 1: // Full Moon
        _drawFullMoon(canvas, center, radius);
        break;
      case 2: // Waning (0-15 days)
        _drawWaningMoon(canvas, center, radius);
        break;
      case 3: // New Moon
        _drawNewMoon(canvas, center, radius);
        break;
    }
  }

  void _drawWaxingMoon(Canvas canvas, Offset center, double radius) {
    // Dark base
    final shadowPaint = Paint()
      ..color = shadowColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius, shadowPaint);

    // Calculate illumination (0 = new, 15 = full)
    final illumination = fortnightDay / 15.0;

    // Draw lit portion (right side)
    final litPaint = Paint()
      ..color = moonColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = Path();

    // Start at top
    path.moveTo(center.dx, center.dy - radius);

    // Right edge (always lit during waxing)
    path.arcTo(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi,
      false,
    );

    // Terminator line (shadow boundary)
    // Position moves from right edge (day 0) to left edge (day 15)
    final terminatorX = center.dx - radius + (2 * radius * illumination);

    // Calculate ellipse curvature for 3D effect
    // More curved near quarter phases
    final curvature = math.sin(illumination * math.pi);
    final curveOffset = radius * 0.3 * curvature;

    path.quadraticBezierTo(
      terminatorX - curveOffset,
      center.dy,
      center.dx,
      center.dy - radius,
    );

    path.close();
    canvas.drawPath(path, litPaint);

    // Add subtle craters on lit side (only if not too small)
    if (!isWidget || radius > 30) {
      _drawCraters(canvas, center, radius, true);
    }

    // Rim highlight
    _drawRim(canvas, center, radius);
  }

  void _drawWaningMoon(Canvas canvas, Offset center, double radius) {
    // Dark base
    final shadowPaint = Paint()
      ..color = shadowColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius, shadowPaint);

    // Calculate illumination (0 = full, 15 = new)
    final illumination = 1.0 - (fortnightDay / 15.0);

    // Draw lit portion (left side)
    final litPaint = Paint()
      ..color = moonColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = Path();

    // Start at top
    path.moveTo(center.dx, center.dy - radius);

    // Left edge (lit during waning)
    path.arcTo(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      -math.pi,
      false,
    );

    // Terminator line
    final terminatorX = center.dx + radius - (2 * radius * illumination);

    // Curvature
    final curvature = math.sin(illumination * math.pi);
    final curveOffset = radius * 0.3 * curvature;

    path.quadraticBezierTo(
      terminatorX + curveOffset,
      center.dy,
      center.dx,
      center.dy - radius,
    );

    path.close();
    canvas.drawPath(path, litPaint);

    // Add craters on lit side
    if (!isWidget || radius > 30) {
      _drawCraters(canvas, center, radius, false);
    }

    // Rim highlight
    _drawRim(canvas, center, radius);
  }

  void _drawFullMoon(Canvas canvas, Offset center, double radius) {
    // Bright circle
    final moonPaint = Paint()
      ..color = moonColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius, moonPaint);

    // Add craters for detail
    if (!isWidget || radius > 30) {
      _drawFullCraters(canvas, center, radius);
    }

    // Rim
    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isWidget ? 1.0 : 1.5
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius - 1, rimPaint);
  }

  void _drawNewMoon(Canvas canvas, Offset center, double radius) {
    // Completely dark
    final shadowPaint = Paint()
      ..color = shadowColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius, shadowPaint);

    // Very subtle rim
    final rimPaint = Paint()
      ..color = moonColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isWidget ? 1.5 : 2.0
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius - 1, rimPaint);
  }

  void _drawRim(Canvas canvas, Offset center, double radius) {
    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isWidget ? 1.0 : 1.5
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius - 1, rimPaint);
  }

  void _drawFullCraters(Canvas canvas, Offset center, double radius) {
    final craterPaint = Paint()
      ..color = shadowColor.withValues(alpha: isWidget ? 0.15 : 0.2)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Simplified craters for widgets
    final craterSize = isWidget ? radius * 0.12 : radius * 0.15;

    final craters = [
      Offset(center.dx - radius * 0.3, center.dy - radius * 0.25),
      Offset(center.dx + radius * 0.25, center.dy - radius * 0.3),
      Offset(center.dx + radius * 0.3, center.dy + radius * 0.2),
      Offset(center.dx - radius * 0.15, center.dy + radius * 0.35),
    ];

    for (final crater in craters) {
      canvas.drawCircle(crater, craterSize, craterPaint);
    }
  }

  void _drawCraters(
    Canvas canvas,
    Offset center,
    double radius,
    bool rightSide,
  ) {
    final craterPaint = Paint()
      ..color = shadowColor.withValues(alpha: isWidget ? 0.12 : 0.15)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final craterSize = isWidget ? radius * 0.1 : radius * 0.12;

    // Only show craters on the lit side
    final craters = rightSide
        ? [
            // Right side
            Offset(center.dx + radius * 0.25, center.dy - radius * 0.3),
            Offset(center.dx + radius * 0.3, center.dy + radius * 0.2),
          ]
        : [
            // Left side
            Offset(center.dx - radius * 0.3, center.dy - radius * 0.25),
            Offset(center.dx - radius * 0.15, center.dy + radius * 0.35),
          ];

    for (final crater in craters) {
      canvas.drawCircle(crater, craterSize, craterPaint);
    }
  }

  @override
  bool shouldRepaint(OptimizedMoonPhasePainter oldDelegate) {
    return oldDelegate.moonPhase != moonPhase ||
        oldDelegate.fortnightDay != fortnightDay ||
        oldDelegate.moonColor != moonColor ||
        oldDelegate.shadowColor != shadowColor ||
        oldDelegate.showGlow != showGlow;
  }
}

/// Helper to get phase name
String getMoonPhaseName(int moonPhase, int fortnightDay) {
  switch (moonPhase) {
    case 0: // Waxing
      if (fortnightDay < 2) return 'New Moon';
      if (fortnightDay < 6) return 'Waxing Crescent';
      if (fortnightDay < 9) return 'First Quarter';
      if (fortnightDay < 14) return 'Waxing Gibbous';
      return 'Full Moon';
    case 1:
      return 'Full Moon';
    case 2: // Waning
      if (fortnightDay < 2) return 'Full Moon';
      if (fortnightDay < 6) return 'Waning Gibbous';
      if (fortnightDay < 9) return 'Last Quarter';
      if (fortnightDay < 14) return 'Waning Crescent';
      return 'New Moon';
    case 3:
      return 'New Moon';
    default:
      return 'Unknown';
  }
}

/// Helper to get emoji representation
String getMoonPhaseEmoji(int moonPhase, int fortnightDay) {
  switch (moonPhase) {
    case 0:
      if (fortnightDay < 2) return '🌑';
      if (fortnightDay < 6) return '🌒';
      if (fortnightDay < 9) return '🌓';
      if (fortnightDay < 14) return '🌔';
      return '🌕';
    case 1:
      return '🌕';
    case 2:
      if (fortnightDay < 2) return '🌕';
      if (fortnightDay < 6) return '🌖';
      if (fortnightDay < 9) return '🌗';
      if (fortnightDay < 14) return '🌘';
      return '🌑';
    case 3:
      return '🌑';
    default:
      return '🌑';
  }
}
