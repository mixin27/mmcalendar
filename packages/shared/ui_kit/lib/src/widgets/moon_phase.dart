import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../extensions/context_extension.dart';

const double _lunarCycleDays = 29.53;
const double _fullMoonCycleDay = _lunarCycleDays / 2;

@immutable
class MoonPhaseCycleMetrics {
  final double cycleDay;
  final double phase;
  final double illumination;
  final bool isWaxing;

  const MoonPhaseCycleMetrics._({
    required this.cycleDay,
    required this.phase,
    required this.illumination,
    required this.isWaxing,
  });

  factory MoonPhaseCycleMetrics.fromMyanmarData({
    required int moonPhase,
    required int fortnightDay,
  }) {
    final normalizedPhase = moonPhase.clamp(0, 3);
    final normalizedFortnightDay = fortnightDay.clamp(0, 15).toDouble();

    double cycleDay;
    switch (normalizedPhase) {
      case 0:
        cycleDay = normalizedFortnightDay;
        break;
      case 1:
        cycleDay = _fullMoonCycleDay;
        break;
      case 2:
        cycleDay = _fullMoonCycleDay + normalizedFortnightDay;
        break;
      case 3:
        cycleDay = 0;
        break;
      default:
        cycleDay = normalizedFortnightDay;
    }

    final normalizedCycleDay = cycleDay % _lunarCycleDays;
    final phase = normalizedCycleDay / _lunarCycleDays;
    final illumination = ((1 - math.cos(phase * 2 * math.pi)) / 2).clamp(
      0.0,
      1.0,
    );

    return MoonPhaseCycleMetrics._(
      cycleDay: normalizedCycleDay,
      phase: phase,
      illumination: illumination,
      isWaxing: normalizedCycleDay < _fullMoonCycleDay,
    );
  }
}

class MoonPhasePainter extends CustomPainter {
  final int moonPhase;
  final int fortnightDay;
  final Color moonColor;
  final Color shadowColor;
  final bool showGlow;
  final bool showTexture;
  final bool widgetMode;

  MoonPhasePainter({
    required this.moonPhase,
    required this.fortnightDay,
    this.moonColor = const Color(0xFFF5F5DC),
    this.shadowColor = const Color(0xFF1A1A1A),
    this.showGlow = false,
    this.showTexture = true,
    this.widgetMode = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final diameter = math.min(size.width, size.height);
    if (diameter <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = diameter / 2;
    final metrics = MoonPhaseCycleMetrics.fromMyanmarData(
      moonPhase: moonPhase,
      fortnightDay: fortnightDay,
    );

    if (showGlow && metrics.illumination > 0.03) {
      _drawGlow(canvas, center, radius, metrics.illumination);
    }

    final darkPaint = Paint()
      ..color = shadowColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(center, radius, darkPaint);

    if (metrics.illumination >= 0.99) {
      _drawFullMoon(canvas, center, radius);
      return;
    }

    if (metrics.illumination <= 0.01) {
      _drawNewMoonRim(canvas, center, radius);
      return;
    }

    _drawIlluminatedPhase(canvas, center, radius, metrics);
    _drawRim(canvas, center, radius);
  }

  void _drawGlow(
    Canvas canvas,
    Offset center,
    double radius,
    double illumination,
  ) {
    final glowRadiusMultiplier = widgetMode ? 1.3 : 1.45;
    final glowPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              moonColor.withValues(alpha: 0.28 * illumination),
              moonColor.withValues(alpha: 0.14 * illumination),
              Colors.transparent,
            ],
            stops: const [0, 0.58, 1],
          ).createShader(
            Rect.fromCircle(
              center: center,
              radius: radius * glowRadiusMultiplier,
            ),
          );

    canvas.drawCircle(center, radius * glowRadiusMultiplier, glowPaint);
  }

  void _drawFullMoon(Canvas canvas, Offset center, double radius) {
    final litPaint = Paint()
      ..color = moonColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(center, radius, litPaint);

    if (showTexture) {
      _drawCraters(
        canvas,
        center,
        radius,
        craters: [
          (
            Offset(center.dx - radius * 0.30, center.dy - radius * 0.25),
            radius * 0.16,
          ),
          (
            Offset(center.dx + radius * 0.24, center.dy - radius * 0.32),
            radius * 0.13,
          ),
          (
            Offset(center.dx + radius * 0.32, center.dy + radius * 0.18),
            radius * 0.14,
          ),
          (
            Offset(center.dx - radius * 0.14, center.dy + radius * 0.34),
            radius * 0.10,
          ),
        ],
      );
    }

    _drawRim(canvas, center, radius, alpha: 0.42);
  }

  void _drawIlluminatedPhase(
    Canvas canvas,
    Offset center,
    double radius,
    MoonPhaseCycleMetrics metrics,
  ) {
    final litPaint = Paint()
      ..color = moonColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final maskPaint = Paint()
      ..color = shadowColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final clipPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    // Draw a full bright moon, then subtract a shifted dark mask.
    // This keeps the shape progression smooth and monotonic day-to-day.
    canvas.save();
    canvas.clipPath(clipPath);
    canvas.drawCircle(center, radius, litPaint);

    final maskShift =
        (metrics.isWaxing ? -1.0 : 1.0) * (2 * radius * metrics.illumination);
    final maskCenter = Offset(center.dx + maskShift, center.dy);
    canvas.drawCircle(maskCenter, radius, maskPaint);
    canvas.restore();

    if (!showTexture || metrics.illumination < 0.12) {
      return;
    }

    _drawCraters(
      canvas,
      center,
      radius,
      craters: metrics.isWaxing
          ? [
              (
                Offset(center.dx + radius * 0.26, center.dy - radius * 0.30),
                radius * 0.12,
              ),
              (
                Offset(center.dx + radius * 0.30, center.dy + radius * 0.20),
                radius * 0.13,
              ),
            ]
          : [
              (
                Offset(center.dx - radius * 0.30, center.dy - radius * 0.25),
                radius * 0.13,
              ),
              (
                Offset(center.dx - radius * 0.20, center.dy + radius * 0.32),
                radius * 0.10,
              ),
            ],
    );
  }

