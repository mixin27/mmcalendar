import 'package:shared_core/shared_core.dart' show RoutePaths;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/event.dart';
import '../bloc/user_events_bloc.dart';
import '../bloc/user_events_event.dart';

/// Animated, lightweight list row for events.
/// Kept as `AnimatedEventCard` to avoid broad API changes in callers.
class AnimatedEventCard extends StatefulWidget {
  final Event event;
  final Duration delay;
  final VoidCallback? onTap;
  final bool showTimeline;
  final bool isFirst;
  final bool isLast;

  const AnimatedEventCard({
    super.key,
    required this.event,
    this.delay = Duration.zero,
    this.onTap,
    this.showTimeline = false,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  State<AnimatedEventCard> createState() => _AnimatedEventCardState();
}

class _AnimatedEventCardState extends State<AnimatedEventCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 320),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    if (widget.delay == Duration.zero) {
      _animationController.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _animationController.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final event = widget.event;
    final eventColor = Color(event.effectiveColor);
    final isCompleted = event.isCompleted;
    final showOverdue = event.isOverdue && !isCompleted;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [eventColor.withValues(alpha: 0.08), Colors.transparent],
            ),
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap ?? () => _openDetail(context, event),
              onLongPress: () => _showActions(context, event),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 4, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 74,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _timeLabel(event),
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isCompleted
                                      ? colorScheme.onSurfaceVariant
                                      : colorScheme.onSurface,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('EEE, MMM d').format(event.eventDate),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildTimelineDot(eventColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  event.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        decoration: isCompleted
                                            ? TextDecoration.lineThrough
                                            : null,
                                        color: isCompleted
                                            ? colorScheme.onSurfaceVariant
                                            : colorScheme.onSurface,
                                      ),
                                ),
                              ),
                              if (event.isRecurring)
                                Icon(
                                  Icons.repeat,
                                  size: 16,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              if (event.hasNotifications) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.notifications_active_outlined,
                                  size: 16,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                _categoryIcon(event.category.iconName),
                                size: 14,
                                color: eventColor,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  event.category.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ),
                              if (showOverdue)
                                Text(
                                  'Overdue',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: colorScheme.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                            ],
                          ),
                          if ((event.location ?? '').isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    event.location!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: event.id == null
                          ? null
                          : () => _toggleComplete(context, event),
                      tooltip: isCompleted ? 'Reopen event' : 'Mark complete',
                      icon: Icon(
                        isCompleted
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: isCompleted ? colorScheme.primary : eventColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggleComplete(BuildContext context, Event event) {
    final eventId = event.id;
    if (eventId == null) return;

    if (event.isRecurring) {
      if (event.isCompleted) {
        context.read<UserEventsBloc>().add(
          RestoreRecurringInstanceEvent(
            masterEventId: eventId,
            occurrenceDate: event.eventDate,
          ),
        );
      } else {
        context.read<UserEventsBloc>().add(
          CompleteRecurringInstanceEvent(
            masterEventId: eventId,
            occurrenceDate: event.eventDate,
          ),
        );
      }
      return;
    }

    context.read<UserEventsBloc>().add(
      ToggleEventComplete(eventId, !event.isCompleted),
    );
  }

  Future<void> _openDetail(BuildContext context, Event event) async {
    final eventId = event.id;
    if (eventId == null) return;
    await context.push(
      RoutePaths.eventsDetail(eventId),
      extra: event.eventDate,
    );
  }

  Future<void> _showActions(BuildContext context, Event event) async {
    final eventId = event.id;
    if (eventId == null) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  event.isCompleted ? Icons.restart_alt : Icons.check_circle,
                ),
                title: Text(
                  event.isCompleted ? 'Mark as pending' : 'Mark as complete',
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _toggleComplete(context, event);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit event'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.push(RoutePaths.eventsEdit(eventId));
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  event.isRecurring ? 'Delete this occurrence' : 'Delete event',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _confirmDelete(context, event);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, Event event) async {
    final eventId = event.id;
    if (eventId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          event.isRecurring ? 'Delete this occurrence?' : 'Delete event?',
        ),
        content: Text(
          event.isRecurring
              ? 'Only this occurrence will be removed.'
              : 'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      if (event.isRecurring) {
        context.read<UserEventsBloc>().add(
          DeleteRecurringInstanceEvent(
            masterEventId: eventId,
            occurrenceDate: event.eventDate,
          ),
        );
      } else {
        context.read<UserEventsBloc>().add(DeleteEventEvent(eventId));
      }
    }
  }

  Widget _buildTimelineDot(Color color) {
    final lineColor = color.withValues(alpha: 0.35);
    return SizedBox(
      width: 14,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.showTimeline && !widget.isFirst)
            Positioned(
              top: 0,
              child: Container(width: 2, height: 18, color: lineColor),
            ),
          if (widget.showTimeline && !widget.isLast)
            Positioned(
              bottom: 0,
              child: Container(width: 2, height: 18, color: lineColor),
            ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }

  String _timeLabel(Event event) {
    if (event.isAllDay || event.eventTime == null) return 'All day';
    return DateFormat.jm().format(event.eventDateTime);
  }

  IconData _categoryIcon(String iconName) {
    switch (iconName) {
      case 'person':
        return Icons.person;
      case 'work':
        return Icons.work;
      case 'auto_awesome':
        return Icons.auto_awesome;
      case 'family_restroom':
        return Icons.family_restroom;
      case 'favorite':
        return Icons.favorite;
      default:
        return Icons.event;
    }
  }
}
