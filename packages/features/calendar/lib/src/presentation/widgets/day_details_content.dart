import 'package:shared_core/shared_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_localizations/shared_localizations.dart';

import '../../di/calendar_injection.dart';

typedef Event = CalendarEventItem;
typedef EventPriority = CalendarEventPriority;

class DayDetailsContent extends StatelessWidget {
  final DateTime date;
  final CompleteDate completeDate;
  final bool showShanCalendar;
  final AnalyticsPort _analyticsService = getIt<AnalyticsPort>();
  final EventMarkersPort _eventMarkersPort = getIt<EventMarkersPort>();

  DayDetailsContent({
    super.key,
    required this.date,
    required this.completeDate,
    this.showShanCalendar = true,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Event>>(
      stream: _eventMarkersPort.watchEventsForDate(date),
      builder: (context, eventsSnapshot) {
        final dateEvents = eventsSnapshot.data ?? const <Event>[];
        final isEventsLoading =
            eventsSnapshot.connectionState == ConnectionState.waiting &&
            !eventsSnapshot.hasData;
        final eventsErrorMessage = eventsSnapshot.hasError
            ? eventsSnapshot.error.toString()
            : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Date Card with both calendars
            _buildHeroDateCard(context, showShanCalendar),
            const SizedBox(height: 16),

            // Buddhist Calendar Info
            _buildBuddhistCalendarCard(context),
            const SizedBox(height: 16),

            // Moon Phase & Weekday Info
            Row(
              children: [
                Expanded(child: _buildMoonPhaseCard(context)),
                const SizedBox(width: 12),
                Expanded(child: _buildWeekdayCard(context)),
              ],
            ),
            const SizedBox(height: 16),

            // Holidays Section
            if (completeDate.hasHolidays ||
                completeDate.hasAnniversaryDays) ...[
              _buildHolidaysCard(context),
              const SizedBox(height: 16),
            ],

            // Astrological Information
            _buildAstrologyCard(context),
            const SizedBox(height: 16),

            // AI Prompt Generation
            _buildAIPromptSection(context),
            const SizedBox(height: 16),

            _buildQuickStatsCard(context, eventCount: dateEvents.length),
            const SizedBox(height: 16),

            // Events Section
            _buildEventsSection(
              context,
              dateEvents: dateEvents,
              isLoading: isEventsLoading,
              errorMessage: eventsErrorMessage,
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildHeroDateCard(BuildContext context, bool showShanCalendar) {
    final year =
        (MyanmarCalendar.currentLanguage == Language.shan || showShanCalendar)
        ? MyanmarDateTime.fromMyanmarDate(completeDate.myanmar).shanDate.year
        : completeDate.myanmarYear;

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
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  if (MyanmarCalendar.currentLanguage == Language.shan &&
                      showShanCalendar)
                    Text(
                      '${FormatService().translateNumbers(year.toString(), language: Language.shan)} ${completeDate.formatMyanmar(pattern: "&M &P &ff")} ${TranslationService.translate('Yat')}',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    )
                  else
                    Text(
                      '${completeDate.formatMyanmar()} ${TranslationService.translate('Yat')}',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
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
                    context,
                    Icons.calendar_month,
                    AppLocalizations.of(context)?.year ?? 'Year',
                    translateNumbers(year.toString()),
                    Theme.of(context).colorScheme.tertiary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickInfo(
                    context,
                    Icons.event,
                    AppLocalizations.of(context)?.month ?? 'Month',
                    TranslationService.getMonthName(
                      completeDate.myanmarMonth,
                      completeDate.yearType,
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
                    context,
                    Icons.today,
                    AppLocalizations.of(context)?.day ?? 'Day',
                    translateNumbers(completeDate.myanmarDay.toString()),
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickInfo(
                    context,
                    Icons.settings,
                    'Type',
                    _getYearTypeName(completeDate.yearType),
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
    BuildContext context,
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

  String _getYearTypeName(int yearType) {
    return TranslationService.getYearTypeName(yearType);
  }

  Widget _buildBuddhistCalendarCard(BuildContext context) {
    final sasanaYear = completeDate.sasanaYear;
    final buddhist = date.year + 543; // Buddhist Era

    return ExpandableSection(
      title: 'Buddhist Calendar',
      icon: Icons.temple_buddhist,
      iconColor: Colors.amber,
      initiallyExpanded: true,
      child: Column(
        children: [
          _buildInfoRow(
            context,
            AppLocalizations.of(context)?.buddhist_era ?? 'Buddhist Era (BE)',
            translateNumbers(buddhist.toString()),
            Icons.wb_sunny,
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            AppLocalizations.of(context)?.sasana_year ?? 'Sasana Year',
            translateNumbers(sasanaYear.toString()),
            Icons.auto_awesome,
            Colors.amber,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            AppLocalizations.of(context)?.myanmar_era ?? 'Myanmar Era (ME)',
            MyanmarCalendar.formatMyanmar(
              completeDate.myanmar,
              pattern: "&yyyy",
            ),
            Icons.calendar_today,
            Colors.deepOrange,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMoonPhaseCard(BuildContext context) {
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
            Semantics(
              label: AppLocalizations.of(context)?.moon_phase ?? 'Moon Phase',
              child: Text(
                AppLocalizations.of(context)?.moon_phase ?? 'Moon Phase',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),
            Semantics(
              label: TranslationService.getMoonPhaseName(
                completeDate.moonPhase,
              ),
              child: Text(
                TranslationService.getMoonPhaseName(completeDate.moonPhase),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Day ${MyanmarCalendar.formatMyanmar(completeDate.myanmar, pattern: "&f")}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekdayCard(BuildContext context) {
    final weekdayName = TranslationService.getWeekdayName(completeDate.weekday);

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
            Semantics(
              label: AppLocalizations.of(context)?.weekday ?? 'Weekday',
              child: Text(
                AppLocalizations.of(context)?.weekday ?? 'Weekday',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),
            Semantics(
              label: weekdayName,
              child: Text(
                weekdayName,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date.format('EEE'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHolidaysCard(BuildContext context) {
    return ExpandableSection(
      title:
          '${AppLocalizations.of(context)?.holidays ?? "Holidays"} & ${AppLocalizations.of(context)?.anniversary_days ?? "Anniversary Days"}',
      icon: Icons.celebration,
      iconColor: Theme.of(context).colorScheme.error,
      initiallyExpanded: true,
      child: Column(
        children: [
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

  Widget _buildAstrologyCard(BuildContext context) {
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
          if (completeDate.sabbath.isNotEmpty)
            _buildAstroDetail(
              context,
              'Sabbath',
              TranslationService.translate(completeDate.sabbath),
              Icons.brightness_2,
              Colors.orange,
            ),
          if (completeDate.yatyaza.isNotEmpty)
            _buildAstroDetail(
              context,
              'Yatyaza',
              TranslationService.translate(completeDate.yatyaza),
              Icons.warning_amber,
              Colors.red,
            ),
          if (completeDate.pyathada.isNotEmpty)
            _buildAstroDetail(
              context,
              'Pyathada',
              TranslationService.translate(completeDate.pyathada),
              Icons.info_outline,
              Colors.blue,
            ),
          if (completeDate.nagahle.isNotEmpty)
            _buildAstroDetail(
              context,
              AppLocalizations.of(context)?.nagahle ?? 'Nagahle',
              TranslationService.translate(completeDate.nagahle),
              Icons.explore,
              Colors.green,
            ),
          if (completeDate.mahabote.isNotEmpty)
            _buildAstroDetail(
              context,
              'Mahabote',
              TranslationService.translate(completeDate.mahabote),
              Icons.star,
              Colors.purple,
            ),
          if (completeDate.nakhat.isNotEmpty)
            _buildAstroDetail(
              context,
              AppLocalizations.of(context)?.nakhat ?? 'Nakhat',
              TranslationService.translate(completeDate.nakhat),
              Icons.castle,
              Colors.indigo,
            ),
          if (completeDate.yearName.isNotEmpty)
            _buildAstroDetail(
              context,
              AppLocalizations.of(context)?.year_name ?? 'Year Name',
              TranslationService.translate(completeDate.yearName),
              Icons.pets,
              Colors.teal,
            ),

          // Special Days
          if (completeDate.astrologicalDays.isNotEmpty) ...[
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
              children: completeDate.astrologicalDays.map((day) {
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
  }

  Widget _buildAstroDetail(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIPromptSection(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
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
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Horoscope Prompt',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Generate a prompt for AI analysis',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _showAIPromptDialog(context),
                icon: const Icon(Icons.psychology_outlined),
                label: const Text('Generate AI Prompt'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAIPromptDialog(BuildContext context) {
    _analyticsService.logButtonClick(
      buttonName: 'generate_ai_prompt',
      buttonLocation: 'day_details_page',
    );

    final prompt = MyanmarCalendar.generateAIPrompt(
      completeDate,
      language: MyanmarCalendar.currentLanguage,
      type: AIPromptType.horoscope,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.auto_awesome,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Text('AI Prompt'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Copy this prompt into your favorite AI (ChatGPT, Gemini, etc.) for a detailed astrological analysis.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Text(
                  prompt,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: prompt));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Prompt copied to clipboard')),
              );
              Navigator.pop(context);
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy Prompt'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsCard(BuildContext context, {required int eventCount}) {
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
                  context,
                  Icons.event,
                  eventCount.toString(),
                  'Events',
                  Theme.of(context).colorScheme.primary,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                _buildStatItem(
                  context,
                  Icons.celebration,
                  (completeDate.allHolidays.length +
                          completeDate.allAnniversaryDays.length)
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
                  context,
                  Icons.stars,
                  completeDate.astrologicalDays.length.toString(),
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
    BuildContext context,
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

  Widget _buildEventsSection(
    BuildContext context, {
    required List<Event> dateEvents,
    required bool isLoading,
    required String? errorMessage,
  }) {
    if (isLoading) {
      return _buildEventsLoadingCard(context);
    }

    if (errorMessage != null) {
      return _buildEventsErrorCard(context, errorMessage);
    }

    final sortedEvents = <Event>[...dateEvents]
      ..sort((a, b) {
        if (a.isAllDay && !b.isAllDay) return -1;
        if (!a.isAllDay && b.isAllDay) return 1;
        if (a.isAllDay && b.isAllDay) return 0;
        return a.eventTime!.compareTo(b.eventTime!);
      });

    return _buildEventsCard(context, sortedEvents);
  }

  Widget _buildEventsCard(BuildContext context, List<Event> events) {
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
                      ).push('/events/create', extra: date);
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
                _buildEventsEmptyState(context)
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
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Event marked as completed")),
                        );
                      }
                    },
                    onCheckboxChanged: (checked) async {
                      if (event.id != null) {
                        await _toggleEventCompletion(
                          context,
                          eventId: event.id!,
                          isCompleted: checked ?? false,
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

  Widget _buildEventsEmptyState(BuildContext context) {
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
            'Tap + to create an event',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsLoadingCard(BuildContext context) {
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

  Widget _buildEventsErrorCard(BuildContext context, String message) {
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
          ],
        ),
      ),
    );
  }

  Future<void> _toggleEventCompletion(
    BuildContext context, {
    required int eventId,
    required bool isCompleted,
  }) async {
    try {
      await _eventMarkersPort.toggleEventCompletion(
        eventId: eventId,
        isCompleted: isCompleted,
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update event: $error')));
    }
  }
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
                                  context,
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
                                  context,
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
                                    context,
                                    icon: Icons.location_on,
                                    label: widget.event.location!,
                                    color: Colors.red,
                                  ),

                                // Recurring
                                if (widget.event.isRecurring)
                                  _buildDetailChip(
                                    context,
                                    icon: Icons.repeat,
                                    label: 'Repeats',
                                    color: Colors.purple,
                                  ),

                                // Notifications
                                if (widget.event.hasNotifications)
                                  _buildDetailChip(
                                    context,
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

  Widget _buildDetailChip(
    BuildContext context, {
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
