import 'package:flutter/material.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';

import 'moon_phase_display.dart';

/// Full Calendar Widget Preview
class FullCalendarPreviewWidget extends StatelessWidget {
  const FullCalendarPreviewWidget({super.key});

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
          begin: Alignment(0.0, -1.0),
          end: Alignment(0.0, 1.0),
          colors: [Color(0xFF1E88E5), Color(0xFF1976D2), Color(0xFF1565C0)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Myanmar Calendar',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'TODAY',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Content
          Expanded(
            child: Row(
              children: [
                // Left: Dates
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Western Date
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            myanmarDate.formatWestern("%dd"),
                            style: const TextStyle(
                              fontSize: 36,
                              color: Colors.white,
                              fontWeight: FontWeight.w300,
                              height: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                myanmarDate.formatWestern("%M"),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                myanmarDate.formatWestern("%yyyy"),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 8),
                      // Myanmar Date
                      Text(
                        myanmarDate.formatMyanmar('&y &M &P &f'),
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Right: Moon
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Moon Phase
                      MoonPhaseDisplay(
                        moonPhase: myanmarDate.moonPhase,
                        fortnightDay: myanmarDate.fortnightDay,
                        size: 90,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        myanmarDate.formatMyanmar("&P"),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFFFD700),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
