import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/event.dart';
import '../bloc/user_events_bloc.dart';
import '../bloc/user_events_event.dart';
import '../bloc/user_events_state.dart';
import '../widgets/event_list_tile.dart';

class EventsListPage extends StatefulWidget {
  const EventsListPage({super.key});

  @override
  State<EventsListPage> createState() => _EventsListPageState();
}

class _EventsListPageState extends State<EventsListPage> {
  @override
  void initState() {
    super.initState();
    // Load ALL events on page load
    context.read<UserEventsBloc>().add(const LoadAllEvents());
    // context.read<UserEventsBloc>().add(StartWatchingEvents());
  }

  @override
  void dispose() {
    // context.read<UserEventsBloc>().add(StopWatchingEvents());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterOptions(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/events/create');
        },
        icon: const Icon(Icons.add),
        label: const Text('New Event'),
      ),
      body: BlocConsumer<UserEventsBloc, UserEventsState>(
        listener: (context, state) {
          if (state is EventsOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                duration: const Duration(seconds: 2),
              ),
            );
          } else if (state is EventsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.failure.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
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
            return _buildEventsList(state.events);
          }

          if (state is EventsOperationInProgress) {
            return Stack(
              children: [
                _buildEventsList(state.currentEvents),
                Container(
                  color: Colors.black26,
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ],
            );
          }

          if (state is EventsOperationSuccess) {
            return _buildEventsList(state.events);
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildEventsList(List<Event> events) {
    if (events.isEmpty) {
      return _buildEmptyState();
    }

    // Group events by date
    final groupedEvents = <DateTime, List<Event>>{};
    for (final event in events) {
      final dateKey = DateTime(
        event.eventDate.year,
        event.eventDate.month,
        event.eventDate.day,
      );
      groupedEvents[dateKey] = [...(groupedEvents[dateKey] ?? []), event];
    }

    final sortedDates = groupedEvents.keys.toList()..sort();

    return RefreshIndicator(
      onRefresh: () async {
        context.read<UserEventsBloc>().add(const RefreshEvents());
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.builder(
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final date = sortedDates[index];
          final dateEvents = groupedEvents[date]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('EEEE, MMM d, yyyy').format(date),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${dateEvents.length} event${dateEvents.length > 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              ...dateEvents.map((event) {
                return EventListTile(
                  event: event,
                  onTap: () {
                    context.push('/events/${event.id}/detail');
                  },
                  onCheckboxChanged: (checked) {
                    if (event.id != null) {
                      context.read<UserEventsBloc>().add(
                        ToggleEventComplete(event.id!, checked ?? false),
                      );
                    }
                  },
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text('No events yet', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to create your first event',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
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
            'Oops! Something went wrong',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              context.read<UserEventsBloc>().add(const LoadAllEvents());
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _showSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: _EventSearchDelegate(context.read<UserEventsBloc>()),
    );
  }

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (dialogContext) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('All Events'),
              onTap: () {
                Navigator.pop(dialogContext);
                context.read<UserEventsBloc>().add(const LoadAllEvents());
              },
            ),
            ListTile(
              leading: const Icon(Icons.upcoming),
              title: const Text('Upcoming (7 days)'),
              onTap: () {
                Navigator.pop(dialogContext);
                context.read<UserEventsBloc>().add(const LoadUpcomingEvents());
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('This Month'),
              onTap: () {
                Navigator.pop(dialogContext);
                final now = DateTime.now();
                final startOfMonth = DateTime(now.year, now.month, 1);
                final endOfMonth = DateTime(now.year, now.month + 1, 0);
                context.read<UserEventsBloc>().add(
                  LoadEventsByDateRange(startOfMonth, endOfMonth),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EventSearchDelegate extends SearchDelegate<Event?> {
  final UserEventsBloc eventsBloc;

  _EventSearchDelegate(this.eventsBloc);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Enter search query'));
    }

    eventsBloc.add(SearchEventsEvent(query));

    return BlocBuilder<UserEventsBloc, UserEventsState>(
      bloc: eventsBloc,
      builder: (context, state) {
        if (state is EventsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is EventsLoaded) {
          if (state.events.isEmpty) {
            return const Center(child: Text('No results found'));
          }

          return ListView.builder(
            itemCount: state.events.length,
            itemBuilder: (context, index) {
              final event = state.events[index];
              return EventListTile(
                event: event,
                onTap: () => close(context, event),
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const Center(
      child: Text('Search for events by title or description'),
    );
  }
}
