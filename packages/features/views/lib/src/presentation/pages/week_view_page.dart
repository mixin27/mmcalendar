import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart'
    hide MoonPhaseIndicator, CompactMoonPhaseIndicator;
import 'package:go_router/go_router.dart';

import '../bloc/views_bloc.dart';
import '../bloc/views_event.dart';
import '../bloc/views_state.dart';

class WeekViewPage extends StatefulWidget {
  const WeekViewPage({super.key});

  @override
  State<WeekViewPage> createState() => _WeekViewPageState();
}

class _WeekViewPageState extends State<WeekViewPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppConstants.mediumAnimationDuration,
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<ViewsBloc, ViewsState>(
        listener: (context, state) {
          if (state is ViewsError) {
            _showErrorSnackBar(context, state.message);
          }
          if (state is WeekViewLoaded) {
            _animationController.reset();
            _animationController.forward();
          }
        },
        builder: (context, state) {
          if (state is ViewsInitial) {
            context.read<ViewsBloc>().add(LoadWeekView(DateTime.now()));
            return _buildLoadingState();
          }

          if (state is ViewsLoading) {
            return _buildLoadingState();
          }

          if (state is ViewsError) {
            return _buildErrorState(state.message);
          }

          if (state is WeekViewLoaded) {
            return _buildWeekContent(state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildWeekContent(WeekViewLoaded state) {
    return CustomScrollView(
      slivers: [
        // App Bar
        _buildAppBar(state),

        // Week Days List
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverFadeTransition(
            opacity: _fadeAnimation,
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final dayInfo = state.weekData.days[index];
                final date = dayInfo.western.toDateTime();
                final isToday = date.isToday;

                return _buildDayCard(dayInfo, date, isToday, index);
              }, childCount: state.weekData.days.length),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(WeekViewLoaded state) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16, right: 16),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Week ${state.weekData.weekNumber}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              '${state.weekData.weekStart.format('MMM d')} - ${state.weekData.weekEnd.format('MMM d')}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
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
                context.colorScheme.secondaryContainer,
                context.colorScheme.secondaryContainer.withValues(alpha: 0.7),
              ],
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            HapticFeedback.lightImpact();
            context.read<ViewsBloc>().add(const NavigateWeekPrevious());
          },
          tooltip: 'Previous Week',
        ),
        IconButton(
          icon: const Icon(Icons.today),
          onPressed: () {
            HapticFeedback.lightImpact();
            context.read<ViewsBloc>().add(LoadWeekView(DateTime.now()));
          },
          tooltip: 'This Week',
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            HapticFeedback.lightImpact();
            context.read<ViewsBloc>().add(const NavigateWeekNext());
          },
          tooltip: 'Next Week',
        ),
      ],
    );
  }

  Widget _buildDayCard(
    CompleteDate dayInfo,
    DateTime date,
    bool isToday,
    int index,
  ) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isToday
                ? context.colorScheme.primary
                : context.colorScheme.outlineVariant,
            width: isToday ? 2 : 1,
          ),
        ),
        child: Container(
          decoration: isToday
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      context.colorScheme.primaryContainer.withValues(
                        alpha: 0.3,
                      ),
                      context.colorScheme.primaryContainer.withValues(
                        alpha: 0.1,
                      ),
                    ],
                  ),
                )
              : null,
          child: InkWell(
            onTap: () {
              // Navigate to day details
              context.read<ViewsBloc>().add(LoadDayView(date));
              GoRouter.of(context).go('/views/day', extra: date);
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Badge
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isToday
                          ? context.colorScheme.primary
                          : context.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          date.day.toString(),
                          style: context.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isToday
                                ? context.colorScheme.onPrimary
                                : context.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          date.format('EEE'),
                          style: context.textTheme.bodySmall?.copyWith(
                            color: isToday
                                ? context.colorScheme.onPrimary.withValues(
                                    alpha: 0.8,
                                  )
                                : context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          date.format('MMMM d, yyyy'),
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dayInfo.formatMyanmar(),
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: context.colorScheme.primary,
                          ),
                        ),

                        // Moon Phase
                        if (dayInfo.isFullMoon || dayInfo.isNewMoon) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              CompactMoonPhaseIndicator(
                                moonPhase: dayInfo.moonPhase,
                                fortnightDay: dayInfo.fortnightDay,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                dayInfo.isFullMoon ? 'Full Moon' : 'New Moon',
                                style: context.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],

                        // Holidays
                        if (dayInfo.hasHolidays) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: context.colorScheme.errorContainer
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.celebration,
                                  size: 14,
                                  color: context.colorScheme.onErrorContainer,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    dayInfo.allHolidays.first,
                                    style: context.textTheme.bodySmall
                                        ?.copyWith(
                                          color: context
                                              .colorScheme
                                              .onErrorContainer,
                                          fontWeight: FontWeight.w500,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (dayInfo.allHolidays.length > 1)
                                  Text(
                                    ' +${dayInfo.allHolidays.length - 1}',
                                    style: context.textTheme.bodySmall
                                        ?.copyWith(
                                          color: context
                                              .colorScheme
                                              .onErrorContainer,
                                        ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Chevron
                  Icon(
                    Icons.chevron_right,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                context.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading week...',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
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
                context.read<ViewsBloc>().add(LoadWeekView(DateTime.now()));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: context.colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
