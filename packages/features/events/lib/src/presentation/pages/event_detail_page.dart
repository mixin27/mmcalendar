import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/event.dart';
import '../bloc/user_events_bloc.dart';
import '../bloc/user_events_event.dart';
import '../bloc/user_events_state.dart';
import '../widgets/priority_badge.dart';
import '../widgets/recurrence_badge.dart';

class EventDetailPage extends StatefulWidget {
  final int eventId;

  const EventDetailPage({super.key, required this.eventId});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  Event? _currentEvent;

  @override
  void initState() {
    super.initState();
    // Start watching the specific event
    _loadEvent();
  }

  void _loadEvent() {
    // Trigger load to ensure we have the event
    context.read<UserEventsBloc>().add(const LoadAllEvents());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        actions: [
          if (_currentEvent != null) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                context.push('/events/${widget.eventId}').then((_) {
                  // Reload after edit
                  _loadEvent();
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ],
      ),
      body: BlocConsumer<UserEventsBloc, UserEventsState>(
        listener: (context, state) {
          if (state is EventsLoaded) {
            try {
              final event = state.events.firstWhere(
                (e) => e.id == widget.eventId,
              );
              setState(() {
                _currentEvent = event;
              });
            } catch (e) {
              log('Event not found');
            }
          }
        },
        builder: (context, state) {
          if (state is EventsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is EventsError) {
            return _buildErrorState(state.failure.message);
          }

          if (state is EventsLoaded) {
            // Find the event
            try {
              return _buildEventDetail(_currentEvent!);
            } catch (e) {
              // Event not found
              return _buildEventNotFound();
            }
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildEventDetail(Event event) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleSection(context, event),
          const SizedBox(height: 24),
          _buildDateTimeSection(context, event),
          const SizedBox(height: 16),
          _buildCategoryPrioritySection(context, event),
          const SizedBox(height: 16),
          if (event.description != null && event.description!.isNotEmpty)
            _buildDescriptionSection(context, event),
          if (event.location != null && event.location!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildLocationSection(context, event),
          ],
          if (event.isRecurring) ...[
            const SizedBox(height: 16),
            _buildRecurrenceSection(context, event),
          ],
          if (event.hasNotifications) ...[
            const SizedBox(height: 16),
            _buildNotificationsSection(context, event),
          ],
          if (event.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildTagsSection(context, event),
          ],
          const SizedBox(height: 32),
          _buildCompleteButton(context, event),
        ],
      ),
    );
  }

  Widget _buildEventNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Event Not Found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'This event may have been deleted',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Event',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(message, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => _loadEvent(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection(BuildContext context, Event event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 60,
              decoration: BoxDecoration(
                color: Color(event.effectiveColor),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                event.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  decoration: event.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateTimeSection(BuildContext context, Event event) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  event.isAllDay ? Icons.event : Icons.access_time,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat(
                          'EEEE, MMMM d, yyyy',
                        ).format(event.eventDate),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      if (!event.isAllDay && event.eventTime != null)
                        Text(
                          TimeOfDay.fromDateTime(
                            event.eventTime!,
                          ).format(context),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPrioritySection(BuildContext context, Event event) {
    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Category'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        _getCategoryIcon(event.category.iconName),
                        color: Color(event.category.colorCode),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          event.category.name,
                          style: TextStyle(
                            color: Color(event.category.colorCode),
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Priority'),
                  const SizedBox(height: 8),
                  PriorityBadge(priority: event.priority),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(BuildContext context, Event event) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.description,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(event.description!),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection(BuildContext context, Event event) {
    return Card(
      child: ListTile(
        leading: Icon(
          Icons.location_on,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('Location'),
        subtitle: Text(event.location!),
      ),
    );
  }

  Widget _buildRecurrenceSection(BuildContext context, Event event) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.repeat,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text('Repeat', style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 12),
            RecurrenceBadge(recurrenceRule: event.recurrenceRule!),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsSection(BuildContext context, Event event) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...event.notifications.map((notification) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.alarm, size: 16),
                    const SizedBox(width: 8),
                    Text(notification.displayName),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection(BuildContext context, Event event) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.label,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text('Tags', style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: event.tags.map((tag) {
                return Chip(
                  label: Text(tag),
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleteButton(BuildContext context, Event event) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () {
          if (event.id != null) {
            context.read<UserEventsBloc>().add(
              ToggleEventComplete(event.id!, !event.isCompleted),
            );
          }
        },
        icon: Icon(event.isCompleted ? Icons.restart_alt : Icons.check),
        label: Text(event.isCompleted ? 'Reopen Event' : 'Mark as Complete'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: event.isCompleted
              ? Theme.of(context).colorScheme.secondary
              : Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String iconName) {
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

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text(
          'Are you sure you want to delete this event? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<UserEventsBloc>().add(
                DeleteEventEvent(widget.eventId),
              );
              Navigator.pop(dialogContext);
              context.pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
