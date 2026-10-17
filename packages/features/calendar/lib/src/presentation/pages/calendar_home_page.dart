import 'package:shared_core/shared_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:go_router/go_router.dart';
import 'package:telegram_web/telegram_web.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';
import 'package:shared_localizations/shared_localizations.dart';

import '../../di/calendar_injection.dart';
import '../bloc/calendar_bloc.dart';
import '../bloc/calendar_event.dart';
import '../bloc/calendar_state.dart';
import '../widgets/calendar_header.dart';
import '../widgets/weekday_header.dart';
import '../widgets/calendar_grid.dart';
import '../widgets/day_cells.dart';
import '../widgets/day_details_content.dart';
import '../widgets/home_day_sheet.dart';
import '../../utils/utils.dart';

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
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<CalendarDisplayConfig>(
          stream: _calendarDisplayConfigPort.watchDisplayConfig(),
          initialData: CalendarDisplayConfig.defaults(),
          builder: (context, configSnapshot) {
            final displayConfig =
                configSnapshot.data ?? CalendarDisplayConfig.defaults();
            _handleDisplayConfigUpdate(displayConfig);

            return BlocConsumer<CalendarBloc, CalendarState>(
              listener: (context, state) {
                if (state is CalendarError) {
                  _analyticsService.logException(
                    exceptionName: 'CalendarLoadError',
                    description: state.message,
                  );
                  _showErrorSnackBar(context, state.message);
                }

                // The split view always shows a day: start with today.
                if (state is CalendarLoaded &&
                    state.selectedDate == null &&
                    MediaQuery.sizeOf(context).width >= _splitBreakpoint) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      context.read<CalendarBloc>().add(
                        SelectDateEvent(state.today),
                      );
                    }
                  });
                }
              },
              builder: (context, state) {
                if (state is CalendarLoaded) {
                  _lastLoadedState = state;
                }
                final shown = _lastLoadedState;
                if (shown == null) {
                  return state is CalendarError
                      ? _buildErrorState(state.message)
                      : _buildLoadingSkeleton();
                }
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildCalendarContent(shown, displayConfig),
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Phones get the fitted grid plus the pull-up day sheet; tablets the
  /// fitted grid alone; from [_splitBreakpoint] the selected day opens
  /// beside the month.
  static const double _phoneBreakpoint = 600;
  static const double _splitBreakpoint = 1024;

  void _handleDisplayConfigUpdate(CalendarDisplayConfig currentConfig) {
    final previousConfig = _lastDisplayConfig;
    final requiresRefresh =
        previousConfig == null ||
        currentConfig.requiresCalendarRefreshComparedTo(previousConfig);

    if (requiresRefresh) {
      applyMyanmarCalendarRuntimeConfig(
        baseConfig: currentConfig.calendarConfig,
        language: currentConfig.calendarLanguage,
        useDeviceTimezone: currentConfig.useDeviceTimezone,
        cacheProfile: MyanmarCalendarCacheProfile.highPerformance,
      );
    }

    if (previousConfig == null) {
      _lastDisplayConfig = currentConfig;
      return;
    }

    _lastDisplayConfig = currentConfig;
    if (!requiresRefresh) {
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

  KeyEventResult _handleGridKeyEvent({
    required KeyEvent event,
    required DateTime selectedDate,
    required VoidCallback onActivate,
  }) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp) {
      _moveSelection(context, selectedDate.subtract(const Duration(days: 7)));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      _moveSelection(context, selectedDate.add(const Duration(days: 7)));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      _moveSelection(context, selectedDate.subtract(const Duration(days: 1)));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      _moveSelection(context, selectedDate.add(const Duration(days: 1)));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space) {
      onActivate();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.home) {
      context.read<CalendarBloc>().add(const NavigateToToday());
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
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
    CalendarLoaded state,
    CalendarDisplayConfig config,
  ) {
    return StreamBuilder<Map<DateTime, List<CalendarEventItem>>>(
      stream: _eventsStreamForMonth(state.calendarMonth.month),
      initialData: const <DateTime, List<CalendarEventItem>>{},
      builder: (context, eventsSnapshot) {
        final eventsByDate =
            eventsSnapshot.data ?? const <DateTime, List<CalendarEventItem>>{};

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            if (width >= _splitBreakpoint && state.selectedDate != null) {
              return _buildSplitLayout(state, config, eventsByDate);
            }
            if (width < _phoneBreakpoint) {
              return _buildPhoneLayout(state, config, eventsByDate);
            }
            return Column(
              children: [
                _buildHeader(state, config),
                WeekdayHeader(language: config.calendarLanguage),
                Expanded(
                  child: _buildGrid(
                    state,
                    config,
                    eventsByDate,
                    maxRowHeightFactor: 1.4,
                    onDateTap: (date) {
                      context.read<CalendarBloc>().add(SelectDateEvent(date));
                      _navigateToDayDetails(context, date);
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            );
          },
        );
      },
    );
  }

  /// The day the phone sheet describes: the selection, else today when it
  /// is in view, else the first of the month.
  CompleteDate _sheetDay(CalendarLoaded state) =>
      state.selectedDate?.completeDate ??
      state.todayCompleteDate ??
      state.calendarMonth.dates.first;

  Widget _buildPhoneLayout(
    CalendarLoaded state,
    CalendarDisplayConfig config,
    Map<DateTime, List<CalendarEventItem>> eventsByDate,
  ) {
    final day = _sheetDay(state);
    final dayDate = DateTime(day.westernYear, day.westernMonth, day.westernDay);
    final options = DayCellOptions(
      showHolidays: config.showHolidays,
      showAnniversaryDays: config.showAnniversaryDays,
      showSabbaths: config.showSabbaths,
      showAstrology: config.showAstrology,
      showWesternDates: config.showWesternDates,
      showMyanmarDates: config.showMyanmarDates,
    );

    return Column(
      children: [
        _buildHeader(state, config),
        WeekdayHeader(language: config.calendarLanguage),
        Expanded(
          child: LayoutBuilder(
            builder: (context, area) {
              final peek = HomeDaySheet.peekHeight(context);
              final rows = CalendarGrid.visibleRows(
                state.calendarMonth.gridDates,
                state.calendarMonth.month,
              ).length;
              final rowHeight = CalendarGrid.rowHeightFor(
                size: Size(area.maxWidth, area.maxHeight - peek),
                rows: rows,
              );
              final gridHeight = rowHeight * rows;
              final peekFraction =
                  ((area.maxHeight - gridHeight) / area.maxHeight).clamp(
                    .05,
                    .9,
                  );

              return Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: gridHeight,
                    child: _buildGrid(
                      state,
                      config,
                      eventsByDate,
                      highlighted: dayDate,
                      onDateTap: (date) {
                        _analyticsService.logDateSelection(
                          selectedDate: date.toString(),
                          calendarType: 'myanmar',
                          dateFormat: '${date.year}/${date.month}/${date.day}',
                        );
                        if (DateUtils.isSameDay(date, dayDate)) {
                          _navigateToDayDetails(context, date);
                        } else {
                          _moveSelection(context, date);
                        }
                      },
                    ),
                  ),
                  StreamBuilder<Map<DateTime, List<CalendarEventItem>>>(
                    stream: _upcomingEventsStream(state.today),
                    initialData: const <DateTime, List<CalendarEventItem>>{},
                    builder: (context, upcoming) => HomeDaySheet(
                      key: ValueKey(peekFraction.toStringAsFixed(3)),
                      peekFraction: peekFraction,
                      day: day,
                      today: state.today,
                      events:
                          eventsByDate[dayDate] ?? const <CalendarEventItem>[],
                      upcomingEvents:
                          upcoming.data ??
                          const <DateTime, List<CalendarEventItem>>{},
                      options: options,
                      onOpenDetails: (date) =>
                          _navigateToDayDetails(context, date),
                      onOpenDay: (date) => _navigateToDayDetails(context, date),
                      onOpenEvent: (event) => event.id == null
                          ? _navigateToDayDetails(context, event.eventDate)
                          : GoRouter.of(
                              context,
                            ).push('${RoutePaths.events}/${event.id}/detail'),
                      onAddEvent: (date) => GoRouter.of(
                        context,
                      ).push('${RoutePaths.events}/create', extra: date),
                      onStudioTap: () =>
                          GoRouter.of(context).push(RoutePaths.studio),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(CalendarLoaded state, CalendarDisplayConfig config) {
    final month = state.calendarMonth.month;
    final selected = state.selectedDate?.date;
    final atToday =
        month.year == state.today.year &&
        month.month == state.today.month &&
        (selected == null || DateUtils.isSameDay(selected, state.today));

    return CalendarHeader(
      key: ValueKey(month),
      currentMonth: month,
      monthDates: state.calendarMonth.dates,
      language: config.calendarLanguage,
      showShanCalendar: config.showShanCalendar,
      onToday: atToday
          ? null
          : () => context.read<CalendarBloc>().add(const NavigateToToday()),
      onStudioTap: () => GoRouter.of(context).push(RoutePaths.studio),
      onPreviousMonth: () => _changeMonth(state, -1),
      onNextMonth: () => _changeMonth(state, 1),
      onMonthYearTap: () {
        _analyticsService.logButtonClick(
          buttonName: 'month_year_picker',
          buttonLocation: 'calendar_header',
        );
        _showMonthYearPicker(context, month);
      },
    );
  }

  void _changeMonth(CalendarLoaded state, int delta) {
    final from = state.calendarMonth.month;
    _analyticsService.logWidgetInteraction(
      widgetName: 'calendar_header',
      actionType: delta < 0 ? 'previous_month' : 'next_month',
      metadata: {
        'from_month': from.toString(),
        'to_month': DateTime(from.year, from.month + delta).toString(),
      },
    );
    context.read<CalendarBloc>().add(
      delta < 0 ? const NavigateToPreviousMonth() : const NavigateToNextMonth(),
    );
  }

  /// The month grid with keyboard navigation and swipe-to-change-month.
  Widget _buildGrid(
    CalendarLoaded state,
    CalendarDisplayConfig config,
    Map<DateTime, List<CalendarEventItem>> eventsByDate, {
    required ValueChanged<DateTime> onDateTap,
    DateTime? highlighted,
    double maxRowHeightFactor = 1.6,
  }) {
    final selectedDate = highlighted ?? state.selectedDate?.date;
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        final current = selectedDate ?? state.today;
        return _handleGridKeyEvent(
          event: event,
          selectedDate: current,
          onActivate: () => onDateTap(current),
        );
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity.abs() < 250) return;
          _changeMonth(state, velocity < 0 ? 1 : -1);
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.topCenter,
            children: [...previous, ?current],
          ),
          child: CalendarGrid(
            key: ValueKey(state.calendarMonth.month),
            gridDates: state.calendarMonth.gridDates,
            currentMonth: state.calendarMonth.month,
            selectedDate: selectedDate,
            today: state.today,
            gridStyle: config.gridStyle,
            maxRowHeightFactor: maxRowHeightFactor,
            showHolidays: config.showHolidays,
            showAnniversaryDays: config.showAnniversaryDays,
            showSabbaths: config.showSabbaths,
            showAstrology: config.showAstrology,
            showWesternDates: config.showWesternDates,
            showMyanmarDates: config.showMyanmarDates,
            eventsByDate: eventsByDate,
            onDateTap: onDateTap,
          ),
        ),
      ),
    );
  }

  Widget _buildSplitLayout(
    CalendarLoaded state,
    CalendarDisplayConfig config,
    Map<DateTime, List<CalendarEventItem>> eventsByDate,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildHeader(state, config),
              WeekdayHeader(language: config.calendarLanguage),
              Expanded(
                child: _buildGrid(
                  state,
                  config,
                  eventsByDate,
                  maxRowHeightFactor: 1.2,
                  onDateTap: (date) {
                    _analyticsService.logDateSelection(
                      selectedDate: date.toString(),
                      calendarType: 'myanmar',
                      dateFormat: '${date.year}/${date.month}/${date.day}',
                    );
                    context.read<CalendarBloc>().add(SelectDateEvent(date));
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          flex: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              child: DayDetailsContent(
                date: state.selectedDate!.date,
                completeDate: state.selectedDate!.completeDate,
                showShanCalendar: config.showShanCalendar,
              ),
            ),
          ),
        ),
      ],
    );
  }

  DateTime? _upcomingFrom;
  Stream<Map<DateTime, List<CalendarEventItem>>>? _upcomingStream;

  Stream<Map<DateTime, List<CalendarEventItem>>> _upcomingEventsStream(
    DateTime today,
  ) {
    final from = DateUtils.dateOnly(today);
    if (_upcomingStream != null && _upcomingFrom == from) {
      return _upcomingStream!;
    }
    _upcomingFrom = from;
    return _upcomingStream = _eventMarkersPort.watchEventMarkers(
      startDate: from,
      endDate: from.add(const Duration(days: 31)),
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
              AppLocalizations.of(context)?.somethingWentWrong ??
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
              label: Text(
                AppLocalizations.of(context)?.tryAgain ?? 'Try Again',
              ),
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
    _haptics?.hapticImpact('light');

    // This callback is used by the single-column layout. Whether the detail
    // pane is visible is decided from the calendar's actual LayoutBuilder
    // constraints, which can be narrower than MediaQuery on iPad because of
    // the navigation rail. The split layout handles taps inline instead.
    final dateStr = date.toIso8601String();
    GoRouter.of(context).go("/home/${RoutePaths.dayDetails}?date=$dateStr");
  }

  /// Telegram haptics, when the app runs inside Telegram's host.
  TelegramService? get _haptics =>
      getIt.isRegistered<TelegramService>() ? getIt<TelegramService>() : null;

  void _moveSelection(BuildContext context, DateTime date) {
    context.read<CalendarBloc>().add(SelectDateEvent(date));
    _haptics?.hapticSelectionChanged();
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

  void _showErrorSnackBar(BuildContext context, String message) =>
      context.showToast(message, kind: AppToastKind.error);
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
    final l10n = AppLocalizations.of(context);

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
                      l10n?.calendarJumpToMonth ?? 'Jump to month',
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
                    tooltip: l10n?.calendarPreviousYear ?? 'Previous year',
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
                    tooltip: l10n?.calendarNextYear ?? 'Next year',
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
                label: Text(l10n?.today ?? 'Today'),
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
                    child: Text(l10n?.cancel ?? 'Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _applySelection,
                    child: Text(l10n?.apply ?? 'Apply'),
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
    return getShortWesternMonthName(month, MyanmarCalendar.currentLanguage);
  }
}
