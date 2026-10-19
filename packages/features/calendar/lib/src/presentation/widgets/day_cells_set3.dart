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
                            crossAxisAlignment: CrossAxisAlignment.stretch,
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
          // Myanmar digits need a taller line than the other cells use.
          final line = 15.0 * scale;
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
                            ).copyWith(height: 1.5),
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

/// A compact day: the date, the lunar day or the moon on moon days, and
/// (with [dots]) dots for a holiday, Sabbath and events. The grids that
/// put the day's detail elsewhere use it: Focus week (a [FocusWeekPanel]),
/// Moon band (a [MoonBand]), Hero today and Week ribbons.
class FocusWeekDayCell extends StatelessWidget {
  const FocusWeekDayCell({
    super.key,
    required this.data,
    this.onTap,
    this.dots = true,
  });

  final DayCellData data;
  final VoidCallback? onTap;

  /// Whether to draw the holiday, Sabbath and event dots.
  final bool dots;

  @override
  Widget build(BuildContext context) {
    final colors = CalendarColors.of(context);
    final inMonth = data.isInMonth;
    return _Cell(
      data: data,
      onTap: onTap,
      radius: 12,
      padding: const EdgeInsets.fromLTRB(2, 3, 2, 2),
      child: LayoutBuilder(
        builder: (context, box) {
          final line = 15.0 * MediaQuery.textScalerOf(context).scale(1);
          final lunar =
              inMonth &&
              data.options.showMyanmarDates &&
              box.maxHeight >= 22 + line;
          final dots =
              this.dots &&
              inMonth &&
              box.maxHeight >= 22 + (lunar ? line : 0) + 6;
          return Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: _Number(data: data, colors: colors, size: 15),
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
                              colors.secondaryLabel,
                            ).copyWith(height: 1.5),
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
                      if (data.showsSabbath) _Dot(color: colors.sabbath),
                      if (data.events.isNotEmpty) _Dot(color: colors.accent),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// The open day of a Focus week grid: its moon and Myanmar date, its
/// holidays and astrology as chips, and its events. Scrolls when there is
/// more than fits.
class FocusWeekPanel extends StatelessWidget {
  const FocusWeekPanel({super.key, required this.data, this.onTap});

  final DayCellData data;

  /// Opens the day.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = CalendarColors.of(context);
    final good = context.tokens.success;
    final language = MyanmarCalendar.currentLanguage;
    final options = data.options;
    final marks = [
      for (final mark in AstroPhrases.marks(data.info))
        if (AstroPhrases.tone(mark) == AstroTone.sabbath
            ? options.showSabbaths
            : options.showAstrology)
          mark,
    ];
    Color tone(String mark) => switch (AstroPhrases.tone(mark)) {
      AstroTone.sabbath => colors.sabbath,
      AstroTone.good => good,
      AstroTone.caution => colors.holiday,
    };
    final chips = <Widget>[
      if (data.showsHoliday)
        for (final holiday in data.info.allHolidays)
          _PanelChip(
            text: TranslationService.translateTo(holiday, language),
            color: colors.holiday,
          ),
      for (final mark in marks)
        _PanelChip(text: AstroPhrases.mark(mark, language), color: tone(mark)),
    ];
    return Semantics(
      container: true,
      button: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          key: const ValueKey('focus-week-panel'),
          margin: const EdgeInsets.fromLTRB(2, 2, 2, 6),
          decoration: BoxDecoration(
            color: colors.fill,
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    MoonGlyph(state: data.moon, size: 26),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            MyanmarCalendar.formatMyanmar(
                              data.info.myanmar,
                              pattern: '&M &P &f',
                              language: language,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.45,
                              fontWeight: FontWeight.w700,
                              color: colors.label,
                            ),
                          ),
                          Text(
                            context.calendarFormat.fullDate(data.date),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: colors.secondaryLabel,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: colors.tertiaryLabel,
                    ),
                  ],
                ),
                if (chips.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6, children: chips),
                ],
                for (final event in data.events) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 16,
                        decoration: BoxDecoration(
                          color: eventColor(event, colors),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: colors.label,
                          ),
                        ),
                      ),
                      if (!event.isAllDay && event.eventTime != null)
                        Text(
                          TimeOfDay.fromDateTime(
                            event.eventTime!,
                          ).format(context),
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.secondaryLabel,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PanelChip extends StatelessWidget {
  const _PanelChip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        height: 1.45,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    ),
  );
}

