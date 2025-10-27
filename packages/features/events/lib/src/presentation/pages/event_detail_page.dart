import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/event.dart';
import '../bloc/user_events_bloc.dart';
import '../bloc/user_events_event.dart';
import '../bloc/user_events_state.dart';

class EventDetailPage extends StatefulWidget {
  final int eventId;

  const EventDetailPage({super.key, required this.eventId});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage>
    with TickerProviderStateMixin {
  Event? _currentEvent;
  late AnimationController _fabController;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();
    _loadEvent();

    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeOutBack),
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _fabController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  void _loadEvent() {
    context.read<UserEventsBloc>().add(const LoadAllEvents());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              // Event not found
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

          if (_currentEvent != null) {
            return _buildEventDetail(_currentEvent!);
          }

          return _buildEventNotFound();
        },
      ),
      floatingActionButton: _currentEvent != null
          ? ScaleTransition(
              scale: _fabScaleAnimation,
              child: FloatingActionButton.extended(
                onPressed: () {
                  if (_currentEvent!.id != null) {
                    context.read<UserEventsBloc>().add(
                      ToggleEventComplete(
                        _currentEvent!.id!,
                        !_currentEvent!.isCompleted,
                      ),
                    );
                  }
                },
                icon: Icon(
                  _currentEvent!.isCompleted ? Icons.restart_alt : Icons.check,
                ),
                label: Text(
                  _currentEvent!.isCompleted ? 'Reopen Event' : 'Mark Complete',
                ),
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                backgroundColor: _currentEvent!.isCompleted
                    ? Theme.of(context).colorScheme.secondary
                    : Color(_currentEvent!.effectiveColor),
              ),
            )
          : null,
    );
  }

  Widget _buildEventDetail(Event event) {
    final colorScheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        // Hero App Bar
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(event.effectiveColor),
                    Color(event.effectiveColor).withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (event.isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Completed',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        event.title,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              decoration: event.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    context.push('/events/${widget.eventId}');
                    break;
                  case 'delete':
                    _confirmDelete(context);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 12),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),

        // Content
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildInfoSection(
                context,
                icon: Icons.calendar_today,
                title: 'Date & Time',
                color: colorScheme.primary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(event.eventDate),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!event.isAllDay && event.eventTime != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        TimeOfDay.fromDateTime(
                          event.eventTime!,
                        ).format(context),
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 4),
                      Text(
                        'All day event',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      context,
                      icon: _getCategoryIcon(event.category.iconName),
                      title: 'Category',
                      subtitle: event.category.name,
                      color: Color(event.category.colorCode),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoCard(
                      context,
                      icon: Icons.flag,
                      title: 'Priority',
                      subtitle: event.priority.displayName,
                      color: _getPriorityColor(event.priority),
                    ),
                  ),
                ],
              ),

              if (event.description != null &&
                  event.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildInfoSection(
                  context,
                  icon: Icons.description,
                  title: 'Description',
                  color: colorScheme.secondary,
                  child: Text(
                    event.description!,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                ),
              ],

              if (event.location != null && event.location!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildInfoSection(
                  context,
                  icon: Icons.location_on,
                  title: 'Location',
                  color: Colors.red,
                  child: Text(
                    event.location!,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ],

              if (event.isRecurring) ...[
                const SizedBox(height: 12),
                _buildInfoSection(
                  context,
                  icon: Icons.repeat,
                  title: 'Recurrence',
                  color: Colors.purple,
                  child: Text(
                    event.recurrenceRule!.type.displayName,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ],

              if (event.hasNotifications) ...[
                const SizedBox(height: 12),
                _buildInfoSection(
                  context,
                  icon: Icons.notifications_active,
                  title: 'Notifications',
                  color: Colors.amber.shade700,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: event.notifications.map((notification) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.alarm,
                                size: 16,
                                color: Colors.amber.shade700,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              notification.displayName,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

              if (event.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildInfoSection(
                  context,
                  icon: Icons.label,
                  title: 'Tags',
                  color: Colors.teal,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: event.tags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        backgroundColor: colorScheme.secondaryContainer,
                        labelStyle: TextStyle(
                          color: colorScheme.onSecondaryContainer,
                          fontSize: 13,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

              const SizedBox(height: 80), // Space for FAB
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventNotFound() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_busy,
                size: 64,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Event Not Found',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'This event may have been deleted',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Error Loading Event',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _loadEvent(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
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

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.warning, color: Colors.orange, size: 48),
        title: const Text('Delete Event?'),
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
