import 'package:firebase_analytics_app/firebase_analytics_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/core.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';
import 'package:go_router/go_router.dart';
import 'package:settings/settings.dart';
import 'package:shimmer/shimmer.dart';

import '../../di/calendar_injection.dart';
import '../bloc/calendar_bloc.dart';
import '../bloc/calendar_event.dart';
import '../bloc/calendar_state.dart';
import '../widgets/calendar_app_bar.dart';
import '../widgets/calendar_header.dart';
import '../widgets/weekday_header.dart';
import '../widgets/calendar_grid.dart';
// import '../widgets/astrology_expandable_card.dart';

class CalendarHomePage extends StatefulWidget {
  const CalendarHomePage({super.key});

  @override
  State<CalendarHomePage> createState() => _CalendarHomePageState();
}

class _CalendarHomePageState extends State<CalendarHomePage>
    with TickerProviderStateMixin {
  final AnalyticsService _analyticsService = getIt<AnalyticsService>();

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

  @override
  void dispose() {
    _fadeController.dispose();
    // _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          // Get display preferences from settings
          final showHolidays = settingsState is SettingsLoaded
              ? settingsState.settings.showHolidays
              : true;
          final showAnniversaryDays = settingsState is SettingsLoaded
              ? settingsState.settings.showAnniversaryDays
              : true;
          final showSabbaths = settingsState is SettingsLoaded
              ? settingsState.settings.showSabbaths
              : true;
          final showAstrology = settingsState is SettingsLoaded
              ? settingsState.settings.showAstrology
              : false;
          final showWesternDates = settingsState is SettingsLoaded
              ? settingsState.settings.showWesternDates
              : true;
          final showMyanmarDates = settingsState is SettingsLoaded
              ? settingsState.settings.showMyanmarDates
              : true;

          final showShanCalendar = settingsState is SettingsLoaded
              ? settingsState.settings.showShanCalendar
              : true;

          final calendarLanguage = settingsState is SettingsLoaded
              ? settingsState.settings.calendarLanguage
              : Language.myanmar;

          return CustomScrollView(
            slivers: [
              // Compact App Bar
              SliverToBoxAdapter(
                child: CalendarAppBar(
                  language: calendarLanguage,
                  showShanCalendar: showShanCalendar,
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
                    // Replay animation on month change
                    // if (state is CalendarLoaded) {
                    //   _slideController.reset();
                    //   _slideController.forward();
                    // }
                  },
                  builder: (context, state) {
                    if (state is CalendarLoading) {
                      return _buildLoadingSkeleton();
                    }

                    if (state is CalendarError) {
                      return _buildErrorState(state.message);
                    }

                    if (state is CalendarLoaded) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildCalendarContent(
                          state,
                          showHolidays: showHolidays,
                          showAnniversaryDays: showAnniversaryDays,
                          showSabbaths: showSabbaths,
                          showAstrology: showAstrology,
                          showWesternDates: showWesternDates,
                          showMyanmarDates: showMyanmarDates,
                          showShanCalendar: showShanCalendar,
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

  Widget _buildCalendarContent(
    CalendarLoaded state, {
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
            return FadeTransition(
              opacity: animation,
              child: child,
              // child: SlideTransition(
              //   position: Tween<Offset>(
              //     begin: const Offset(0, -0.1),
              //     end: Offset.zero,
              //   ).animate(animation),
              //   child: child,
              // ),
            );
          },
          child: CalendarHeader(
            key: ValueKey(state.calendarMonth.month),
            currentMonth: state.calendarMonth.month,
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
            onTodayTap: () {
              _analyticsService.logButtonClick(
                buttonName: 'today',
                buttonLocation: 'calendar_header',
              );
              context.read<CalendarBloc>().add(const NavigateToToday());
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
        const WeekdayHeader(),

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
              eventsByDate: state.eventsByDate,
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

  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        highlightColor: Theme.of(
          context,
        ).colorScheme.secondary.withValues(alpha: 0.2),
        child: Column(
          children: [
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
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
    HapticFeedback.lightImpact();

    GoRouter.of(
      context,
    ).go("/home/${RoutePaths.dayDetails}", extra: {"date": date});
  }

  void _moveSelection(BuildContext context, DateTime date) {
    context.read<CalendarBloc>().add(SelectDateEvent(date));
    HapticFeedback.selectionClick();
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
}

class _MonthYearPickerBottomSheet extends StatefulWidget {
  final DateTime currentMonth;
  final AnalyticsService analyticsService;
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
  late int selectedYear;
  late int selectedMonth;

  @override
  void initState() {
    super.initState();
    selectedYear = widget.currentMonth.year;
    selectedMonth = widget.currentMonth.month;

    widget.analyticsService.logWidgetInteraction(
      widgetName: 'month_year_picker',
      actionType: 'opened',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.colorScheme.onSurfaceVariant.withValues(
                alpha: 0.4,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'Select Month & Year',
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),

          // Year selector
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: context.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    widget.analyticsService.logWidgetInteraction(
                      widgetName: 'year_selector',
                      actionType: 'previous_year',
                      metadata: {
                        'from_year': selectedYear.toString(),
                        'to_year': (selectedYear - 1).toString(),
                      },
                    );
                    setState(() => selectedYear--);
                  },
                ),
                const SizedBox(width: 16),
                Text(
                  selectedYear.toString(),
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    widget.analyticsService.logWidgetInteraction(
                      widgetName: 'year_selector',
                      actionType: 'next_year',
                      metadata: {
                        'from_year': selectedYear.toString(),
                        'to_year': (selectedYear + 1).toString(),
                      },
                    );
                    setState(() => selectedYear++);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Month grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 2.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: List.generate(12, (index) {
              final month = index + 1;
              final isSelected =
                  month == selectedMonth &&
                  selectedYear == widget.currentMonth.year;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    widget.analyticsService.logWidgetInteraction(
                      widgetName: 'month_picker',
                      actionType: 'month_selected',
                      metadata: {
                        'selected_month': month.toString(),
                        'selected_year': selectedYear.toString(),
                      },
                    );
                    widget.onMonthSelected(DateTime(selectedYear, month, 1));
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.colorScheme.primaryContainer
                          : context.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(
                              color: context.colorScheme.primary,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        _getMonthName(month),
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: isSelected
                              ? context.colorScheme.onPrimaryContainer
                              : context.colorScheme.onSurface,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    return TranslationService.getShortWesternMonthName(month - 1);
  }
}
