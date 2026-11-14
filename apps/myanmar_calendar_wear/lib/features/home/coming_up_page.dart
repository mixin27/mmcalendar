import 'package:flutter/material.dart';
import 'package:myanmar_calendar_wear/app/watch_colors.dart';
import 'package:myanmar_calendar_wear/features/home/watch_strings.dart';
import 'package:shared_localizations/shared_localizations.dart';

/// One entry of the payload's `upcoming`: a holiday, Sabbath, full or new
/// moon, with its day.
typedef UpcomingItem = ({DateTime date, String kind, String name});

/// The next holidays, Sabbath days and moons, then the language button.
///
/// It is the last page of the day pages; pulling down at its top goes back
/// to them ([onPullDown]), since a list inside a page view doesn't hand
/// its scroll on by itself.
class ComingUpPage extends StatelessWidget {
  const ComingUpPage({
    required this.items,
    required this.today,
    required this.strings,
    required this.languageName,
    required this.onLanguage,
    required this.onPullDown,
    super.key,
  });

  /// Null until the payload is written.
  final List<UpcomingItem>? items;
  final DateTime today;
  final WatchStrings strings;
  final String languageName;
  final VoidCallback onLanguage;
  final VoidCallback onPullDown;

  static List<UpcomingItem> parse(Map<String, Object?>? payload) => [
    for (final raw in (payload?['upcoming'] as List?) ?? const <Object?>[])
      if (raw is Map)
        if (DateTime.tryParse('${raw['d']}') case final DateTime date)
          (date: date, kind: '${raw['k']}', name: '${raw['n']}'),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final list = items;
    return NotificationListener<OverscrollNotification>(
      onNotification: (n) {
        if (n.overscroll < -6 &&
            n.metrics.pixels <= n.metrics.minScrollExtent) {
          onPullDown();
        }
        return false;
      },
      child: ListView(
        key: const ValueKey('watch-coming-up'),
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 30, 24, 44),
        children: [
          Text(
            strings.comingUp,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: WatchColors.accent,
            ),
          ),
          const SizedBox(height: 8),
          if (list == null)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: WatchColors.secondary,
                  ),
                ),
              ),
            )
          else
            for (final item in list.take(10))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _UpcomingTile(
                  item: item,
                  countdown: strings.countdown(
                    item.date.difference(today).inDays,
                  ),
                ),
              ),
          const SizedBox(height: 6),
          Center(
            child: Semantics(
              button: true,
              label: l10n.language,
              child: GestureDetector(
                key: const ValueKey('watch-language'),
                onTap: onLanguage,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: WatchColors.accentSoft,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.language_rounded,
                        size: 15,
                        color: WatchColors.accent,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          languageName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: WatchColors.label,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  const _UpcomingTile({required this.item, required this.countdown});

  final UpcomingItem item;
  final String countdown;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (item.kind) {
      'holiday' => (Icons.star_rounded, WatchColors.holiday),
      'sabbath' => (Icons.brightness_3_rounded, WatchColors.sabbath),
      'fullMoon' => (Icons.circle, WatchColors.moon),
      'newMoon' => (Icons.circle_outlined, WatchColors.moon),
      _ => (Icons.event_rounded, WatchColors.accent),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: WatchColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: WatchColors.label,
                  ),
                ),
                Text(
                  countdown,
                  style: const TextStyle(
                    fontSize: 11,
                    color: WatchColors.secondary,
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
