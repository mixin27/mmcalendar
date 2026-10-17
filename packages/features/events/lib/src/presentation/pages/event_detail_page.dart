import 'package:shared_core/shared_core.dart' show RoutePaths;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart' hide ContextExtension;

import '../../domain/entities/event.dart';
import '../bloc/user_events_bloc.dart';
import '../bloc/user_events_event.dart';
import '../bloc/user_events_state.dart';
import '../widgets/category_icon.dart';

class EventDetailPage extends StatefulWidget {
  final int eventId;
  final DateTime? occurrenceDate;

  const EventDetailPage({
    super.key,
    required this.eventId,
    this.occurrenceDate,
  });

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  Event? _currentEvent;
  bool _hasTriedDirectLookup = false;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  void _loadEvent() {
    final occurrenceDate = widget.occurrenceDate;
    if (occurrenceDate != null) {
      context.read<UserEventsBloc>().add(LoadEventsByDate(occurrenceDate));
      return;
    }
    context.read<UserEventsBloc>().add(
      const LoadAllEvents(includeCompleted: true),
    );
  }

  bool _syncCurrentEvent(List<Event> events) {
    for (final event in events) {
      if (_matchesEvent(event)) {
        setState(() {
          _currentEvent = event;
        });
        return true;
      }
    }
    if (_currentEvent != null) {
      setState(() {
        _currentEvent = null;
      });
    }
    return false;
  }

  bool _matchesEvent(Event event) {
    if (event.id != widget.eventId) return false;
    final occurrenceDate = widget.occurrenceDate;
    if (occurrenceDate == null) return true;
    return _isSameDay(event.eventDate, occurrenceDate);
  }

  Future<void> _tryLoadDirectCompletedEvent() async {
    if (_hasTriedDirectLookup || widget.occurrenceDate == null) return;
    _hasTriedDirectLookup = true;

    final result = await context
        .read<UserEventsBloc>()
        .eventsRepository
        .getEventById(widget.eventId);

    if (!mounted) return;

    result.fold((_) => null, (event) {
      final occurrenceDate = widget.occurrenceDate!;
      final isOneTimeMatch =
          !event.isRecurring && _isSameDay(event.eventDate, occurrenceDate);
      if (isOneTimeMatch) {
        setState(() {
          _currentEvent = event;
        });
      }
    });
  }

  void _popWithResult() {
    context.pop(_currentEvent?.eventDate);
  }

  void _toggleCurrentEventCompletion(Event event) {
    final eventId = event.id;
    if (eventId == null) return;

    final occurrenceDate = widget.occurrenceDate;
    if (event.isRecurring && occurrenceDate != null) {
      if (event.isCompleted) {
        context.read<UserEventsBloc>().add(
          RestoreRecurringInstanceEvent(
            masterEventId: eventId,
            occurrenceDate: occurrenceDate,
          ),
        );
      } else {
        context.read<UserEventsBloc>().add(
          CompleteRecurringInstanceEvent(
            masterEventId: eventId,
            occurrenceDate: occurrenceDate,
          ),
        );
      }
      return;
    }

    context.read<UserEventsBloc>().add(
      ToggleEventComplete(eventId, !event.isCompleted),
    );
  }

