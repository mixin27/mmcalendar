import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';

import '../bloc/views_bloc.dart';
import '../bloc/views_event.dart';
import '../bloc/views_state.dart';

class WeekViewPage extends StatelessWidget {
  const WeekViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Week View'), centerTitle: true),
      body: BlocConsumer<ViewsBloc, ViewsState>(
        listener: (context, state) {
          if (state is ViewsError) {
            context.showErrorSnackBar(state.message);
          }
        },
        builder: (context, state) {
          if (state is ViewsInitial) {
            context.read<ViewsBloc>().add(LoadWeekView(DateTime.now()));
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
                    'Error loading week',
                    style: context.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(state.message),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<ViewsBloc>().add(
                        LoadWeekView(DateTime.now()),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is WeekViewLoaded) {
            return Column(
              children: [
                // Week Navigation Header
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
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          context.read<ViewsBloc>().add(
                            const NavigateWeekPrevious(),
                          );
                        },
                        tooltip: 'Previous Week',
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Week ${state.weekData.weekNumber}',
                              style: context.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${state.weekData.weekStart.format('MMM d')} - ${state.weekData.weekEnd.format('MMM d, yyyy')}',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: context.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          context.read<ViewsBloc>().add(
                            const NavigateWeekNext(),
                          );
                        },
                        tooltip: 'Next Week',
                      ),
                    ],
                  ),
                ),

                // Days List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.weekData.days.length,
                    itemBuilder: (context, index) {
                      final dayInfo = state.weekData.days[index];
                      final date = dayInfo.western.toDateTime();
                      final isToday = date.isToday;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: isToday ? 4 : 1,
                        color: isToday
                            ? context.colorScheme.primaryContainer
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date header
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isToday
                                          ? context.colorScheme.primary
                                          : context
                                                .colorScheme
                                                .primaryContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          date.day.toString(),
                                          style: context.textTheme.headlineSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: isToday
                                                    ? context
                                                          .colorScheme
                                                          .onPrimary
                                                    : context
                                                          .colorScheme
                                                          .onPrimaryContainer,
                                              ),
                                        ),
                                        Text(
                                          date.format('EEE'),
                                          style: context.textTheme.bodySmall
                                              ?.copyWith(
                                                color: isToday
                                                    ? context
                                                          .colorScheme
                                                          .onPrimary
                                                    : context
                                                          .colorScheme
                                                          .onPrimaryContainer,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          date.format('MMMM d, yyyy'),
                                          style: context.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        Text(
                                          dayInfo.formatMyanmar(),
                                          style: context.textTheme.bodyMedium
                                              ?.copyWith(
                                                color:
                                                    context.colorScheme.primary,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              // Holidays
                              if (dayInfo.hasHolidays) ...[
                                const SizedBox(height: 12),
                                const Divider(),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.event,
                                      size: 16,
                                      color: context.colorScheme.error,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        dayInfo.allHolidays.join(', '),
                                        style: context.textTheme.bodySmall
                                            ?.copyWith(
                                              color: context.colorScheme.error,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              // Moon phase
                              if (dayInfo.isFullMoon || dayInfo.isNewMoon) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.brightness_1,
                                      size: 16,
                                      color: dayInfo.isFullMoon
                                          ? Colors.amber
                                          : Colors.indigo,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      dayInfo.isFullMoon
                                          ? 'Full Moon'
                                          : 'New Moon',
                                      style: context.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
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
