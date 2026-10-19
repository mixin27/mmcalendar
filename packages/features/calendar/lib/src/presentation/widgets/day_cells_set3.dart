part of 'day_cells.dart';

// The grid designs from "New calendar grids" (docs/grid-designs.html).
// They share set 1's shell (_Cell), date (_Number) and states.

/// Almanac: everything the calendar knows about a day, in its cell. The
/// date and moon, the lunar day, the holiday as a banner, as many events
/// as fit, and a strip along the bottom for Sabbath and good or careful
/// days. Where a Myanmar month begins, a rule on the left and the month's
/// name in place of the lunar day.
///
/// Content is dropped, least important first, when a row is short:
/// events, then the holiday banner, then the lunar day.
class AlmanacDayCell extends StatelessWidget {
  const AlmanacDayCell({super.key, required this.data, this.onTap});

  final DayCellData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = CalendarColors.of(context);
    final good = context.tokens.success;
    return _CellShell(
      data: data,
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, box) {
          final scale = MediaQuery.textScalerOf(context).scale(1);
          final line = _labelLine * scale;
          final inMonth = data.isInMonth;
          final tones = inMonth ? data.astroTones : const <AstroTone>[];
          // Padding, the date row and, when there is one, the strip.
          var budget = box.maxHeight - 8 - 20 - (tones.isEmpty ? 0 : 6);
          bool take(double height) {
            if (budget < height) return false;
            budget -= height;
            return true;
          }

          final starts = inMonth && data.monthPlace.starts;
          final lunar =
              inMonth &&
              (data.options.showMyanmarDates || starts) &&
              take(line);
          final holiday = inMonth && data.showsHoliday && take(line + 2);
          var shown = 0;
          while (inMonth && shown < data.events.length && take(line + 1)) {
            shown++;
          }
          final hidden = data.events.length - shown;

          return Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: colors.separator, width: .5),
                left: starts
                    ? BorderSide(color: colors.accent, width: 2)
                    : BorderSide.none,
              ),
            ),
            child: _SelectedTint(
              selected: data.isSelected,
              color: colors.accentSoft,
              radius: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(3, 4, 3, 4),
                child: Opacity(
                  opacity: inMonth ? 1 : .3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 20,
                        child: Row(
                          children: [
                            // Large text shrinks the number instead of
                            // pushing the moon out.
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: _Number(
                                  data: data,
                                  colors: colors,
                                  size: 14,
                                  disc: 20,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (inMonth && box.maxWidth >= 38)
                              MoonGlyph(state: data.moon, size: 10),
                          ],
                        ),
                      ),
                      if (lunar)
                        Text(
                          starts ? data.myanmarMonthName : data.lunarLabel,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.fade,
                          style: _small(
                            context,
                            starts ? colors.accent : colors.secondaryLabel,
                            weight: starts ? FontWeight.w700 : null,
                          ),
                        ),
                      if (holiday)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: _Banner(
                            text: data.holidayName,
                            color: colors.holiday,
                            background: colors.holidaySoft,
                          ),
                        ),
                      for (final (i, event) in data.events.take(shown).indexed)
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: _Banner(
                            text: i == shown - 1 && hidden > 0
                                ? '${event.title} +$hidden'
                                : event.title,
                            color: colors.label,
                            background: eventColor(
                              event,
                              colors,
                            ).withValues(alpha: .18),
                          ),
                        ),
                      if (inMonth && shown == 0 && data.events.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: _EventBars(
                            events: data.events,
                            colors: colors,
                          ),
                        ),
                      const Spacer(),
                      if (tones.isNotEmpty)
                        SizedBox(
                          height: 4,
                          child: Row(
                            children: [
                              for (final (i, tone) in tones.indexed) ...[
                                if (i > 0) const SizedBox(width: 2),
                                Expanded(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: switch (tone) {
                                        AstroTone.sabbath => colors.sabbath,
                                        AstroTone.good => good,
                                        AstroTone.caution => colors.holiday,
                                      },
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// One line of text on a soft tint: a holiday or an event in a cell.
class _Banner extends StatelessWidget {
  const _Banner({
    required this.text,
    required this.color,
    required this.background,
  });

  final String text;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(3),
    ),
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: _small(context, color, weight: FontWeight.w600),
    ),
  );
}

/// Myanmar months: each Myanmar month is a tinted region of the Western
/// grid, with an edge where it changes and its name where it begins.
/// The cells stay calm: the date, the lunar day or the moon on moon days,
/// and a dot for a holiday or events.
class MonthRegionsDayCell extends StatelessWidget {
  const MonthRegionsDayCell({super.key, required this.data, this.onTap});

  final DayCellData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = CalendarColors.of(context);
    final place = data.monthPlace;
    final inMonth = data.isInMonth;
    final tint = place.index.isEven
        ? colors.accent.withValues(alpha: .08)
        : colors.anniversary.withValues(alpha: .1);
    final edge = BorderSide(
      color: colors.accent.withValues(alpha: .6),
      width: 2,
    );
    final named = inMonth && (place.starts || data.info.westernDay == 1);
    return _Cell(
      data: data,
      onTap: onTap,
      background: tint,
      border: Border(
        left: place.edgeLeft ? edge : BorderSide.none,
        top: place.edgeTop ? edge : BorderSide.none,
      ),
      padding: const EdgeInsets.fromLTRB(2, 5, 2, 3),
      child: LayoutBuilder(
        builder: (context, box) {
          final scale = MediaQuery.textScalerOf(context).scale(1);
          final line = _labelLine * scale;
          var budget = box.maxHeight - 22;
          final lunar =
              inMonth && data.options.showMyanmarDates && budget >= line;
          if (lunar) budget -= line;
          final dots = inMonth && budget >= 6;
          if (dots) budget -= 6;
          final name = named && budget >= line;
          return Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: _Number(data: data, colors: colors, size: 15, disc: 22),
              ),
              if (lunar)
                SizedBox(
                  height: line,
                  child: Center(
                    child: data.isMoonDay
                        ? MoonGlyph(state: data.moon, size: 10)
                        : Text(
                            data.lunarLabel,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.fade,
                            style: _small(
                              context,
                              data.showsSabbath
                                  ? colors.sabbath
                                  : colors.secondaryLabel,
                              weight: data.showsSabbath
                                  ? FontWeight.w700
                                  : null,
                            ),
                          ),
                  ),
                ),
              if (dots)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (data.showsHoliday) _Dot(color: colors.holiday),
                      if (data.events.isNotEmpty) _Dot(color: colors.accent),
                    ],
                  ),
                ),
              const Spacer(),
              if (name)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    data.myanmarMonthName,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                    style: _small(
                      context,
                      colors.accent,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
