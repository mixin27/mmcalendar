import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/converter_bloc.dart';
import '../bloc/converter_event.dart';
import '../bloc/converter_state.dart';

class MoonPhaseFinderCard extends StatefulWidget {
  const MoonPhaseFinderCard({super.key});

  @override
  State<MoonPhaseFinderCard> createState() => _MoonPhaseFinderCardState();
}

class _MoonPhaseFinderCardState extends State<MoonPhaseFinderCard> {
  DateTime _startDate = DateTime.now();
  int _selectedMoonPhase = 1; // Default to Full Moon

  void _findNext() {
    context.read<ConverterBloc>().add(
      FindNextMoonPhaseEvent(_startDate, _selectedMoonPhase),
    );
  }

  // void _reset() {
  //   context.read<ConverterBloc>().add(ResetMoonPhaseEvent());
  //   setState(() {
  //     _startDate = DateTime.now();
  //     _selectedMoonPhase = 1;
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
                Icon(Icons.brightness_3, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Moon Phase Finder',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),

            // Start Date
            Text('From Date:', style: theme.textTheme.titleMedium),
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

            // Moon Phase Selector
            Text('Find Next:', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),

            // Moon Phase Options
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: [
                _buildMoonPhaseOption(
                  theme,
                  0,
                  'Waxing',
                  Icons.brightness_2,
                  Colors.amber,
                ),
                _buildMoonPhaseOption(
                  theme,
                  1,
                  'Full Moon',
                  Icons.brightness_1,
                  Colors.orange,
                ),
                _buildMoonPhaseOption(
                  theme,
                  2,
                  'Waning',
                  Icons.brightness_3,
                  Colors.blue,
                ),
                _buildMoonPhaseOption(
                  theme,
                  3,
                  'New Moon',
                  Icons.brightness_4,
                  Colors.indigo,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Find Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _findNext,
                icon: const Icon(Icons.search),
                label: const Text('Find Next Occurrence'),
              ),
            ),
            const SizedBox(height: 16),

            // Result Section
            BlocBuilder<ConverterBloc, ConverterState>(
              builder: (context, state) {
                if (state is MoonPhaseLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (state is MoonPhaseError) {
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

                if (state is MoonPhaseSuccess) {
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

  Widget _buildMoonPhaseOption(
    ThemeData theme,
    int value,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedMoonPhase == value;

    return InkWell(
      onTap: () {
        setState(() => _selectedMoonPhase = value);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.2)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : theme.colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? color : theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection(ThemeData theme, MoonPhaseSuccess state) {
    final result = state.result;
    final completeDate = result.dateFound;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getMoonPhaseColor(result.moonPhase).withValues(alpha: 0.1),
            _getMoonPhaseColor(result.moonPhase).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getMoonPhaseColor(result.moonPhase).withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Moon Icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getMoonPhaseColor(
                    result.moonPhase,
                  ).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getMoonPhaseIcon(result.moonPhase),
                  color: _getMoonPhaseColor(result.moonPhase),
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next ${result.moonPhaseName}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getMoonPhaseColor(result.moonPhase),
                      ),
                    ),
                    Text(
                      'In ${result.daysFromStart} ${result.daysFromStart == 1 ? "day" : "days"}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // Date Information
          _buildDateInfo(
            theme,
            'Western Date',
            '${completeDate.western.day}/${completeDate.western.month}/${completeDate.western.year}',
            Icons.event,
          ),
          const SizedBox(height: 8),

          _buildDateInfo(
            theme,
            'Myanmar Date',
            '${completeDate.myanmar.year}/${completeDate.myanmar.month}/${completeDate.myanmar.day}',
            Icons.calendar_month,
          ),
          const SizedBox(height: 8),

          _buildDateInfo(
            theme,
            'Weekday',
            _getWeekdayName(completeDate.weekday),
            Icons.today,
          ),
          const SizedBox(height: 8),

          _buildDateInfo(
            theme,
            'Fortnight Day',
            completeDate.fortnightDay.toString(),
            Icons.looks_one,
          ),

          // Holidays if any
          if (completeDate.hasHolidays) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.celebration,
                  size: 18,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Holidays:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ...completeDate.allHolidays.map(
              (holiday) => Padding(
                padding: const EdgeInsets.only(left: 26, top: 2),
                child: Text('• $holiday', style: theme.textTheme.bodyMedium),
              ),
            ),
          ],

          // Astrological Days
          if (completeDate.hasAstrologicalDays) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.star, size: 18, color: theme.colorScheme.tertiary),
                const SizedBox(width: 8),
                Text(
                  'Astrological:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ...completeDate.astrologicalDays.map(
              (day) => Padding(
                padding: const EdgeInsets.only(left: 26, top: 2),
                child: Text('• $day', style: theme.textTheme.bodyMedium),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateInfo(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.bodyMedium,
              children: [
                TextSpan(
                  text: '$label: ',
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

  Color _getMoonPhaseColor(int moonPhase) {
    switch (moonPhase) {
      case 0:
        return Colors.amber;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  IconData _getMoonPhaseIcon(int moonPhase) {
    switch (moonPhase) {
      case 0:
        return Icons.brightness_2;
      case 1:
        return Icons.brightness_1;
      case 2:
        return Icons.brightness_3;
      case 3:
        return Icons.brightness_4;
      default:
        return Icons.brightness_medium;
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
