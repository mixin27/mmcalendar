import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_core/shared_core.dart'
    show CalendarFormat, CalendarLanguageContext, RoutePaths;
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart' hide ContextExtension;

import '../../domain/entities/event.dart';
import '../../domain/entities/recurrence_rule.dart';
import '../bloc/user_events_bloc.dart';
import '../bloc/user_events_event.dart';
import 'category_icon.dart';

/// One event in a list, as in the design's Events screen: an icon tile in
/// the category colour (a gray check once completed, with the title struck
/// through), then time · category · repeat · reminder · location.
/// Tapping the tile completes the event; tapping the row opens it;
/// long-press shows its actions.
class EventRow extends StatelessWidget {
  const EventRow({
    super.key,
    required this.event,
    required this.onOpen,
    this.showDate = false,
  });

  final Event event;
  final VoidCallback onOpen;

  /// Prefix the date (search results span many days).
  final bool showDate;

  static const _completedGray = Color(0xFF8E8E93);

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = Color(event.effectiveColor);
    final done = event.isCompleted;
    final l10n = AppLocalizations.of(context);

    final tile = t.isClear
        ? Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: done ? _completedGray : color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              done
                  ? Icons.check_rounded
                  : categoryIcon(event.category.iconName),
              size: 18,
              color: Colors.white,
            ),
          )
        : Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: done ? t.fill : color.withValues(alpha: .16),
              shape: BoxShape.circle,
            ),
            child: Icon(
              done
                  ? Icons.check_rounded
                  : categoryIcon(event.category.iconName),
              size: 22,
              color: done ? t.secondaryLabel : color,
            ),
          );

    return GestureDetector(
      onLongPress: event.id == null
          ? null
          : () {
              HapticFeedback.mediumImpact();
              showEventActions(context, event);
            },
      child: AppRow(
        leadingWidth: t.isClear ? 30 : 40,
        leading: Semantics(
          checked: done,
          button: true,
          label: done
              ? (l10n?.markAsPending ?? 'Mark as pending')
              : (l10n?.markComplete ?? 'Mark complete'),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: event.id == null
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    toggleEventComplete(context, event);
                  },
            child: tile,
          ),
        ),
        title: event.title,
        subtitleSpan: _details(t, l10n, context.calendarFormat),
        completed: done,
        chevron: showDate,
        onTap: onOpen,
      ),
    );
  }

  InlineSpan _details(
    AppTokens t,
    AppLocalizations? l10n,
    CalendarFormat format,
  ) {
    final parts = <InlineSpan>[
      if (showDate) TextSpan(text: format.shortDate(event.eventDate)),
      TextSpan(
        text: event.isAllDay || event.eventTime == null
            ? (l10n?.allDay ?? 'All day')
            : DateFormat.Hm().format(event.eventDateTime),
      ),
      TextSpan(text: event.category.name),
      if (event.recurrenceRule case final rule?
          when rule.type != RecurrenceType.none)
        TextSpan(text: _repeatText(rule, l10n)),
      if (event.hasNotifications)
        TextSpan(
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 13,
                  color: t.secondaryLabel,
                ),
              ),
            ),
            TextSpan(text: _reminderText(l10n)),
          ],
        ),
      if ((event.location ?? '').isNotEmpty) TextSpan(text: event.location),
      if (event.priority.value >= EventPriority.high.value)
        TextSpan(
          text: event.priority.displayName,
          style: TextStyle(color: t.holiday, fontWeight: FontWeight.w600),
        ),
    ];
    return TextSpan(
      children: [
        for (var i = 0; i < parts.length; i++) ...[
          if (i > 0) const TextSpan(text: ' · '),
          parts[i],
        ],
      ],
    );
  }

  static String _repeatText(RecurrenceRule rule, AppLocalizations? l10n) {
    const units = {
      RecurrenceType.daily: ('daily', 'days'),
      RecurrenceType.weekly: ('weekly', 'weeks'),
      RecurrenceType.monthly: ('monthly', 'months'),
      RecurrenceType.yearly: ('yearly', 'years'),
    };
    final (once, plural) = units[rule.type]!;
    final n = rule.interval;
    final localized = l10n == null
        ? null
        : n > 1
        ? switch (rule.type) {
            RecurrenceType.daily => l10n.eventsRepeatsEveryNDays(n),
            RecurrenceType.weekly => l10n.eventsRepeatsEveryNWeeks(n),
            RecurrenceType.monthly => l10n.eventsRepeatsEveryNMonths(n),
            RecurrenceType.yearly => l10n.eventsRepeatsEveryNYears(n),
            RecurrenceType.none => null,
          }
        : switch (rule.type) {
            RecurrenceType.daily => l10n.eventsRepeatsDaily,
            RecurrenceType.weekly => l10n.eventsRepeatsWeekly,
            RecurrenceType.monthly => l10n.eventsRepeatsMonthly,
            RecurrenceType.yearly => l10n.eventsRepeatsYearly,
            RecurrenceType.none => null,
          };
    return localized ?? (n > 1 ? 'repeats every $n $plural' : 'repeats $once');
  }

  /// The earliest reminder, short ("15 min", "1 h", "1 day"), plus how many
  /// more there are.
  String _reminderText(AppLocalizations? l10n) {
    final minutes = event.notifications
        .map((n) => n.minutesBefore)
        .reduce((a, b) => a > b ? a : b);
    final first = switch (minutes) {
      0 => l10n?.eventsReminderAtStart ?? 'at start',
      < 60 => l10n?.eventsReminderMinutes(minutes) ?? '$minutes min',
      < 1440 =>
        l10n?.eventsReminderHours(minutes ~/ 60) ?? '${minutes ~/ 60} h',
      _ =>
        l10n?.eventsReminderDays(minutes ~/ 1440) ??
            '${minutes ~/ 1440} day${minutes >= 2880 ? 's' : ''}',
    };
    final more = event.notifications.length - 1;
    return more > 0 ? '$first +$more' : first;
  }
}

