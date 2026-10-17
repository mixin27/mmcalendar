part of 'day_cells.dart';

// The grid designs from "Calendar Grids v4", set 1. Every cell shares the
// same states: today is a solid accent disc on the date, the selected day a
// soft accent tint over the whole cell, out-of-month days are faded.

/// The day number: an accent disc today, red on Sundays and holidays.
class _Number extends StatelessWidget {
  const _Number({
    required this.data,
    required this.colors,
    this.size = 13.5,
    this.disc = 22,
    this.weight = FontWeight.w600,
  });

  final DayCellData data;
  final CalendarColors colors;
  final double size;
  final double disc;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    final today = data.isToday;
    final color = today
        ? colors.onAccent
        : (data.showsHoliday || data.isSunday)
        ? colors.holiday
        : colors.label;
    // Hug the number: a Container with an alignment would stretch the disc
    // across the whole cell.
    return Container(
      constraints: BoxConstraints(minWidth: disc, minHeight: disc),
      height: disc,
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: today
          ? BoxDecoration(
              color: colors.accent,
              borderRadius: BorderRadius.circular(disc / 2),
            )
          : null,
      child: Center(
        widthFactor: 1,
        child: Text(
          data.options.showWesternDates ? '${data.info.westernDay}' : '',
          maxLines: 1,
          style: TextStyle(
            fontSize: size,
            height: 1,
            fontWeight: today ? FontWeight.w700 : weight,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

/// The date on the left and an optional mark on the right that shrinks
/// rather than overflow in narrow cells.
class _TopRow extends StatelessWidget {
  const _TopRow({required this.left, this.right});
  final Widget left;
  final Widget? right;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Flexible(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: left,
        ),
      ),
      if (right case final mark?)
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: FittedBox(fit: BoxFit.scaleDown, child: mark),
          ),
        ),
    ],
  );
}

/// Lays [child] out at its natural height and clips whatever a short row
/// cannot show, instead of overflowing.
class _Clip extends StatelessWidget {
  const _Clip({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRect(
    child: OverflowBox(
      alignment: Alignment.topCenter,
      maxHeight: double.infinity,
      child: child,
    ),
  );
}

/// The shell every set-1 cell shares: tap target, faded out-of-month days,
/// the selected tint and an optional background.
class _Cell extends StatelessWidget {
  const _Cell({
    required this.data,
    required this.onTap,
    required this.child,
    this.background,
    this.border,
    this.radius = 9,
    this.padding = const EdgeInsets.all(3),
  });

  final DayCellData data;
  final VoidCallback? onTap;
  final Widget child;
  final Color? background;
  final BoxBorder? border;
  final double radius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final colors = CalendarColors.of(context);
    final shape = border == null ? BorderRadius.circular(radius) : null;
    return _CellShell(
      data: data,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: data.isInMonth ? background : null,
          borderRadius: shape,
          border: border,
        ),
        child: _SelectedTint(
          selected: data.isSelected,
          color: colors.accentSoft,
          radius: border == null ? radius : 0,
          child: Padding(
            padding: padding,
            child: Opacity(opacity: data.isInMonth ? 1 : .3, child: child),
          ),
        ),
      ),
    );
  }
}

