import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myanmar_calendar_wear/features/day_details/bloc/day_details_bloc.dart';
import 'package:myanmar_calendar_wear/features/day_details/models/day_details.dart';
import 'package:myanmar_calendar_wear/features/day_details/widgets/additional_info_widget.dart';
import 'package:myanmar_calendar_wear/features/day_details/widgets/astrology_warning.dart';
import 'package:myanmar_calendar_wear/features/day_details/widgets/holiday_banner.dart';
import 'package:myanmar_calendar_wear/features/day_details/widgets/moon_phase_widget.dart';
import 'package:myanmar_calendar_wear/features/day_details/widgets/myanmar_date_card.dart';
import 'package:myanmar_calendar_wear/features/day_details/widgets/sabbath_indicator.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:myanmar_calendar_wear/shared/watch_shape.dart';

/// The day: swipe or tap the side arrows for other days, Today to come
/// back, the globe for the calendar language.
class DayDetailsScreen extends StatelessWidget {
  const DayDetailsScreen({super.key});

  static const settingsRoute = '/settings';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dim = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);
    Widget arrow({required bool previous}) => IconButton(
      key: ValueKey(previous ? 'watch-previous-day' : 'watch-next-day'),
      tooltip: previous ? l10n.watchPreviousDay : l10n.watchNextDay,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(foregroundColor: dim),
      onPressed: () => context.read<DayDetailsBloc>().add(
        previous ? const NavigateToPreviousDay() : const NavigateToNextDay(),
      ),
      icon: Icon(previous ? Icons.chevron_left : Icons.chevron_right),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: WatchShape(
        builder: (context, shape, child) => Stack(
          children: [
            SafeArea(
              child: BlocBuilder<DayDetailsBloc, DayDetailsState>(
                builder: (context, state) => switch (state) {
                  DayDetailsInitial() => const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  DayDetailsError(:final message) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ),
                  DayDetailsLoaded(:final dayDetails) => _DayContent(
                    dayDetails: dayDetails,
                    isRound: shape == WearShape.round,
                  ),
                },
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: -8,
              child: Center(child: arrow(previous: true)),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              right: -8,
              child: Center(child: arrow(previous: false)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayContent extends StatelessWidget {
  const _DayContent({required this.dayDetails, required this.isRound});

  final DayDetails dayDetails;
  final bool isRound;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<DayDetailsBloc>();
    final isToday = dayDetails.isToday(bloc.today);
    final holidays = dayDetails.holidays(l10n);
    final edge = isRound ? 20.0 : 12.0;
    const gap = SizedBox(height: 10);

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < 0) bloc.add(const NavigateToNextDay());
        if (velocity > 0) bloc.add(const NavigateToPreviousDay());
      },
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(edge, isRound ? 52 : 40, edge, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: _Pill(
                    text: isToday ? l10n.today : dayDetails.monthName,
                  ),
                ),
                const SizedBox(height: 8),
                MyanmarDateCard(dayDetails: dayDetails),
                gap,
                if (holidays.isNotEmpty) ...[
                  HolidayBanner(holidays: holidays),
                  gap,
                ],
                if (dayDetails.sabbathLabel.isNotEmpty) ...[
                  SabbathIndicator(dayDetails: dayDetails),
                  gap,
                ],
                MoonPhaseWidget(dayDetails: dayDetails),
                gap,
                if (dayDetails.astrology.isNotEmpty) ...[
                  AstrologyWarnings(dayDetails: dayDetails),
                  gap,
                ],
                AdditionalInfoWidget(dayDetails: dayDetails),
              ],
            ),
          ),
          Positioned(
            top: isRound ? 14 : 8,
            left: 8,
            right: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 8,
              children: [
                _TopButton(
                  key: const ValueKey('watch-language'),
                  label: l10n.language,
                  icon: Icons.language,
                  onTap: () => Navigator.pushNamed(
                    context,
                    DayDetailsScreen.settingsRoute,
                  ),
                ),
                if (!isToday)
                  _TopButton(
                    key: const ValueKey('watch-today'),
                    label: l10n.today,
                    icon: Icons.today,
                    showLabel: true,
                    onTap: () => bloc.add(const LoadToday()),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade700.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade500),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TopButton extends StatelessWidget {
  const _TopButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.showLabel = false,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final color = Colors.white.withValues(alpha: 0.7);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: showLabel ? 10 : 6,
            vertical: showLabel ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [
              Icon(icon, size: showLabel ? 12 : 14, color: color),
              if (showLabel)
                Text(label, style: TextStyle(fontSize: 9, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