/// Completes or restores an event (or one occurrence of a repeating one).
void toggleEventComplete(BuildContext context, Event event) {
  final id = event.id;
  if (id == null) return;
  final bloc = context.read<UserEventsBloc>();
  if (event.isRecurring) {
    bloc.add(
      event.isCompleted
          ? RestoreRecurringInstanceEvent(
              masterEventId: id,
              occurrenceDate: event.eventDate,
            )
          : CompleteRecurringInstanceEvent(
              masterEventId: id,
              occurrenceDate: event.eventDate,
            ),
    );
    return;
  }
  bloc.add(ToggleEventComplete(id, !event.isCompleted));
}

/// Complete, edit or delete, from a long-press.
Future<void> showEventActions(BuildContext context, Event event) async {
  final id = event.id;
  if (id == null) return;
  final l10n = AppLocalizations.of(context);
  await showAppSheet<void>(
    context: context,
    title: event.title,
    cancelLabel: l10n?.close ?? 'Close',
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppGroup(
              children: [
                AppRow(
                  icon: event.isCompleted
                      ? Icons.restart_alt
                      : Icons.check_rounded,
                  iconColor: const Color(0xFF1F9D63),
                  title: event.isCompleted
                      ? (l10n?.markAsPending ?? 'Mark as pending')
                      : (l10n?.markComplete ?? 'Mark complete'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    toggleEventComplete(context, event);
                  },
                ),
                AppRow(
                  icon: Icons.edit_outlined,
                  iconColor: const Color(0xFF2F5BEA),
                  title: l10n?.editEvent ?? 'Edit event',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.push(RoutePaths.eventsEdit(id));
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            AppGroup(
              children: [
                AppRow(
                  icon: Icons.delete_outline,
                  iconColor: const Color(0xFFE5383B),
                  title: event.isRecurring
                      ? (l10n?.eventsDeleteThisOccurrence ??
                            'Delete this occurrence')
                      : (l10n?.deleteEvent ?? 'Delete event'),
                  tone: AppRowTone.destructive,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    confirmDeleteEvent(context, event);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> confirmDeleteEvent(BuildContext context, Event event) async {
  final id = event.id;
  if (id == null) return;
  final l10n = AppLocalizations.of(context);
  final confirmed = await showAppConfirm(
    context: context,
    title: event.isRecurring
        ? (l10n?.eventsDeleteThisOccurrenceQuestion ??
              'Delete this occurrence?')
        : (l10n?.deleteEventQuestion ?? 'Delete event?'),
    message: event.isRecurring
        ? (l10n?.eventsOnlyThisOccurrenceRemoved ??
              'Only this occurrence will be removed.')
        : (l10n?.eventsEventWillBeRemoved(event.title) ??
              '“${event.title}” will be removed. This can’t be undone.'),
    confirmLabel: l10n?.delete ?? 'Delete',
    destructive: true,
  );
  if (!confirmed || !context.mounted) return;
  final bloc = context.read<UserEventsBloc>();
  bloc.add(
    event.isRecurring
        ? DeleteRecurringInstanceEvent(
            masterEventId: id,
            occurrenceDate: event.eventDate,
          )
        : DeleteEventEvent(id),
  );
}
