import 'package:flutter/material.dart';
import 'package:myanmar_calendar_wear/features/day_details/models/day_details.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_localizations/shared_localizations.dart';

/// The day's astrological marks, green when good and orange when they
/// call for care, by the phone's rule.
class AstrologyWarnings extends StatelessWidget {
  const AstrologyWarnings({required this.dayDetails, super.key});

  final DayDetails dayDetails;

  @override
  Widget build(BuildContext context) {
    final marks = dayDetails.astrology;
    if (marks.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.shade900.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.purple.shade700.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.purple.shade200, size: 16),
              const SizedBox(width: 8),
              Text(
                l10n.astrology,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final mark in marks) _MarkChip(mark)],
          ),
        ],
      ),
    );
  }
}

class _MarkChip extends StatelessWidget {
  const _MarkChip(this.mark);

  final AstroMark mark;

  @override
  Widget build(BuildContext context) {
    final good = mark.tone == AstroTone.good;
    final color = good ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(good ? Icons.star : Icons.error_outline, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              mark.name,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
