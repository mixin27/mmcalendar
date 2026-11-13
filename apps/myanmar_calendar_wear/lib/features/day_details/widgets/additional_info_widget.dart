import 'package:flutter/material.dart';
import 'package:myanmar_calendar_wear/features/day_details/models/day_details.dart';
import 'package:shared_localizations/shared_localizations.dart';

/// Nagahle, Mahabote and Nakhat.
class AdditionalInfoWidget extends StatelessWidget {
  const AdditionalInfoWidget({required this.dayDetails, super.key});

  final DayDetails dayDetails;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rows = [
      (l10n.nagahle, dayDetails.nagahle),
      (l10n.mahabote, dayDetails.mahabote),
      (l10n.nakhat, dayDetails.nakhat),
    ].where((row) => row.$2.isNotEmpty);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.shade900.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade700.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          for (final (label, value) in rows)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 70,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.teal.shade200,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(fontSize: 11, color: Colors.white),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
