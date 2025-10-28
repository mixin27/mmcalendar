import 'package:events/events.dart';
import 'package:firebase_analytics_app/firebase_analytics_app.dart';
import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';
import 'package:go_router/go_router.dart';
import 'package:localizations/localizations.dart';

import '../../di/calendar_injection.dart';

class DayDetailsPage extends StatefulWidget {
  final DateTime date;

  const DayDetailsPage({super.key, required this.date});

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

    // Load events for the current date
    _loadEventsForCurrentDate();
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

  void _loadEventsForCurrentDate() {
    // Load all events - we'll filter by date in the UI
    context.read<UserEventsBloc>().add(const LoadAllEvents());
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
              onPressed: () async {
                _analyticsService.logButtonClick(
                  buttonName: 'add_event',
                  buttonLocation: 'day_details_fab',
                );

                // Navigate to event creation with pre-filled date
                await GoRouter.of(
                  context,
                ).push('/events/create', extra: _currentDate);

                // Reload events when coming back
                if (mounted) {
                  _loadEventsForCurrentDate();
                }
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
          '${AppLocalizations.of(context)?.holidays ?? "Holidays"} & ${AppLocalizations.of(context)?.anniversary_days ?? "Anniversary Days"}',
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
    return BlocBuilder<UserEventsBloc, UserEventsState>(
      builder: (context, state) {
        // Loading state
        if (state is EventsLoading) {
          return _buildEventsLoadingCard();
        }

        // Error state
        if (state is EventsError) {
          return _buildEventsErrorCard(state.failure.message);
        }

        // Get events for current date
        List<Event> dateEvents = [];
        if (state is EventsLoaded || state is EventsOperationSuccess) {
          final allEvents = state is EventsLoaded
              ? state.events
              : (state as EventsOperationSuccess).events;

          dateEvents = allEvents.where((event) {
            return event.eventDate.year == _currentDate.year &&
                event.eventDate.month == _currentDate.month &&
                event.eventDate.day == _currentDate.day;
          }).toList();

          // Sort by time
          dateEvents.sort((a, b) {
            if (a.isAllDay && !b.isAllDay) return -1;
            if (!a.isAllDay && b.isAllDay) return 1;
            if (a.isAllDay && b.isAllDay) return 0;
            return a.eventTime!.compareTo(b.eventTime!);
          });
        }

        return _buildEventsCard(dateEvents);
      },
    );
  }

  Widget _buildEventsCard(List<Event> events) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.2),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with action button
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.event_note,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Events',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (events.isNotEmpty)
                          Text(
                            '${events.length} ${events.length == 1 ? 'event' : 'events'} scheduled',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                      ],
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      _analyticsService.logButtonClick(
                        buttonName: 'add_event_from_day',
                        buttonLocation: 'day_details_events_section',
                      );

                      await GoRouter.of(
                        context,
                      ).push('/events/create', extra: _currentDate);

