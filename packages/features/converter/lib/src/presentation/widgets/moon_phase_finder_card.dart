import 'package:shared_core/shared_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';
import 'package:shared_localizations/shared_localizations.dart';

import '../../di/converter_injection.dart';
import '../../domain/entities/moon_phase_result.dart';
import '../bloc/converter_bloc.dart';
import '../bloc/converter_event.dart';
import '../bloc/converter_state.dart';

class MoonPhaseFinderCard extends StatefulWidget {
  const MoonPhaseFinderCard({super.key});

  @override
  State<MoonPhaseFinderCard> createState() => _MoonPhaseFinderCardState();
}

class _MoonPhaseFinderCardState extends State<MoonPhaseFinderCard>
    with SingleTickerProviderStateMixin {
  final AnalyticsPort _analyticsService = getIt<AnalyticsPort>();
  DateTime _startDate = DateTime.now();
  int _selectedMoonPhase = 1; // Default to Full Moon

  void _findNext() {
    _analyticsService.logButtonClick(
      buttonName: 'find_next_occurrence',
      buttonLocation: 'moon_phase_finder_card',
    );
    context.read<ConverterBloc>().add(
      FindNextMoonPhaseEvent(_startDate, _selectedMoonPhase),
    );
  }

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _analyticsService.logScreenView(
      screenName: 'moon_phase_finder',
      screenClass: 'MoonPhaseFinderCard',
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
    _animationController.dispose();
    super.dispose();
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
            _buildFindButton(),
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
      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.brightness_3,
                color: theme.colorScheme.onSecondaryContainer,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Moon Phase Finder',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Find the next occurrence of a moon phase',
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
            // From Date
            Text(
              'From Date',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildDateSelector(),
            const SizedBox(height: 24),

            // Find Next
            Text(
              'Find Next',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildMoonPhaseGrid(),
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

  Widget _buildMoonPhaseGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        _buildMoonPhaseOption(
          0,
          TranslationService.translate('Waxing'),
          Icons.brightness_2,
          Colors.amber,
        ),
        _buildMoonPhaseOption(
          1,
          TranslationService.translate('Full Moon'),
          Icons.brightness_1,
          Colors.orange,
        ),
        _buildMoonPhaseOption(
          2,
          TranslationService.translate('Waning'),
          Icons.brightness_3,
          Colors.blue,
        ),
        _buildMoonPhaseOption(
          3,
          TranslationService.translate('New Moon'),
          Icons.brightness_4,
          Colors.indigo,
        ),
      ],
    );
  }

  Widget _buildMoonPhaseOption(
    int value,
    String label,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    final isSelected = _selectedMoonPhase == value;

    return InkWell(
      onTap: () => setState(() => _selectedMoonPhase = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.2)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
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
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? color
                      : theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFindButton() {
    return FilledButton.icon(
      onPressed: _findNext,
      icon: const Icon(Icons.search),
      label: const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('Find Next Occurrence', style: TextStyle(fontSize: 16)),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: context.colorScheme.tertiary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildResultSection() {
    return BlocBuilder<ConverterBloc, ConverterState>(
      builder: (context, state) {
        if (state is MoonPhaseLoading) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (state is MoonPhaseError) {
          return _buildErrorCard(state.message);
        }

        if (state is MoonPhaseSuccess) {
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

  Widget _buildSuccessCard(MoonPhaseResult result) {
    final theme = Theme.of(context);
    final completeDate = result.dateFound;
    final color = _getMoonPhaseColor(result.moonPhase);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.5), width: 2),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.3),
                  color.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getMoonPhaseIcon(result.moonPhase),
                    color: color,
                    size: 40,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next ${result.moonPhaseName}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'In ${result.daysFromStart} ${result.daysFromStart == 1 ? "day" : "days"}',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Date Information
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
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
                  theme.colorScheme.primary,
                ),
                const SizedBox(height: 12),
                _buildInfoTile(
                  'Fortnight Day',
                  MyanmarCalendar.formatMyanmar(
                    completeDate.myanmar,
                    pattern: "&f",
                  ),
                  Icons.looks_one,
                  theme.colorScheme.tertiary,
                ),

                // Holidays
                if (completeDate.hasHolidays ||
                    completeDate.hasAnniversaryDays) ...[
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildAdditionalInfo(
                    "${AppLocalizations.of(context)?.holidays ?? 'Holidays'} & ${AppLocalizations.of(context)?.anniversary_days ?? 'Anniversary Days'}",
                    [
                      ...completeDate.allHolidays,
                      ...completeDate.allAnniversaryDays,
                    ],
                    Icons.celebration,
                    theme.colorScheme.error,
                  ),
                ],

                // Astrological Days
                if (completeDate.hasAstrologicalDays) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildAdditionalInfo(
                    'Astrological Days',
                    completeDate.astrologicalDays,
                    Icons.star,
                    Colors.purple,
                  ),
                ],
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
        const SizedBox(height: 12),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(left: 28, bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 8, right: 12),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
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

  Color _getMoonPhaseColor(int moonPhase) {
    const colors = [Colors.amber, Colors.orange, Colors.blue, Colors.indigo];
    return colors[moonPhase % 4];
  }

  IconData _getMoonPhaseIcon(int moonPhase) {
    const icons = [
      Icons.brightness_2,
      Icons.brightness_1,
      Icons.brightness_3,
      Icons.brightness_4,
    ];
    return icons[moonPhase % 4];
  }

  String _getWeekdayName(int weekday) {
    return TranslationService.getWeekdayName(weekday);
  }
}
