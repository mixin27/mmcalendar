import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/event.dart';
import '../bloc/events_bloc.dart';
import '../bloc/events_event.dart';
import '../bloc/events_state.dart';

class EventDetailPage extends StatefulWidget {
  final int eventId;

  const EventDetailPage({super.key, required this.eventId});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<EventsBloc>().add(LoadEventById(widget.eventId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              context.push('/events/${widget.eventId}');
            },
            tooltip: 'Edit',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmDelete,
            tooltip: 'Delete',
          ),
        ],
      ),
      body: BlocConsumer<EventsBloc, EventsState>(
        listener: (context, state) {
          if (state is EventDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Event deleted successfully')),
            );
            context.pop();
          } else if (state is EventsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is EventsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is EventsError) {
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
                    'Error loading event',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<EventsBloc>().add(
                        LoadEventById(widget.eventId),
                      );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is EventDetailLoaded) {
            return _buildEventDetail(context, state.event);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEventDetail(BuildContext context, Event event) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final categoryColor = event.colorCode != null
        ? Color(event.colorCode!)
        : colorScheme.primary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: textTheme.headlineSmall?.copyWith(
                            decoration: event.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      if (event.priority > 0)
                        Icon(
                          Icons.flag,
                          color: _getPriorityColor(event.priority),
                          size: 28,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    avatar: Icon(
                      _getCategoryIcon(event.category),
                      color: categoryColor,
                      size: 18,
                    ),
                    label: Text(event.category),
                    backgroundColor: categoryColor.withValues(alpha: 0.1),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Date & Time Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date & Time', style: textTheme.titleMedium),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Date'),
                    subtitle: Text(
                      '${event.eventDate.year}-${event.eventDate.month.toString().padLeft(2, '0')}-${event.eventDate.day.toString().padLeft(2, '0')}',
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (!event.isAllDay && event.eventTime != null)
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('Time'),
                      subtitle: Text(
                        TimeOfDay.fromDateTime(
                          event.eventTime!,
                        ).format(context),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  if (event.isAllDay)
                    ListTile(
                      leading: const Icon(Icons.all_inclusive),
                      title: const Text('All Day Event'),
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Description Card
          if (event.description != null && event.description!.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Description', style: textTheme.titleMedium),
                    const Divider(),
                    Text(event.description!),
                  ],
                ),
              ),
            ),

          // Location Card
          if (event.location != null && event.location!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Location', style: textTheme.titleMedium),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.location_on),
                      title: Text(event.location!),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Tags Card
          if (event.tags != null && event.tags!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tags', style: textTheme.titleMedium),
                    const Divider(),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: event.tags!
                          .map((tag) => Chip(label: Text(tag)))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Status Card
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status', style: textTheme.titleMedium),
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      event.isCompleted
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: event.isCompleted ? Colors.green : null,
                    ),
                    title: Text(event.isCompleted ? 'Completed' : 'Pending'),
                    subtitle: event.completedAt != null
                        ? Text(
                            'Completed on ${_formatDateTime(event.completedAt!)}',
                          )
                        : null,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),

          // Metadata Card
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Metadata', style: textTheme.titleMedium),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.create),
                    title: const Text('Created'),
                    subtitle: Text(_formatDateTime(event.createdAt)),
                    contentPadding: EdgeInsets.zero,
                  ),
                  ListTile(
                    leading: const Icon(Icons.update),
                    title: const Text('Last Updated'),
                    subtitle: Text(_formatDateTime(event.updatedAt)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                context.read<EventsBloc>().add(
                  ToggleEventComplete(widget.eventId),
                );
              },
              icon: Icon(
                event.isCompleted
                    ? Icons.radio_button_unchecked
                    : Icons.check_circle,
              ),
              label: Text(
                event.isCompleted ? 'Mark as Pending' : 'Mark as Completed',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 3:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 1:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'personal':
        return Icons.person;
      case 'work':
        return Icons.work;
      case 'religious':
        return Icons.auto_awesome;
      case 'family':
        return Icons.family_restroom;
      case 'health':
        return Icons.favorite;
      default:
        return Icons.category;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _confirmDelete() {
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
              context.read<EventsBloc>().add(DeleteEvent(widget.eventId));
              Navigator.pop(dialogContext);
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
