import 'package:events/events.dart';
import 'package:firebase_analytics_app/firebase_analytics_app.dart';
import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:localizations/localizations.dart';

import '../../di/calendar_injection.dart';

class DayDetailsPage extends StatefulWidget {
  final DateTime date;
  final List<Event> events;

  const DayDetailsPage({super.key, required this.date, this.events = const []});

  @override
  State<DayDetailsPage> createState() => _DayDetailsPageState();
}

class _DayDetailsPageState extends State<DayDetailsPage>
    with SingleTickerProviderStateMixin {
  final AnalyticsService _analyticsService = getIt<AnalyticsService>();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late CompleteDate _completeDate;
  late DateTime _currentDate;

  @override
  void initState() {
    super.initState();
    // Log screen view when page loads
    _analyticsService.logScreenView(
      screenName: 'day_details',
      screenClass: 'DayDetailsPage',
    );

    // Log date viewing
    _analyticsService.logDateSelection(
      selectedDate: widget.date.toString(),
      calendarType: 'myanmar',
      dateFormat: 'detailed_view',
    );

    _currentDate = widget.date;
    _completeDate = MyanmarCalendar.getCompleteDate(widget.date);
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  void _navigateToDay(DateTime newDate) {
    setState(() {
      _currentDate = newDate;
      _completeDate = MyanmarCalendar.getCompleteDate(_currentDate);
    });
    _animationController.reset();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          // Swipe right - previous day
          final previousDay = _currentDate.subtract(const Duration(days: 1));

          _analyticsService.logWidgetInteraction(
            widgetName: 'day_details_page',
            actionType: 'swipe_previous',
            metadata: {
              'from_date': _currentDate.toString(),
              'to_date': previousDay.toString(),
            },
          );
          _navigateToDay(previousDay);
        } else if (details.primaryVelocity! < 0) {
          // Swipe left - next day
          final nextDay = _currentDate.add(const Duration(days: 1));

          _analyticsService.logWidgetInteraction(
            widgetName: 'day_details_page',
            actionType: 'swipe_next',
            metadata: {
              'from_date': _currentDate.toString(),
              'to_date': nextDay.toString(),
            },
          );

          _navigateToDay(nextDay);
        }
      },
      child: Scaffold(
        // bottomNavigationBar: SizedBox(
        //   height: 100,
        //   width: double.infinity,
        //   child: _buildBottomDateNavigation(),
        // ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Add Reminder (Future feature)
            // FloatingActionButton.small(
            //   heroTag: 'reminder',
            //   onPressed: () {
            //     _analyticsService.logButtonClick(
            //       buttonName: 'add_reminder',
            //       buttonLocation: 'day_details_fab',
            //     );

            //     // todo(mixin27): Add reminder
            //     _showComingSoonSnackBar(context, 'Reminder feature');
            //   },
            //   tooltip: 'Add Reminder',
            //   child: const Icon(Icons.notifications_outlined),
            // ),
            // const SizedBox(height: 12),

            // Add Event
            FloatingActionButton(
              heroTag: 'event',
              onPressed: () {
                _analyticsService.logButtonClick(
                  buttonName: 'add_event',
                  buttonLocation: 'day_details_fab',
                );

                // Navigate to event creation with pre-filled date
                GoRouter.of(
                  context,
                ).push('/events/create', extra: _currentDate);
              },
              tooltip: 'Add Event',
              child: const Icon(Icons.add),
            ),
          ],
        ),
        body: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Hero Date Card with both calendars
                            // better ux with Hero, but overflow error occure while transition making
                            _buildHeroDateCard(),
                            const SizedBox(height: 16),

                            // Buddhist Calendar Info
                            _buildBuddhistCalendarCard(),
                            const SizedBox(height: 16),

                            // Moon Phase & Weekday Info
                            Row(
                              children: [
                                Expanded(child: _buildMoonPhaseCard()),
                                const SizedBox(width: 12),
                                Expanded(child: _buildWeekdayCard()),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Holidays Section
                            if (_completeDate.hasHolidays ||
                                _completeDate.hasAnniversaryDays) ...[
                              _buildHolidaysCard(),
                              const SizedBox(height: 16),
                            ],

                            // Astrological Information
                            _buildAstrologyCard(),
                            const SizedBox(height: 16),

                            _buildQuickStatsCard(),
                            const SizedBox(height: 16),

                            // Events Section (Placeholder for future)
                            _buildEventsSection(),
                            const SizedBox(height: 24),
                          ],
                        ),

                        _buildTodayIndicator(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
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
              _currentDate.format('EEEE'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              _currentDate.format('MMMM d, yyyy'),
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
                Theme.of(context).colorScheme.primaryContainer,
                Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.7),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            _analyticsService.logButtonClick(
              buttonName: 'previous_day',
              buttonLocation: 'day_details_appbar',
            );

            HapticFeedback.lightImpact();
            final previousDay = _currentDate.subtract(const Duration(days: 1));
            _navigateToDay(previousDay);
          },
          tooltip: 'Previous Day',
        ),
        IconButton(
          icon: const Icon(Icons.calendar_month),
          onPressed: () {
            _analyticsService.logButtonClick(
              buttonName: 'jump_to_date',
              buttonLocation: 'day_details_appbar',
            );
            _showDatePicker(context);
          },
          tooltip: 'Jump to Date',
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            _analyticsService.logButtonClick(
              buttonName: 'next_day',
              buttonLocation: 'day_details_appbar',
            );

            HapticFeedback.lightImpact();
            final nextDay = _currentDate.add(const Duration(days: 1));
            _navigateToDay(nextDay);
          },
          tooltip: 'Next Day',
        ),
        // Share button
        IconButton(
          icon: const Icon(Icons.share_outlined),
          onPressed: _shareDate,
          tooltip: 'Share',
        ),
      ],
    );
  }

  Widget _buildHeroDateCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.4),
              Theme.of(
                context,
              ).colorScheme.secondaryContainer.withValues(alpha: 0.2),
            ],
          ),
        ),
        child: Column(
          children: [
            // Myanmar Date Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Myanmar Calendar',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _completeDate.formatMyanmar(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
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
                  child: _buildQuickInfo(
                    Icons.calendar_month,
                    AppLocalizations.of(context)?.year ?? 'Year',
                    translateNumbers(_completeDate.myanmarYear.toString()),
                    Theme.of(context).colorScheme.tertiary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickInfo(
                    Icons.event,
                    AppLocalizations.of(context)?.month ?? 'Month',
                    TranslationService.getMonthName(
                      _completeDate.myanmarMonth,
                      _completeDate.yearType,
                    ),
                    Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildQuickInfo(
                    Icons.today,
                    AppLocalizations.of(context)?.day ?? 'Day',
                    translateNumbers(_completeDate.myanmarDay.toString()),
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickInfo(
                    Icons.settings,
                    'Type',
                    _getYearTypeName(_completeDate.yearType),
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInfo(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBuddhistCalendarCard() {
    final sasanaYear = _completeDate.sasanaYear;
    final buddhist = widget.date.year + 543; // Buddhist Era

    return ExpandableSection(
      title: 'Buddhist Calendar',
      icon: Icons.temple_buddhist,
      iconColor: Colors.amber,
      initiallyExpanded: true,
      child: Column(
        children: [
          _buildInfoRow(
            AppLocalizations.of(context)?.buddhist_era ?? 'Buddhist Era (BE)',
            translateNumbers(buddhist.toString()),
            Icons.wb_sunny,
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            AppLocalizations.of(context)?.sasana_year ?? 'Sasana Year',
            translateNumbers(sasanaYear.toString()),
            Icons.auto_awesome,
            Colors.amber,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            AppLocalizations.of(context)?.myanmar_era ?? 'Myanmar Era (ME)',
            MyanmarCalendar.formatMyanmar(
              _completeDate.myanmar,
              pattern: "&yyyy",
            ),
            Icons.calendar_today,
            Colors.deepOrange,
          ),
        ],
      ),
    );
  }

  Widget _buildMoonPhaseCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.brightness_3,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)?.moon_phase ?? 'Moon Phase',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              TranslationService.getMoonPhaseName(_completeDate.moonPhase),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Day ${MyanmarCalendar.formatMyanmar(_completeDate.myanmar, pattern: "&f")}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekdayCard() {
    final weekdayName = TranslationService.getWeekdayName(
      _completeDate.weekday,
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.event_note,
                color: Theme.of(context).colorScheme.secondary,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)?.weekday ?? 'Weekday',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              weekdayName,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              widget.date.format('EEE'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHolidaysCard() {
    return ExpandableSection(
      title:
          '${AppLocalizations.of(context)?.holidays ?? "Holidays"} & ${AppLocalizations.of(context)?.special_days ?? "Special Days"}',
      icon: Icons.celebration,
      iconColor: Theme.of(context).colorScheme.error,
      initiallyExpanded: true,
      child: Column(
        children: [
          ..._completeDate.allHolidays.map((holiday) {
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
                      color: Theme.of(context).colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      holiday,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          ..._completeDate.allAnniversaryDays.map((holiday) {
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
                      color: Theme.of(context).colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      holiday,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
    );
  }

  Widget _buildAstrologyCard() {
    return ExpandableSection(
      title:
          AppLocalizations.of(context)?.astrological_information ??
          'Astrological Information',
      icon: Icons.stars_rounded,
      iconColor: Theme.of(context).colorScheme.tertiary,
      initiallyExpanded: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Astrological Details
          if (_completeDate.sabbath.isNotEmpty)
            _buildAstroDetail(
              'Sabbath',
              TranslationService.translate(_completeDate.sabbath),
              Icons.brightness_2,
              Colors.orange,
            ),
          if (_completeDate.yatyaza.isNotEmpty)
            _buildAstroDetail(
              'Yatyaza',
              TranslationService.translate(_completeDate.yatyaza),
              Icons.warning_amber,
              Colors.red,
            ),
          if (_completeDate.pyathada.isNotEmpty)
            _buildAstroDetail(
              'Pyathada',
              TranslationService.translate(_completeDate.pyathada),
              Icons.info_outline,
              Colors.blue,
            ),
          if (_completeDate.nagahle.isNotEmpty)
            _buildAstroDetail(
              AppLocalizations.of(context)?.nagahle ?? 'Nagahle',
              TranslationService.translate(_completeDate.nagahle),
              Icons.explore,
              Colors.green,
            ),
          if (_completeDate.mahabote.isNotEmpty)
            _buildAstroDetail(
              'Mahabote',
              TranslationService.translate(_completeDate.mahabote),
              Icons.star,
              Colors.purple,
            ),
          if (_completeDate.nakhat.isNotEmpty)
            _buildAstroDetail(
              AppLocalizations.of(context)?.nakhat ?? 'Nakhat',
              TranslationService.translate(_completeDate.nakhat),
              Icons.castle,
              Colors.indigo,
            ),
          if (_completeDate.yearName.isNotEmpty)
            _buildAstroDetail(
              AppLocalizations.of(context)?.year_name ?? 'Year Name',
              TranslationService.translate(_completeDate.yearName),
              Icons.pets,
              Colors.teal,
            ),

          // Special Days
          if (_completeDate.astrologicalDays.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)?.special_days ?? 'Special Days',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _completeDate.astrologicalDays.map((day) {
                return Chip(
                  label: Text(TranslationService.translate(day)),
                  labelStyle: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer,
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
    //     side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    //   ),
    //   child: Padding(
    //     padding: const EdgeInsets.all(20),
    //     child: Column(

    //     ),
    //   ),
    // );
  }

  Widget _buildAstroDetail(
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
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsSection() {
    // Placeholder for future events feature
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: widget.events.isEmpty
            ? _buildNoEventsPlaceholder()
            : _buildEventsList(),
      ),
    );
  }

  Widget _buildEventsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.event,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Events',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                // Navigate to event creation with pre-filled date
                GoRouter.of(
                  context,
                ).push('/events/create', extra: _currentDate);
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...widget.events.map((event) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              onTap: () {
                GoRouter.of(context).push('/events/${event.id}/detail');
              },
              leading: Container(
                width: 4,
                height: double.infinity,
                color: Color(event.effectiveColor),
              ),
              title: Text(
                event.title,
                style: TextStyle(
                  decoration: event.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                  color: event.isCompleted ? Colors.grey : null,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        event.isAllDay ? Icons.event : Icons.access_time,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatEventTime(event),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        _getCategoryIcon(event),
                        size: 14,
                        color: Color(event.category.colorCode),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        event.category.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(event.category.colorCode),
                        ),
                      ),
                    ],
                  ),

                  if (event.location != null && event.location!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNoEventsPlaceholder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.event,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Events',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                // Navigate to event creation with pre-filled date
                GoRouter.of(
                  context,
                ).push('/events/create', extra: _currentDate);
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: Column(
            children: [
              Icon(
                Icons.event_available,
                size: 48,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              Text(
                'No events scheduled',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Events feature coming in the next update',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Quick Summary',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  Icons.event,
                  '0',
                  'Events',
                  Theme.of(context).colorScheme.primary,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                _buildStatItem(
                  Icons.celebration,
                  (_completeDate.allHolidays.length +
                          _completeDate.allAnniversaryDays.length)
                      .toString(),
                  'Holidays',
                  Theme.of(context).colorScheme.error,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                _buildStatItem(
                  Icons.stars,
                  _completeDate.astrologicalDays.length.toString(),
                  'Special',
                  Theme.of(context).colorScheme.tertiary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }

  // Widget _buildBottomDateNavigation() {
  //   final previousDay = _currentDate.subtract(const Duration(days: 1));
  //   final nextDay = _currentDate.add(const Duration(days: 1));

  //   return Container(
  //     padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
  //     decoration: BoxDecoration(
  //       color: Theme.of(context).colorScheme.surface,
  //       border: Border(
  //         top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
  //       ),
  //     ),
  //     child: Row(
  //       children: [
  //         // Previous Day
  //         Expanded(
  //           child: _buildNavDay(
  //             previousDay,
  //             Icons.chevron_left,
  //             'Yesterday',
  //             Alignment.centerLeft,
  //           ),
  //         ),

  //         // Today Button
  //         OutlinedButton.icon(
  //           onPressed: () => _navigateToDay(DateTime.now()),
  //           icon: const Icon(Icons.today, size: 16),
  //           label: const Text('Today'),
  //           style: OutlinedButton.styleFrom(
  //             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //           ),
  //         ),

  //         // Next Day
  //         Expanded(
  //           child: _buildNavDay(
  //             nextDay,
  //             Icons.chevron_right,
  //             'Tomorrow',
  //             Alignment.centerRight,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildNavDay(
  //   DateTime date,
  //   IconData icon,
  //   String label,
  //   Alignment alignment,
  // ) {
  //   return InkWell(
  //     onTap: () => _navigateToDay(date),
  //     borderRadius: BorderRadius.circular(8),
  //     child: Padding(
  //       padding: const EdgeInsets.all(8),
  //       child: Column(
  //         crossAxisAlignment: alignment == Alignment.centerLeft
  //             ? CrossAxisAlignment.start
  //             : CrossAxisAlignment.end,
  //         children: [
  //           Icon(icon, size: 20),
  //           Text(label, style: Theme.of(context).textTheme.labelSmall),
  //           Text(
  //             date.format('MMM d'),
  //             style: Theme.of(
  //               context,
  //             ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildTodayIndicator() {
    final isToday = _isSameDay(_currentDate, DateTime.now());

    if (!isToday) return const SizedBox.shrink();

    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.today,
              size: 16,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            const SizedBox(width: 4),
            Text(
              'Today',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _getYearTypeName(int yearType) {
    return TranslationService.getYearTypeName(yearType);
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final selectedDate = await showMyanmarDatePicker(
      context: context,
      initialDate: _currentDate,
      theme: MyanmarCalendarTheme.fromColor(
        Theme.of(context).colorScheme.primary,
      ),
    );

    if (selectedDate != null) {
      _analyticsService.logDateSelection(
        selectedDate: selectedDate.western.toDateTime().toString(),
        calendarType: 'myanmar',
        dateFormat: 'from_date_picker',
      );

      _navigateToDay(selectedDate.western.toDateTime());
    }
  }

  void _shareDate() async {
    try {
      HapticFeedback.lightImpact();
      final text =
          '''
📅 ${_currentDate.format('EEEE, MMMM d, yyyy')}

🗓️ Myanmar Calendar:
${_completeDate.formatMyanmar()}

🌙 Moon Phase: ${TranslationService.getMoonPhaseName(_completeDate.moonPhase)}
📆 Fortnight Day: ${_completeDate.fortnightDay}

${_completeDate.hasHolidays ? '\n🎉 Holidays:\n${[..._completeDate.allHolidays, ..._completeDate.allAnniversaryDays].join('\n')}\n' : ''}
✨ Astrological Info:
${_completeDate.sabbath.isNotEmpty ? '• Sabbath: ${_completeDate.sabbath}\n' : ''}${_completeDate.yatyaza.isNotEmpty ? '• Yatyaza: ${_completeDate.yatyaza}\n' : ''}${_completeDate.pyathada.isNotEmpty ? '• Pyathada: ${_completeDate.pyathada}\n' : ''}
Shared from Myanmar Calendar App
''';
      await share(
        title: "Share Day",
        subject: "Please check myanmar calendar",
        content: text,
      );

      // Log share with rich metadata
      await _analyticsService.logShare(
        contentType: 'date_details',
        platform: 'device_share',
        metadata: {
          'date': _currentDate.toString(),
          'year': _currentDate.year.toString(),
          'month': _currentDate.month.toString(),
          'day': _currentDate.day.toString(),
          'has_holidays': _completeDate.hasHolidays ? "true" : "false",
          'holiday_count':
              (_completeDate.allHolidays.length +
                      _completeDate.allAnniversaryDays.length)
                  .toString(),
          'moon_phase': _completeDate.moonPhase.toString(),
          'has_sabbath': _completeDate.sabbath.isNotEmpty ? "true" : "false",
          'has_yatyaza': _completeDate.yatyaza.isNotEmpty ? "true" : "false",
          'has_pyathada': _completeDate.pyathada.isNotEmpty ? "true" : "false",
        },
      );
    } catch (e, stack) {
      // Log share error
      await _analyticsService.logException(
        exceptionName: 'ShareError',
        description: 'Failed to share: $e',
        stackTrace: stack.toString(),
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to share')));
      }
    }
  }

  // void _showComingSoonSnackBar(BuildContext context, String message) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text('$message coming soon!'),
  //       behavior: SnackBarBehavior.floating,
  //     ),
  //   );
  // }

  String _formatEventTime(Event event) {
    if (event.isAllDay) {
      return DateFormat('MMM dd, yyyy').format(event.eventDate);
    } else {
      return DateFormat('MMM dd, yyyy • hh:mm a').format(event.eventDateTime);
    }
  }

  IconData _getCategoryIcon(Event event) {
    // Map icon name to IconData
    switch (event.category.iconName) {
      case 'person':
        return Icons.person;
      case 'work':
        return Icons.work;
      case 'auto_awesome':
        return Icons.auto_awesome;
      case 'family_restroom':
        return Icons.family_restroom;
      case 'favorite':
        return Icons.favorite;
      default:
        return Icons.event;
    }
  }
}
