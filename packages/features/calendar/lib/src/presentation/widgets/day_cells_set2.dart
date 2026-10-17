part of 'day_cells.dart';

// The grid designs from "Calendar Grids v4", set 2. They share set 1's
// shell (_Cell), date (_Number) and states.

/// Tiles: every day is a small card; holidays rose, Sabbath days gold.
class TilesDayCell extends StatelessWidget {
  const TilesDayCell({super.key, required this.data, this.onTap});
  final DayCellData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = CalendarColors.of(context);
    final inMonth = data.isInMonth;
    final background = !inMonth
        ? null
        : data.showsHoliday
        ? colors.holidaySoft
        : data.showsSabbath
        ? colors.sabbathSoft
        : colors.surface;
    return Padding(
      padding: const EdgeInsets.all(1.5),
      child: _Cell(
        data: data,
        onTap: onTap,
        radius: 10,
        background: background,
        padding: const EdgeInsets.fromLTRB(3, 3, 3, 2),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: _Number(
                data: data,
                colors: colors,
                size: 15,
                weight: FontWeight.w700,
              ),
            ),
            if (inMonth && data.events.isNotEmpty)
              Positioned(top: 3, right: 2, child: _Dot(color: colors.accent)),
            if (inMonth && data.options.showMyanmarDates)
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  data.isMoonDay ? data.lunarPhase : data.lunarLabel,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  softWrap: false,
                  style: _small(
                    context,
                    data.showsHoliday
                        ? colors.holiday
                        : data.showsSabbath
                        ? colors.sabbath
                        : colors.secondaryLabel,
                  ).copyWith(fontSize: 9),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Moonlight: each day glows with the moon, brightest at the full moon.
class MoonlightDayCell extends StatelessWidget {
  const MoonlightDayCell({super.key, required this.data, this.onTap});
  final DayCellData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = CalendarColors.of(context);
    final inMonth = data.isInMonth;
    final glow = colors.moon.withValues(alpha: data.moon.illumination * .3);
    return Padding(
      padding: const EdgeInsets.all(1),
      child: _Cell(
        data: data,
        onTap: onTap,
        radius: 10,
        background: glow,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Number(data: data, colors: colors, size: 15),
                if (inMonth && data.options.showMyanmarDates)
                  Text(
                    data.isMoonDay ? data.lunarPhase : data.lunarLabel,
                    maxLines: 1,
                    style: _small(
                      context,
                      data.isMoonDay ? colors.label : colors.secondaryLabel,
                      weight: data.isMoonDay ? FontWeight.w700 : null,
                    ).copyWith(fontSize: 9),
                  ),
                if (inMonth && data.events.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: _Dot(color: colors.accent),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Split: the Gregorian date top left, the lunar day bottom right, divided
/// by a fine diagonal.
class SplitDayCell extends StatelessWidget {
  const SplitDayCell({super.key, required this.data, this.onTap});
  final DayCellData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = CalendarColors.of(context);
    final inMonth = data.isInMonth;
    return _Cell(
      data: data,
      onTap: onTap,
      background: data.showsHoliday ? colors.holidaySoft : null,
      border: Border(
        right: BorderSide(color: colors.separator, width: .5),
        bottom: BorderSide(color: colors.separator, width: .5),
      ),
      padding: EdgeInsets.zero,
      child: CustomPaint(
        painter: _DiagonalPainter(colors.separator),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: _Number(
                  data: data,
                  colors: colors,
                  size: 14,
                  weight: FontWeight.w700,
                ),
              ),
              if (inMonth && data.events.isNotEmpty)
                Positioned(top: 5, right: 2, child: _Dot(color: colors.accent)),
              if (inMonth && data.options.showMyanmarDates)
                Align(
                  alignment: Alignment.bottomRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.bottomRight,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (data.isMoonDay)
                          MoonGlyph(state: data.moon, size: 16)
                        else
                          Text(
                            data.lunarNumber,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                              color: data.showsSabbath
                                  ? colors.sabbath
                                  : colors.secondaryLabel,
                            ),
                          ),
                        Text(
                          data.lunarPhase,
                          style: _small(
                            context,
                            colors.tertiaryLabel,
                          ).copyWith(fontSize: 8),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiagonalPainter extends CustomPainter {
  const _DiagonalPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawLine(
    Offset(0, size.height),
    Offset(size.width, 0),
    Paint()
      ..color = color
      ..strokeWidth = .7,
  );

  @override
  bool shouldRepaint(_DiagonalPainter oldDelegate) =>
      color != oldDelegate.color;
}

/// Poster: big bold numbers; a short gold bar for Sabbath days and a red
/// one for holidays.
class PosterDayCell extends StatelessWidget {
  const PosterDayCell({super.key, required this.data, this.onTap});
  final DayCellData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = CalendarColors.of(context);
    final inMonth = data.isInMonth;
    final bar = !inMonth
        ? null
        : data.showsHoliday
        ? colors.holiday
        : data.showsSabbath
        ? colors.moon
        : null;
    return _Cell(
      data: data,
      onTap: onTap,
      radius: 12,
      child: LayoutBuilder(
        builder: (context, box) {
          final disc = (box.maxHeight * .6).clamp(26.0, 40.0);
          return Stack(
            children: [
              Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Number(
                        data: data,
                        colors: colors,
                        size: disc * .58,
                        disc: disc,
                        weight: FontWeight.w800,
                      ),
                      const SizedBox(height: 3),
                      Container(
                        width: 16,
                        height: 3,
                        decoration: BoxDecoration(
                          color: bar ?? Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (inMonth && data.events.isNotEmpty)
                Positioned(top: 3, right: 3, child: _Dot(color: colors.accent)),
            ],
          );
        },
      ),
    );
  }
}

/// Moon ring: a ring around each date fills with the moon's light.
class MoonRingDayCell extends StatelessWidget {
  const MoonRingDayCell({super.key, required this.data, this.onTap});
  final DayCellData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = CalendarColors.of(context);
    final inMonth = data.isInMonth;
    final sabbath = data.showsSabbath && !data.isMoonDay;
    return _Cell(
      data: data,
      onTap: onTap,
      radius: 12,
      child: Stack(
        children: [
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox.square(
                    dimension: 34,
                    child: CustomPaint(
                      painter: inMonth
                          ? _RingPainter(
                              lit: data.moon.illumination,
                              track: colors.fill,
                              color: colors.moon,
                            )
                          : null,
                      child: Center(
                        child: _Number(
                          data: data,
                          colors: colors,
                          size: 13,
                          disc: 26,
                        ),
                      ),
                    ),
                  ),
                  if (inMonth && data.options.showMyanmarDates)
                    Text(
                      sabbath
                          ? data.sabbathName
                          : data.isMoonDay
                          ? data.lunarPhase
                          : data.lunarLabel,
                      maxLines: 1,
                      style: _small(
                        context,
                        sabbath ? colors.sabbath : colors.secondaryLabel,
                        weight: sabbath ? FontWeight.w700 : null,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (inMonth && data.events.isNotEmpty)
            Positioned(top: 3, right: 3, child: _Dot(color: colors.accent)),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.lit,
    required this.track,
    required this.color,
  });

  final double lit;
  final Color track;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 2.5;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, paint..color = track);
    if (lit > .01) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * lit,
        false,
        paint..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      lit != oldDelegate.lit ||
      track != oldDelegate.track ||
      color != oldDelegate.color;
}

/// Astrology: each day lists its astrological days (Thamanyo in green) and
/// holidays as red tags; the lunar day sits beside the date.
class AstrologyDayCell extends StatelessWidget {
  const AstrologyDayCell({super.key, required this.data, this.onTap});
  final DayCellData data;
  final VoidCallback? onTap;

  static const _good = Color(0xFF1F9D63);

  @override
  Widget build(BuildContext context) {
    final colors = CalendarColors.of(context);
    final language = MyanmarCalendar.currentLanguage;
    final thamanyo = TranslationService.translateTo('Thamanyo', language);
    return _Cell(
      data: data,
      onTap: onTap,
      radius: 8,
      padding: const EdgeInsets.fromLTRB(2, 3, 2, 2),
      child: LayoutBuilder(
        builder: (context, box) {
          final inMonth = data.isInMonth;
          final room = box.maxHeight >= 70 ? 2 : 1;
          final tags = <(String, Color, Color)>[
            if (data.showsHoliday)
              (data.holidayName, colors.holidaySoft, colors.holiday),
            if (data.options.showAstrology)
              for (final day in data.info.astrologicalDays)
                day == 'Thamanyo' || day == thamanyo
                    ? (
                        TranslationService.translateTo(day, language),
                        _good.withValues(alpha: .14),
                        _good,
                      )
                    : (
                        TranslationService.translateTo(day, language),
                        colors.fill,
                        colors.secondaryLabel,
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
                    for (final (text, background, foreground) in tags.take(
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
                          ).copyWith(fontSize: 8.2),
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
