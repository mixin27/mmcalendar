import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_core/shared_core.dart' show RoutePaths;
import 'package:shared_ui_kit/shared_ui_kit.dart' hide ContextExtension;

import '../../domain/entities/event.dart';
import '../bloc/user_events_bloc.dart';
import '../bloc/user_events_event.dart';

/// One event in a list: a complete toggle in the category colour, the
/// title, time · category · location, repeat and reminder marks.
/// Tap opens it; long-press shows its actions.
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

  Color get _color => Color(event.colorCode ?? event.category.colorCode);

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final time = event.isAllDay || event.eventTime == null
        ? 'All day'
        : DateFormat.jm().format(event.eventDateTime);
    final subtitle = [
      if (showDate) DateFormat('EEE, MMM d').format(event.eventDate),
      time,
      event.category.name,
      if ((event.location ?? '').isNotEmpty) event.location!,
    ].join(' · ');

    return GestureDetector(
      onLongPress: event.id == null
          ? null
          : () {
              HapticFeedback.mediumImpact();
              showEventActions(context, event);
            },
      child: AppRow(
        leading: Semantics(
          checked: event.isCompleted,
          button: true,
          label: event.isCompleted ? 'Mark as pending' : 'Mark complete',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: event.id == null
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    toggleEventComplete(context, event);
                  },
            child: Icon(
              event.isCompleted
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              size: 26,
              color: event.isCompleted ? t.accent : _color,
            ),
          ),
        ),
        title: event.title,
        subtitle: subtitle,
        completed: event.isCompleted,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (event.priority.value >= 2)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.priority_high_rounded,
                  size: 16,
                  color: t.holiday,
                ),
              ),
            if (event.isRecurring)
              Icon(Icons.repeat, size: 16, color: t.tertiaryLabel),
            if (event.hasNotifications)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 16,
                  color: t.tertiaryLabel,
                ),
              ),
          ],
        ),
        chevron: true,
        onTap: onOpen,
      ),
    );
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
