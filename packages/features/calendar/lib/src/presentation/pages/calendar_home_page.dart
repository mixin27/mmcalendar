import 'package:shared_core/shared_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:go_router/go_router.dart';
import 'package:telegram_web/telegram_web.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import '../../di/calendar_injection.dart';
import '../bloc/calendar_bloc.dart';
import '../bloc/calendar_event.dart';
import '../bloc/calendar_state.dart';
import '../widgets/calendar_app_bar.dart';
import '../widgets/calendar_header.dart';
import '../widgets/weekday_header.dart';
import '../widgets/calendar_grid.dart';
import '../widgets/day_details_content.dart';
// import '../widgets/astrology_expandable_card.dart';

class CalendarHomePage extends StatefulWidget {
  const CalendarHomePage({super.key, this.initialDate});

  final DateTime? initialDate;

  @override
  State<CalendarHomePage> createState() => _CalendarHomePageState();
}

class _CalendarHomePageState extends State<CalendarHomePage>
    with TickerProviderStateMixin {
  final AnalyticsPort _analyticsService = getIt<AnalyticsPort>();
  final CalendarDisplayConfigPort _calendarDisplayConfigPort =
      getIt<CalendarDisplayConfigPort>();
  final EventMarkersPort _eventMarkersPort = getIt<EventMarkersPort>();
  DateTime? _lastAppliedInitialDate;
  CalendarLoaded? _lastLoadedState;
  CalendarDisplayConfig? _lastDisplayConfig;
  DateTime? _visibleEventsMonth;
  Stream<Map<DateTime, List<CalendarEventItem>>>? _visibleEventsStream;

  late AnimationController _fadeController;
  // late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  // late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Log screen view when page loads
    _analyticsService.logScreenView(
      screenName: 'home',
      screenClass: 'CalendarHomePage',
    );

    _initializeAnimations();
    _applyInitialDateIfNeeded(widget.initialDate);
  }

  @override
  void didUpdateWidget(covariant CalendarHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _applyInitialDateIfNeeded(widget.initialDate);
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // _slideController = AnimationController(
    //   duration: const Duration(milliseconds: 400),
    //   vsync: this,
    // );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // _slideAnimation =
    //     Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero).animate(
    //       CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    //     );

    // Start animations
    _fadeController.forward();
    // _slideController.forward();
  }

  void _applyInitialDateIfNeeded(DateTime? initialDate) {
    if (initialDate == null) {
      return;
    }

    final normalizedDate = DateTime(
      initialDate.year,
      initialDate.month,
      initialDate.day,
    );

    if (_lastAppliedInitialDate == normalizedDate) {
      return;
    }
    _lastAppliedInitialDate = normalizedDate;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<CalendarBloc>().add(LoadCalendarMonth(normalizedDate));
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    // _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<CalendarDisplayConfig>(
        stream: _calendarDisplayConfigPort.watchDisplayConfig(),
        initialData: CalendarDisplayConfig.defaults(),
        builder: (context, configSnapshot) {
          final displayConfig =
              configSnapshot.data ?? CalendarDisplayConfig.defaults();
          _handleDisplayConfigUpdate(displayConfig);

          return CustomScrollView(
            slivers: [
              // Compact App Bar
              SliverToBoxAdapter(
                child: CalendarAppBar(
                  onTodayTap: _goToToday,
                  language: displayConfig.calendarLanguage,
                  showShanCalendar: displayConfig.showShanCalendar,
                ),
              ),

              // Main Calendar Content
              SliverToBoxAdapter(
                child: BlocConsumer<CalendarBloc, CalendarState>(
                  listener: (context, state) {
                    if (state is CalendarError) {
                      _analyticsService.logException(
                        exceptionName: 'CalendarLoadError',
                        description: state.message,
                      );
                      _showErrorSnackBar(context, state.message);
                    }

                    // Auto-select today's date on large screens for split view
                    if (state is CalendarLoaded && state.selectedDate == null) {
                      final screenWidth = MediaQuery.sizeOf(context).width;
                      if (screenWidth > 1000) {
                        // Auto-select today's date to show split view
                        final today = state.today;
                        // Use a post-frame callback to avoid modifying state during build
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            context.read<CalendarBloc>().add(
                              SelectDateEvent(today),
                            );
                          }
                        });
                      }
                    }
                    // Replay animation on month change
                    // if (state is CalendarLoaded) {
                    //   _slideController.reset();
                    //   _slideController.forward();
                    // }
                  },
                  builder: (context, state) {
                    if (state is CalendarLoaded) {
                      _lastLoadedState = state;
                    }

                    if (state is CalendarLoading) {
                      if (_lastLoadedState != null) {
                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: _buildCalendarContent(
                            _lastLoadedState!,
                            calendarLanguage: displayConfig.calendarLanguage,
                            showHolidays: displayConfig.showHolidays,
                            showAnniversaryDays:
                                displayConfig.showAnniversaryDays,
                            showSabbaths: displayConfig.showSabbaths,
                            showAstrology: displayConfig.showAstrology,
                            showWesternDates: displayConfig.showWesternDates,
                            showMyanmarDates: displayConfig.showMyanmarDates,
                            showShanCalendar: displayConfig.showShanCalendar,
                          ),
                        );
                      }
                      return _buildLoadingSkeleton();
                    }

                    if (state is CalendarError) {
                      if (_lastLoadedState != null) {
                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: _buildCalendarContent(
                            _lastLoadedState!,
                            calendarLanguage: displayConfig.calendarLanguage,
                            showHolidays: displayConfig.showHolidays,
                            showAnniversaryDays:
                                displayConfig.showAnniversaryDays,
                            showSabbaths: displayConfig.showSabbaths,
                            showAstrology: displayConfig.showAstrology,
                            showWesternDates: displayConfig.showWesternDates,
                            showMyanmarDates: displayConfig.showMyanmarDates,
                            showShanCalendar: displayConfig.showShanCalendar,
                          ),
                        );
                      }
                      return _buildErrorState(state.message);
                    }

                    if (state is CalendarLoaded) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildCalendarContent(
                          state,
                          calendarLanguage: displayConfig.calendarLanguage,
                          showHolidays: displayConfig.showHolidays,
                          showAnniversaryDays:
                              displayConfig.showAnniversaryDays,
                          showSabbaths: displayConfig.showSabbaths,
                          showAstrology: displayConfig.showAstrology,
                          showWesternDates: displayConfig.showWesternDates,
                          showMyanmarDates: displayConfig.showMyanmarDates,
                          showShanCalendar: displayConfig.showShanCalendar,
                        ),
                        // child: SlideTransition(
                        //   position: _slideAnimation,
                        //   child: _buildCalendarContent(state),
                        // ),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleDisplayConfigUpdate(CalendarDisplayConfig currentConfig) {
    final previousConfig = _lastDisplayConfig;
    if (previousConfig == null ||
        previousConfig.calendarLanguage != currentConfig.calendarLanguage) {
      MyanmarCalendar.setLanguage(currentConfig.calendarLanguage);
      MyanmarCalendar.clearCache();
      MyanmarCalendar.configureCache(const CacheConfig.highPerformance());
    }

    if (previousConfig == null) {
      _lastDisplayConfig = currentConfig;
      return;
    }

    _lastDisplayConfig = currentConfig;
    if (!currentConfig.requiresCalendarRefreshComparedTo(previousConfig)) {
      return;
    }

    _visibleEventsMonth = null;
    _visibleEventsStream = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      if (context.read<CalendarBloc>().state is CalendarLoaded) {
        context.read<CalendarBloc>().add(const RefreshCalendar());
      }
    });
  }

  Stream<Map<DateTime, List<CalendarEventItem>>> _eventsStreamForMonth(
    DateTime month,
  ) {
    final currentMonthKey = DateTime(month.year, month.month);
    if (_visibleEventsMonth != null &&
        _visibleEventsStream != null &&
        _visibleEventsMonth!.year == currentMonthKey.year &&
        _visibleEventsMonth!.month == currentMonthKey.month) {
      return _visibleEventsStream!;
    }

    _visibleEventsMonth = currentMonthKey;
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);
    final startDate = startOfMonth.subtract(const Duration(days: 7));
    final endDate = endOfMonth.add(const Duration(days: 7));
    _visibleEventsStream = _eventMarkersPort.watchEventMarkers(
      startDate: startDate,
      endDate: endDate,
    );
    return _visibleEventsStream!;
  }

  Widget _buildCalendarContent(
    CalendarLoaded state, {
    required Language calendarLanguage,
    bool showHolidays = true,
    bool showAnniversaryDays = true,
    bool showSabbaths = true,
    bool showAstrology = true,
    bool showWesternDates = true,
    bool showMyanmarDates = true,
    bool showShanCalendar = true,
  }) {
    return StreamBuilder<Map<DateTime, List<CalendarEventItem>>>(
      stream: _eventsStreamForMonth(state.calendarMonth.month),
      initialData: const <DateTime, List<CalendarEventItem>>{},
      builder: (context, eventsSnapshot) {
        final eventsByDate =
            eventsSnapshot.data ?? const <DateTime, List<CalendarEventItem>>{};

        return LayoutBuilder(
          builder: (context, constraints) {
            final isLargeScreen = constraints.maxWidth > 1000;

            if (isLargeScreen && state.selectedDate != null) {
              // Master-Detail Layout for large screens
              return _buildMasterDetailLayout(
                state,
                calendarLanguage: calendarLanguage,
                eventsByDate: eventsByDate,
                showHolidays: showHolidays,
                showAnniversaryDays: showAnniversaryDays,
                showSabbaths: showSabbaths,
                showAstrology: showAstrology,
                showWesternDates: showWesternDates,
                showMyanmarDates: showMyanmarDates,
                showShanCalendar: showShanCalendar,
              );
            }

            // Standard single-column layout for mobile/tablet
            return _buildStandardLayout(
              state,
              calendarLanguage: calendarLanguage,
              eventsByDate: eventsByDate,
              showHolidays: showHolidays,
              showAnniversaryDays: showAnniversaryDays,
              showSabbaths: showSabbaths,
              showAstrology: showAstrology,
              showWesternDates: showWesternDates,
              showMyanmarDates: showMyanmarDates,
              showShanCalendar: showShanCalendar,
            );
          },
        );
      },
    );
  }

  Widget _buildStandardLayout(
    CalendarLoaded state, {
    required Language calendarLanguage,
    Map<DateTime, List<CalendarEventItem>> eventsByDate =
        const <DateTime, List<CalendarEventItem>>{},
    bool showHolidays = true,
    bool showAnniversaryDays = true,
    bool showSabbaths = true,
    bool showAstrology = true,
    bool showWesternDates = true,
    bool showMyanmarDates = true,
    bool showShanCalendar = true,
  }) {
    return Column(
      children: [
        // Calendar Header with smooth transitions
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: CalendarHeader(
            key: ValueKey(state.calendarMonth.month),
            currentMonth: state.calendarMonth.month,
            monthDates: state.calendarMonth.dates,
            language: calendarLanguage,
            showShanCalendar: showShanCalendar,
            onPreviousMonth: () {
              _analyticsService.logWidgetInteraction(
                widgetName: 'calendar_header',
                actionType: 'previous_month',
                metadata: {
                  'from_month': state.calendarMonth.month.toString(),
                  'to_month': (DateTime(
                    state.calendarMonth.month.year,
                    state.calendarMonth.month.month - 1,
                  )).toString(),
                },
              );
              context.read<CalendarBloc>().add(const NavigateToPreviousMonth());
            },
            onNextMonth: () {
              _analyticsService.logWidgetInteraction(
                widgetName: 'calendar_header',
                actionType: 'next_month',
                metadata: {
                  'from_month': state.calendarMonth.month.toString(),
                  'to_month': (DateTime(
                    state.calendarMonth.month.year,
                    state.calendarMonth.month.month + 1,
                  )).toString(),
                },
              );
              context.read<CalendarBloc>().add(const NavigateToNextMonth());
            },
            onMonthYearTap: () {
              _analyticsService.logButtonClick(
                buttonName: 'month_year_picker',
                buttonLocation: 'calendar_header',
              );
              _showMonthYearPicker(context, state.calendarMonth.month);
            },
          ),
        ),

        // Weekday Header
        WeekdayHeader(language: calendarLanguage),

        // Calendar Grid with page transition
        Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            final selectedDate = state.selectedDate?.date ?? state.today;
            return CalendarKeyboardHandler.handleKeyEvent(
              node,
              event,
              onArrowUp: () => _moveSelection(
                context,
                selectedDate.subtract(const Duration(days: 7)),
              ),
              onArrowDown: () => _moveSelection(
                context,
                selectedDate.add(const Duration(days: 7)),
              ),
              onArrowLeft: () => _moveSelection(
                context,
                selectedDate.subtract(const Duration(days: 1)),
              ),
              onArrowRight: () => _moveSelection(
                context,
                selectedDate.add(const Duration(days: 1)),
              ),
              onEnter: () => _navigateToDayDetails(context, selectedDate),
              onSpace: () => _navigateToDayDetails(context, selectedDate),
              onHome: () =>
                  context.read<CalendarBloc>().add(const NavigateToToday()),
            );
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(
                    begin: 0.95,
                    end: 1.0,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: CalendarGrid(
              key: ValueKey(state.calendarMonth.month),
              gridDates: state.calendarMonth.gridDates,
              currentMonth: state.calendarMonth.month,
              selectedDate: state.selectedDate?.date,
              today: state.today,
              showHolidays: showHolidays,
              showAnniversaryDays: showAnniversaryDays,
              showSabbaths: showSabbaths,
              showAstrology: showAstrology,
              showWesternDates: showWesternDates,
              showMyanmarDates: showMyanmarDates,
              eventsByDate: eventsByDate,
              onDateTap: (date) {
                _analyticsService.logDateSelection(
                  selectedDate: date.toString(),
                  calendarType: 'myanmar',
                  dateFormat: '${date.year}/${date.month}/${date.day}',
                );

                context.read<CalendarBloc>().add(SelectDateEvent(date));
                _navigateToDayDetails(context, date);
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMasterDetailLayout(
    CalendarLoaded state, {
    required Language calendarLanguage,
    Map<DateTime, List<CalendarEventItem>> eventsByDate =
        const <DateTime, List<CalendarEventItem>>{},
    bool showHolidays = true,
    bool showAnniversaryDays = true,
    bool showSabbaths = true,
    bool showAstrology = true,
    bool showWesternDates = true,
    bool showMyanmarDates = true,
    bool showShanCalendar = true,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Calendar Grid (Master) - 2/3 width
        Expanded(
          flex: 2,
          child: Column(
            children: [
              // Calendar Header
              CalendarHeader(
                key: ValueKey(state.calendarMonth.month),
                currentMonth: state.calendarMonth.month,
                monthDates: state.calendarMonth.dates,
                language: calendarLanguage,
                showShanCalendar: showShanCalendar,
                onPreviousMonth: () {
                  _analyticsService.logWidgetInteraction(
                    widgetName: 'calendar_header',
                    actionType: 'previous_month',
                    metadata: {
                      'from_month': state.calendarMonth.month.toString(),
                      'to_month': (DateTime(
                        state.calendarMonth.month.year,
                        state.calendarMonth.month.month - 1,
                      )).toString(),
                    },
                  );
                  context.read<CalendarBloc>().add(
                    const NavigateToPreviousMonth(),
                  );
                },
                onNextMonth: () {
                  _analyticsService.logWidgetInteraction(
                    widgetName: 'calendar_header',
                    actionType: 'next_month',
                    metadata: {
                      'from_month': state.calendarMonth.month.toString(),
                      'to_month': (DateTime(
                        state.calendarMonth.month.year,
                        state.calendarMonth.month.month + 1,
                      )).toString(),
                    },
                  );
                  context.read<CalendarBloc>().add(const NavigateToNextMonth());
                },
                onMonthYearTap: () {
                  _analyticsService.logButtonClick(
                    buttonName: 'month_year_picker',
                    buttonLocation: 'calendar_header',
                  );
                  _showMonthYearPicker(context, state.calendarMonth.month);
                },
              ),

              // Weekday Header
              WeekdayHeader(language: calendarLanguage),

              // Calendar Grid
              Focus(
                autofocus: true,
                onKeyEvent: (node, event) {
                  final selectedDate = state.selectedDate?.date ?? state.today;
                  return CalendarKeyboardHandler.handleKeyEvent(
                    node,
                    event,
                    onArrowUp: () => _moveSelection(
                      context,
                      selectedDate.subtract(const Duration(days: 7)),
                    ),
                    onArrowDown: () => _moveSelection(
                      context,
                      selectedDate.add(const Duration(days: 7)),
                    ),
                    onArrowLeft: () => _moveSelection(
                      context,
                      selectedDate.subtract(const Duration(days: 1)),
                    ),
                    onArrowRight: () => _moveSelection(
                      context,
                      selectedDate.add(const Duration(days: 1)),
                    ),
                    onEnter: () => context.read<CalendarBloc>().add(
                      SelectDateEvent(selectedDate),
                    ),
                    onSpace: () => context.read<CalendarBloc>().add(
                      SelectDateEvent(selectedDate),
                    ),
                    onHome: () => context.read<CalendarBloc>().add(
                      const NavigateToToday(),
                    ),
                  );
                },
                child: CalendarGrid(
                  key: ValueKey(state.calendarMonth.month),
                  gridDates: state.calendarMonth.gridDates,
                  currentMonth: state.calendarMonth.month,
                  selectedDate: state.selectedDate?.date,
                  today: state.today,
                  showHolidays: showHolidays,
                  showAnniversaryDays: showAnniversaryDays,
                  showSabbaths: showSabbaths,
                  showAstrology: showAstrology,
                  showWesternDates: showWesternDates,
                  showMyanmarDates: showMyanmarDates,
                  eventsByDate: eventsByDate,
                  onDateTap: (date) {
                    _analyticsService.logDateSelection(
                      selectedDate: date.toString(),
                      calendarType: 'myanmar',
                      dateFormat: '${date.year}/${date.month}/${date.day}',
                    );
                    // In split view, just select the date, don't navigate
                    context.read<CalendarBloc>().add(SelectDateEvent(date));
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 16),

        // Right: Day Details (Detail) - 1/3 width, max 400px
        Flexible(
          flex: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: _buildDayDetailsPanel(state, showShanCalendar),
          ),
        ),
      ],
    );
  }

  Widget _buildDayDetailsPanel(CalendarLoaded state, bool showShanCalendar) {
    if (state.selectedDate == null) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      child: DayDetailsContent(
        date: state.selectedDate!.date,
        completeDate: state.selectedDate!.completeDate,
        showShanCalendar: showShanCalendar,
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return SizedBox(
      height: 420,
      child: Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: context.colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                context.read<CalendarBloc>().add(
                  LoadCalendarMonth(DateTime.now()),
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDayDetails(BuildContext context, DateTime date) {
    _analyticsService.logButtonClick(
      buttonName: 'view_day_details',
      buttonLocation: 'calendar_grid',
      additionalData: {'date': date.toString()},
    );

    // Add subtle haptic feedback
    getIt<TelegramService>().hapticImpact('light');

    // Check if we're in large screen mode
    final screenWidth = MediaQuery.sizeOf(context).width;
    if (screenWidth > 1000) {
      // In split view, just select the date, don't navigate
      context.read<CalendarBloc>().add(SelectDateEvent(date));
    } else {
      // On small screens, navigate to full-page details
      final dateStr = date.toIso8601String();
      GoRouter.of(context).go("/home/${RoutePaths.dayDetails}?date=$dateStr");
    }
  }

  void _moveSelection(BuildContext context, DateTime date) {
    context.read<CalendarBloc>().add(SelectDateEvent(date));
    getIt<TelegramService>().hapticSelectionChanged();
  }

  void _showMonthYearPicker(BuildContext context, DateTime currentMonth) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (dialogContext) => _MonthYearPickerBottomSheet(
        currentMonth: currentMonth,
        analyticsService: _analyticsService,
        onMonthSelected: (month) {
          _analyticsService.logSettingsChange(
            settingName: 'calendar_month',
            oldValue: currentMonth.month,
            newValue: month.month,
          );

          context.read<CalendarBloc>().add(LoadCalendarMonth(month));
          Navigator.of(dialogContext).pop();
        },
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: context.colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _goToToday() {
    final today = DateTime.now();
    _analyticsService.logButtonClick(
      buttonName: 'today',
      buttonLocation: 'calendar_app_bar',
    );
    context.read<CalendarBloc>().add(const NavigateToToday());
    context.read<CalendarBloc>().add(SelectDateEvent(today));
  }
}

class _MonthYearPickerBottomSheet extends StatefulWidget {
  final DateTime currentMonth;
  final AnalyticsPort analyticsService;
  final Function(DateTime) onMonthSelected;

  const _MonthYearPickerBottomSheet({
    required this.currentMonth,
    required this.analyticsService,
    required this.onMonthSelected,
  });

  @override
  State<_MonthYearPickerBottomSheet> createState() =>
      _MonthYearPickerBottomSheetState();
}

class _MonthYearPickerBottomSheetState
    extends State<_MonthYearPickerBottomSheet> {
  static const int _minYear = 1900;
  static const int _maxYear = 2100;

  late int selectedYear;
  late int selectedMonth;
  late final FixedExtentScrollController _yearController;

  @override
  void initState() {
    super.initState();
    selectedYear = widget.currentMonth.year;
    selectedMonth = widget.currentMonth.month;
    _yearController = FixedExtentScrollController(
      initialItem: selectedYear - _minYear,
    );

    widget.analyticsService.logWidgetInteraction(
      widgetName: 'month_year_picker',
      actionType: 'opened',
    );
  }

  @override
  void dispose() {
    _yearController.dispose();
    super.dispose();
  }

  void _shiftYear(int delta) {
    final nextYear = (selectedYear + delta).clamp(_minYear, _maxYear);
    if (nextYear == selectedYear) return;
    setState(() {
      selectedYear = nextYear;
    });
    _yearController.animateToItem(
      selectedYear - _minYear,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _selectToday() {
    final now = DateTime.now();
    setState(() {
      selectedYear = now.year;
      selectedMonth = now.month;
    });
    _yearController.animateToItem(
      selectedYear - _minYear,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
    widget.analyticsService.logWidgetInteraction(
      widgetName: 'month_year_picker',
      actionType: 'jump_to_today',
      metadata: {
        'year': selectedYear.toString(),
        'month': selectedMonth.toString(),
      },
    );
  }

  void _applySelection() {
    widget.analyticsService.logWidgetInteraction(
      widgetName: 'month_year_picker',
      actionType: 'applied',
      metadata: {
        'year': selectedYear.toString(),
        'month': selectedMonth.toString(),
      },
    );
    widget.onMonthSelected(DateTime(selectedYear, selectedMonth, 1));
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final selectedLabel = '${_getMonthName(selectedMonth)} $selectedYear';

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: context.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.32,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jump to month',
                      style: context.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.6,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Previous year',
                    onPressed: () => _shiftYear(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: ListWheelScrollView.useDelegate(
                      controller: _yearController,
                      itemExtent: 40,
                      physics: const FixedExtentScrollPhysics(),
                      perspective: 0.004,
                      onSelectedItemChanged: (index) {
                        final year = _minYear + index;
                        if (year == selectedYear) return;
                        setState(() {
                          selectedYear = year;
                        });
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: _maxYear - _minYear + 1,
                        builder: (context, index) {
                          final year = _minYear + index;
                          final isSelected = year == selectedYear;
                          return Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 160),
                              style: context.textTheme.titleMedium!.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                                color: isSelected
                                    ? context.colorScheme.primary
                                    : context.colorScheme.onSurfaceVariant,
                              ),
                              child: Text(year.toString()),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Next year',
                    onPressed: () => _shiftYear(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: _selectToday,
                icon: const Icon(Icons.today, size: 18),
                label: const Text('Today'),
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 12,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1.9,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final month = index + 1;
                final isSelected = month == selectedMonth;
                final isCurrentMonth =
                    selectedYear == now.year && month == now.month;

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        selectedMonth = month;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? context.colorScheme.primaryContainer
                            : context.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? context.colorScheme.primary
                              : (isCurrentMonth
                                    ? context.colorScheme.primary.withValues(
                                        alpha: 0.6,
                                      )
                                    : context.colorScheme.outlineVariant),
                          width: isSelected ? 1.8 : 1.0,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _getMonthName(month),
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: isSelected
                                ? context.colorScheme.onPrimaryContainer
                                : context.colorScheme.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _applySelection,
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    return TranslationService.getShortWesternMonthName(month - 1);
  }
}
