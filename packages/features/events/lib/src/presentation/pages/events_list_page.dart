import 'package:shared_core/shared_core.dart' show RoutePaths;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/event.dart';
import '../../domain/repositories/events_repository.dart';
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
    with SingleTickerProviderStateMixin {
  late final AnimationController _fabAnimationController;
  late final Animation<double> _fabScaleAnimation;
  late final EventsRepository _eventsRepository;
  DateTime _selectedDate = _dateOnly(DateTime.now());
  Map<DateTime, int> _dayEventCounts = const <DateTime, int>{};
  int _dayCountRequestId = 0;

  @override
  void initState() {
    super.initState();
    _eventsRepository = GetIt.I<EventsRepository>();
    _loadSelectedDateEvents();
    _refreshDayEventCounts();

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabScaleAnimation = Tween<double>(begin: 0, end: 1).animate(
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
        listenWhen: (previous, current) =>
            current is EventsOperationSuccess || current is EventsError,
        listener: (context, state) {
          ScaffoldMessenger.of(context).clearSnackBars();
          if (state is EventsOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is EventsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.failure.message),
                behavior: SnackBarBehavior.floating,
                backgroundColor: colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final events = List<Event>.from(
            _eventsFromState(state),
            growable: true,
          )..sort((a, b) => a.eventDateTime.compareTo(b.eventDateTime));
          final isInitialLoading = state is EventsLoading && events.isEmpty;

          return RefreshIndicator(
            onRefresh: _refreshSelectedDateAndIndicators,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                _buildAppBar(context, events),
                SliverToBoxAdapter(child: _buildDaySelector(context)),
                if (state is EventsOperationInProgress)
                  const SliverToBoxAdapter(
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                if (isInitialLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state is EventsError && events.isEmpty)
                  SliverFillRemaining(
                    child: _buildErrorState(state.failure.message),
                  )
                else
                  _buildSelectedDateEvents(events),
              ],
            ),
          );
        },
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnimation,
        child: FloatingActionButton.extended(
          onPressed: () async {
            await context.push(RoutePaths.eventsCreate());
            if (context.mounted) {
              await _refreshSelectedDateAndIndicators();
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('New Event'),
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, List<Event> events) {
    final colorScheme = Theme.of(context).colorScheme;
    return SliverAppBar(
      expandedHeight: 142,
      pinned: true,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Events', style: TextStyle(fontWeight: FontWeight.w700)),
            Text(
              '${DateFormat('EEEE, MMM d').format(_selectedDate)} • ${events.length} event${events.length == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
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
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => _showSearch(context),
          tooltip: 'Search events',
        ),
        IconButton(
          icon: const Icon(Icons.date_range),
          tooltip: 'Pick date',
          onPressed: () => _pickDate(context),
        ),
        IconButton(
          icon: const Icon(Icons.today),
          tooltip: 'Jump to today',
          onPressed: () => _onDaySelected(_dateOnly(DateTime.now())),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
          onPressed: _refreshSelectedDateAndIndicators,
        ),
      ],
    );
  }

  Widget _buildDaySelector(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final startDate = _selectedDate.subtract(const Duration(days: 6));
    final dates = List<DateTime>.generate(
      13,
      (index) => _dateOnly(startDate.add(Duration(days: index))),
    );

    return Column(
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                DateFormat('MMMM yyyy').format(_selectedDate),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _onDaySelected(
                  _selectedDate.subtract(const Duration(days: 1)),
                ),
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous day',
              ),
              IconButton(
                onPressed: () =>
                    _onDaySelected(_selectedDate.add(const Duration(days: 1))),
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next day',
              ),
            ],
          ),
        ),
        SizedBox(
          height: 86,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: dates.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final date = dates[index];
              final isSelected = _isSameDay(date, _selectedDate);
              final isToday = _isSameDay(date, DateTime.now());
              final eventCount = _dayEventCounts[_dateOnly(date)] ?? 0;
              final hasEvents = eventCount > 0;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest,
                  border: Border.all(
                    color: isToday
                        ? colorScheme.primary.withValues(alpha: 0.45)
                        : Colors.transparent,
                    width: 1.3,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _onDaySelected(date),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('E').format(date).toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        DateFormat('d').format(date),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: isSelected
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      if (hasEvents) ...[
                        const SizedBox(height: 4),
                        Container(
                          constraints: const BoxConstraints(minWidth: 8),
                          padding: eventCount > 1
                              ? const EdgeInsets.symmetric(horizontal: 4)
                              : EdgeInsets.zero,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: eventCount > 1
                              ? Center(
                                  child: Text(
                                    eventCount > 9 ? '9+' : '$eventCount',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected
                                              ? colorScheme.primary
                                              : colorScheme.onPrimary,
                                        ),
                                  ),
                                )
                              : null,
                        ),
                      ] else if (isToday && !isSelected) ...[
                        const SizedBox(height: 4),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSelectedDateEvents(List<Event> events) {
    if (events.isEmpty) {
      return SliverFillRemaining(child: _buildEmptyState());
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return AnimatedEventCard(
            event: event,
            delay: Duration(milliseconds: index * 40),
            showTimeline: true,
            isFirst: index == 0,
            isLast: index == events.length - 1,
            onTap: () => _openEventDetail(event),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_busy,
                size: 64,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No events for ${DateFormat('MMM d').format(_selectedDate)}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Select another day or create a new event.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => context.push(RoutePaths.eventsCreate()),
              icon: const Icon(Icons.add),
              label: const Text('Create Event'),
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
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _refreshSelectedDateAndIndicators,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && context.mounted) {
      _onDaySelected(_dateOnly(picked));
    }
  }

  void _showSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: _EventSearchDelegate(
        eventsBloc: context.read<UserEventsBloc>(),
        onClosed: () {
          _refreshSelectedDateAndIndicators();
        },
      ),
    );
  }

  void _onDaySelected(DateTime date) {
    final normalized = _dateOnly(date);
    if (_isSameDay(normalized, _selectedDate)) return;
    setState(() => _selectedDate = normalized);
    _loadSelectedDateEvents();
    _refreshDayEventCounts();
  }

  void _loadSelectedDateEvents() {
    context.read<UserEventsBloc>().add(LoadEventsByDate(_selectedDate));
  }

  Future<void> _openEventDetail(Event event) async {
    final eventId = event.id;
    if (eventId == null) return;

    final result = await context.push(
      RoutePaths.eventsDetail(eventId),
      extra: event.eventDate,
    );
    if (!mounted) return;

    if (result is DateTime) {
      final normalized = _dateOnly(result);
      if (!_isSameDay(normalized, _selectedDate)) {
        setState(() => _selectedDate = normalized);
      }
    }

    await _refreshSelectedDateAndIndicators();
  }

  Future<void> _refreshSelectedDateAndIndicators() async {
    _loadSelectedDateEvents();
    await _refreshDayEventCounts();
  }

  Future<void> _refreshDayEventCounts() async {
    final requestId = ++_dayCountRequestId;
    final rangeStart = _selectedDate.subtract(const Duration(days: 6));
    final rangeEnd = _selectedDate.add(const Duration(days: 6));

    final result = await _eventsRepository.getEventsByDateRange(
      rangeStart,
      rangeEnd,
    );

    if (!mounted || requestId != _dayCountRequestId) return;

    result.fold(
      (_) => setState(() => _dayEventCounts = const <DateTime, int>{}),
      (events) {
        final counts = <DateTime, int>{};
        for (final event in events) {
          final key = _dateOnly(event.eventDate);
          counts[key] = (counts[key] ?? 0) + 1;
        }
        setState(() => _dayEventCounts = counts);
      },
    );
  }

  List<Event> _eventsFromState(UserEventsState state) {
    if (state is EventsLoaded) return state.events;
    if (state is EventsOperationSuccess) return state.events;
    if (state is EventsOperationInProgress) return state.currentEvents;
    return const [];
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _EventSearchDelegate extends SearchDelegate<Event?> {
  final UserEventsBloc eventsBloc;
  final VoidCallback onClosed;
  String _lastDispatchedQuery = '';

  _EventSearchDelegate({required this.eventsBloc, required this.onClosed});

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
            _lastDispatchedQuery = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        onClosed();
        close(context, null);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final normalized = query.trim();
    if (normalized.isEmpty) return _buildPrompt(context);
    _dispatchIfNeeded(normalized);
    return _buildResultsList(context);
  }

  @override
  Widget buildResults(BuildContext context) {
    final normalized = query.trim();
    if (normalized.isEmpty) return _buildPrompt(context);
    _dispatchIfNeeded(normalized);
    return _buildResultsList(context);
  }

  void _dispatchIfNeeded(String normalizedQuery) {
    if (_lastDispatchedQuery == normalizedQuery) return;
    _lastDispatchedQuery = normalizedQuery;
    eventsBloc.add(SearchEventsEvent(normalizedQuery));
  }

  Widget _buildResultsList(BuildContext context) {
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
                delay: Duration(milliseconds: index * 30),
                onTap: () async {
                  if (event.id != null) {
                    final router = GoRouter.of(context);
                    close(context, event);
                    await router.push(
                      RoutePaths.eventsDetail(event.id!),
                      extra: event.eventDate,
                    );
                    onClosed();
                  }
                },
              );
            },
          );
        }
        if (state is EventsError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(state.failure.message, textAlign: TextAlign.center),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildPrompt(BuildContext context) {
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
          Text('Search events', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Type title or description',
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
            'Try a different keyword',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
