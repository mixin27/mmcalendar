import 'package:flutter/material.dart';
import 'package:myanmar_calendar_wear/app/watch_colors.dart';
import 'package:myanmar_calendar_wear/features/day_details/models/day_details.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_localizations/shared_localizations.dart';

/// A day's astrology, opened by tapping its page: the full Myanmar date,
/// the good and caution marks by the phone's rule, then Nagahle, Mahabote
/// and Nakhat. Swipe right (back) to return.
class DayDetailScreen extends StatelessWidget {
  const DayDetailScreen({required this.day, required this.label, super.key});

  final DayDetails day;

  /// "Today", "Tomorrow" or the weekday, as on the day's page.
  final String label;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final marks = day.astrology;
    return Scaffold(
      backgroundColor: WatchColors.background,
      body: ListView(
        key: const ValueKey('watch-day-detail'),
        padding: const EdgeInsets.fromLTRB(26, 34, 26, 44),
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: WatchColors.accent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            day.myanmarDate,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              height: 1.3,
              fontWeight: FontWeight.w700,
              color: WatchColors.label,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            day.westernDate,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: WatchColors.secondary),
          ),
          const SizedBox(height: 12),
          _SectionTitle(l10n.astrology),
          const SizedBox(height: 6),
          if (marks.isEmpty)
            const Text(
              '—',
              textAlign: TextAlign.center,
              style: TextStyle(color: WatchColors.tertiary),
            )
          else
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [for (final mark in marks) _MarkChip(mark)],
            ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: WatchColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                for (final (name, value) in [
                  (l10n.nagahle, day.nagahle),
                  (l10n.mahabote, day.mahabote),
                  (l10n.nakhat, day.nakhat),
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 12,
                              color: WatchColors.secondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            value,
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: WatchColors.label,
                            ),
                          ),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.auto_awesome, size: 13, color: WatchColors.accent),
      const SizedBox(width: 5),
      Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: WatchColors.secondary,
        ),
      ),
    ],
  );
}

class _MarkChip extends StatelessWidget {
  const _MarkChip(this.mark);

  final AstroMark mark;

  @override
  Widget build(BuildContext context) {
    final good = mark.tone == AstroTone.good;
    final color = good ? WatchColors.good : WatchColors.sabbath;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: good ? WatchColors.goodSoft : WatchColors.sabbathSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            good ? Icons.check_circle_rounded : Icons.error_outline_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              mark.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
