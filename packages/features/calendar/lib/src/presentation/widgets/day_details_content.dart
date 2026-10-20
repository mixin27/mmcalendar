import 'package:shared_core/shared_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart' as mm;
import 'package:go_router/go_router.dart';
import 'package:holidays/holidays.dart';
import 'package:myanmar_calendar_dart/ai.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import '../../di/calendar_injection.dart';
import 'astro_phrases.dart';
import 'calendar_labels.dart';
import 'calendar_colors.dart';
import 'day_cells.dart' show eventColor;

typedef Event = CalendarEventItem;
typedef EventPriority = CalendarEventPriority;

/// Everything about one day, as grouped lists in the app style: the
/// Myanmar date, Buddhist calendar, moon and weekday, holidays, astrology,
/// the AI horoscope prompt, a quick summary and the day's events.
///
/// Used by Day Details (phones and Views › Day) and the split view's side
/// panel.
class DayDetailsContent extends StatelessWidget {
  final DateTime date;
  final CompleteDate completeDate;
  final bool showShanCalendar;
  final AnalyticsPort _analyticsService = getIt<AnalyticsPort>();
  final EventActionsPort _eventActionsPort = getIt<EventActionsPort>();
  final EventMarkersPort _eventMarkersPort = getIt<EventMarkersPort>();

  DayDetailsContent({
    super.key,
    required this.date,
    required this.completeDate,
    this.showShanCalendar = true,
  });

  static const _spacing = 22.0;

