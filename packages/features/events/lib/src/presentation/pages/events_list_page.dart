import 'package:events/src/presentation/pages/pending_notification_list_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/event.dart';
import '../bloc/user_events_bloc.dart';
import '../bloc/user_events_event.dart';
import '../bloc/user_events_state.dart';
import '../widgets/animated_event_card.dart';

class EventsListPage extends StatefulWidget {
  const EventsListPage({super.key});

  @override
  State<EventsListPage> createState() => _EventsListPageState();
}

class _EventsListPageState extends State<EventsListPage>
    with TickerProviderStateMixin {
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;
  bool _showCompletedEvents = false;

  @override
  void initState() {
    super.initState();
    context.read<UserEventsBloc>().add(const LoadAllEvents());

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: BlocConsumer<UserEventsBloc, UserEventsState>(
        listener: (context, state) {
          if (state is EventsOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(child: Text(state.message)),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          } else if (state is EventsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(child: Text(state.failure.message)),
                  ],
                ),
                backgroundColor: colorScheme.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              // Modern App Bar with gradient
              _buildAppBar(context, state),

              // Quick filters section
              SliverToBoxAdapter(child: _buildQuickFilters(context)),

              // Events content
              if (state is EventsLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state is EventsError)
                SliverFillRemaining(
                  child: _buildErrorState(state.failure.message),
                )
              else if (state is EventsLoaded || state is EventsOperationSuccess)
                _buildEventsList(
                  state is EventsLoaded
                      ? state.events
                      : (state as EventsOperationSuccess).events,
                )
              else
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnimation,
        child: FloatingActionButton.extended(
          onPressed: () async {
            await context.push('/events/create');
            if (context.mounted) {
              context.read<UserEventsBloc>().add(const LoadAllEvents());
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('New Event'),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, UserEventsState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final events = state is EventsLoaded
        ? state.events
        : state is EventsOperationSuccess
        ? state.events
        : <Event>[];

    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      elevation: 0,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate collapse ratio
          final expandedHeight = 160.0;
          final collapsedHeight =
              kToolbarHeight + MediaQuery.of(context).padding.top;
          final currentHeight = constraints.maxHeight;

          // Value from 0 (collapsed) to 1 (expanded)
          final opacity =
              ((currentHeight - collapsedHeight) /
                      (expandedHeight - collapsedHeight))
                  .clamp(0.0, 1.0);

          return FlexibleSpaceBar(
            titlePadding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 16 + (opacity * 8), // Adjust position based on expansion
            ),
            title: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Events',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                // Show stats only when expanded
                if (events.isNotEmpty && opacity > 0.3)
                  Opacity(
                    opacity: opacity,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildStatChip(
                              icon: Icons.event,
                              label: '${events.length} Total',
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            _buildStatChip(
                              icon: Icons.upcoming,
                              label:
                                  '${events.where((e) => !e.isCompleted).length} Active',
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 6),
                            _buildStatChip(
                              icon: Icons.check_circle,
                              label:
                                  '${events.where((e) => e.isCompleted).length} Done',
                              color: Colors.green,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.primaryContainer.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => _showSearch(context),
          tooltip: 'Search events',
        ),
        if (kDebugMode)
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PendingNotificationListPage(),
                ),
              );
            },
            icon: const Icon(Icons.bug_report),
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'filter':
                _showFilterOptions(context);
                break;
              case 'toggle_completed':
                setState(() {
                  _showCompletedEvents = !_showCompletedEvents;
                });
                context.read<UserEventsBloc>().add(
                  LoadAllEvents(includeCompleted: _showCompletedEvents),
                );
                break;
              case 'refresh':
                context.read<UserEventsBloc>().add(
                  RefreshEvents(includeCompleted: _showCompletedEvents),
                );
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'filter',
              child: Row(
                children: [
                  Icon(Icons.filter_list, size: 20),
                  SizedBox(width: 12),
                  Text('Filter'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle_completed',
              child: Row(
                children: [
                  Icon(
                    _showCompletedEvents
                        ? Icons.visibility_off
                        : Icons.visibility,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _showCompletedEvents ? 'Hide Completed' : 'Show Completed',
                  ),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh, size: 20),
                  SizedBox(width: 12),
                  Text('Refresh'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilters(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              context,
              label: 'All',
              icon: Icons.event,
              onTap: () {
                context.read<UserEventsBloc>().add(const LoadAllEvents());
              },
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              context,
              label: 'Upcoming',
              icon: Icons.upcoming,
              onTap: () {
                context.read<UserEventsBloc>().add(const LoadUpcomingEvents());
              },
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              context,
              label: 'This Month',
              icon: Icons.calendar_month,
              onTap: () {
                final now = DateTime.now();
                final startOfMonth = DateTime(now.year, now.month, 1);
                final endOfMonth = DateTime(now.year, now.month + 1, 0);
                context.read<UserEventsBloc>().add(
                  LoadEventsByDateRange(startOfMonth, endOfMonth),
                );
              },
            ),
            // const SizedBox(width: 8),
            // _buildFilterChip(
            //   context,
            //   label: 'Priority',
            //   icon: Icons.priority_high,
            //   onTap: () {
            //     // todo(mixin27): Filter by priority - implement in bloc
            //   },
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildEventsList(List<Event> allEvents) {
    // Filter events based on visibility settings
    final events = _showCompletedEvents
        ? allEvents
        : allEvents.where((e) => !e.isCompleted).toList();

    if (events.isEmpty) {
      return SliverFillRemaining(child: _buildEmptyState());
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

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final date = sortedDates[index];
          final dateEvents = groupedEvents[date]!;

          return _EventDateSection(date: date, events: dateEvents);
        }, childCount: sortedDates.length),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_available,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No events yet',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to create your first event',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              context.push('/events/create');
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Event'),
          ),
        ],
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
              'Oops! Something went wrong',
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
              onPressed: () {
                context.read<UserEventsBloc>().add(const LoadAllEvents());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (dialogContext) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Events',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _FilterOption(
              icon: Icons.event,
              title: 'All Events',
              subtitle: 'Show all events',
              onTap: () {
                Navigator.pop(dialogContext);
                context.read<UserEventsBloc>().add(const LoadAllEvents());
              },
            ),
            _FilterOption(
              icon: Icons.upcoming,
              title: 'Upcoming',
              subtitle: 'Next 7 days',
              onTap: () {
                Navigator.pop(dialogContext);
                context.read<UserEventsBloc>().add(const LoadUpcomingEvents());
              },
            ),
            _FilterOption(
              icon: Icons.date_range,
              title: 'This Month',
              subtitle: 'Current month events',
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

class _EventDateSection extends StatefulWidget {
  final DateTime date;
  final List<Event> events;

  const _EventDateSection({required this.date, required this.events});

  @override
  State<_EventDateSection> createState() => _EventDateSectionState();
}

class _EventDateSectionState extends State<_EventDateSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildDateHeader(context),
            const SizedBox(height: 8),
            ...widget.events.asMap().entries.map((entry) {
              final index = entry.key;
              final event = entry.value;
              return AnimatedEventCard(
                event: event,
                delay: Duration(milliseconds: index * 50),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final isToday =
        widget.date.year == now.year &&
        widget.date.month == now.month &&
        widget.date.day == now.day;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isToday
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isToday ? Icons.today : Icons.calendar_today,
            size: 16,
            color: isToday
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            isToday
                ? 'Today'
                : DateFormat('EEEE, MMM d, yyyy').format(widget.date),

            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isToday
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isToday
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${widget.events.length}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isToday
                    ? Theme.of(context).colorScheme.primaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FilterOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _EventSearchDelegate extends SearchDelegate<Event?> {
  final UserEventsBloc eventsBloc;

  _EventSearchDelegate(this.eventsBloc);

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        titleTextStyle: theme.textTheme.titleLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
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
      return _buildSearchPrompt(context);
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
            return _buildNoResults(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.events.length,
            itemBuilder: (context, index) {
              final event = state.events[index];
              return AnimatedEventCard(
                event: event,
                delay: Duration(milliseconds: index * 50),
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
    return _buildSearchPrompt(context);
  }

  Widget _buildSearchPrompt(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Search for events',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Enter title or description to search',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with different keywords',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
