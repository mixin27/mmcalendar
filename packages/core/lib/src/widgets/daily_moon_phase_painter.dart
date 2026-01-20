import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Custom painter for realistic moon phases with day-by-day progression
/// moonDay: 0-29 representing the lunar cycle
/// 0 = New Moon
/// 7-8 = First Quarter (Waxing)
/// 14-15 = Full Moon
/// 22-23 = Last Quarter (Waning)
class DailyMoonPhasePainter extends CustomPainter {
  final double moonDay; // 0-29.5 for complete lunar cycle
  final Color moonColor;
  final Color shadowColor;
  final Color backgroundColor;
  final bool showGlow;

  DailyMoonPhasePainter({
    required this.moonDay,
    this.moonColor = const Color(0xFFF5F5DC),
    this.shadowColor = const Color(0xFF1A1A1A),
    this.backgroundColor = Colors.transparent,
    this.showGlow = true,
  });

  /// Get the illumination percentage (0.0 to 1.0)
  double get illumination {
    // Convert day to illumination percentage
    // 0 = 0% (new), 7.4 = 50% (first quarter), 14.8 = 100% (full), 22.1 = 50% (last quarter)
    final phase = (moonDay % 29.53) / 29.53;
    return (1 - math.cos(phase * 2 * math.pi)) / 2;
  }

  /// Check if moon is waxing (growing) or waning (shrinking)
  bool get isWaxing => (moonDay % 29.53) < 14.765;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2.2;

    // Draw glow effect (varies with illumination)
    if (showGlow && illumination > 0.05) {
      _drawGlow(canvas, center, radius);
    }

