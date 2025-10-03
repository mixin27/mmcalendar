import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/converter_bloc.dart';
import '../bloc/converter_event.dart';
import '../bloc/converter_state.dart';

class DateArithmeticCard extends StatefulWidget {
  const DateArithmeticCard({super.key});

  @override
  State<DateArithmeticCard> createState() => _DateArithmeticCardState();
}

class _DateArithmeticCardState extends State<DateArithmeticCard> {
  DateTime _startDate = DateTime.now();
  String _operation = 'add'; // 'add' or 'subtract'
  // int _value = 1;
  String _unit = 'days'; // 'days', 'weeks', 'months', 'years'

  final TextEditingController _valueController = TextEditingController(
    text: '1',
  );

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  void _calculate() {
    final value = int.tryParse(_valueController.text);
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid positive number')),
      );
      return;
    }

    context.read<ConverterBloc>().add(
      PerformDateArithmeticEvent(
        startDate: _startDate,
        operation: _operation,
        value: value,
        unit: _unit,
      ),
    );
  }

  // void _reset() {
  //   context.read<ConverterBloc>().add(ResetArithmeticEvent());
  //   setState(() {
  //     _startDate = DateTime.now();
  //     _operation = 'add';
  //     _value = 1;
  //     _unit = 'days';
  //     _valueController.text = '1';
  //   });
  // }

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
                Icon(
                  Icons.add_circle_outline,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Date Arithmetic',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),

            // Start Date
            Text('Start Date:', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  setState(() => _startDate = date);
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
                    Icon(
                      Icons.calendar_today,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Operation Selector
            Text('Operation:', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'add',
                  label: Text('Add'),
                  icon: Icon(Icons.add),
                ),
                ButtonSegment(
                  value: 'subtract',
                  label: Text('Subtract'),
                  icon: Icon(Icons.remove),
                ),
              ],
              selected: {_operation},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _operation = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 16),

            // Value Input
            Text('Value:', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _valueController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter a number',
                prefixIcon: Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Unit Selector
            Text('Unit:', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildUnitChip(theme, 'days', 'Days'),
                _buildUnitChip(theme, 'weeks', 'Weeks'),
                _buildUnitChip(theme, 'months', 'Months'),
                _buildUnitChip(theme, 'years', 'Years'),
              ],
            ),
            const SizedBox(height: 16),

            // Calculate Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _calculate,
                icon: const Icon(Icons.play_arrow),
                label: Text('Calculate Result'),
              ),
            ),
            const SizedBox(height: 16),

            // Result Section
            BlocBuilder<ConverterBloc, ConverterState>(
              builder: (context, state) {
                if (state is ArithmeticLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (state is ArithmeticError) {
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

                if (state is ArithmeticSuccess) {
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

  Widget _buildUnitChip(ThemeData theme, String value, String label) {
    final isSelected = _unit == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _unit = value);
        }
      },
    );
  }

  Widget _buildResultSection(ThemeData theme, ArithmeticSuccess state) {
    final result = state.result;
    final completeDate = result.resultDate;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: theme.colorScheme.tertiary),
              const SizedBox(width: 8),
              Text(
                'Result Date',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.tertiary,
                ),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 12),

          // Operation Summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  result.operation == 'add' ? Icons.add : Icons.remove,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${result.operation == 'add' ? 'Added' : 'Subtracted'} ${result.value} ${result.unit}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Western Date
          _buildInfoRow(
            theme,
            'Western Date:',
            '${completeDate.western.day}/${completeDate.western.month}/${completeDate.western.year}',
            Icons.event,
          ),
          const SizedBox(height: 8),

          // Myanmar Date
          _buildInfoRow(
            theme,
            'Myanmar Date:',
            '${completeDate.myanmar.year}/${completeDate.myanmar.month}/${completeDate.myanmar.day}',
            Icons.calendar_month,
          ),
          const SizedBox(height: 8),

          // Moon Phase
          _buildInfoRow(
            theme,
            'Moon Phase:',
            _getMoonPhaseName(completeDate.moonPhase),
            Icons.brightness_3,
          ),
          const SizedBox(height: 8),

          // Weekday
          _buildInfoRow(
            theme,
            'Weekday:',
            _getWeekdayName(completeDate.weekday),
            Icons.today,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.bodyMedium,
              children: [
                TextSpan(
                  text: '$label ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getMoonPhaseName(int moonPhase) {
    switch (moonPhase) {
      case 0:
        return 'Waxing';
      case 1:
        return 'Full Moon';
      case 2:
        return 'Waning';
      case 3:
        return 'New Moon';
      default:
        return 'Unknown';
    }
  }

  String _getWeekdayName(int weekday) {
    const weekdays = [
      'Saturday',
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
    ];
    return weekdays[weekday % 7];
  }
}
