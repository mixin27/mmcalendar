import 'package:core/src/extensions/context_extension.dart';
import 'package:flutter/material.dart';

class MoonPhaseIndicator extends StatelessWidget {
  final int moonPhase; // 0=waxing, 1=full, 2=waning, 3=new
  final int fortnightDay;
  final double size;
  final bool showLabel;
  final bool showDay;
  final String Function(int mp)? getMoonPhaseName;
  final String Function(int fd)? getFortnightDay;

  const MoonPhaseIndicator({
    super.key,
    required this.moonPhase,
    required this.fortnightDay,
    this.size = 80,
    this.showLabel = true,
    this.showDay = true,
    this.getMoonPhaseName,
    this.getFortnightDay,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Moon visual
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: _getMoonGradient(),
            boxShadow: [
              BoxShadow(
                color: _getMoonColor().withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: CustomPaint(
            painter: MoonPhasePainter(
              moonPhase: moonPhase,
              fortnightDay: fortnightDay,
            ),
          ),
        ),

        if (showLabel || showDay) ...[
          const SizedBox(height: 12),

          // Moon phase name
          if (showLabel)
            Text(
              getMoonPhaseName?.call(moonPhase) ?? _getMoonPhaseName(),
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: _getMoonColor(),
              ),
            ),

          // Fortnight day
          if (showDay && !(moonPhase == 1 || moonPhase == 3)) ...[
            const SizedBox(height: 4),
            Text(
              getFortnightDay?.call(fortnightDay) ?? 'Day $fortnightDay',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ],
    );
  }

  LinearGradient _getMoonGradient() {
    switch (moonPhase) {
      case 0: // Waxing
        return LinearGradient(
          colors: [const Color(0xFFFFF9C4), const Color(0xFFFFE082)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 1: // Full Moon
        return LinearGradient(
          colors: [const Color(0xFFFFE082), const Color(0xFFFFD54F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 2: // Waning
        return LinearGradient(
          colors: [const Color(0xFFE1BEE7), const Color(0xFFCE93D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 3: // New Moon
        return LinearGradient(
          colors: [const Color(0xFF9FA8DA), const Color(0xFF7986CB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return LinearGradient(colors: [Colors.grey, Colors.grey.shade400]);
    }
  }

  Color _getMoonColor() {
    switch (moonPhase) {
      case 0:
        return const Color(0xFFF57F17);
      case 1:
        return const Color(0xFFFF6F00);
      case 2:
        return const Color(0xFF6A1B9A);
      case 3:
        return const Color(0xFF283593);
      default:
        return Colors.grey;
    }
  }

  String _getMoonPhaseName() {
    switch (moonPhase) {
      case 0:
        return 'Waxing';
      case 1:
        return 'Full Moon';
      case 2:
        return 'Waning';
      case 3:
        return 'New Moon';
      default:
        return 'Unknown';
    }
  }
}

class CompactMoonPhaseIndicator extends StatelessWidget {
  final int moonPhase;
  final int fortnightDay;
  final double size;

  const CompactMoonPhaseIndicator({
    super.key,
    required this.moonPhase,
    required this.fortnightDay,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getMoonColor().withValues(alpha: 0.2),
        border: Border.all(color: _getMoonColor(), width: 2),
      ),
      child: Center(
        child: Text(
          _getMoonIcon(),
          style: TextStyle(fontSize: size * 0.5, color: _getMoonColor()),
        ),
      ),
    );
  }

  Color _getMoonColor() {
    switch (moonPhase) {
      case 0:
        return const Color(0xFFF57F17);
      case 1:
        return const Color(0xFFFF6F00);
      case 2:
        return const Color(0xFF6A1B9A);
      case 3:
        return const Color(0xFF283593);
      default:
        return Colors.grey;
    }
  }

  String _getMoonIcon() {
    switch (moonPhase) {
      case 0:
        return '☽';
      case 1:
        return '●';
      case 2:
        return '☾';
      case 3:
        return '○';
      default:
        return '';
    }
  }
}

class MoonPhasePainter extends CustomPainter {
  final int moonPhase;
  final int fortnightDay;

  MoonPhasePainter({required this.moonPhase, required this.fortnightDay});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Save canvas state
    canvas.save();

    // Clip to circle to prevent overflow
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );

    // Draw moon surface
    final surfacePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, surfacePaint);

    // Draw shadow based on phase
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    if (moonPhase == 0) {
      // Waxing - shadow on left
      _drawWaxingShadow(canvas, center, radius, fortnightDay, shadowPaint);
    } else if (moonPhase == 2) {
      // Waning - shadow on right
      _drawWaningShadow(canvas, center, radius, fortnightDay, shadowPaint);
    } else if (moonPhase == 3) {
      // New moon - completely dark
      canvas.drawCircle(center, radius, shadowPaint);
    }
    // Full moon has no shadow (moonPhase == 1)

    // Draw crater marks for realism
    _drawCraters(canvas, center, radius);

    // Restore canvas before drawing glow ring
    canvas.restore();

    // Draw glow ring (outside the clip)
    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, glowPaint);
  }

  void _drawWaxingShadow(
    Canvas canvas,
    Offset center,
    double radius,
    int day,
    Paint shadowPaint,
  ) {
    // Calculate illumination percentage (0 = new moon, 15 = full moon)
    final illumination = day / 15.0;

    // Create shadow path using a more accurate crescent shape
    final path = Path();

    // Define the shadow arc on the left side
    final shadowRadius = radius * (1 - illumination);

    // Create an ellipse for the shadow
    final rect = Rect.fromCenter(
      center: Offset(center.dx - radius + shadowRadius, center.dy),
      width: shadowRadius * 2,
      height: radius * 2,
    );

    path.addOval(rect);
    canvas.drawPath(path, shadowPaint);
  }

  void _drawWaningShadow(
    Canvas canvas,
    Offset center,
    double radius,
    int day,
    Paint shadowPaint,
  ) {
    // Calculate shadow percentage (0 = full moon, 15 = new moon)
    final shadowAmount = day / 15.0;

    // Create shadow path using a more accurate crescent shape
    final path = Path();

    // Define the shadow arc on the right side
    final shadowRadius = radius * shadowAmount;

    // Create an ellipse for the shadow
    final rect = Rect.fromCenter(
      center: Offset(center.dx + radius - shadowRadius, center.dy),
      width: shadowRadius * 2,
      height: radius * 2,
    );

    path.addOval(rect);
    canvas.drawPath(path, shadowPaint);
  }

  void _drawCraters(Canvas canvas, Offset center, double radius) {
    final craterPaint = Paint()
      ..color = Colors.grey.shade300.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    // Add a few crater marks for detail
    final craters = [
      Offset(center.dx + radius * 0.2, center.dy - radius * 0.3),
      Offset(center.dx - radius * 0.3, center.dy + radius * 0.2),
      Offset(center.dx + radius * 0.1, center.dy + radius * 0.4),
    ];

    for (var crater in craters) {
      canvas.drawCircle(crater, radius * 0.1, craterPaint);
    }
  }

  @override
  bool shouldRepaint(MoonPhasePainter oldDelegate) {
    return oldDelegate.moonPhase != moonPhase ||
        oldDelegate.fortnightDay != fortnightDay;
  }
}
