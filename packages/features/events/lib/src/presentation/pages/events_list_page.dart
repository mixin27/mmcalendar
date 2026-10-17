import 'package:shared_core/shared_core.dart'
    show
        CalendarFormat,
        CalendarLanguageContext,
        RoutePaths,
        showAppMyanmarDatePicker;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_localizations/shared_localizations.dart';

import '../../domain/entities/event.dart';
import '../../domain/repositories/events_repository.dart';
import '../bloc/user_events_bloc.dart';
import '../bloc/user_events_event.dart';
import '../bloc/user_events_state.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart' hide ContextExtension;

import '../widgets/event_row.dart';

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

  String _noEventsTitle(AppLocalizations? l10n) {
    final dateText = context.calendarFormat.shortDate(_selectedDate);
    return l10n?.eventsNoEventsOn(dateText) ?? 'No events on $dateText';
  }

  Future<void> _create() async {
    await context.push(RoutePaths.eventsCreate(), extra: _selectedDate);
    if (mounted) await _refreshSelectedDateAndIndicators();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<UserEventsBloc, UserEventsState>(
      listenWhen: (previous, current) =>
          current is EventsOperationSuccess || current is EventsError,
      listener: (context, state) {
        if (state is EventsOperationSuccess) {
          context.showToast(state.message, kind: AppToastKind.success);
          _refreshDayEventCounts();
        } else if (state is EventsError) {
          context.showToast(state.failure.message, kind: AppToastKind.error);
        }
      },
      builder: (context, state) {
        final events = List<Event>.from(_eventsFromState(state))
          ..sort((a, b) => a.eventDateTime.compareTo(b.eventDateTime));
        final loading = state is EventsLoading && events.isEmpty;
        final count = events.length;

        return RefreshIndicator(
          onRefresh: _refreshSelectedDateAndIndicators,
          child: AppPage(
            title: l10n?.events ?? 'Events',
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                tooltip: l10n?.eventsSearchEvents ?? 'Search events',
                onPressed: () => _showSearch(context),
              ),
              _MoreMenu(
                onPickDate: () => _pickDate(context),
                onToday: () => _onDaySelected(_dateOnly(DateTime.now())),
                onRefresh: _refreshSelectedDateAndIndicators,
                onCategories: () =>
                    context.push(RoutePaths.eventsCategoriesPath()),
              ),
              if (t.isClear)
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: l10n?.newEvent ?? 'New Event',
                  onPressed: _create,
                ),
            ],
            floatingActionButton: t.isClear
                ? null
                : ScaleTransition(
                    scale: _fabScaleAnimation,
                    child: FloatingActionButton(
                      tooltip: l10n?.newEvent ?? 'New Event',
                      onPressed: _create,
                      child: const Icon(Icons.add),
                    ),
                  ),
            children: [
              _DayStrip(
                selected: _selectedDate,
                counts: _dayEventCounts,
                onSelected: _onDaySelected,
              ),
              if (state is EventsOperationInProgress)
                const LinearProgressIndicator(minHeight: 2),
              if (loading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state is EventsError && events.isEmpty)
                _EmptyCard(
                  icon: Icons.error_outline,
                  title: state.failure.message,
                  action: l10n?.tryAgain ?? 'Try Again',
                  onAction: _refreshSelectedDateAndIndicators,
                )
              else if (events.isEmpty)
                _EmptyCard(
                  icon: Icons.event_available_outlined,
                  title: _noEventsTitle(l10n),
                  subtitle:
                      l10n?.eventsPickAnotherDay ??
                      'Pick another day or create one.',
                  action: l10n?.newEvent ?? 'New Event',
                  onAction: _create,
                )
              else
                AppGroup(
                  label:
                      '${_isSameDay(_selectedDate, DateTime.now()) ? (l10n?.today ?? 'Today') : context.calendarFormat.shortDate(_selectedDate)} · '
                      '${l10n?.eventsEventCount(count) ?? '$count event${count == 1 ? '' : 's'}'}',
                  children: [
                    for (final event in events)
                      EventRow(
                        event: event,
                        onOpen: () => _openEventDetail(event),
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showAppMyanmarDatePicker(
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
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppGroup(
                label: AppLocalizations.of(context)?.eventsResults ?? 'Results',
                children: [
                  for (final event in state.events)
                    EventRow(
                      event: event,
                      showDate: true,
                      onOpen: () async {
                        if (event.id == null) return;
                        final router = GoRouter.of(context);
                        close(context, event);
                        await router.push(
                          RoutePaths.eventsDetail(event.id!),
                          extra: event.eventDate,
                        );
                        onClosed();
                      },
                    ),
                ],
              ),
            ],
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
    final l10n = AppLocalizations.of(context);
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
            l10n?.eventsSearchEvents ?? 'Search events',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.eventsSearchPromptHint ?? 'Type title or description',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
            l10n?.eventsNoResultsFound ?? 'No results found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.eventsTryDifferentKeyword ?? 'Try a different keyword',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Search, pick a date, today, refresh and Categories.
class _MoreMenu extends StatelessWidget {
  const _MoreMenu({
    required this.onPickDate,
    required this.onToday,
    required this.onRefresh,
    required this.onCategories,
  });

  final VoidCallback onPickDate;
  final VoidCallback onToday;
  final VoidCallback onRefresh;
  final VoidCallback onCategories;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppMenuButton(
      groups: [
        [
          AppMenuAction(
            label: l10n?.eventsPickADate ?? 'Pick a date',
            icon: Icons.calendar_month_outlined,
            onSelected: onPickDate,
          ),
          AppMenuAction(
            label: l10n?.eventsJumpToToday ?? 'Jump to today',
            icon: Icons.today_outlined,
            onSelected: onToday,
          ),
          AppMenuAction(
            label: l10n?.refresh ?? 'Refresh',
            icon: Icons.refresh_rounded,
            onSelected: onRefresh,
          ),
        ],
        [
          AppMenuAction(
            label: l10n?.categories ?? 'Categories',
            icon: Icons.sell_outlined,
            onSelected: onCategories,
          ),
        ],
      ],
    );
  }
}

/// Thirteen days around the selection with event counts.
class _DayStrip extends StatelessWidget {
  const _DayStrip({
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  final DateTime selected;
  final Map<DateTime, int> counts;
  final ValueChanged<DateTime> onSelected;

  static String _semanticsLabel(
    AppLocalizations? l10n,
    CalendarFormat format,
    DateTime date,
    int count,
  ) {
    final dateText = format.fullDate(date);
    return l10n?.eventsDayEventsSemantics(dateText, count) ??
        '$dateText, $count events';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final start = selected.subtract(const Duration(days: 6));
    final today = DateUtils.dateOnly(DateTime.now());
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 13,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        // Start scrolled so the selected day sits in view.
        controller: ScrollController(initialScrollOffset: 6 * 52 - 120),
        itemBuilder: (context, i) {
          final date = DateUtils.dateOnly(start.add(Duration(days: i)));
          final isSelected = DateUtils.isSameDay(date, selected);
          final isToday = DateUtils.isSameDay(date, today);
          final count = counts[date] ?? 0;
          final fg = isSelected ? t.onAccent : t.label;
          return Semantics(
            selected: isSelected,
            button: true,
            label: _semanticsLabel(l10n, context.calendarFormat, date, count),
            excludeSemantics: true,
            child: Material(
              color: isSelected ? t.accent : t.surface,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onSelected(date),
                child: Container(
                  width: 46,
                  decoration: isToday && !isSelected
                      ? BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: t.accent, width: 1.2),
                        )
                      : null,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        context.calendarFormat.weekday(date, short: true),
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? t.onAccent.withValues(alpha: .8)
                              : t.secondaryLabel,
                        ),
                      ),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: fg,
                        ),
                      ),
                      SizedBox(
                        height: 6,
                        child: count == 0
                            ? null
                            : Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: isSelected ? t.onAccent : t.accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.action,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
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
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (subtitle != null)
              Text(
                subtitle!,
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
