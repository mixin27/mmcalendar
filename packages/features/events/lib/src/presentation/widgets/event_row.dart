import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_core/shared_core.dart' show RoutePaths;
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
          label: done ? 'Mark as pending' : 'Mark complete',
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
        subtitleSpan: _details(t),
        completed: done,
        chevron: showDate,
        onTap: onOpen,
      ),
    );
  }

  InlineSpan _details(AppTokens t) {
    final parts = <InlineSpan>[
      if (showDate)
        TextSpan(text: DateFormat('EEE d MMM').format(event.eventDate)),
      TextSpan(
        text: event.isAllDay || event.eventTime == null
            ? 'All day'
            : DateFormat.Hm().format(event.eventDateTime),
      ),
      TextSpan(text: event.category.name),
      if (event.recurrenceRule case final rule?
          when rule.type != RecurrenceType.none)
        TextSpan(text: _repeatText(rule)),
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
            TextSpan(text: _reminderText()),
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

  static String _repeatText(RecurrenceRule rule) {
    const units = {
      RecurrenceType.daily: ('daily', 'days'),
      RecurrenceType.weekly: ('weekly', 'weeks'),
      RecurrenceType.monthly: ('monthly', 'months'),
      RecurrenceType.yearly: ('yearly', 'years'),
    };
    final (once, plural) = units[rule.type]!;
    return rule.interval > 1
        ? 'repeats every ${rule.interval} $plural'
        : 'repeats $once';
  }

  /// The earliest reminder, short ("15 min", "1 h", "1 day"), plus how many
  /// more there are.
  String _reminderText() {
    final minutes = event.notifications
        .map((n) => n.minutesBefore)
        .reduce((a, b) => a > b ? a : b);
    final first = switch (minutes) {
      0 => 'at start',
      < 60 => '$minutes min',
      < 1440 => '${minutes ~/ 60} h',
      _ => '${minutes ~/ 1440} day${minutes >= 2880 ? 's' : ''}',
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
  await showAppSheet<void>(
    context: context,
    title: event.title,
    cancelLabel: 'Close',
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
                      ? 'Mark as pending'
                      : 'Mark complete',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    toggleEventComplete(context, event);
                  },
                ),
                AppRow(
                  icon: Icons.edit_outlined,
                  iconColor: const Color(0xFF2F5BEA),
                  title: 'Edit event',
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
                      ? 'Delete this occurrence'
                      : 'Delete event',
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
  final confirmed = await showAppConfirm(
    context: context,
    title: event.isRecurring ? 'Delete this occurrence?' : 'Delete event?',
    message: event.isRecurring
        ? 'Only this occurrence will be removed.'
        : '“${event.title}” will be removed. This can’t be undone.',
    confirmLabel: 'Delete',
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
