import 'package:flutter/material.dart';

import 'moon_phase_painter.dart';

/// Widget wrapper for the moon phase painter
class MoonPhaseWidget extends StatelessWidget {
  final int moonPhase;
  final double size;
  final Color? moonColor;
  final Color? shadowColor;
  final bool showGlow;

  const MoonPhaseWidget({
    super.key,
    required this.moonPhase,
    this.size = 80,
    this.moonColor,
    this.shadowColor,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: Colors.transparent,
      child: CustomPaint(
        painter: MoonPhasePainter(
          moonPhase: moonPhase,
          moonColor: moonColor ?? const Color(0xFFF5F5DC),
          shadowColor: shadowColor ?? const Color(0xFF1A1A1A),
          backgroundColor: Colors.transparent,
          showGlow: showGlow,
        ),
      ),
    );
  }
}
