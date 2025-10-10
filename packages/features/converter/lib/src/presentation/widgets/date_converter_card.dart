import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';

import '../../domain/entities/conversion_result.dart';
import '../bloc/converter_bloc.dart';
import '../bloc/converter_event.dart';
import '../bloc/converter_state.dart';

class DateConverterCard extends StatefulWidget {
  const DateConverterCard({super.key});

  @override
  State<DateConverterCard> createState() => _DateConverterCardState();
}

class _DateConverterCardState extends State<DateConverterCard>
    with SingleTickerProviderStateMixin {
  // Conversion direction: true = Western to Myanmar, false = Myanmar to Western
  bool _isWesternToMyanmar = true;

  // Western date input
  DateTime _selectedWesternDate = DateTime.now();

  // Myanmar date input
  final TextEditingController _myanmarYearController = TextEditingController();
  final TextEditingController _myanmarMonthController = TextEditingController();
  final TextEditingController _myanmarDayController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
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
    _animationController.dispose();
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDirectionCard(),
            const SizedBox(height: 16),
            _buildInputCard(),
            const SizedBox(height: 16),
            _buildConvertButton(),
            const SizedBox(height: 16),
            _buildResultSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionCard() {
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildDirectionItem('Western', Icons.event, !_isWesternToMyanmar),
            IconButton.filledTonal(
              onPressed: _switchDirection,
              icon: const Icon(Icons.swap_horiz),
              tooltip: 'Switch direction',
              iconSize: 28,
            ),
            _buildDirectionItem(
              'Myanmar',
              Icons.calendar_month,
              _isWesternToMyanmar,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionItem(String label, IconData icon, bool isTarget) {
    final theme = Theme.of(context);
    final color = isTarget
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isTarget
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 32),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: isTarget ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
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
            Row(
              children: [
                Icon(
                  _isWesternToMyanmar ? Icons.event : Icons.calendar_month,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  _isWesternToMyanmar
                      ? 'Select Western Date'
                      : 'Enter Myanmar Date',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _isWesternToMyanmar ? _buildWesternInput() : _buildMyanmarInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildWesternInput() {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedWesternDate,
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
        );
        if (date != null) {
          setState(() => _selectedWesternDate = date);
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
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            width: 2,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Date',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_selectedWesternDate.day}/${_selectedWesternDate.month}/${_selectedWesternDate.year}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildMyanmarInput() {
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _myanmarYearController,
                label: 'Year',
                hint: '1385',
                icon: Icons.calendar_view_week,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _myanmarMonthController,
                label: 'Month',
                hint: '0-14',
                icon: Icons.calendar_view_month,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _myanmarDayController,
                label: 'Day',
                hint: '1-30',
                icon: Icons.calendar_view_day,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: theme.colorScheme.onTertiaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Month: 0=First Waso, 1-12=Tagu to Tabaung, 13=Late Tagu, 14=Second Waso',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        // prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    );
  }

  Widget _buildConvertButton() {
    return FilledButton.icon(
      onPressed: _convert,
      icon: const Icon(Icons.transform),
      label: const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('Convert', style: TextStyle(fontSize: 16)),
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
        if (state is ConversionLoading) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (state is ConversionError) {
          return _buildErrorCard(state.message);
        }

        if (state is ConversionSuccess) {
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

  Widget _buildSuccessCard(ConversionResult result) {
    final theme = Theme.of(context);
    final completeDate = result.completeDate;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
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
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
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
                  color: theme.colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Text(
                  'Conversion Result',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildInfoTile(
                  'Western Date',
                  result.formattedWestern,
                  Icons.event,
                  theme.colorScheme.secondary,
                ),
                const SizedBox(height: 12),
                _buildInfoTile(
                  'Myanmar Date',
                  result.formattedMyanmar,
                  Icons.calendar_month,
                  theme.colorScheme.tertiary,
                ),
                const SizedBox(height: 12),
                _buildInfoTile(
                  'Weekday',
                  _getWeekdayName(completeDate.weekday),
                  Icons.today,
                  theme.colorScheme.primary,
                ),
                const SizedBox(height: 12),
                _buildInfoTile(
                  'Moon Phase',
                  _getMoonPhaseName(completeDate.moonPhase),
                  Icons.brightness_3,
                  _getMoonPhaseColor(completeDate.moonPhase),
                ),

                if (completeDate.hasHolidays ||
                    completeDate.hasAstrologicalDays) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                ],

                if (completeDate.hasHolidays) ...[
                  _buildAdditionalInfo(
                    'Holidays',
                    completeDate.allHolidays,
                    Icons.celebration,
                    theme.colorScheme.error,
                  ),
                  if (completeDate.hasAstrologicalDays)
                    const SizedBox(height: 16),
                ],

                if (completeDate.hasAstrologicalDays)
                  _buildAdditionalInfo(
                    'Astrological Days',
                    completeDate.astrologicalDays,
                    Icons.star,
                    theme.colorScheme.tertiary,
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
            child: Icon(icon, color: color, size: 24),
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

  Widget _buildAdditionalInfo(
    String title,
    List<String> items,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(left: 28, top: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('•  ', style: TextStyle(color: color)),
                Expanded(
                  child: Text(
                    TranslationService.translate(item),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
