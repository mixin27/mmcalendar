import 'dart:developer';

import 'package:shared_core/shared_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import '../../di/views_injection.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

import '../../domain/entities/year_data.dart';
import '../bloc/views_bloc.dart';
import '../bloc/views_event.dart';
import '../bloc/views_state.dart';

class YearViewPage extends StatefulWidget {
  const YearViewPage({super.key});

  @override
  State<YearViewPage> createState() => _YearViewPageState();
}

class _YearViewPageState extends State<YearViewPage>
    with SingleTickerProviderStateMixin {
  final AnalyticsPort _analyticsService = getIt<AnalyticsPort>();
  final MonthPreviewPort _monthPreviewPort = getIt<MonthPreviewPort>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Log screen view when page loads
    _analyticsService.logScreenView(
      screenName: 'year_view',
      screenClass: 'YearViewPage',
    );

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
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
        if (state is YearViewLoaded) {
          _animationController
            ..reset()
            ..forward();
        }
      },
      builder: (context, state) {
        if (state is ViewsInitial) {
          context.read<ViewsBloc>().add(LoadYearView(DateTime.now().year));
        }
        final year = state is YearViewLoaded
            ? state.yearData.year
            : DateTime.now().year;
        void go(ViewsEvent event) {
          HapticFeedback.lightImpact();
          context.read<ViewsBloc>().add(event);
        }

        return AppPage(
          title: '$year',
          previousTitle: 'Views',
          actions: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              tooltip: 'Previous Year',
              onPressed: () => go(const NavigateYearPrevious()),
            ),
            IconButton(
              icon: const Icon(Icons.today_outlined),
              tooltip: 'This Year',
              onPressed: () => go(LoadYearView(DateTime.now().year)),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              tooltip: 'Next Year',
              onPressed: () => go(const NavigateYearNext()),
            ),
          ],
          slivers: [
            if (state is YearViewLoaded)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                sliver: SliverFadeTransition(
                  opacity: _fadeAnimation,
                  sliver: SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 170,
                          childAspectRatio: .8,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemCount: state.yearData.months.length,
                    itemBuilder: (context, index) => _MonthTile(
                      month: state.yearData.months[index],
                      onTap: () {
                        final month = state.yearData.months[index];
                        _showMonthSheet(
                          context,
                          DateTime(month.firstDay.year, month.monthNumber),
                          month.monthName,
                        );
                      },
                    ),
                  ),
                ),
              )
            else
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: state is ViewsError
                      ? Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(state.message, textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              AppButton(
                                label: 'Try Again',
                                icon: Icons.refresh,
                                expand: false,
                                onPressed: () => context.read<ViewsBloc>().add(
                                  LoadYearView(DateTime.now().year),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const CircularProgressIndicator(),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showMonthSheet(BuildContext context, DateTime month, String title) {
    void openHome(BuildContext sheetContext, DateTime date) {
      HapticFeedback.lightImpact();
      Navigator.pop(sheetContext);
      context.go(
        '${RoutePaths.home}?date=${Uri.encodeComponent(date.toIso8601String())}',
      );
    }

    showAppSheet<void>(
      context: context,
      title: '$title ${month.year}',
      cancelLabel: 'Close',
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * .68,
        child: Column(
          children: [
            Expanded(
              child: _monthPreviewPort.buildMonthPreview(
                date: month,
                onDateTap: (date) {
                  log('selected: ${date.toIso8601String()}');
                  openHome(sheetContext, date);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: AppButton(
                label: 'View Full Month',
                kind: AppButtonKind.tinted,
                onPressed: () => openHome(sheetContext, month),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One month of the year: name, a mini grid starting on the right weekday
/// (Sunday first), today and holidays marked, and a holiday count.
class _MonthTile extends StatelessWidget {
  const _MonthTile({required this.month, required this.onTap});

  final MonthSummary month;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final now = DateTime.now();
    final isCurrent =
        month.firstDay.month == now.month && month.firstDay.year == now.year;
    final holidays = month.dates.where((d) => d.hasHolidays).length;
    // DateTime.weekday: Monday 1 … Sunday 7; the grid starts on Sunday.
    final leading = month.firstDay.weekday % 7;

    return Material(
      color: t.surface,
      borderRadius: BorderRadius.circular(t.groupRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(t.groupRadius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: isCurrent
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(t.groupRadius),
                  border: Border.all(color: t.accent, width: 1.5),
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                month.monthName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isCurrent ? t.accent : t.label,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 7,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: [
                    for (var i = 0; i < leading; i++) const SizedBox.shrink(),
                    for (final day in month.dates) _MiniDay(day: day, now: now),
                  ],
                ),
              ),
              if (holidays > 0)
                Row(
                  children: [
                    Icon(Icons.star_rounded, size: 12, color: t.holiday),
                    const SizedBox(width: 3),
                    Text(
                      translateNumbers('$holidays'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: t.holiday,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniDay extends StatelessWidget {
  const _MiniDay({required this.day, required this.now});
  final CompleteDate day;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final isToday =
        day.westernDay == now.day &&
        day.westernMonth == now.month &&
        day.westernYear == now.year;
    return Container(
      alignment: Alignment.center,
      decoration: isToday
          ? BoxDecoration(color: t.accent, shape: BoxShape.circle)
          : null,
      child: Text(
        '${day.westernDay}',
        style: TextStyle(
          fontSize: 8.5,
          height: 1,
          fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
          color: isToday
              ? t.onAccent
              : day.hasHolidays
              ? t.holiday
              : t.secondaryLabel,
        ),
      ),
    );
  }
}
