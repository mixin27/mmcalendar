import 'package:flutter/material.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import 'calendar_colors.dart';
import 'day_cells.dart';

/// The pull-up sheet under the month on phones.
///
/// Collapsed, it peeks with a one-line summary of the selected day (today
/// by default). Pulled up, it shows that day's events, a link to the full
/// Day Details, the next 30 days of holidays, Sabbaths, moons and events,
/// and the Calendar Studio row.
class HomeDaySheet extends StatefulWidget {
  const HomeDaySheet({
    super.key,
    required this.peekFraction,
    required this.day,
    required this.today,
    required this.events,
    required this.upcomingEvents,
    required this.options,
    required this.onOpenDetails,
    required this.onOpenEvent,
    required this.onAddEvent,
    required this.onOpenDay,
    required this.onStudioTap,
  });

  /// Collapsed height as a fraction of the area the sheet lives in.
  final double peekFraction;
  final CompleteDate day;
  final DateTime today;
  final List<CalendarEventItem> events;
  final Map<DateTime, List<CalendarEventItem>> upcomingEvents;
  final DayCellOptions options;
  final ValueChanged<DateTime> onOpenDetails;
  final ValueChanged<CalendarEventItem> onOpenEvent;
  final ValueChanged<DateTime> onAddEvent;
  final ValueChanged<DateTime> onOpenDay;
  final VoidCallback onStudioTap;

  /// Collapsed height in logical pixels for the current text scale.
  static double peekHeight(BuildContext context) =>
      66 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.3);

  @override
  State<HomeDaySheet> createState() => _HomeDaySheetState();
}

class _HomeDaySheetState extends State<HomeDaySheet> {
  final _controller = DraggableScrollableController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<double> get _snaps {
    final peek = widget.peekFraction;
    return [peek, if (.55 > peek + .08) .55, 1.0];
  }