/// Detailed v2: a calmer detailed cell. No ruling, the moon only on moon
/// days, the lunar day under the date, then the holiday name and an event
/// when the row is tall enough.
class DetailedV2DayCell extends StatelessWidget {
  const DetailedV2DayCell({super.key, required this.data, this.onTap});
  final DayCellData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = CalendarColors.of(context);
    return _Cell(
      data: data,
      onTap: onTap,
      background: data.showsHoliday ? colors.holidaySoft : null,
      child: LayoutBuilder(
        builder: (context, box) {
          final inMonth = data.isInMonth;
          final roomy = box.maxHeight >= 54;
          final tall = box.maxHeight >= 64;
          final sabbath = data.showsSabbath && !data.isMoonDay;
          return Stack(
            children: [
              _Clip(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TopRow(
                      left: _Number(data: data, colors: colors),
                      right: inMonth && data.isMoonDay
                          ? MoonGlyph(state: data.moon, size: 12)
                          : null,
                    ),
                    if (inMonth && data.options.showMyanmarDates)
                      Padding(
                        padding: const EdgeInsets.only(left: 2, top: 1),
                        child: Text(
                          sabbath ? data.sabbathName : data.lunarLabel,
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          softWrap: false,
                          style: _small(
                            context,
                            sabbath ? colors.sabbath : colors.secondaryLabel,
                            weight: sabbath ? FontWeight.w700 : null,
                          ).copyWith(fontSize: 9.5),
                        ),
                      ),
                    if (inMonth && data.showsHoliday && roomy)
                      Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Text(
                          data.holidayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _small(
                            context,
                            colors.holiday,
                            weight: FontWeight.w600,
                          ).copyWith(fontSize: 9),
                        ),
                      ),
                  ],
                ),
              ),
              if (inMonth && data.events.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: tall
                      ? _EventChip(events: data.events, colors: colors)
                      : Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: .6,
                            child: _EventBars(
                              events: data.events,
                              colors: colors,
                            ),
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

/// Lunar first: the lunar day is the big figure, the Gregorian date small
/// in the corner. Moon days show the moon; Sabbath days are gold.
class LunarFirstDayCell extends StatelessWidget {
  const LunarFirstDayCell({super.key, required this.data, this.onTap});
  final DayCellData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = CalendarColors.of(context);
    final inMonth = data.isInMonth;
    final myanmarScript = MyanmarCalendar.currentLanguage != Language.english;
    final lunarColor = data.showsSabbath ? colors.sabbath : colors.label;
    return _Cell(
      data: data,
      onTap: onTap,
      background: data.showsHoliday ? colors.holidaySoft : null,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: _Number(data: data, colors: colors, size: 10.5, disc: 18),
          ),
          if (inMonth)
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: data.isMoonDay
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MoonGlyph(state: data.moon, size: 20),
                            Text(
                              data.lunarPhase,
                              style: _small(
                                context,
                                colors.sabbath,
                                weight: FontWeight.w700,
                              ).copyWith(fontSize: 9.5),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              data.lunarPhase,
                              style: _small(
                                context,
                                colors.tertiaryLabel,
                                weight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              data.lunarNumber,
                              style: TextStyle(
                                fontSize: myanmarScript ? 17 : 19,
                                height: myanmarScript ? 1.35 : 1.15,
                                fontWeight: FontWeight.w700,
                                color: lunarColor,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          if (inMonth)
            Positioned(
              left: 0,
              right: 0,
              bottom: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (data.showsHoliday) _Dot(color: colors.holiday),
                  if (data.events.isNotEmpty) _Dot(color: colors.accent),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Minimal: the date and one status dot (holiday, Sabbath or event).
class MinimalDayCell extends StatelessWidget {
  const MinimalDayCell({super.key, required this.data, this.onTap});
  final DayCellData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = CalendarColors.of(context);
    final dot = !data.isInMonth
        ? null
        : data.showsHoliday
        ? colors.holiday
        : data.showsSabbath
        ? colors.moon
        : data.events.isNotEmpty
        ? colors.accent
        : null;
    return _Cell(
      data: data,
      onTap: onTap,
      radius: 12,
      child: LayoutBuilder(
        builder: (context, box) {
          final disc = (box.maxHeight * .55).clamp(24.0, 34.0);
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Number(
                  data: data,
                  colors: colors,
                  size: disc * .5,
                  disc: disc,
                  weight: FontWeight.w500,
                ),
                const SizedBox(height: 4),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: dot ?? Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Moon strip: every day shows tonight's moon, with the lunar day under it.
class MoonStripDayCell extends StatelessWidget {
  const MoonStripDayCell({super.key, required this.data, this.onTap});
  final DayCellData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = CalendarColors.of(context);
    return _Cell(
      data: data,
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, box) {
          final inMonth = data.isInMonth;
          final size = box.maxHeight >= 64 ? 20.0 : 16.0;
          final label = data.isMoonDay ? data.lunarPhase : data.lunarLabel;
          return _Clip(
            child: SizedBox(
              height: box.maxHeight,
              child: Column(
                children: [
                  _Number(data: data, colors: colors),
                  if (inMonth) ...[
                    Expanded(
                      child: Center(
                        child: MoonGlyph(state: data.moon, size: size),
                      ),
                    ),
                    if (data.options.showMyanmarDates)
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        softWrap: false,
                        style: _small(
                          context,
                          data.isMoonDay
                              ? colors.sabbath
                              : data.showsHoliday
                              ? colors.holiday
                              : colors.secondaryLabel,
                          weight: data.isMoonDay ? FontWeight.w700 : null,
                        ).copyWith(fontSize: 9),
                      ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Agenda: event titles inside the cell (two at most, then "+n"), holidays
/// as red chips, the lunar day beside the date.
class AgendaDayCell extends StatelessWidget {
  const AgendaDayCell({super.key, required this.data, this.onTap});
  final DayCellData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = CalendarColors.of(context);
    return _Cell(
      data: data,
      onTap: onTap,
      radius: 8,
      padding: const EdgeInsets.fromLTRB(2, 3, 2, 2),
      child: LayoutBuilder(
        builder: (context, box) {
          final inMonth = data.isInMonth;
          final room = box.maxHeight >= 70 ? 2 : 1;
          final items = <(String, Color, Color)>[
            if (data.showsHoliday)
              (data.holidayName, colors.holidaySoft, colors.holiday),
            for (final event in data.events)
              (
                event.title,
                eventColor(event, colors).withValues(alpha: .16),
                eventColor(event, colors),
              ),
          ];
          return DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: colors.separator, width: .5),
              ),
            ),
            child: _Clip(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TopRow(
                    left: _Number(data: data, colors: colors),
                    right: inMonth && data.isMoonDay
                        ? MoonGlyph(state: data.moon, size: 11)
                        : inMonth && data.options.showMyanmarDates
                        ? Text(
                            data.lunarNumber,
                            style: _small(
                              context,
                              data.showsSabbath
                                  ? colors.sabbath
                                  : colors.tertiaryLabel,
                              weight: data.showsSabbath
                                  ? FontWeight.w700
                                  : null,
                            ),
                          )
                        : null,
                  ),
                  if (inMonth)
                    for (final (text, background, foreground) in items.take(
                      room,
                    ))
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: background,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _small(
                            context,
                            foreground,
                            weight: FontWeight.w600,
                          ).copyWith(fontSize: 8.8),
                        ),
                      ),
                  if (inMonth && items.length > room)
                    Padding(
                      padding: const EdgeInsets.only(left: 3, top: 1),
                      child: Text(
                        '+${translateNumbers('${items.length - room}')}',
                        style: _small(context, colors.tertiaryLabel),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Classic print: a ruled table like a printed wall calendar, a bold date
/// in each box and the full Myanmar date in the lower right.
class ClassicPrintDayCell extends StatelessWidget {
  const ClassicPrintDayCell({super.key, required this.data, this.onTap});
  final DayCellData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = CalendarColors.of(context);
    final inMonth = data.isInMonth;
    final label = data.isMoonDay ? data.lunarPhase : data.myanmarDate;
    return _Cell(
      data: data,
      onTap: onTap,
      background: data.showsHoliday ? colors.holidaySoft : null,
      // Half-width lines on every side add up to one rule between cells.
      border: Border.all(color: colors.separator, width: .4),
      padding: const EdgeInsets.fromLTRB(3, 3, 3, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TopRow(
            left: _Number(
              data: data,
              colors: colors,
              size: 15,
              disc: 24,
              weight: FontWeight.w700,
            ),
            right: inMonth && data.isMoonDay
                ? MoonGlyph(state: data.moon, size: 11)
                : null,
          ),
          const Spacer(),
          if (inMonth)
            Row(
              children: [
                if (data.showsHoliday) _PrintBar(color: colors.holiday),
                if (data.events.isNotEmpty) _PrintBar(color: colors.accent),
              ],
            ),
          if (inMonth && data.options.showMyanmarDates)
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.clip,
              softWrap: false,
              textAlign: TextAlign.end,
              style: _small(
                context,
                data.showsSabbath ? colors.sabbath : colors.secondaryLabel,
                weight: data.showsSabbath ? FontWeight.w700 : null,
              ).copyWith(fontSize: 8.6),
            ),
        ],
      ),
    );
  }
}

class _PrintBar extends StatelessWidget {
  const _PrintBar({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 12,
    height: 3,
    margin: const EdgeInsets.only(right: 2, bottom: 2),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}
