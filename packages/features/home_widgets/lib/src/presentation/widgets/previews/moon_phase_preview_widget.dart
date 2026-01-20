import 'package:flutter/material.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';

import 'moon_phase_display.dart';

/// Moon Phase Widget Preview
class MoonPhasePreviewWidget extends StatelessWidget {
  const MoonPhasePreviewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    MyanmarCalendar.setLanguage(Language.myanmar);
    final myanmarDate = MyanmarCalendar.fromWestern(
      today.year,
      today.month,
      today.day,
    );

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D1B2A), Color(0xFF1B263B), Color(0xFF0D1B2A)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Myanmar Date (compact)
          Text(
            myanmarDate.formatMyanmar("&M &P &ff"),
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          // Moon Phase
          MoonPhaseDisplay(
            moonPhase: myanmarDate.moonPhase,
            fortnightDay: myanmarDate.fortnightDay,
            size: 70,
          ),
          const SizedBox(height: 12),
          // Moon Phase Name
          Text(
            myanmarDate.formatMyanmar("&P"),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          // Fortnight Day
          Text(
            '${myanmarDate.formatMyanmar("&ff")} ${TranslationService.translate("Yat")}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const Spacer(),
          // Next Phase
          Text(
            'Next: New Moon in 7d',
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFFFFD700),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