  void _toggle() {
    if (!_controller.isAttached) return;
    final expanded = _controller.size > widget.peekFraction + .02;
    _controller.animateTo(
      expanded ? widget.peekFraction : (_snaps.length > 2 ? _snaps[1] : 1.0),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = CalendarColors.of(context);
    final l10n = AppLocalizations.of(context);
    return DraggableScrollableSheet(
      controller: _controller,
      initialChildSize: widget.peekFraction,
      minChildSize: widget.peekFraction,
      maxChildSize: 1,
      snap: true,
      snapSizes: _snaps.sublist(1, _snaps.length - 1),
      builder: (context, scrollController) => DecoratedBox(
        decoration: BoxDecoration(
          color: context.tokens.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .14),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Semantics(
                button: true,
                label:
                    l10n?.calendarToggleDayDetails ??
                    'Show or hide day details',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _toggle,
                  child: Column(
                    children: [
                      Container(
                        width: 36,
                        height: 5,
                        margin: const EdgeInsets.only(top: 6, bottom: 6),
                        decoration: BoxDecoration(
                          color: colors.tertiaryLabel,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      _Summary(
                        day: widget.day,
                        today: widget.today,
                        eventCount: widget.events.length,
                        options: widget.options,
                      ),
                    ],
                  ),
                ),
              ),
              _DayBadges(day: widget.day, options: widget.options),
              const SizedBox(height: 14),
              AppGroup(
                label: l10n?.events ?? 'Events',
                children: [
                  for (final event in widget.events)
                    AppRow(
                      icon: Icons.event_outlined,
                      iconColor: eventColor(event, colors),
                      title: event.title,
                      subtitle: _eventTime(context, event),
                      onTap: () => widget.onOpenEvent(event),
                    ),
                  AppRow(
                    title: l10n?.addEvent ?? 'Add event',
                    tone: AppRowTone.accent,
                    onTap: () => widget.onAddEvent(_date(widget.day)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AppGroup(
                children: [
                  AppRow(
                    title: l10n?.calendarFullDayDetails ?? 'Full day details',
                    subtitle:
                        l10n?.calendarFullDayDetailsSubtitle ??
                        'Astrology, Buddhist calendar, AI prompt',
                    chevron: true,
                    onTap: () => widget.onOpenDetails(_date(widget.day)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _UpcomingGroup(
                today: widget.today,
                events: widget.upcomingEvents,
                options: widget.options,
                onOpenDay: widget.onOpenDay,
                onOpenEvent: widget.onOpenEvent,
              ),
              const SizedBox(height: 14),
              AppGroup(
                children: [
                  AppRow(
                    icon: Icons.edit_calendar_outlined,
                    iconColor: const Color(0xFF4C5BD4),
                    title:
                        l10n?.calendarMakeYourCalendar(
                          context.uiNumber(widget.today.year + 1),
                        ) ??
                        'Make your ${widget.today.year + 1} calendar',
                    subtitle: l10n?.calendarStudio ?? 'Calendar Studio',
                    chevron: true,
                    onTap: widget.onStudioTap,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static DateTime _date(CompleteDate day) =>
      DateTime(day.westernYear, day.westernMonth, day.westernDay);

  static String _eventTime(BuildContext context, CalendarEventItem event) {
    final category = event.category.name;
    if (event.isAllDay || event.eventTime == null) {
      return '${AppLocalizations.of(context)?.allDay ?? 'All day'} · $category';
    }
    final time = TimeOfDay.fromDateTime(event.eventTime!).format(context);
    return '$time · $category';
  }
}

/// The peek: the moon, then the date and the Myanmar date on two short
/// lines, and the event count. Calendar data follows the calendar language;
/// "Today" and "in 3 days" are interface words.
class _Summary extends StatelessWidget {
  const _Summary({
    required this.day,
    required this.today,
    required this.eventCount,
    required this.options,
  });

  final CompleteDate day;
  final DateTime today;
  final int eventCount;
  final DayCellOptions options;

  @override
  Widget build(BuildContext context) {
    final colors = CalendarColors.of(context);
    final format = context.calendarFormat;
    final date = DateTime(day.westernYear, day.westernMonth, day.westernDay);
    final moon = MoonPhaseState.evening(date);
    final days = DateUtils.dateOnly(
      date,
    ).difference(DateUtils.dateOnly(today)).inDays;
    final l10n = AppLocalizations.of(context);
    final when = switch (days) {
      0 => '${l10n?.today ?? 'Today'} · ',
      1 => '${l10n?.tomorrow ?? 'Tomorrow'} · ',
      -1 => '${l10n?.yesterday ?? 'Yesterday'} · ',
      _ => '',
    };
    final distance = days.abs() > 1
        ? ' · ${days > 0 ? l10n?.calendarInDays(days) ?? 'in $days days' : l10n?.calendarDaysAgo(-days) ?? '${-days} days ago'}'
        : '';
    final marker = options.showHolidays && day.allHolidays.isNotEmpty
        ? (format.translate(day.allHolidays.first), colors.holiday)
        : options.showSabbaths && day.isSabbath
        ? (format.translate('Sabbath'), colors.sabbath)
        : null;

    return Row(
      children: [
        MoonGlyph(state: moon, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$when${format.shortDate(date)}$distance',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: colors.secondaryLabel,
                ),
              ),
              Text(
                format.myanmar(day.myanmar, '&M &P &f'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                  color: colors.label,
                ),
              ),
            ],
          ),
        ),
        // The date reads first; the marker chip shortens instead.
        if (marker case (final text, final color)) ...[
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 96),
            child: _Badge(text: text, color: color),
          ),
        ],
        if (eventCount > 0) ...[
          const SizedBox(width: 6),
          _Badge(
            text:
                l10n?.calendarEventCount(eventCount) ??
                (eventCount == 1 ? '1 event' : '$eventCount events'),
            color: colors.accent,
          ),
        ],
      ],
    );
  }
}

/// Every holiday, Sabbath and astrological day, shown once the sheet opens.
class _DayBadges extends StatelessWidget {
  const _DayBadges({required this.day, required this.options});

  final CompleteDate day;
  final DayCellOptions options;

  @override
  Widget build(BuildContext context) {
    final colors = CalendarColors.of(context);
    final format = context.calendarFormat;
    final date = DateTime(day.westernYear, day.westernMonth, day.westernDay);
    final moon = MoonPhaseState.evening(date);
    final l10n = AppLocalizations.of(context);
    final badges = <Widget>[
      _Badge(
        text:
            // Interface text, so the number follows the app language.
            l10n?.dayDetailsPercentLit(context.uiNumber(moon.percentLit)) ??
            '${moon.percentLit}% lit',
        color: colors.secondaryLabel,
      ),
      if (options.showHolidays)
        for (final holiday in day.allHolidays)
          _Badge(text: format.translate(holiday), color: colors.holiday),
      if (options.showSabbaths && day.isSabbath)
        _Badge(text: format.translate('Sabbath'), color: colors.sabbath),
      if (options.showAstrology)
        for (final astro in day.astrologicalDays)
          _Badge(text: format.translate(astro), color: colors.secondaryLabel),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(spacing: 5, runSpacing: 5, children: badges),
    );
  }
}

/// One upcoming line: a holiday run, a Sabbath or moon day, or an event.
class _Upcoming {
  const _Upcoming({
    required this.date,
    required this.title,
    required this.subtitle,
    this.leading,
    this.icon,
    this.iconColor,
    this.event,
  });

  final DateTime date;
  final String title;
  final String subtitle;
  final Widget? leading;
  final IconData? icon;
  final Color? iconColor;
  final CalendarEventItem? event;
}

class _UpcomingGroup extends StatelessWidget {
  const _UpcomingGroup({
    required this.today,
    required this.events,
    required this.options,
    required this.onOpenDay,
    required this.onOpenEvent,
  });

  final DateTime today;
  final Map<DateTime, List<CalendarEventItem>> events;
  final DayCellOptions options;
  final ValueChanged<DateTime> onOpenDay;
  final ValueChanged<CalendarEventItem> onOpenEvent;

  static const _days = 30;
  static const _limit = 8;

  List<_Upcoming> _collect(BuildContext context, CalendarColors colors) {
    final language = context.calendarLanguage;
    final format = context.calendarFormat;
    final items = <_Upcoming>[];
    String? runName;
    DateTime? runStart;
    DateTime? runEnd;

    void closeRun() {
      final name = runName, from = runStart, to = runEnd;
      if (name == null || from == null || to == null) return;
      final range = from == to
          ? format.dayMonth(from)
          : '${format.dayMonth(from)} – '
                '${format.dayMonth(to)}';
      items.add(
        _Upcoming(
          date: from,
          title: name,
          subtitle: range,
          icon: Icons.star_rounded,
          iconColor: colors.holiday,
        ),
      );
      runName = null;
    }

    final start = DateUtils.dateOnly(today);
    for (var i = 1; i <= _days; i++) {
      final date = start.add(Duration(days: i));
      final day = MyanmarCalendar.getCompleteDate(date);
      final holiday = options.showHolidays && day.allHolidays.isNotEmpty
          ? TranslationService.translateTo(day.allHolidays.first, language)
          : null;
      if (holiday != null && holiday == runName) {
        runEnd = date;
      } else {
        closeRun();
        if (holiday != null) {
          runName = holiday;
          runStart = date;
          runEnd = date;
        }
      }
      if ((options.showSabbaths && day.isSabbath) ||
          day.isFullMoon ||
          day.isNewMoon) {
        final phase = TranslationService.getMoonPhaseName(
          day.moonPhase,
          language,
        );
        final sabbath = day.isSabbath
            ? TranslationService.translateTo('Sabbath', language)
            : null;
        items.add(
          _Upcoming(
            date: date,
            title: day.isFullMoon || day.isNewMoon
                ? [phase, ?sabbath].join(' · ')
                : sabbath!,
            subtitle:
                '${format.dayMonth(date)} · '
                '${MyanmarCalendar.formatMyanmar(day.myanmar, pattern: '&P &f', language: language)}',
            leading: MoonGlyph(date: date, size: 28),
          ),
        );
      }
      for (final event in events[date] ?? const <CalendarEventItem>[]) {
        items.add(
          _Upcoming(
            date: date,
            title: event.title,
            subtitle: '${format.dayMonth(date)} · ${event.category.name}',
            icon: Icons.event_outlined,
            iconColor: eventColor(event, colors),
            event: event,
          ),
        );
      }
    }
    closeRun();
    items.sort((a, b) => a.date.compareTo(b.date));
    return items.take(_limit).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = CalendarColors.of(context);
    final items = _collect(context, colors);
    if (items.isEmpty) return const SizedBox.shrink();
    final start = DateUtils.dateOnly(today);
    final l10n = AppLocalizations.of(context);
    return AppGroup(
      label: l10n?.calendarUpcoming ?? 'Upcoming',
      children: [
        for (final item in items)
          AppRow(
            leading: item.leading,
            icon: item.icon,
            iconColor: item.iconColor,
            title: item.title,
            subtitle: item.subtitle,
            // "2 d" is interface text, in the app language's digits.
            value:
                l10n?.calendarDaysShort(item.date.difference(start).inDays) ??
                '${item.date.difference(start).inDays} d',
            onTap: item.event != null
                ? () => onOpenEvent(item.event!)
                : () => onOpenDay(item.date),
          ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    // Sized to its text: a Container with an alignment would stretch the
    // chip across the whole row.
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .13),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 11.5,
        height: 1.35,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    ),
  );
}