/// Auspice: each day tinted by how it reads astrologically. Good days are
/// green (deeper with two good marks), days to be careful on are striped
/// so they read without colour, and Sabbath days are outlined in gold.
class AuspiceDayCell extends StatelessWidget {
  const AuspiceDayCell({super.key, required this.data, this.onTap});

  final DayCellData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = CalendarColors.of(context);
    final good = context.tokens.success;
    final l10n = AppLocalizations.of(context);
    final inMonth = data.isInMonth;
    final score = inMonth ? data.auspice : 0;
    final background = score >= 2
        ? good.withValues(alpha: .26)
        : score == 1
        ? good.withValues(alpha: .13)
        : score < 0
        ? colors.holiday.withValues(alpha: .07)
        : colors.fill;
    final word = score > 0
        ? l10n?.gridAuspiceGood ?? 'Good'
        : score < 0
        ? l10n?.gridAuspiceCareful ?? 'Careful'
        : null;
    final ring = data.isToday
        ? colors.accent
        : inMonth && data.showsSabbath
        ? colors.sabbath
        : null;
    return Padding(
      padding: const EdgeInsets.all(1.5),
      child: _Cell(
        data: data,
        onTap: onTap,
        radius: 10,
        background: background,
        padding: EdgeInsets.zero,
        child: CustomPaint(
          painter: score < 0
              ? _StripePainter(colors.holiday.withValues(alpha: .16))
              : null,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: ring == null ? null : Border.all(color: ring, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(2, 5, 2, 3),
              child: LayoutBuilder(
                builder: (context, box) {
                  final line =
                      _labelLine * MediaQuery.textScalerOf(context).scale(1);
                  final label = word != null && box.maxHeight >= 22 + line;
                  final moon =
                      inMonth &&
                      data.isMoonDay &&
                      box.maxHeight >= 22 + (label ? line : 0) + 11;
                  return Column(
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: _Number(
                          data: data,
                          colors: colors,
                          size: 15,
                          weight: FontWeight.w700,
                        ),
                      ),
                      if (label)
                        Text(
                          word,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.fade,
                          style: _small(
                            context,
                            score > 0 ? good : colors.holiday,
                            weight: FontWeight.w700,
                          ),
                        ),
                      if (moon)
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: MoonGlyph(state: data.moon, size: 10),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Diagonal stripes, so a careful day reads without colour.
class _StripePainter extends CustomPainter {
  const _StripePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3;
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10)),
    );
    for (var x = -size.height; x < size.width; x += 9) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StripePainter old) => old.color != color;
}

/// Moon band: the moon under a week, as a band that brightens through the
/// waxing fortnight and fades through the waning one, with the full and new
/// moon marked on it.
class MoonBand extends StatelessWidget {
  const MoonBand({super.key, required this.days});

  /// The week's seven days.
  final List<DayCellData> days;

  @override
  Widget build(BuildContext context) {
    final colors = CalendarColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(3, 2, 3, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final day in days)
              Expanded(
                child: Opacity(
                  opacity: day.isInMonth ? 1 : .35,
                  child: ColoredBox(
                    color: Color.lerp(
                      colors.fill,
                      colors.moon,
                      day.moon.illumination,
                    )!,
                    child: day.isMoonDay
                        ? Center(child: MoonGlyph(state: day.moon, size: 11))
                        : null,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