  Language get _language => MyanmarCalendar.currentLanguage;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Event>>(
      stream: _eventMarkersPort.watchEventsForDate(date),
      builder: (context, eventsSnapshot) {
        final events = [...?eventsSnapshot.data]
          ..sort((a, b) {
            if (a.isAllDay != b.isAllDay) return a.isAllDay ? -1 : 1;
            if (a.isAllDay || a.eventTime == null || b.eventTime == null) {
              return 0;
            }
            return a.eventTime!.compareTo(b.eventTime!);
          });
        final loading =
            eventsSnapshot.connectionState == ConnectionState.waiting &&
            !eventsSnapshot.hasData;

        final sections = <Widget>[
          _hero(context),
          _buddhistCalendar(context),
          _moonAndWeekday(context),
          _comingUp(context),
          if (completeDate.hasHolidays || completeDate.hasAnniversaryDays)
            _holidays(context),
          _astrology(context),
          if (completeDate.nagahle.isNotEmpty) _nagahle(context),
          _aiPrompt(context),
          _summary(context, eventCount: events.length),
          _events(
            context,
            events,
            loading: loading,
            error: eventsSnapshot.hasError
                ? eventsSnapshot.error.toString()
                : null,
          ),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, section) in sections.indexed) ...[
              if (i > 0) const SizedBox(height: _spacing),
              section,
            ],
          ],
        );
      },
    );
  }

  int get _displayYear => (_language == Language.shan && showShanCalendar)
      ? MyanmarDateTime.fromMyanmarDate(completeDate.myanmar).shanDate.year
      : completeDate.myanmarYear;

  /// The Myanmar date as the page's headline, with year, month, day and
  /// year type beneath.
  Widget _hero(BuildContext context) {
    final t = context.tokens;
    final l10n = AppLocalizations.of(context);
    final title = _language == Language.shan && showShanCalendar
        ? '${translateNumbers('$_displayYear', language: Language.shan)} '
              '${MyanmarCalendar.formatMyanmar(completeDate.myanmar, pattern: '&M &P &f &Yat')}'
        : MyanmarCalendar.formatMyanmar(
            completeDate.myanmar,
            pattern: '&y &M &P &f &Yat',
          );
    final tiles = [
      (
        CalendarLabels.of('Year', _language, l10n?.year ?? 'Year'),
        translateNumbers('$_displayYear'),
      ),
      (
        CalendarLabels.of('Month', _language, l10n?.month ?? 'Month'),
        TranslationService.getMonthName(
          completeDate.myanmarMonth,
          completeDate.yearType,
          _language,
        ),
      ),
      (
        CalendarLabels.day(_language, l10n?.day ?? 'Day'),
        translateNumbers('${completeDate.myanmarDay}'),
      ),
      (
        CalendarLabels.of(
          'Year Type',
          _language,
          l10n?.dayDetailsYearType ?? 'Type',
        ),
        TranslationService.getYearTypeName(completeDate.yearType, _language),
      ),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 20,
                height: 1.6,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              context.calendarFormat.fullDate(date),
              style: TextStyle(fontSize: 13, color: t.secondaryLabel),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final (i, (label, value)) in tiles.indexed) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 7,
                        horizontal: 4,
                      ),
                      decoration: BoxDecoration(
                        color: t.fill,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(
                            label,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: t.tertiaryLabel,
                            ),
                          ),
                          Text(
                            value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buddhistCalendar(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppGroup(
      label: CalendarLabels.of(
        'Eras',
        _language,
        l10n?.dayDetailsBuddhistCalendar ?? 'Buddhist Calendar',
      ),
      children: [
        AppRow(
          title: CalendarLabels.of(
            'Buddhist Era',
            _language,
            l10n?.buddhist_era ?? 'Buddhist Era (BE)',
          ),
          value: translateNumbers('${date.year + 543}'),
        ),
        AppRow(
          title: CalendarLabels.of(
            'Sasana Year',
            _language,
            l10n?.sasana_year ?? 'Sasana Year',
          ),
          value: translateNumbers('${completeDate.sasanaYear}'),
        ),
        AppRow(
          title: CalendarLabels.of(
            'Myanmar Era',
            _language,
            l10n?.myanmar_era ?? 'Myanmar Era (ME)',
          ),
          value: MyanmarCalendar.formatMyanmar(
            completeDate.myanmar,
            pattern: '&yyyy',
          ),
        ),
      ],
    );
  }

  Widget _moonAndWeekday(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final moon = MoonPhaseState.evening(date);
    final phase = TranslationService.getMoonPhaseName(
      completeDate.moonPhase,
      _language,
    );
    return AppGroup(
      label:
          '${l10n?.moon_phase ?? 'Moon Phase'} · ${l10n?.weekday ?? 'Weekday'}',
      children: [
        AppRow(
          leading: MoonGlyph(state: moon, size: 30),
          title: phase,
          // One sentence, one language: the interface's, digits included.
          subtitle: completeDate.isFullMoon || completeDate.isNewMoon
              ? l10n?.dayDetailsPercentLit(context.uiNumber(moon.percentLit)) ??
                    '${moon.percentLit}% lit'
              : l10n?.dayDetailsFortnightDayPercentLit(
                      context.uiNumber(completeDate.fortnightDay),
                      context.uiNumber(moon.percentLit),
                    ) ??
                    'Day ${completeDate.fortnightDay} · ${moon.percentLit}% lit',
        ),
        Builder(
          builder: (context) {
            final weekday = TranslationService.getWeekdayName(
              completeDate.weekday,
              _language,
            );
            return AppRow(
              icon: Icons.calendar_today_outlined,
              iconColor: const Color(0xFF2F5BEA),
              title: weekday,
            );
          },
        ),
      ],
    );
  }

  Widget _holidays(BuildContext context) {
    final l10n =
        AppLocalizations.of(context) ??
        lookupAppLocalizations(const Locale('en'));
    final colors = CalendarColors.of(context);
    final day = DateTime(date.year, date.month, date.day);
    final holidays = HolidayYears.of(
      day.year,
      context.calendarLanguage,
    ).where((o) => o.contains(day));
    // Inside Views the holiday opens in Views, otherwise in Home.
    final inViews = GoRouterState.of(
      context,
    ).uri.path.startsWith(RoutePaths.views);
    return AppGroup(
      label: '${l10n.holidays} & ${l10n.anniversary_days}',
      children: [
        for (final o in holidays)
          AppRow(
            key: ValueKey('day-holiday-${o.entry.id}'),
            icon: o.entry.kind == HolidayKind.anniversary
                ? Icons.celebration_outlined
                : Icons.star_rounded,
            iconColor: o.entry.kind == HolidayKind.anniversary
                ? colors.anniversary
                : colors.holiday,
            title: o.entry.title(l10n),
            subtitle: [
              ...o.days
                  .firstWhere((d) => d.date == day)
                  .labels
                  .where((label) => label != o.entry.title(l10n)),
              if (o.length > 1) context.calendarFormat.holidayRange(o),
            ].join(' · '),
            chevron: true,
            onTap: () => GoRouter.of(context).push(
              inViews
                  ? RoutePaths.holidayInViews(o.entry.id, day.year)
                  : RoutePaths.holidayInHome(o.entry.id, day.year),
            ),
          ),
      ],
    );
  }

  /// The next full moon, new moon and Sabbath, counted from this day.
  Widget _comingUp(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppGroup(
      label: l10n?.dayDetailsComingUp ?? 'Coming up',
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
          child: mm.NextMoonCountdown(
            key: const ValueKey('day-details-moon-countdown'),
            from: date,
            surface: false,
          ),
        ),
      ],
    );
  }

  /// Which way the dragon's head turns this month, as a compass.
  Widget _nagahle(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.tokens;
    return AppGroup(
      label: l10n?.dayDetailsNagahleCompass ?? "Dragon's head",
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              mm.NagahleCompass.forDirection(
                completeDate.nagahle,
                key: const ValueKey('day-details-nagahle-compass'),
                size: 96,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AstroPhrases.nagahle(completeDate.nagahle, _language),
                      style: TextStyle(
                        fontSize: 18,
                        height: 1.5,
                        fontWeight: FontWeight.w700,
                        color: t.label,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// The day's astrology: what applies to it as chips (the name says what
  /// it is), then Mahabote, Nakhat and the year name as labelled tiles. All
  /// of it, labels included, in the calendar language.
  Widget _astrology(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.tokens;
    final colors = CalendarColors.of(context);
    Color tone(AstroTone tone) => switch (tone) {
      AstroTone.sabbath => colors.sabbath,
      AstroTone.good => t.success,
      AstroTone.caution => t.holiday,
    };
    final flags = AstroPhrases.marks(completeDate);
    final facts = [
      if (completeDate.mahabote.isNotEmpty)
        (
          'Mahabote',
          AstroPhrases.mahabote(completeDate.mahabote, _language),
          Icons.grid_view_rounded,
        ),
      if (completeDate.nakhat.isNotEmpty)
        (
          'Nakhat',
          AstroPhrases.nakhat(completeDate.nakhat, _language),
          Icons.star_outline_rounded,
        ),
      if (completeDate.yearName.isNotEmpty)
        (
          'Year Name',
          AstroPhrases.yearName(completeDate.yearName, _language),
          Icons.calendar_month_outlined,
        ),
    ];
    return AppGroup(
      label: l10n?.astrological_information ?? 'Astrological Information',
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (flags.isEmpty)
                Text(
                  l10n?.dayDetailsNoAstrologicalDays ??
                      'No special astrological days',
                  style: TextStyle(fontSize: 13, color: t.secondaryLabel),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final key in flags)
                      _AstroChip(
                        key: ValueKey('day-astro-$key'),
                        label: AstroPhrases.mark(key, _language),
                        icon: _astroIcon(key),
                        color: tone(AstroPhrases.tone(key)),
                      ),
                  ],
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final (i, (kind, phrase, icon)) in facts.indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _AstroFact(
                        key: ValueKey('day-astro-fact-$kind'),
                        phrase: phrase,
                        icon: icon,
                        color: colors.astrology,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static IconData _astroIcon(String key) => switch (key) {
    'Sabbath' => Icons.self_improvement_rounded,
    'Sabbath Eve' => Icons.nights_stay_outlined,
    'Afternoon Pyathada' => Icons.wb_twilight_rounded,
    _ => switch (AstroPhrases.tone(key)) {
      AstroTone.good => Icons.auto_awesome_rounded,
      _ => Icons.error_outline_rounded,
    },
  };

  Widget _aiPrompt(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppGroup(
      children: [
        AppRow(
          icon: Icons.auto_awesome,
          iconColor: const Color(0xFF8E6CEF),
          title: l10n?.dayDetailsAiHoroscopePrompt ?? 'AI Horoscope Prompt',
          subtitle:
              l10n?.dayDetailsAiHoroscopePromptSubtitle ??
              'Copy a ready-made prompt for this day',
          chevron: true,
          onTap: () => _showAIPrompt(context),
        ),
      ],
    );
  }

  Future<void> _showAIPrompt(BuildContext context) {
    _analyticsService.logButtonClick(
      buttonName: 'generate_ai_prompt',
      buttonLocation: 'day_details_page',
    );
    final l10n = AppLocalizations.of(context);
    final strings = mm.MmStrings.of(_language);
    final promptTitle =
        l10n?.dayDetailsAiHoroscopePrompt ?? 'AI Horoscope Prompt';
    var type = AIPromptType.horoscope;
    return showAppSheet<void>(
      context: context,
      title: promptTitle,
      cancelLabel: l10n?.close ?? 'Close',
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) {
          final t = sheetContext.tokens;
          final prompt = AIPromptService.generatePrompt(
            completeDate,
            language: _language,
            type: type,
          );
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n?.dayDetailsAiPromptHint ??
                      'Paste this into any AI assistant (ChatGPT, Gemini, …) for a '
                          'reading of the day. Nothing is sent from this app.',
                  style: TextStyle(fontSize: 13, color: t.secondaryLabel),
                ),
                const SizedBox(height: 12),
                // Horoscope, fortune-telling or divination.
                Center(
                  child: mm.MmSegmented<AIPromptType>(
                    key: const ValueKey('day-details-ai-kind'),
                    segments: {
                      AIPromptType.horoscope: strings.horoscope,
                      AIPromptType.fortuneTelling: strings.fortune,
                      AIPromptType.divination: strings.divination,
                    },
                    selected: type,
                    onChanged: (next) {
                      _analyticsService.logWidgetInteraction(
                        widgetName: 'ai_prompt_kind',
                        actionType: next.name,
                      );
                      setSheet(() => type = next);
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: SelectableText(
                      prompt,
                      style: const TextStyle(fontSize: 13, height: 1.55),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: l10n?.dayDetailsCopyPrompt ?? 'Copy Prompt',
                  icon: Icons.copy_rounded,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: prompt));
                    Navigator.of(sheetContext).pop();
                    context.showToast(
                      l10n?.dayDetailsPromptCopied ??
                          'Prompt copied to clipboard',
                      kind: AppToastKind.success,
                    );
                  },
                ),
                const SizedBox(height: 8),
                AppButton(
                  label: l10n?.share ?? 'Share',
                  icon: Icons.ios_share,
                  kind: AppButtonKind.tinted,
                  onPressed: () => share(
                    title: promptTitle,
                    subject: promptTitle,
                    content: prompt,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _summary(BuildContext context, {required int eventCount}) {
    final t = context.tokens;
    final colors = CalendarColors.of(context);
    final l10n = AppLocalizations.of(context);
    final stats = [
      ('$eventCount', l10n?.events ?? 'Events', t.accent),
      (
        '${completeDate.allHolidays.length + completeDate.allAnniversaryDays.length}',
        l10n?.holidays ?? 'Holidays',
        colors.holiday,
      ),
      (
        '${completeDate.astrologicalDays.length}',
        l10n?.dayDetailsSpecial ?? 'Special',
        colors.astrology,
      ),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            for (final (value, label, color) in stats)
              Expanded(
                child: Column(
                  children: [
                    Text(
                      translateNumbers(value),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(fontSize: 12, color: t.secondaryLabel),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _events(
    BuildContext context,
    List<Event> events, {
    required bool loading,
    String? error,
  }) {
    final colors = CalendarColors.of(context);
    final l10n = AppLocalizations.of(context);
    final rows = <Widget>[
      if (loading)
        AppRow(
          title: l10n?.dayDetailsLoadingEvents ?? 'Loading events…',
          trailing: const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        )
      else if (error != null)
        AppRow(
          title: l10n?.dayDetailsErrorLoadingEvents ?? 'Error loading events',
          subtitle: error,
          tone: AppRowTone.destructive,
        )
      else
        for (final event in events)
          AppRow(
            leading: _CompleteToggle(
              done: event.isCompleted,
              color: eventColor(event, colors),
              onChanged: event.id == null
                  ? null
                  : (done) => _toggleEventCompletion(
                      context,
                      event: event,
                      isCompleted: done,
                    ),
            ),
            title: event.title,
            subtitle: _eventSubtitle(context, event),
            completed: event.isCompleted,
            trailing: _EventMarks(event: event),
            chevron: true,
            onTap: event.id == null
                ? null
                : () {
                    _analyticsService.logButtonClick(
                      buttonName: 'view_event_detail',
                      buttonLocation: 'day_details_events_section',
                      additionalData: {'event_id': event.id.toString()},
                    );
                    _eventActionsPort.openEventDetail(
                      context,
                      eventId: event.id!,
                      occurrenceDate: event.eventDate,
                    );
                  },
          ),
      AppRow(
        title: events.isEmpty && !loading
            ? l10n?.dayDetailsNoEventsAddEvent ?? 'No events · Add event'
            : l10n?.addEvent ?? 'Add event',
        tone: AppRowTone.accent,
        onTap: () {
          _analyticsService.logButtonClick(
            buttonName: 'add_event_from_day',
            buttonLocation: 'day_details_events_section',
          );
          _eventActionsPort.openCreateEvent(context, initialDate: date);
        },
      ),
    ];
    return AppGroup(
      label: events.isEmpty
          ? l10n?.events ?? 'Events'
          : '${l10n?.events ?? 'Events'} · ${events.length}',
      children: rows,
    );
  }

  String _eventSubtitle(BuildContext context, Event event) {
    final time = event.isAllDay || event.eventTime == null
        ? AppLocalizations.of(context)?.allDay ?? 'All day'
        : TimeOfDay.fromDateTime(event.eventTime!).format(context);
    return [
      time,
      event.category.name,
      if ((event.location ?? '').isNotEmpty) event.location!,
    ].join(' · ');
  }

  Future<void> _toggleEventCompletion(
    BuildContext context, {
    required Event event,
    required bool isCompleted,
  }) async {
    try {
      await _eventMarkersPort.toggleEventCompletion(
        eventId: event.id!,
        isCompleted: isCompleted,
        isRecurring: event.isRecurring,
        occurrenceDate: event.eventDate,
      );
    } catch (error) {
      if (!context.mounted) return;
      context.showToast(
        AppLocalizations.of(context)?.dayDetailsFailedToUpdateEvent('$error') ??
            'Failed to update event: $error',
        kind: AppToastKind.error,
      );
    }
  }
}

/// One astrological mark that applies to the day, e.g. Yatyaza.
class _AstroChip extends StatelessWidget {
  const _AstroChip({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? .2 : .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(9, 5, 12, 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: context.tokens.label,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// An astrological value said as a phrase, e.g. "ဘင်္ဂဖွား".
class _AstroFact extends StatelessWidget {
  const _AstroFact({
    super.key,
    required this.phrase,
    required this.icon,
    required this.color,
  });

  final String phrase;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
      decoration: BoxDecoration(
        color: t.fill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            phrase,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              fontWeight: FontWeight.w700,
              color: t.label,
            ),
          ),
        ],
      ),
    );
  }
}

/// The round "mark complete" control on an event row.
class _CompleteToggle extends StatelessWidget {
  const _CompleteToggle({
    required this.done,
    required this.color,
    required this.onChanged,
  });

  final bool done;
  final Color color;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
    checked: done,
    label: done
        ? AppLocalizations.of(context)?.dayDetailsMarkNotDone ?? 'Mark not done'
        : AppLocalizations.of(context)?.markComplete ?? 'Mark complete',
    button: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onChanged == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              onChanged!(!done);
            },
      child: Icon(
        done ? Icons.check_circle : Icons.radio_button_unchecked,
        color: done ? context.tokens.accent : color,
        size: 26,
      ),
    ),
  );
}

class _EventMarks extends StatelessWidget {
  const _EventMarks({required this.event});
  final Event event;

  @override
  Widget build(BuildContext context) {
    final color = context.tokens.tertiaryLabel;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (event.isRecurring) Icon(Icons.repeat, size: 16, color: color),
        if (event.hasNotifications) ...[
          const SizedBox(width: 4),
          Icon(Icons.notifications_none_rounded, size: 16, color: color),
        ],
      ],
    );
  }
}
