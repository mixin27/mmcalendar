import 'package:flutter/material.dart';
import 'package:myanmar_calendar_wear/features/day_details/models/day_details.dart';
import 'package:shared_moon/shared_moon.dart';

/// The evening moon as the phone draws it, with the calendar's phase and
/// day of the fortnight.
class MoonPhaseWidget extends StatelessWidget {
  const MoonPhaseWidget({required this.dayDetails, super.key});

  final DayDetails dayDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.indigo.shade900.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.indigo.shade700.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          MoonGlyph(date: dayDetails.date, size: 28, colors: MoonColors.dark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayDetails.moonPhaseName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dayDetails.fortnightDay,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
