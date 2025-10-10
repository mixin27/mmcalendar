import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/events_bloc.dart';
import '../bloc/events_event.dart';
import '../bloc/events_state.dart';
import '../widgets/category_filter_chips.dart';
import '../widgets/date_range_selector.dart';
import '../widgets/event_date_group.dart';

class EventsListPage extends StatefulWidget {
  const EventsListPage({super.key});

  @override
  State<EventsListPage> createState() => _EventsListPageState();
}

class _EventsListPageState extends State<EventsListPage> {
  @override
  void initState() {
    super.initState();
    // Load all events on page init
    context.read<EventsBloc>().add(const LoadAllEvents());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchPage(context),
            tooltip: 'Search',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'categories',
                child: ListTile(
                  leading: Icon(Icons.category),
                  title: Text('Manage Categories'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: ListTile(
                  leading: Icon(Icons.refresh),
                  title: Text('Refresh'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Date range selector
          const DateRangeSelector(),

          // Category filter chips
          const CategoryFilterChips(),

          const Divider(height: 1),

          // Events list
          Expanded(
            child: BlocBuilder<EventsBloc, EventsState>(
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
                          'Error',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.message,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            context.read<EventsBloc>().add(
                              const RefreshEvents(),
                            );
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is EventsEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Events',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.message,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () => _navigateToCreateEvent(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Create Event'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is EventsLoaded) {
                  final groupedEvents = state.groupedByDate;
                  final sortedDates = groupedEvents.keys.toList()
                    ..sort((a, b) => a.compareTo(b));

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<EventsBloc>().add(const RefreshEvents());
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: sortedDates.length,
                      itemBuilder: (context, index) {
                        final date = sortedDates[index];
                        final events = groupedEvents[date]!;

                        return EventDateGroup(
                          date: date,
                          events: events,
                          onEventTap: (event) =>
                              _navigateToEventDetail(context, event.id),
                          onEventToggle: (eventId) {
                            context.read<EventsBloc>().add(
                              ToggleEventComplete(eventId),
                            );
                          },
                        );
                      },
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateEvent(context),
        icon: const Icon(Icons.add),
        label: const Text('New Event'),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Filter Events'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: const Text('All Events'),
              onTap: () {
                context.read<EventsBloc>().add(const LoadAllEvents());
                Navigator.pop(dialogContext);
              },
            ),
            ListTile(
              leading: const Icon(Icons.today),
              title: const Text('Today'),
              onTap: () {
                context.read<EventsBloc>().add(
                  LoadEventsByDate(DateTime.now()),
                );
                Navigator.pop(dialogContext);
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('This Week'),
              onTap: () {
                final now = DateTime.now();
                final startOfWeek = now.subtract(
                  Duration(days: now.weekday - 1),
                );
                final endOfWeek = startOfWeek.add(const Duration(days: 6));
                context.read<EventsBloc>().add(
                  LoadEventsByDateRange(
                    startDate: startOfWeek,
                    endDate: endOfWeek,
                  ),
                );
                Navigator.pop(dialogContext);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('This Month'),
              onTap: () {
                final now = DateTime.now();
                final startOfMonth = DateTime(now.year, now.month, 1);
                final endOfMonth = DateTime(now.year, now.month + 1, 0);
                context.read<EventsBloc>().add(
                  LoadEventsByDateRange(
                    startDate: startOfMonth,
                    endDate: endOfMonth,
                  ),
                );
                Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showSearchPage(BuildContext context) {
    // todo(mixin27): Implement search page
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Search feature coming soon')));
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'categories':
        context.push('/events/categories');
        break;
      case 'refresh':
        context.read<EventsBloc>().add(const RefreshEvents());
        break;
    }
  }

  void _navigateToCreateEvent(BuildContext context) {
    context.push('/events/create');
  }

  void _navigateToEventDetail(BuildContext context, int eventId) {
    context.push('/events/$eventId');
  }
}
