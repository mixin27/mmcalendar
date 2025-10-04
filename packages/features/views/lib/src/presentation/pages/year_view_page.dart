import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/year_data.dart';
import '../bloc/views_bloc.dart';
import '../bloc/views_event.dart';
import '../bloc/views_state.dart';

class YearViewPage extends StatefulWidget {
  const YearViewPage({super.key});

  @override
  State<YearViewPage> createState() => _YearViewPageState();
}

class _YearViewPageState extends State<YearViewPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
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
          if (state is YearViewLoaded) {
            _animationController.reset();
            _animationController.forward();
          }
        },
        builder: (context, state) {
          if (state is ViewsInitial) {
            context.read<ViewsBloc>().add(LoadYearView(DateTime.now().year));
            return _buildLoadingState();
          }

          if (state is ViewsLoading) {
            return _buildLoadingState();
          }

          if (state is ViewsError) {
            return _buildErrorState(state.message);
          }

          if (state is YearViewLoaded) {
            return _buildYearContent(state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildYearContent(YearViewLoaded state) {
    return CustomScrollView(
      slivers: [
        // App Bar
        _buildAppBar(state),

        // Months Grid
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverFadeTransition(
            opacity: _fadeAnimation,
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final month = state.yearData.months[index];
                return _buildMonthCard(month, index);
              }, childCount: state.yearData.months.length),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(YearViewLoaded state) {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
        title: Text(
          state.yearData.year.toString(),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.colorScheme.tertiaryContainer,
                context.colorScheme.tertiaryContainer.withValues(alpha: 0.7),
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
            context.read<ViewsBloc>().add(const NavigateYearPrevious());
          },
          tooltip: 'Previous Year',
        ),
        IconButton(
          icon: const Icon(Icons.today),
          onPressed: () {
            HapticFeedback.lightImpact();
            context.read<ViewsBloc>().add(LoadYearView(DateTime.now().year));
          },
          tooltip: 'This Year',
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            HapticFeedback.lightImpact();
            context.read<ViewsBloc>().add(const NavigateYearNext());
          },
          tooltip: 'Next Year',
        ),
      ],
    );
  }

  Widget _buildMonthCard(MonthSummary month, int index) {
    final now = DateTime.now();
    final isCurrentMonth =
        month.firstDay.month == now.month && month.firstDay.year == now.year;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 30)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isCurrentMonth
                ? context.colorScheme.primary
                : context.colorScheme.outlineVariant,
            width: isCurrentMonth ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: () {
            // Navigate to calendar for that month
            context.showSnackBar('${month.monthName} ${month.firstDay.year}');
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: isCurrentMonth
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month name
                Text(
                  month.monthName,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isCurrentMonth
                        ? context.colorScheme.primary
                        : context.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),

                // Mini calendar
                Expanded(child: _buildMiniCalendar(month, now, isCurrentMonth)),

                // Stats
                const SizedBox(height: 8),
                _buildMonthStats(month, isCurrentMonth),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniCalendar(
    MonthSummary month,
    DateTime now,
    bool isCurrentMonth,
  ) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
      ),
      itemCount: month.dates.length,
      itemBuilder: (context, index) {
        final dateInfo = month.dates[index];
        final date = dateInfo.western.toDateTime();
        final isToday =
            date.day == now.day &&
            date.month == now.month &&
            date.year == now.year;

        return Container(
          alignment: Alignment.center,
          decoration: isToday
              ? BoxDecoration(
                  color: context.colorScheme.primary,
                  shape: BoxShape.circle,
                )
              : null,
          child: Text(
            date.day.toString(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: isToday ? FontWeight.bold : null,
              color: isToday
                  ? context.colorScheme.onPrimary
                  : dateInfo.hasHolidays
                  ? context.colorScheme.error
                  : isCurrentMonth
                  ? context.colorScheme.primary
                  : context.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthStats(MonthSummary month, bool isCurrentMonth) {
    final holidayCount = month.dates.where((d) => d.hasHolidays).length;

    if (holidayCount == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.celebration, size: 12, color: context.colorScheme.error),
          const SizedBox(width: 4),
          Text(
            '$holidayCount',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
            'Loading year...',
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
                context.read<ViewsBloc>().add(
                  LoadYearView(DateTime.now().year),
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
