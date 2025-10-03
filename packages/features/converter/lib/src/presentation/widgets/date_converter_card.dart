import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/converter_bloc.dart';
import '../bloc/converter_event.dart';
import '../bloc/converter_state.dart';

class DateConverterCard extends StatefulWidget {
  const DateConverterCard({super.key});

  @override
  State<DateConverterCard> createState() => _DateConverterCardState();
}

class _DateConverterCardState extends State<DateConverterCard> {
  // Conversion direction: true = Western to Myanmar, false = Myanmar to Western
  bool _isWesternToMyanmar = true;

  // Western date input
  DateTime _selectedWesternDate = DateTime.now();

  // Myanmar date input
  final TextEditingController _myanmarYearController = TextEditingController();
  final TextEditingController _myanmarMonthController = TextEditingController();
  final TextEditingController _myanmarDayController = TextEditingController();

  @override
  void dispose() {
    _myanmarYearController.dispose();
    _myanmarMonthController.dispose();
    _myanmarDayController.dispose();
    super.dispose();
  }

  void _convert() {
    if (_isWesternToMyanmar) {
      context.read<ConverterBloc>().add(
        ConvertWesternToMyanmarEvent(_selectedWesternDate),
      );
    } else {
      final year = int.tryParse(_myanmarYearController.text);
      final month = int.tryParse(_myanmarMonthController.text);
      final day = int.tryParse(_myanmarDayController.text);

      if (year == null || month == null || day == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter valid Myanmar date values'),
          ),
        );
        return;
      }

      context.read<ConverterBloc>().add(
        ConvertMyanmarToWesternEvent(year, month, day),
      );
    }
  }

  void _reset() {
    context.read<ConverterBloc>().add(ResetConverterEvent());
    setState(() {
      _selectedWesternDate = DateTime.now();
      _myanmarYearController.clear();
      _myanmarMonthController.clear();
      _myanmarDayController.clear();
    });
  }

  void _switchDirection() {
    setState(() {
      _isWesternToMyanmar = !_isWesternToMyanmar;
    });
    _reset();
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
                Icon(Icons.sync_alt, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Date Converter',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.swap_horiz),
                  onPressed: _switchDirection,
                  tooltip: 'Switch conversion direction',
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),

            // Input Section
            _buildInputSection(theme),
            const SizedBox(height: 16),

            // Convert Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _convert,
                icon: const Icon(Icons.transform),
                label: const Text('Convert'),
              ),
            ),
            const SizedBox(height: 16),

            // Result Section
            BlocBuilder<ConverterBloc, ConverterState>(
              builder: (context, state) {
                if (state is ConversionLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (state is ConversionError) {
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

                if (state is ConversionSuccess) {
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

  Widget _buildInputSection(ThemeData theme) {
    if (_isWesternToMyanmar) {
      return _buildWesternInput(theme);
    } else {
      return _buildMyanmarInput(theme);
    }
  }

  Widget _buildWesternInput(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Western Date:', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedWesternDate,
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
            );
            if (date != null) {
              setState(() {
                _selectedWesternDate = date;
              });
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
                  '${_selectedWesternDate.day}/${_selectedWesternDate.month}/${_selectedWesternDate.year}',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMyanmarInput(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Enter Myanmar Date:', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _myanmarYearController,
                decoration: const InputDecoration(
                  labelText: 'Year',
                  border: OutlineInputBorder(),
                  hintText: '1385',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _myanmarMonthController,
                decoration: const InputDecoration(
                  labelText: 'Month',
                  border: OutlineInputBorder(),
                  hintText: '1-14',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _myanmarDayController,
                decoration: const InputDecoration(
                  labelText: 'Day',
                  border: OutlineInputBorder(),
                  hintText: '1-30',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Month: 0=First Waso, 1-12=Tagu to Tabaung, 13=Late Tagu, 14=Second Waso',
          style: theme.textTheme.bodySmall?.copyWith(
            fontStyle: FontStyle.italic,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildResultSection(ThemeData theme, ConversionSuccess state) {
    final result = state.result;
    final completeDate = result.completeDate;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Conversion Result',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 8),

          // Myanmar Date
          _buildResultRow(
            theme,
            'Myanmar Date:',
            result.formattedMyanmar,
            Icons.calendar_month,
          ),
          const SizedBox(height: 8),

          // Western Date
          _buildResultRow(
            theme,
            'Western Date:',
            result.formattedWestern,
            Icons.event,
          ),
          const SizedBox(height: 8),

          // Additional Info
          _buildResultRow(
            theme,
            'Moon Phase:',
            _getMoonPhaseName(completeDate.moonPhase),
            Icons.brightness_3,
          ),
          const SizedBox(height: 8),

          _buildResultRow(
            theme,
            'Weekday:',
            _getWeekdayName(completeDate.weekday),
            Icons.today,
          ),

          // Holidays
          if (completeDate.hasHolidays) ...[
            const SizedBox(height: 12),
            const Divider(),
            Text(
              'Holidays:',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            ...completeDate.allHolidays.map(
              (holiday) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.celebration,
                      size: 16,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(holiday, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Astrological Info
          if (completeDate.hasAstrologicalDays) ...[
            const SizedBox(height: 12),
            const Divider(),
            Text(
              'Astrological Information:',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            ...completeDate.astrologicalDays.map(
              (day) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 16,
                      color: theme.colorScheme.tertiary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(day, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultRow(
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