  void _drawCraters(
    Canvas canvas,
    Offset center,
    double radius, {
    required List<(Offset, double)> craters,
  }) {
    final craterPaint = Paint()
      ..color = shadowColor.withValues(alpha: widgetMode ? 0.14 : 0.18)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    for (final crater in craters) {
      canvas.drawCircle(crater.$1, crater.$2, craterPaint);
      if (widgetMode) continue;

      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;
      canvas.drawCircle(
        Offset(
          crater.$1.dx - crater.$2 * 0.30,
          crater.$1.dy - crater.$2 * 0.30,
        ),
        crater.$2 * 0.42,
        highlightPaint,
      );
    }
  }

  void _drawRim(Canvas canvas, Offset center, double radius, {double? alpha}) {
    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: alpha ?? 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = widgetMode ? 1.0 : 1.35
      ..isAntiAlias = true;
    canvas.drawCircle(center, radius - 0.8, rimPaint);
  }

  void _drawNewMoonRim(Canvas canvas, Offset center, double radius) {
    final rimPaint = Paint()
      ..color = moonColor.withValues(alpha: widgetMode ? 0.2 : 0.17)
      ..style = PaintingStyle.stroke
      ..strokeWidth = widgetMode ? 1.2 : 1.8
      ..isAntiAlias = true;
    canvas.drawCircle(center, radius - 1, rimPaint);
  }

  @override
  bool shouldRepaint(MoonPhasePainter oldDelegate) {
    return oldDelegate.moonPhase != moonPhase ||
        oldDelegate.fortnightDay != fortnightDay ||
        oldDelegate.moonColor != moonColor ||
        oldDelegate.shadowColor != shadowColor ||
        oldDelegate.showGlow != showGlow ||
        oldDelegate.showTexture != showTexture ||
        oldDelegate.widgetMode != widgetMode;
  }
}

class MoonPhaseVisual extends StatelessWidget {
  final int moonPhase;
  final int fortnightDay;
  final double size;
  final Color moonColor;
  final Color shadowColor;
  final bool showGlow;
  final bool showTexture;
  final bool widgetMode;

  const MoonPhaseVisual({
    super.key,
    required this.moonPhase,
    required this.fortnightDay,
    this.size = 80,
    this.moonColor = const Color(0xFFF5F5DC),
    this.shadowColor = const Color(0xFF1A1A1A),
    this.showGlow = false,
    this.showTexture = true,
    this.widgetMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: MoonPhasePainter(
          moonPhase: moonPhase,
          fortnightDay: fortnightDay,
          moonColor: moonColor,
          shadowColor: shadowColor,
          showGlow: showGlow,
          showTexture: showTexture,
          widgetMode: widgetMode,
        ),
      ),
    );
  }
}

class MoonPhaseIndicator extends StatelessWidget {
  final int moonPhase;
  final int fortnightDay;
  final double size;
  final bool showLabel;
  final bool showDay;
  final String Function(int moonPhase)? getMoonPhaseName;
  final String Function(int fortnightDay)? getFortnightDay;

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
    final phaseColor = _getMoonColor();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: _getMoonGradient(),
            boxShadow: [
              BoxShadow(
                color: phaseColor.withValues(alpha: 0.28),
                blurRadius: size * 0.18,
                spreadRadius: size * 0.04,
              ),
            ],
          ),
          child: Center(
            child: MoonPhaseVisual(
              moonPhase: moonPhase,
              fortnightDay: fortnightDay,
              size: size,
              showGlow: true,
              showTexture: true,
            ),
          ),
        ),
        if (showLabel || showDay) ...[
          const SizedBox(height: 12),
          if (showLabel)
            Text(
              getMoonPhaseName?.call(moonPhase) ?? _getMoonPhaseName(),
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: phaseColor,
              ),
              textAlign: TextAlign.center,
            ),
          if (showDay && moonPhase != 1 && moonPhase != 3) ...[
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
      case 0:
        return const LinearGradient(
          colors: [Color(0xFFFFF9C4), Color(0xFFFFE082)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 1:
        return const LinearGradient(
          colors: [Color(0xFFFFE082), Color(0xFFFFD54F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 2:
        return const LinearGradient(
          colors: [Color(0xFFE1BEE7), Color(0xFFCE93D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 3:
        return const LinearGradient(
          colors: [Color(0xFF9FA8DA), Color(0xFF7986CB)],
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
    final accentColor = _getAccentColor(moonPhase);
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accentColor.withValues(alpha: 0.14),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.50),
          width: size < 18 ? 1 : 1.5,
        ),
      ),
      child: MoonPhaseVisual(
        moonPhase: moonPhase,
        fortnightDay: fortnightDay,
        size: size * 0.76,
        showGlow: false,
        showTexture: size >= 16,
        widgetMode: true,
      ),
    );
  }

  Color _getAccentColor(int phase) {
    switch (phase) {
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
}