  Future<void> _edit() async {
    await context.push(RoutePaths.eventsEdit(widget.eventId));
    if (mounted) _loadEvent();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _popWithResult();
      },
      child: BlocConsumer<UserEventsBloc, UserEventsState>(
        listener: (context, state) {
          if (state is EventsLoaded) {
            if (!_syncCurrentEvent(state.events)) {
              _tryLoadDirectCompletedEvent();
            }
          } else if (state is EventsOperationSuccess) {
            if (!_syncCurrentEvent(state.events)) {
              _tryLoadDirectCompletedEvent();
            }
          } else if (state is EventsOperationInProgress) {
            _syncCurrentEvent(state.currentEvents);
          }
        },
        builder: (context, state) {
          final event = _currentEvent;
          return AppPage(
            title: 'Event',
            largeTitle: false,
            previousTitle: 'Events',
            actions: [
              if (event != null) ...[
                if (t.isClear)
                  TextButton(onPressed: _edit, child: const Text('Edit'))
                else
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Edit',
                    onPressed: _edit,
                  ),
              ],
            ],
            children: switch ((state, event)) {
              (EventsLoading(), null) => const [
                Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              (EventsError(:final failure), _) => [
                _StateCard(
                  icon: Icons.error_outline,
                  title: 'Couldn’t load this event',
                  message: failure.message,
                  action: 'Try Again',
                  onAction: _loadEvent,
                ),
              ],
              (_, final Event event) => _details(context, event),
              _ => [
                _StateCard(
                  icon: Icons.event_busy,
                  title: 'Event not found',
                  message: 'It may have been deleted.',
                  action: 'Go back',
                  onAction: () => context.pop(),
                ),
              ],
            },
          );
        },
      ),
    );
  }

  List<Widget> _details(BuildContext context, Event event) {
    final t = context.tokens;
    final color = Color(event.effectiveColor);
    final time = event.isAllDay || event.eventTime == null
        ? 'All day'
        : TimeOfDay.fromDateTime(event.eventTime!).format(context);
    final isOccurrence = event.isRecurring && widget.occurrenceDate != null;
    Widget badge(String text, Color c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c),
      ),
    );

    return [
      Card(
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 5)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  badge(event.category.name, color),
                  if (isOccurrence) badge('Occurrence', t.secondaryLabel),
                  if (event.isCompleted) badge('Completed', t.success),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                event.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  decoration: event.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              Text(
                '${DateFormat('EEEE, MMMM d, yyyy').format(event.eventDate)} · $time',
                style: TextStyle(color: t.secondaryLabel),
              ),
            ],
          ),
        ),
      ),
      if ((event.description ?? '').isNotEmpty)
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppGroupLabel('Description'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: SelectableText(
                  event.description!,
                  style: const TextStyle(fontSize: 15, height: 1.55),
                ),
              ),
            ),
          ],
        ),
      AppGroup(
        children: [
          AppRow(
            icon: categoryIcon(event.category.iconName),
            iconColor: Color(event.category.colorCode),
            title: 'Category',
            value: event.category.name,
          ),
          AppRow(
            icon: Icons.flag_outlined,
            iconColor: _getPriorityColor(event.priority),
            title: 'Priority',
            value: event.priority.displayName,
          ),
          if ((event.location ?? '').isNotEmpty)
            AppRow(
              icon: Icons.location_on_outlined,
              iconColor: const Color(0xFF1F9D63),
              title: 'Location',
              value: event.location,
            ),
          if (event.isRecurring)
            AppRow(
              icon: Icons.repeat,
              iconColor: const Color(0xFF8E8E93),
              title: 'Repeat',
              value: event.recurrenceRule!.type.displayName,
            ),
          if (event.hasNotifications)
            AppRow(
              icon: Icons.notifications_none_rounded,
              iconColor: t.holiday,
              title: 'Reminders',
              subtitle: event.notifications
                  .map((n) => n.displayName)
                  .join(', '),
            ),
          if (event.tags.isNotEmpty)
            AppRow(
              icon: Icons.sell_outlined,
              iconColor: const Color(0xFF8E6CEF),
              title: 'Tags',
              subtitle: event.tags.join(', '),
            ),
        ],
      ),
      AppGroup(
        children: [
          AppRow(
            title: event.isCompleted ? 'Reopen event' : 'Mark complete',
            tone: AppRowTone.accent,
            onTap: () => _toggleCurrentEventCompletion(event),
          ),
          AppRow(
            title: 'Delete event',
            tone: AppRowTone.destructive,
            onTap: () => _confirmDelete(context),
          ),
        ],
      ),
    ];
  }

  Color _getPriorityColor(EventPriority priority) {
    switch (priority) {
      case EventPriority.urgent:
        return Colors.red;
      case EventPriority.high:
        return Colors.orange;
      case EventPriority.normal:
        return Colors.blue;
      case EventPriority.low:
        return Colors.grey;
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showAppConfirm(
      context: context,
      title: 'Delete event?',
      message: 'This event will be removed. This can’t be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    context.read<UserEventsBloc>().add(DeleteEventEvent(widget.eventId));
    context.pop();
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
        child: Column(
          children: [
            Icon(icon, size: 40, color: t.tertiaryLabel),
            const SizedBox(height: 10),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: t.secondaryLabel),
            ),
            const SizedBox(height: 16),
            AppButton(
              label: action,
              kind: AppButtonKind.tinted,
              expand: false,
              compact: true,
              onPressed: onAction,
            ),
          ],
        ),
      ),
    );
  }
}
