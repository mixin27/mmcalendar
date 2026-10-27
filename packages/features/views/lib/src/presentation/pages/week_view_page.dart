import 'package:shared_core/shared_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import '../../di/views_injection.dart';
import '../../domain/entities/week_data.dart';
import '../bloc/views_bloc.dart';
import '../bloc/views_event.dart';
import '../bloc/views_state.dart';

class WeekViewPage extends StatefulWidget {
  const WeekViewPage({super.key});

  @override
  State<WeekViewPage> createState() => _WeekViewPageState();
}

class _WeekViewPageState extends State<WeekViewPage>
    with SingleTickerProviderStateMixin {
  final AnalyticsPort _analyticsService = getIt<AnalyticsPort>();
  final DisplayPreferencesPort _displayPreferencesPort =
      getIt<DisplayPreferencesPort>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Log screen view when page loads
    _analyticsService.logScreenView(
      screenName: 'week_view',
      screenClass: 'WeekViewPage',
    );

    _animationController = AnimationController(
      duration: AppConstants.mediumAnimationDuration,
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
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
    return BlocConsumer<ViewsBloc, ViewsState>(
      listener: (context, state) {
        if (state is ViewsError) {
          context.showToast(state.message, kind: AppToastKind.error);
        }
        if (state is WeekViewLoaded) {
          _animationController
            ..reset()
            ..forward();
        }
      },
      builder: (context, state) {
        if (state is ViewsInitial) {
          context.read<ViewsBloc>().add(LoadWeekView(DateTime.now()));
        }
        void go(ViewsEvent event) {
          HapticFeedback.lightImpact();
          context.read<ViewsBloc>().add(event);
        }

        final week = state is WeekViewLoaded ? state.weekData : null;
        final l10n = AppLocalizations.of(context);
        return AppPage(
          title: week == null
              ? l10n?.week ?? 'Week'
              : l10n?.weekNumber(week.weekNumber) ?? 'Week ${week.weekNumber}',
          previousTitle: l10n?.views ?? 'Views',
          actions: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              tooltip: l10n?.viewsPreviousWeek ?? 'Previous Week',
              onPressed: () => go(const NavigateWeekPrevious()),
            ),
            IconButton(
              icon: const Icon(Icons.today_outlined),
              tooltip: l10n?.viewsThisWeek ?? 'This Week',
              onPressed: () => go(LoadWeekView(DateTime.now())),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              tooltip: l10n?.viewsNextWeek ?? 'Next Week',
              onPressed: () => go(const NavigateWeekNext()),
            ),
          ],
          children: [
            if (week != null)
              StreamBuilder<bool>(
                stream: _displayPreferencesPort.watchShowShanCalendar(),
                initialData: true,
                builder: (context, snapshot) => FadeTransition(
                  opacity: _fadeAnimation,
                  child: _weekGroup(context, week, snapshot.data ?? true),
                ),
              )
            else if (state is ViewsError)
              _buildErrorState(state.message)
            else
              _buildLoadingState(),
          ],
        );
      },
    );
  }

  Widget _weekGroup(BuildContext context, WeekData week, bool showShan) {
    final t = context.tokens;
    final format = context.calendarFormat;
    final shan = format.language == Language.shan && showShan;
    return AppGroup(
      label:
          '${format.dayMonth(week.weekStart)} – ${format.dayMonth(week.weekEnd)} '
          '${format.westernNumber(week.weekEnd.year)}',
      children: [
        for (final day in week.days)
          Builder(
            builder: (context) {
              final date = DateTime(
                day.westernYear,
                day.westernMonth,
                day.westernDay,
              );
              final isToday = date.isToday;
              final holidays = [...day.allHolidays, ...day.allAnniversaryDays];
              final myanmar = format.myanmar(day.myanmar, '&M &P &f &Yat');
              final shanYear = MyanmarDateTime.fromMyanmarDate(
                day.myanmar,
              ).shanDate.year;
              return AppRow(
                leading: MoonGlyph(date: date, size: 28),
                title:
                    '${format.weekday(date, short: true)} ${format.westernNumber(date.day)}',
                subtitle: shan
                    ? '${translateNumbers('$shanYear', language: Language.shan)} $myanmar'
                    : myanmar,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (holidays.isNotEmpty)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 120),
                        child: Text(
                          holidays.length > 1
                              ? '${TranslationService.translateTo(holidays.first, MyanmarCalendar.currentLanguage)} +${holidays.length - 1}'
                              : TranslationService.translateTo(
                                  holidays.first,
                                  MyanmarCalendar.currentLanguage,
                                ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: t.holiday,
                          ),
                        ),
                      ),
                    if (isToday)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: t.accentSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          AppLocalizations.of(context)?.today ?? 'Today',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: t.accent,
                          ),
                        ),
                      ),
                  ],
                ),
                chevron: true,
                onTap: () => GoRouter.of(context).go('/views/day', extra: date),
              );
            },
          ),
      ],
    );
  }

  Widget _buildLoadingState() => const Padding(
    padding: EdgeInsets.all(48),
    child: Center(child: CircularProgressIndicator()),
  );

  Widget _buildErrorState(String message) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: context.colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n?.somethingWentWrong ?? 'Oops! Something went wrong',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                context.read<ViewsBloc>().add(LoadWeekView(DateTime.now()));
              },
              icon: const Icon(Icons.refresh),
              label: Text(l10n?.tryAgain ?? 'Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
