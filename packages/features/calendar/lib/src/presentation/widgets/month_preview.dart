import 'package:shared_core/shared_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

import '../bloc/calendar_bloc.dart';
import '../bloc/calendar_event.dart';
import '../bloc/calendar_state.dart';
import 'calendar_grid.dart';
import 'weekday_header.dart';

class MonthPreview extends StatefulWidget {
  final DateTime date;

  final Function(DateTime date)? onDateTap;

  const MonthPreview({super.key, required this.date, this.onDateTap});

  @override
  State<MonthPreview> createState() => _MonthPreviewState();
}

class _MonthPreviewState extends State<MonthPreview>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _ensurePreviewMonthLoaded();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Start animations
    _fadeController.forward();
  }

  void _ensurePreviewMonthLoaded() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final calendarState = context.read<CalendarBloc>().state;
      if (calendarState is! CalendarLoaded ||
          calendarState.calendarMonth.month.year != widget.date.year ||
          calendarState.calendarMonth.month.month != widget.date.month) {
        context.read<CalendarBloc>().add(LoadCalendarMonth(widget.date));
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CalendarBloc, CalendarState>(
      listener: (context, state) {
        if (state is CalendarError) {
          _showErrorSnackBar(context, state.message);
        }
      },
      builder: (context, state) {
        if (state is CalendarInitial) {
          context.read<CalendarBloc>().add(LoadCalendarMonth(widget.date));
          return _buildLoadingSkeleton();
        }

        if (state is CalendarLoading) {
          return _buildLoadingSkeleton();
        }

        if (state is CalendarError) {
          return _buildErrorState(state.message);
        }

        if (state is CalendarLoaded) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: _buildCalendarContent(state),
            // child: SlideTransition(
            //   position: _slideAnimation,
            //   child: _buildCalendarContent(state),
            // ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCalendarContent(CalendarLoaded state) {
    return Column(
      children: [
        // Weekday Header
        const WeekdayHeader(),

        // Calendar Grid with page transition
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
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
            showHolidays: false,
            showAstrology: false,
            showWesternDates: true,
            showMyanmarDates: true,
            eventsByDate: state.eventsByDate,
            onDateTap: (date) {
              widget.onDateTap?.call(date);
            },
          ),
        ),

        // const SizedBox(height: 8),

        // // Astrology Card with smooth expansion
        // _buildAstrologyCard(state),
        const SizedBox(height: 16),
      ],
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
              height: 200,
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
                  LoadCalendarMonth(widget.date),
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
}
