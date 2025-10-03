import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/converter_bloc.dart';
import '../bloc/converter_event.dart';
import '../bloc/converter_state.dart';

class DateCalculatorCard extends StatefulWidget {
  const DateCalculatorCard({super.key});

  @override
  State<DateCalculatorCard> createState() => _DateCalculatorCardState();
}

class _DateCalculatorCardState extends State<DateCalculatorCard> {
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));

  void _calculate() {
    context.read<ConverterBloc>().add(
      CalculateDateDifferenceEvent(_startDate, _endDate),
    );
  }

  // void _reset() {
  //   context.read<ConverterBloc>().add(ResetCalculatorEvent());
  //   setState(() {
  //     _startDate = DateTime.now();
  //     _endDate = DateTime.now().add(const Duration(days: 30));
  //   });
  // }

  void _swapDates() {
    setState(() {
      final temp = _startDate;
      _startDate = _endDate;
      _endDate = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.calculate, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Date Difference Calculator',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),

            // Start Date
            _buildDateSelector(
              theme,
              'Start Date:',
              _startDate,
              (date) => setState(() => _startDate = date),
            ),
            const SizedBox(height: 12),

            // Swap Button
            Center(
              child: IconButton.outlined(
                onPressed: _swapDates,
                icon: const Icon(Icons.swap_vert),
                tooltip: 'Swap dates',
              ),
            ),
            const SizedBox(height: 12),

            // End Date
            _buildDateSelector(
              theme,
              'End Date:',
              _endDate,
              (date) => setState(() => _endDate = date),
            ),
            const SizedBox(height: 16),

            // Calculate Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _calculate,
                icon: const Icon(Icons.timeline),
                label: const Text('Calculate Difference'),
              ),
            ),
            const SizedBox(height: 16),

            // Result Section
            BlocBuilder<ConverterBloc, ConverterState>(
              builder: (context, state) {
                if (state is CalculationLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (state is CalculationError) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.message,
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (state is CalculationSuccess) {
                  return _buildResultSection(theme, state);
                }

                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector(
    ThemeData theme,
    String label,
    DateTime date,
    Function(DateTime) onDateChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final selectedDate = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
            );
            if (selectedDate != null) {
              onDateChanged(selectedDate);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: theme.textTheme.titleMedium,
                ),
                const Spacer(),
                Icon(Icons.edit, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultSection(ThemeData theme, CalculationSuccess state) {
    final result = state.result;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: theme.colorScheme.secondary),
              const SizedBox(width: 8),
              Text(
                'Calculation Result',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 12),

          // Total Days - Large Display
          Center(
            child: Column(
              children: [
                Text(
                  result.totalDays.abs().toString(),
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  result.totalDays.abs() == 1 ? 'Day' : 'Days',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // Breakdown
          Text(
            'Breakdown:',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          _buildBreakdownRow(
            theme,
            'Years',
            result.years.toString(),
            Icons.calendar_view_week,
          ),
          const SizedBox(height: 4),

          _buildBreakdownRow(
            theme,
            'Months',
            result.months.toString(),
            Icons.calendar_view_month,
          ),
          const SizedBox(height: 4),

          _buildBreakdownRow(
            theme,
            'Days',
            result.days.toString(),
            Icons.calendar_view_day,
          ),
          const SizedBox(height: 4),

          _buildBreakdownRow(
            theme,
            'Weeks',
            result.weeks.toString(),
            Icons.calendar_view_week,
          ),
          const SizedBox(height: 12),

          // Formatted Difference
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.formattedDifference,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