                      if (mounted) {
                        _loadEventsForCurrentDate();
                      }
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Events list or empty state
              if (events.isEmpty)
                _buildEventsEmptyState()
              else
                ...events.asMap().entries.map((entry) {
                  final index = entry.key;
                  final event = entry.value;
                  return _AnimatedEventItem(
                    event: event,
                    delay: Duration(milliseconds: index * 100),
                    onTap: () async {
                      _analyticsService.logButtonClick(
                        buttonName: 'view_event_detail',
                        buttonLocation: 'day_details_events_section',
                        additionalData: {'event_id': event.id.toString()},
                      );

                      if (event.id != null && !event.isCompleted) {
                        await GoRouter.of(
                          context,
                        ).push('/events/${event.id}/detail');

                        if (mounted) {
                          _loadEventsForCurrentDate();
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Event marked as completed")),
                        );
                      }
                    },
                    onCheckboxChanged: (checked) {
                      if (event.id != null) {
                        context.read<UserEventsBloc>().add(
                          ToggleEventComplete(event.id!, checked ?? false),
                        );
                      }
                    },
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventsEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_available,
              size: 48,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No events scheduled',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the Add button to create an event',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsLoadingCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading events...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventsErrorCard(String message) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading events',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadEventsForCurrentDate,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
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
                BlocBuilder<UserEventsBloc, UserEventsState>(
                  builder: (context, state) {
                    int count = 0;
                    if (state is EventsLoaded ||
                        state is EventsOperationSuccess) {
                      final items = state is EventsLoaded
                          ? state.events
                          : (state as EventsOperationSuccess).events;
                      count = items.where((event) {
                        return event.eventDate.year == _currentDate.year &&
                            event.eventDate.month == _currentDate.month &&
                            event.eventDate.day == _currentDate.day;
                      }).length;
                    }
                    return _buildStatItem(
                      Icons.event,
                      count.toString(),
                      'Events',
                      Theme.of(context).colorScheme.primary,
                    );
                  },
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
}

class _AnimatedEventItem extends StatefulWidget {
  final Event event;
  final Duration delay;
  final VoidCallback onTap;
  final Function(bool?) onCheckboxChanged;

  const _AnimatedEventItem({
    required this.event,
    this.delay = Duration.zero,
    required this.onTap,
    required this.onCheckboxChanged,
  });

  @override
  State<_AnimatedEventItem> createState() => _AnimatedEventItemState();
}

class _AnimatedEventItemState extends State<_AnimatedEventItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) {
              setState(() => _isPressed = false);
              widget.onTap();
            },
            onTapCancel: () => setState(() => _isPressed = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 12),
              transform: Matrix4.identity()
                ..scaleByDouble(
                  _isPressed ? 0.98 : 1.0,
                  _isPressed ? 0.98 : 1.0,
                  _isPressed ? 0.98 : 1.0,
                  1.0,
                ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(widget.event.effectiveColor).withValues(alpha: 0.15),
                    Color(widget.event.effectiveColor).withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Color(
                    widget.event.effectiveColor,
                  ).withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: _isPressed
                    ? []
                    : [
                        BoxShadow(
                          color: Color(
                            widget.event.effectiveColor,
                          ).withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  children: [
                    // Color indicator bar
                    Container(
                      width: 6,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(widget.event.effectiveColor),
                            Color(
                              widget.event.effectiveColor,
                            ).withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),

                    // Checkbox
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _CustomCheckbox(
                        value: widget.event.isCompleted,
                        color: Color(widget.event.effectiveColor),
                        onChanged: widget.onCheckboxChanged,
                      ),
                    ),

                    // Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title and Priority
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.event.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          decoration: widget.event.isCompleted
                                              ? TextDecoration.lineThrough
                                              : null,
                                          color: widget.event.isCompleted
                                              ? Colors.grey
                                              : null,
                                        ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (widget.event.priority ==
                                        EventPriority.high ||
                                    widget.event.priority ==
                                        EventPriority.urgent)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color:
                                          widget.event.priority ==
                                              EventPriority.urgent
                                          ? Colors.red.withValues(alpha: 0.2)
                                          : Colors.orange.withValues(
                                              alpha: 0.2,
                                            ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.priority_high,
                                      size: 14,
                                      color:
                                          widget.event.priority ==
                                              EventPriority.urgent
                                          ? Colors.red
                                          : Colors.orange,
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Event details
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                // Time
                                _buildDetailChip(
                                  icon: widget.event.isAllDay
                                      ? Icons.event
                                      : Icons.access_time,
                                  label: widget.event.isAllDay
                                      ? 'All day'
                                      : TimeOfDay.fromDateTime(
                                          widget.event.eventTime!,
                                        ).format(context),
                                  color: Theme.of(context).colorScheme.primary,
                                ),

                                // Category
                                _buildDetailChip(
                                  icon: _getCategoryIcon(
                                    widget.event.category.iconName,
                                  ),
                                  label: widget.event.category.name,
                                  color: Color(widget.event.category.colorCode),
                                ),

                                // Location
                                if (widget.event.location != null &&
                                    widget.event.location!.isNotEmpty)
                                  _buildDetailChip(
                                    icon: Icons.location_on,
                                    label: widget.event.location!,
                                    color: Colors.red,
                                  ),

                                // Recurring
                                if (widget.event.isRecurring)
                                  _buildDetailChip(
                                    icon: Icons.repeat,
                                    label: 'Repeats',
                                    color: Colors.purple,
                                  ),

                                // Notifications
                                if (widget.event.hasNotifications)
                                  _buildDetailChip(
                                    icon: Icons.notifications_active,
                                    label:
                                        '${widget.event.notifications.length}',
                                    color: Colors.amber.shade700,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Arrow
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(
                        Icons.chevron_right,
                        color: Color(widget.event.effectiveColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
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

class _CustomCheckbox extends StatefulWidget {
  final bool value;
  final Color color;
  final ValueChanged<bool?>? onChanged;

  const _CustomCheckbox({
    required this.value,
    required this.color,
    this.onChanged,
  });

  @override
  State<_CustomCheckbox> createState() => _CustomCheckboxState();
}

class _CustomCheckboxState extends State<_CustomCheckbox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    if (widget.value) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(_CustomCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (widget.value) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onChanged?.call(!widget.value);
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: widget.value ? widget.color : Colors.transparent,
            border: Border.all(
              color: widget.value ? widget.color : Colors.grey.shade400,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(6),
            boxShadow: widget.value
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: widget.value
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}
