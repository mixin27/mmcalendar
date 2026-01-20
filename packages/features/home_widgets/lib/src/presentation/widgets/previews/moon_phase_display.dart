import 'package:flutter/material.dart';

import '../moon_phase_widget.dart';

/// Moon Phase Display Widget
class MoonPhaseDisplay extends StatelessWidget {
  final int moonPhase;
  final int fortnightDay;
  final double size;

  const MoonPhaseDisplay({
    super.key,
    required this.moonPhase,
    required this.fortnightDay,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow effect
        Container(
          width: size + 20,
          height: size + 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
          ),
        ),
        // Moon
        Container(
          width: size,
          height: size,
          color: Colors.transparent,
          child: MoonPhaseWidget(
            moonPhase: moonPhase,
            fortnightDay: fortnightDay,
            size: size,
            moonColor: const Color(0xFFF5F5DC),
            shadowColor: const Color(0xFF2C2C2C),
            showGlow: true,
          ),
        ),
      ],
    );
  }
}
