import 'package:shared_core/shared_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import '../../di/calendar_injection.dart';

typedef Event = CalendarEventItem;
typedef EventPriority = CalendarEventPriority;

class DayDetailsContent extends StatelessWidget {
  final DateTime date;
  final CompleteDate completeDate;
  final bool showShanCalendar;
  final AnalyticsPort _analyticsService = getIt<AnalyticsPort>();
  final EventActionsPort _eventActionsPort = getIt<EventActionsPort>();
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
                      '${translateNumbers(year.toString(), language: Language.shan)} '
                      '${MyanmarCalendar.formatMyanmar(completeDate.myanmar, pattern: "&M &P &f &Yat")}',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    )
                  else
                    Text(
                      MyanmarCalendar.formatMyanmar(
                        completeDate.myanmar,
                        pattern: '&y &M &P &f &Yat',
                      ),
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
                      MyanmarCalendar.currentLanguage,
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
    return TranslationService.getYearTypeName(
      yearType,
      MyanmarCalendar.currentLanguage,
    );
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
                MyanmarCalendar.currentLanguage,
              ),
              child: Text(
                TranslationService.getMoonPhaseName(
                  completeDate.moonPhase,
                  MyanmarCalendar.currentLanguage,
                ),
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
    final weekdayName = TranslationService.getWeekdayName(
      completeDate.weekday,
      MyanmarCalendar.currentLanguage,
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
              TranslationService.translateTo(
                completeDate.sabbath,
                MyanmarCalendar.currentLanguage,
              ),
              Icons.brightness_2,
              Colors.orange,
            ),
          if (completeDate.yatyaza.isNotEmpty)
            _buildAstroDetail(
              context,
              'Yatyaza',
              TranslationService.translateTo(
                completeDate.yatyaza,
                MyanmarCalendar.currentLanguage,
              ),
              Icons.warning_amber,
              Colors.red,
            ),
          if (completeDate.pyathada.isNotEmpty)
            _buildAstroDetail(
              context,
              'Pyathada',
              TranslationService.translateTo(
                completeDate.pyathada,
                MyanmarCalendar.currentLanguage,
              ),
              Icons.info_outline,
              Colors.blue,
            ),
          if (completeDate.nagahle.isNotEmpty)
            _buildAstroDetail(
              context,
              AppLocalizations.of(context)?.nagahle ?? 'Nagahle',
              TranslationService.translateTo(
                completeDate.nagahle,
                MyanmarCalendar.currentLanguage,
              ),
              Icons.explore,
              Colors.green,
            ),
          if (completeDate.mahabote.isNotEmpty)
            _buildAstroDetail(
              context,
              'Mahabote',
              TranslationService.translateTo(
                completeDate.mahabote,
                MyanmarCalendar.currentLanguage,
              ),
              Icons.star,
              Colors.purple,
            ),
          if (completeDate.nakhat.isNotEmpty)
            _buildAstroDetail(
              context,
              AppLocalizations.of(context)?.nakhat ?? 'Nakhat',
              TranslationService.translateTo(
                completeDate.nakhat,
                MyanmarCalendar.currentLanguage,
              ),
              Icons.castle,
              Colors.indigo,
            ),
          if (completeDate.yearName.isNotEmpty)
            _buildAstroDetail(
              context,
              AppLocalizations.of(context)?.year_name ?? 'Year Name',
              TranslationService.translateTo(
                completeDate.yearName,
                MyanmarCalendar.currentLanguage,
              ),
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
                  label: Text(
                    TranslationService.translateTo(
                      day,
                      MyanmarCalendar.currentLanguage,
                    ),
                  ),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.event_note,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Events',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${events.length} ${events.length == 1 ? 'event' : 'events'} scheduled',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
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
                    await _eventActionsPort.openCreateEvent(
                      context,
                      initialDate: date,
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (events.isEmpty)
              _buildEventsEmptyState(context)
            else
              ...events.asMap().entries.map((entry) {
                final index = entry.key;
                final event = entry.value;
                return _AnimatedEventItem(
                  event: event,
                  delay: Duration(milliseconds: index * 80),
                  onTap: () async {
                    _analyticsService.logButtonClick(
                      buttonName: 'view_event_detail',
                      buttonLocation: 'day_details_events_section',
                      additionalData: {'event_id': event.id.toString()},
                    );

                    if (event.id != null) {
                      await _eventActionsPort.openEventDetail(
                        context,
                        eventId: event.id!,
                        occurrenceDate: event.eventDate,
                      );
                    }
                  },
                  onCheckboxChanged: (checked) async {
                    if (event.id != null) {
                      await _toggleEventCompletion(
                        context,
                        event: event,
                        isCompleted: checked ?? false,
                      );
                    }
                  },
                );
              }),
          ],
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
    required Event event,
    required bool isCompleted,
  }) async {
    try {
      await _eventMarkersPort.toggleEventCompletion(
        eventId: event.id!,
        isCompleted: isCompleted,
        isRecurring: event.isRecurring,
        occurrenceDate: event.eventDate,
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
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 320),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
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
    final colorScheme = Theme.of(context).colorScheme;
    final event = widget.event;
    final eventColor = Color(event.effectiveColor);
    final isCompleted = event.isCompleted;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [eventColor.withValues(alpha: 0.08), Colors.transparent],
            ),
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        widget.onCheckboxChanged(!event.isCompleted);
                      },
                      icon: Icon(
                        isCompleted
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: isCompleted ? colorScheme.primary : eventColor,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: eventColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  event.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        decoration: isCompleted
                                            ? TextDecoration.lineThrough
                                            : null,
                                        color: isCompleted
                                            ? colorScheme.onSurfaceVariant
                                            : colorScheme.onSurface,
                                      ),
                                ),
                              ),
                              if (event.isRecurring)
                                Icon(
                                  Icons.repeat,
                                  size: 16,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              if (event.hasNotifications) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.notifications_active_outlined,
                                  size: 16,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                event.isAllDay
                                    ? Icons.event
                                    : Icons.access_time,
                                size: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _timeLabel(context),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(width: 10),
                              Icon(
                                _getCategoryIcon(event.category.iconName),
                                size: 14,
                                color: eventColor,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  event.category.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          if ((event.location ?? '').isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    event.location!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
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

  String _timeLabel(BuildContext context) {
    if (widget.event.isAllDay || widget.event.eventTime == null) {
      return 'All day';
    }
    return TimeOfDay.fromDateTime(widget.event.eventTime!).format(context);
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
