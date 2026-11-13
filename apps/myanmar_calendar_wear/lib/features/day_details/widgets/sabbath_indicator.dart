import 'package:flutter/material.dart';
import 'package:myanmar_calendar_wear/features/day_details/models/day_details.dart';

/// Sabbath or Sabbath Eve, in the calendar language.
class SabbathIndicator extends StatelessWidget {
  const SabbathIndicator({required this.dayDetails, super.key});

  final DayDetails dayDetails;

  @override
  Widget build(BuildContext context) {
    if (dayDetails.sabbathLabel.isEmpty) return const SizedBox.shrink();
    final isSabbath = dayDetails.isSabbath;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isSabbath
            ? Colors.orange.shade900.withValues(alpha: 0.4)
            : Colors.orange.shade800.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSabbath
              ? Colors.orange.shade600.withValues(alpha: 0.6)
              : Colors.orange.shade700.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSabbath ? Icons.self_improvement : Icons.event_note,
            color: isSabbath ? Colors.orange.shade200 : Colors.orange.shade300,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              dayDetails.sabbathLabel,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
