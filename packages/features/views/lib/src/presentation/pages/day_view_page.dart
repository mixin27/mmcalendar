import 'package:shared_core/shared_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';
import 'package:views/src/utils/utils.dart';

import '../../di/views_injection.dart';
import '../bloc/views_bloc.dart';
import '../bloc/views_event.dart';
import '../bloc/views_state.dart';

class DayViewPage extends StatefulWidget {
  const DayViewPage({super.key, this.date});

  final DateTime? date;

  @override
  State<DayViewPage> createState() => _DayViewPageState();
}

class _DayViewPageState extends State<DayViewPage>
    with TickerProviderStateMixin {
  final AnalyticsPort _analyticsService = getIt<AnalyticsPort>();
  final DisplayPreferencesPort _displayPreferencesPort =
      getIt<DisplayPreferencesPort>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Log screen view when page loads
    _analyticsService.logScreenView(
      screenName: 'day_view',
      screenClass: 'DayViewPage',
    );

    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
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
    return Scaffold(
      body: BlocConsumer<ViewsBloc, ViewsState>(
        listener: (context, state) {
          if (state is ViewsError) {
            _showErrorSnackBar(context, state.message);
          }
          if (state is DayViewLoaded) {
            _animationController.reset();
            _animationController.forward();
          }
        },
        builder: (context, state) {
          if (state is ViewsInitial) {
            context.read<ViewsBloc>().add(
              LoadDayView(widget.date ?? DateTime.now()),
            );
            return _buildLoadingState();
          }

          if (state is ViewsLoading) {
            return _buildLoadingState();
          }

          if (state is ViewsError) {
            return _buildErrorState(state.message);
          }

          if (state is DayViewLoaded) {
            return _buildDayContent(state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildDayContent(DayViewLoaded state) {
    final dayData = state.dayData;
    final completeDate = dayData.completeDate;
    final date = dayData.date;

    return StreamBuilder<bool>(
      stream: _displayPreferencesPort.watchShowShanCalendar(),
      initialData: true,
      builder: (context, snapshot) {
        final showShanCalendar = snapshot.data ?? true;

        return CustomScrollView(
          slivers: [
            // Beautiful App Bar
            _buildAppBar(date),

            // Main Content
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Hero Date Card
                        _buildHeroDateCard(
                          completeDate,
                          date,
                          showShanCalendar,
                        ),
                        const SizedBox(height: 16),

                        // Moon Phase Section
                        _buildMoonPhaseCard(completeDate),
                        const SizedBox(height: 16),

                        // Holidays Card
                        if (completeDate.hasHolidays ||
                            completeDate.hasAnniversaryDays)
                          _buildHolidaysCard(completeDate),
                        if (completeDate.hasHolidays)
                          const SizedBox(height: 16),

                        // Astrology Card
                        _buildAstrologyCard(completeDate),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppBar(DateTime date) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16, right: 16),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              date.format('EEEE'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              date.format('MMMM d, yyyy'),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.colorScheme.primaryContainer,
                context.colorScheme.primaryContainer.withValues(alpha: 0.7),
              ],
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        // Previous Day
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            HapticFeedback.lightImpact();
            context.read<ViewsBloc>().add(const NavigateDayPrevious());
          },
          tooltip: 'Previous Day',
        ),
        // Today
        IconButton(
          icon: const Icon(Icons.today),
          onPressed: () {
            HapticFeedback.lightImpact();
            context.read<ViewsBloc>().add(LoadDayView(DateTime.now()));
          },
          tooltip: AppLocalizations.of(context)?.today ?? 'Today',
        ),
        // Next Day
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            HapticFeedback.lightImpact();
            context.read<ViewsBloc>().add(const NavigateDayNext());
          },
          tooltip: 'Next Day',
        ),
      ],
    );
  }

  Widget _buildHeroDateCard(
    CompleteDate completeDate,
    DateTime date,
    bool showShanCalendar,
  ) {
    final year =
        (MyanmarCalendar.currentLanguage == Language.shan || showShanCalendar)
        ? MyanmarDateTime.fromMyanmarDate(completeDate.myanmar).shanDate.year
        : completeDate.myanmarYear;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: context.colorScheme.outlineVariant, width: 1),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.colorScheme.primaryContainer.withValues(alpha: 0.3),
              context.colorScheme.secondaryContainer.withValues(alpha: 0.2),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Myanmar Date
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Myanmar Calendar',
                    style: context.textTheme.labelLarge?.copyWith(
                      color: context.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (MyanmarCalendar.currentLanguage == Language.shan &&
                      showShanCalendar)
                    Text(
                      '${translateNumbers(year.toString(), language: Language.shan)} '
                      '${MyanmarCalendar.formatMyanmar(completeDate.myanmar, pattern: "&M &P &ff")}',
                      style: context.textTheme.headlineSmall?.copyWith(
                        color: context.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    )
                  else
                    Text(
                      MyanmarCalendar.formatMyanmar(completeDate.myanmar),
                      style: context.textTheme.headlineSmall?.copyWith(
                        color: context.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Quick Info Grid
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(
                    Icons.calendar_month,
                    translateNumbers(
                      '${AppLocalizations.of(context)?.year ?? "Year"} $year',
                    ),
                    context.colorScheme.tertiary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip(
                    Icons.today,
                    translateNumbers(
                      '${AppLocalizations.of(context)?.day ?? "Day"} ${completeDate.myanmarDay}',
                    ),
                    context.colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoonPhaseCard(CompleteDate completeDate) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.colorScheme.outlineVariant, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.brightness_3,
                    color: context.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)?.moon_phase ?? 'Moon Phase',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Moon Phase Indicator
            MoonPhaseIndicator(
              moonPhase: completeDate.moonPhase,
              fortnightDay: completeDate.fortnightDay,
              size: 100,
              getMoonPhaseName: (mp) {
                return TranslationService.getMoonPhaseName(
                  mp,
                  MyanmarCalendar.currentLanguage,
                );
              },
              getFortnightDay: (fd) {
                return translateNumbers('Day $fd');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHolidaysCard(CompleteDate completeDate) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: context.colorScheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.colorScheme.errorContainer.withValues(alpha: 0.3),
              context.colorScheme.errorContainer.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.celebration,
                    color: context.colorScheme.error,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)?.holidays ?? 'Holidays',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            ...completeDate.allHolidays.map((holiday) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: context.colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        holiday,
                        style: context.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            ...completeDate.allAnniversaryDays.map((holiday) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: context.colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        holiday,
                        style: context.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAstrologyCard(CompleteDate completeDate) {
    final astroItems = _getAstroItems(completeDate);

    return ExpandableSection(
      title:
          AppLocalizations.of(context)?.astrological_information ??
          'Astrological Information',
      icon: Icons.stars_rounded,
      iconColor: context.colorScheme.tertiary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...astroItems.map(
            (item) =>
                _buildAstroItem(item.label, item.value, item.icon, item.color),
          ),

          // Special Days
          if (completeDate.astrologicalDays.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)?.special_days ?? 'Special Days',
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: completeDate.astrologicalDays.map((day) {
                return Chip(
                  label: Text(
                    TranslationService.translateTo(
                      day,
                      MyanmarCalendar.currentLanguage,
                    ),
                  ),
                  labelStyle: context.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  backgroundColor: context.colorScheme.secondaryContainer,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );

    // return Card(
    //   elevation: 0,
    //   shape: RoundedRectangleBorder(
    //     borderRadius: BorderRadius.circular(16),
    //     side: BorderSide(color: context.colorScheme.outlineVariant, width: 1),
    //   ),
    //   child: Padding(
    //     padding: const EdgeInsets.all(20),
    //     child:
    //   ),
    // );
  }

  Widget _buildAstroItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.textTheme.labelMedium?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: context.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_AstroItemData> _getAstroItems(CompleteDate completeDate) {
    final items = <_AstroItemData>[];

    if (completeDate.sabbath.isNotEmpty) {
      items.add(
        _AstroItemData(
          'Sabbath',
          TranslationService.translateTo(
            completeDate.sabbath,
            MyanmarCalendar.currentLanguage,
          ),
          Icons.brightness_2,
          Colors.orange,
        ),
      );
    }
    if (completeDate.yatyaza.isNotEmpty) {
      items.add(
        _AstroItemData(
          'Yatyaza',
          translateSentence(completeDate.yatyaza),
          Icons.warning_amber,
          Colors.red,
        ),
      );
    }
    if (completeDate.pyathada.isNotEmpty) {
      items.add(
        _AstroItemData(
          'Pyathada',
          translateSentence(completeDate.pyathada),
          Icons.info_outline,
          Colors.blue,
        ),
      );
    }
    if (completeDate.nagahle.isNotEmpty) {
      items.add(
        _AstroItemData(
          AppLocalizations.of(context)?.nagahle ?? 'Nagahle',
          translateSentence(completeDate.nagahle),
          Icons.explore,
          Colors.green,
        ),
      );
    }
    if (completeDate.mahabote.isNotEmpty) {
      items.add(
        _AstroItemData(
          AppLocalizations.of(context)?.mahabote ?? 'Mahabote',
          translateSentence(completeDate.mahabote),
          Icons.star,
          Colors.purple,
        ),
      );
    }
    if (completeDate.nakhat.isNotEmpty) {
      items.add(
        _AstroItemData(
          AppLocalizations.of(context)?.nakhat ?? 'Nakhat',
          translateSentence(completeDate.nakhat),
          Icons.castle,
          Colors.indigo,
        ),
      );
    }
    if (completeDate.yearName.isNotEmpty) {
      items.add(
        _AstroItemData(
          AppLocalizations.of(context)?.year_name ?? 'Year Name',
          translateSentence(completeDate.yearName),
          Icons.calendar_today,
          Colors.teal,
        ),
      );
    }

    return items;
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                context.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading day information...',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
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
              'Oops! Something went wrong',
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
                context.read<ViewsBloc>().add(
                  LoadDayView(widget.date ?? DateTime.now()),
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: context.colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}

class _AstroItemData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  _AstroItemData(this.label, this.value, this.icon, this.color);
}
