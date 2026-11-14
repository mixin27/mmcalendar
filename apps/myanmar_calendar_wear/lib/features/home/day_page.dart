import 'package:flutter/material.dart';
import 'package:myanmar_calendar_wear/app/watch_colors.dart';
import 'package:myanmar_calendar_wear/features/day_details/models/day_details.dart';
import 'package:myanmar_calendar_wear/features/day_details/views/day_detail_screen.dart';
import 'package:myanmar_calendar_wear/features/home/watch_strings.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_moon/shared_moon.dart';

/// One day at a glance, sized to fit the screen without scrolling: the
/// moon, the Myanmar date, the Western date, then Sabbath and holidays.
/// Tap it for the day's astrology.
class DayPage extends StatelessWidget {
  const DayPage({
    required this.day,
    required this.offset,
    required this.strings,
    this.nextSabbath,
    super.key,
  });

  final DayDetails day;

  /// Days from today.
  final int offset;
  final WatchStrings strings;

  /// "Sabbath · in 3 days", shown on a plain day when nothing else is.
  final String? nextSabbath;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = switch (offset) {
      0 => strings.today,
      1 => strings.tomorrow,
      _ => day.weekday,
    };
    final western = offset < 2
        ? '${day.weekday}, ${day.westernDate}'
        : day.westernDate;
    final holidays = day.holidays(l10n);
    final chips = <Widget>[
      if (day.sabbathLabel.isNotEmpty)
        _Chip(
          icon: Icons.brightness_3_rounded,
          text: day.sabbathLabel,
          color: WatchColors.sabbath,
          background: WatchColors.sabbathSoft,
        ),
      for (final name in holidays.take(2))
        _Chip(
          icon: Icons.star_rounded,
          text: name,
          color: WatchColors.holiday,
          background: WatchColors.holidaySoft,
        ),
      if (day.sabbathLabel.isEmpty && holidays.isEmpty && nextSabbath != null)
        _Chip(
          icon: Icons.brightness_3_rounded,
          text: nextSabbath!,
          color: WatchColors.secondary,
          background: WatchColors.surface,
        ),
    ];

    return Semantics(
      button: true,
      child: GestureDetector(
        key: ValueKey('watch-day-$offset'),
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => DayDetailScreen(day: day, label: label),
          ),
        ),
        child: Padding(
          // The corners of a round screen are cut off.
          padding: const EdgeInsets.fromLTRB(30, 22, 30, 18),
          child: LayoutBuilder(
            builder: (context, constraints) => Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: WatchColors.accent,
                        ),
                      ),
                      const SizedBox(height: 6),
                      MoonGlyph(
                        date: day.date,
                        size: 42,
                        colors: MoonColors.dark,
                        semanticLabel: day.moonPhaseName,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        day.phaseLine,
                        key: const ValueKey('watch-phase'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                          color: WatchColors.label,
                        ),
                      ),
                      Text(
                        day.monthYear,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                          color: WatchColors.label,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        western,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: WatchColors.secondary,
                        ),
                      ),
                      if (chips.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ...chips.expand(
                          (chip) => [chip, const SizedBox(height: 4)],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.text,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String text;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
