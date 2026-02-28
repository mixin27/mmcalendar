import 'package:shared_core/shared_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

import '../../di/converter_injection.dart';
import '../../domain/entities/date_arithmetic_result.dart';
import '../bloc/converter_bloc.dart';
import '../bloc/converter_event.dart';
import '../bloc/converter_state.dart';

class DateArithmeticCard extends StatefulWidget {
  const DateArithmeticCard({super.key});

  @override
  State<DateArithmeticCard> createState() => _DateArithmeticCardState();
}

class _DateArithmeticCardState extends State<DateArithmeticCard>
    with SingleTickerProviderStateMixin {
  final AnalyticsPort _analyticsService = getIt<AnalyticsPort>();

  DateTime _startDate = DateTime.now();
  String _operation = 'add';
  String _unit = 'days';
  final TextEditingController _valueController = TextEditingController(
    text: '1',
  );

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _analyticsService.logScreenView(
      screenName: 'date_arithmetic',
      screenClass: 'DateArithmeticCard',
    );

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _valueController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _calculate() {
    _analyticsService.logButtonClick(
      buttonName: 'calculate',
      buttonLocation: 'date_arithmetic_card',
    );

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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 16),
            _buildInputCard(),
            const SizedBox(height: 16),
            _buildCalculateButton(),
            const SizedBox(height: 16),
            _buildResultSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.add_circle_outline,
                color: theme.colorScheme.onTertiaryContainer,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date Arithmetic',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add or subtract time from a date',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Start Date
            Text(
              'Start Date',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildDateSelector(),
            const SizedBox(height: 24),

            // Operation
            Text(
              'Operation',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildOperationSelector(),
            const SizedBox(height: 24),

            // Value
            Text(
              'Value',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildValueInput(),
            const SizedBox(height: 24),

            // Unit
            Text(
              'Unit',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildUnitSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    final theme = Theme.of(context);

    return InkWell(
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.calendar_today,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(Icons.edit, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationSelector() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'add', label: Text('Add'), icon: Icon(Icons.add)),
        ButtonSegment(
          value: 'subtract',
          label: Text('Subtract'),
          icon: Icon(Icons.remove),
        ),
      ],
      selected: {_operation},
      onSelectionChanged: (Set<String> newSelection) {
        setState(() => _operation = newSelection.first);
      },
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
    );
  }

  Widget _buildValueInput() {
    return TextField(
      controller: _valueController,
      decoration: InputDecoration(
        hintText: 'Enter a number',
        prefixIcon: const Icon(Icons.numbers),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    );
  }

  Widget _buildUnitSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildUnitChip('days', 'Days', Icons.calendar_view_day),
        _buildUnitChip('weeks', 'Weeks', Icons.date_range),
        _buildUnitChip('months', 'Months', Icons.calendar_view_month),
        _buildUnitChip('years', 'Years', Icons.calendar_view_week),
      ],
    );
  }

  Widget _buildUnitChip(String value, String label, IconData icon) {
    final theme = Theme.of(context);
    final isSelected = _unit == value;

    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 18), const SizedBox(width: 8), Text(label)],
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() => _unit = value);
        }
      },
      backgroundColor: theme.colorScheme.surface,
      selectedColor: theme.colorScheme.primaryContainer,
    );
  }

  Widget _buildCalculateButton() {
    return FilledButton.icon(
      onPressed: _calculate,
      icon: const Icon(Icons.play_arrow),
      label: const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('Calculate Result', style: TextStyle(fontSize: 16)),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.tertiary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildResultSection() {
    return BlocBuilder<ConverterBloc, ConverterState>(
      builder: (context, state) {
        if (state is ArithmeticLoading) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (state is ArithmeticError) {
          return _buildErrorCard(state.message);
        }

        if (state is ArithmeticSuccess) {
          return _buildSuccessCard(state.result);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildErrorCard(String message) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.errorContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.onErrorContainer,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessCard(DateArithmeticResult result) {
    final theme = Theme.of(context);
    final completeDate = result.resultDate;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.tertiaryContainer,
                  theme.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.tertiary,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Text(
                  'Result Date',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        result.operation == 'add' ? Icons.add : Icons.remove,
                        color: theme.colorScheme.tertiary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${result.operation == 'add' ? 'Added' : 'Subtracted'} ${result.value} ${result.unit}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildInfoTile(
                  'Western Date',
                  MyanmarCalendar.formatWestern(
                    completeDate.western,
                    pattern: "%dd/%mm/%yyyy",
                  ),
                  Icons.event,
                  theme.colorScheme.primary,
                ),
                const SizedBox(height: 12),
                _buildInfoTile(
                  'Myanmar Date',
                  MyanmarCalendar.formatMyanmar(
                    completeDate.myanmar,
                    pattern: "&yyyy/&mm/&dd",
                  ),
                  Icons.calendar_month,
                  theme.colorScheme.secondary,
                ),
                const SizedBox(height: 12),
                _buildInfoTile(
                  'Weekday',
                  _getWeekdayName(completeDate.weekday),
                  Icons.today,
                  theme.colorScheme.tertiary,
                ),
                const SizedBox(height: 12),
                _buildInfoTile(
                  'Moon Phase',
                  _getMoonPhaseName(completeDate.moonPhase),
                  Icons.brightness_3,
                  _getMoonPhaseColor(completeDate.moonPhase),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMoonPhaseName(int moonPhase) {
    return TranslationService.getMoonPhaseName(moonPhase);
  }

  Color _getMoonPhaseColor(int moonPhase) {
    const colors = [Colors.amber, Colors.orange, Colors.blue, Colors.indigo];
    return colors[moonPhase % 4];
  }

  String _getWeekdayName(int weekday) {
    return TranslationService.getWeekdayName(weekday);
  }
}
