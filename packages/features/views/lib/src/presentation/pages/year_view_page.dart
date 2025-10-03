import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/year_data.dart';
import '../bloc/views_bloc.dart';
import '../bloc/views_event.dart';
import '../bloc/views_state.dart';

class YearViewPage extends StatelessWidget {
  const YearViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Year View'), centerTitle: true),
      body: BlocConsumer<ViewsBloc, ViewsState>(
        listener: (context, state) {
          if (state is ViewsError) {
            context.showErrorSnackBar(state.message);
          }
        },
        builder: (context, state) {
          if (state is ViewsInitial) {
            context.read<ViewsBloc>().add(LoadYearView(DateTime.now().year));
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ViewsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ViewsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: context.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading year',
                    style: context.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(state.message),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<ViewsBloc>().add(
                        LoadYearView(DateTime.now().year),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is YearViewLoaded) {
            return Column(
              children: [
                // Year Navigation Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: context.colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          context.read<ViewsBloc>().add(
                            const NavigateYearPrevious(),
                          );
                        },
                        tooltip: 'Previous Year',
                      ),
                      const SizedBox(width: 16),
                      Text(
                        state.yearData.year.toString(),
                        style: context.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          context.read<ViewsBloc>().add(
                            const NavigateYearNext(),
                          );
                        },
                        tooltip: 'Next Year',
                      ),
                    ],
                  ),
                ),

                // Months Grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                        ),
                    itemCount: state.yearData.months.length,
                    itemBuilder: (context, index) {
                      final month = state.yearData.months[index];
                      return _MonthCard(
                        month: month,
                        onTap: () {
                          // Navigate to calendar for that month
                          context.showSnackBar(
                            'Tapped ${month.monthName} ${state.yearData.year}',
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _MonthCard extends StatelessWidget {
  final MonthSummary month;
  final VoidCallback onTap;

  const _MonthCard({required this.month, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth =
        month.firstDay.month == now.month && month.firstDay.year == now.year;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month name
              Text(
                month.monthName,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isCurrentMonth
                      ? context.colorScheme.onPrimaryContainer
                      : context.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),

              // Mini calendar grid
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 0.7,
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
                          fontSize: 10,
                          color: isToday
                              ? context.colorScheme.onPrimary
                              : dateInfo.hasHolidays
                              ? context.colorScheme.error
                              : isCurrentMonth
                              ? context.colorScheme.onPrimaryContainer
                              : context.colorScheme.onSurface,
                          fontWeight: isToday ? FontWeight.bold : null,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Info row
              if (month.dates.where((d) => d.hasHolidays).isNotEmpty)
                Row(
                  children: [
                    Icon(
                      Icons.event,
                      size: 12,
                      color: context.colorScheme.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${month.dates.where((d) => d.hasHolidays).length} holidays',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: isCurrentMonth
                            ? context.colorScheme.onPrimaryContainer
                            : context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