    // Draw moon with current phase
    _drawMoon(canvas, center, radius);
  }

  void _drawGlow(Canvas canvas, Offset center, double radius) {
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          moonColor.withValues(alpha: 0.5 * illumination),
          moonColor.withValues(alpha: 0.3 * illumination),
          moonColor.withValues(alpha: 0.1 * illumination),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 0.8, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.5));

    canvas.drawCircle(center, radius * 1.5, glowPaint);
  }

  void _drawMoon(Canvas canvas, Offset center, double radius) {
    // Draw dark base (always draw the full dark circle first)
    final shadowPaint = Paint()
      ..color = shadowColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius, shadowPaint);

    // For new moon (very low illumination), just show dark circle
    if (illumination < 0.01) {
      _drawNewMoonRim(canvas, center, radius);
      return;
    }

    // For full moon (very high illumination), show complete bright circle
    if (illumination > 0.99) {
      _drawFullMoon(canvas, center, radius);
      return;
    }

    // Draw the illuminated portion
    final litPaint = Paint()
      ..color = moonColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = Path();

    if (isWaxing) {
      // Waxing: illumination grows from right
      _drawWaxingPhase(canvas, center, radius, path, litPaint);
    } else {
      // Waning: illumination shrinks from left
      _drawWaningPhase(canvas, center, radius, path, litPaint);
    }

    // Add craters on illuminated portion
    _drawPhaseCraters(canvas, center, radius);

    // Add rim highlight
    _drawRim(canvas, center, radius);
  }

  void _drawWaxingPhase(
    Canvas canvas,
    Offset center,
    double radius,
    Path path,
    Paint litPaint,
  ) {
    // Start from top
    path.moveTo(center.dx, center.dy - radius);

    // Draw right edge (always visible during waxing)
    path.arcTo(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start at top
      math.pi, // Sweep through right side to bottom
      false,
    );

    // Calculate terminator curve position
    // illumination 0.0 = curve at right edge (new moon)
    // illumination 0.5 = curve at center (first quarter)
    // illumination 1.0 = curve at left edge (full moon)
    final curveX = center.dx - radius + (2 * radius * illumination);

    // Draw terminator (day/night boundary) as ellipse
    // The curve should be more pronounced near quarter phases
    final ellipseWidth = radius * 2 * (1 - math.cos(illumination * math.pi));

    path.quadraticBezierTo(
      curveX - ellipseWidth / 2,
      center.dy,
      center.dx,
      center.dy - radius,
    );

    path.close();
    canvas.drawPath(path, litPaint);
  }

  void _drawWaningPhase(
    Canvas canvas,
    Offset center,
    double radius,
    Path path,
    Paint litPaint,
  ) {
    // Start from top
    path.moveTo(center.dx, center.dy - radius);

    // Draw left edge (visible during waning)
    path.arcTo(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start at top
      -math.pi, // Sweep through left side to bottom (counterclockwise)
      false,
    );

    // Calculate terminator curve
    // For waning: illumination goes from 1.0 (full) to 0.0 (new)
    // But we're in the waning phase, so we need to invert
    final waningIllumination = 1.0 - ((moonDay % 29.53) - 14.765) / 14.765;
    final curveX = center.dx + radius - (2 * radius * waningIllumination);

    final ellipseWidth =
        radius * 2 * (1 - math.cos(waningIllumination * math.pi));

    path.quadraticBezierTo(
      curveX + ellipseWidth / 2,
      center.dy,
      center.dx,
      center.dy - radius,
    );

    path.close();
    canvas.drawPath(path, litPaint);
  }

  void _drawFullMoon(Canvas canvas, Offset center, double radius) {
    // Draw bright full circle
    final moonPaint = Paint()
      ..color = moonColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius, moonPaint);

    // Add full set of craters
    _drawFullCraters(canvas, center, radius);

    // Add rim highlight
    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius - 1, rimPaint);
  }

  void _drawNewMoonRim(Canvas canvas, Offset center, double radius) {
    final rimPaint = Paint()
      ..color = moonColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius - 1, rimPaint);
  }

  void _drawRim(Canvas canvas, Offset center, double radius) {
    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius - 1, rimPaint);
  }

  void _drawFullCraters(Canvas canvas, Offset center, double radius) {
    final craterPaint = Paint()
      ..color = shadowColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

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
      canvas.drawCircle(crater.$1, crater.$2, craterPaint);

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

  void _drawPhaseCraters(Canvas canvas, Offset center, double radius) {
    final craterPaint = Paint()
      ..color = shadowColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Select craters based on which side is lit
    final List<(Offset, double)> craters;

    if (isWaxing) {
      // Show right-side craters during waxing
      craters = [
        (
          Offset(center.dx + radius * 0.30, center.dy - radius * 0.35),
          radius * 0.15,
        ),
        (
          Offset(center.dx + radius * 0.35, center.dy + radius * 0.25),
          radius * 0.18,
        ),
      ];
    } else {
      // Show left-side craters during waning
      craters = [
        (
          Offset(center.dx - radius * 0.35, center.dy - radius * 0.30),
          radius * 0.20,
        ),
        (
          Offset(center.dx - radius * 0.20, center.dy + radius * 0.40),
          radius * 0.12,
        ),
      ];
    }

    for (final crater in craters) {
      canvas.drawCircle(crater.$1, crater.$2, craterPaint);

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
  bool shouldRepaint(DailyMoonPhasePainter oldDelegate) {
    return oldDelegate.moonDay != moonDay ||
        oldDelegate.moonColor != moonColor ||
        oldDelegate.shadowColor != shadowColor ||
        oldDelegate.showGlow != showGlow;
  }
}

/// Helper widget to display moon phase with label
class DailyMoonPhaseWidget extends StatelessWidget {
  final double moonDay;
  final double size;

  const DailyMoonPhaseWidget({
    super.key,
    required this.moonDay,
    this.size = 200,
  });

  String getPhaseName() {
    final day = moonDay % 29.53;
    if (day < 1) return 'New Moon';
    if (day < 7) return 'Waxing Crescent';
    if (day < 9) return 'First Quarter';
    if (day < 14) return 'Waxing Gibbous';
    if (day < 16) return 'Full Moon';
    if (day < 22) return 'Waning Gibbous';
    if (day < 24) return 'Last Quarter';
    return 'Waning Crescent';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size(size, size),
          painter: DailyMoonPhasePainter(moonDay: moonDay),
        ),
        const SizedBox(height: 8),
        Text(
          getPhaseName(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        Text(
          'Day ${moonDay.toStringAsFixed(1)}',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
