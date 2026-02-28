import 'package:shared_core/shared_core.dart';
import 'package:flutter/material.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

class CalendarAppBar extends StatelessWidget {
  final Language language;
  final bool showShanCalendar;
  final VoidCallback onTodayTap;

  const CalendarAppBar({
    super.key,
    required this.onTodayTap,
    this.language = Language.myanmar,
    this.showShanCalendar = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 44, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // App title and date
            Expanded(
              child: Column(
                crossAxisAlignment:
                    (ResponsiveUtils.isTablet(context) ||
                        ResponsiveUtils.isDesktop(context))
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  // Text(
                  //   _getGreeting(),
                  //   style: theme.textTheme.bodySmall?.copyWith(
                  //     color: theme.colorScheme.onPrimaryContainer.withValues(
                  //       alpha: 0.8,
                  //     ),
                  //   ),
                  // ),
                  // const SizedBox(height: 4),
                  Text(
                    _getTodayString(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer.withValues(
                        alpha: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Semantics(
                    label: AppConstants.appName,
                    child: Text(
                      AppConstants.appName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  Text(
                    _getTodayMyanmarString(showShanCalendar),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer.withValues(
                        alpha: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Action buttons
            // todo(mixin27): implement search functionality
            // IconButton.filledTonal(
            //   icon: const Icon(Icons.search, size: 22),
            //   onPressed: () => _showSearch(context),
            //   tooltip: 'Search',
            // ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              style: IconButton.styleFrom(
                backgroundColor: context.colorScheme.tertiaryContainer,
                foregroundColor: context.colorScheme.onTertiaryContainer,
              ),
              icon: const Icon(Icons.today_outlined, size: 22),
              onPressed: onTodayTap,
              tooltip: l10n?.go_to_today ?? 'Go to Today',
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              style: IconButton.styleFrom(
                backgroundColor: context.colorScheme.tertiaryContainer,
                foregroundColor: context.colorScheme.onTertiaryContainer,
              ),
              icon: const Icon(Icons.share_outlined, size: 22),
              onPressed: () {
                final today = DateTime.now();
                final completeDate = MyanmarCalendar.getCompleteDate(today);

                final detailedShareText = _formatDetailedShareText(
                  context,
                  completeDate,
                );
                SharePlus.instance.share(
                  ShareParams(
                    text: detailedShareText,
                    subject: AppLocalizations.of(context)?.today ?? 'Today',
                  ),
                );
              },
              tooltip: l10n?.today ?? 'Share Today',
            ),
          ],
        ),
      ),
    );
  }

  String _getTodayString() {
    final now = DateTime.now();
    return now.format('EEEE, MMMM d');
  }

  String _getTodayMyanmarString([bool showShanCalendar = true]) {
    final myanmarDateTime = MyanmarCalendar.today();

    if (showShanCalendar && language == Language.shan) {
      return '${myanmarDateTime.shanDate.year} ${myanmarDateTime.formatMyanmar("&M &P &ff")}';
    } else {
      return myanmarDateTime.formatMyanmar(null, language);
    }

    // final s = TranslationService.translateTo('Sasana Year', MyanmarCalendar.currentLanguage);
    // final sv = TranslationService.translate(myanmarDate.sasanaYear.toString());
    // final formatted = "$s $sv, ${myanmarDate.formatMyanmar()}";

    // return formatted;
  }

  // todo(mixin27): implement search functionality
  // void _showSearch(BuildContext context) {
  //   showSearch(context: context, delegate: _CalendarSearchDelegate());
  // }

  String _formatDetailedShareText(
    BuildContext context,
    CompleteDate completeDate,
  ) {
    final buffer = StringBuffer();
    final l10n = AppLocalizations.of(context);

    // Date Header
    buffer.writeln('📅 ${_getTodayString()}');
    buffer.writeln('🇲🇲 ${_getTodayMyanmarString(showShanCalendar)}');
    buffer.writeln('');

    // Holidays
    if (completeDate.hasHolidays || completeDate.hasAnniversaryDays) {
      buffer.writeln('🎊 ${l10n?.holidays ?? "Holidays"}:');
      for (final h in completeDate.allHolidays) {
        buffer.writeln('• $h');
      }
      for (final h in completeDate.allAnniversaryDays) {
        buffer.writeln('• $h');
      }
      buffer.writeln('');
    }

    // Buddhist info
    buffer.writeln(
      '☸️ ${l10n?.sasana_year ?? "Sasana Year"}: ${translateNumbers(completeDate.sasanaYear.toString())}',
    );
    buffer.writeln(
      '☀️ ${l10n?.buddhist_era ?? "Buddhist Era"}: ${translateNumbers((DateTime.now().year + 543).toString())}',
    );
    buffer.writeln('');

    // Moon Phase & Weekday
    buffer.writeln(
      '🌙 ${l10n?.moon_phase ?? "Moon Phase"}: ${TranslationService.getMoonPhaseName(completeDate.moonPhase, MyanmarCalendar.currentLanguage)}',
    );
    buffer.writeln(
      '🗓️ ${l10n?.weekday ?? "Weekday"}: ${TranslationService.getWeekdayName(completeDate.weekday, MyanmarCalendar.currentLanguage)}',
    );
    buffer.writeln('');

    // Astrology
    buffer.writeln(
      '✨ ${l10n?.astrological_information ?? "Astrological Info"}:',
    );
    if (completeDate.sabbath.isNotEmpty) {
      buffer.writeln(
        '• Sabbath: ${TranslationService.translateTo(completeDate.sabbath, MyanmarCalendar.currentLanguage)}',
      );
    }
    if (completeDate.yatyaza.isNotEmpty) {
      buffer.writeln(
        '• Yatyaza: ${TranslationService.translateTo(completeDate.yatyaza, MyanmarCalendar.currentLanguage)}',
      );
    }
    if (completeDate.pyathada.isNotEmpty) {
      buffer.writeln(
        '• Pyathada: ${TranslationService.translateTo(completeDate.pyathada, MyanmarCalendar.currentLanguage)}',
      );
    }
    if (completeDate.nagahle.isNotEmpty) {
      buffer.writeln(
        '• ${l10n?.nagahle ?? "Nagahle"}: ${TranslationService.translateTo(completeDate.nagahle, MyanmarCalendar.currentLanguage)}',
      );
    }
    if (completeDate.mahabote.isNotEmpty) {
      buffer.writeln(
        '• Mahabote: ${TranslationService.translateTo(completeDate.mahabote, MyanmarCalendar.currentLanguage)}',
      );
    }

    if (completeDate.astrologicalDays.isNotEmpty) {
      buffer.writeln('🌟 ${l10n?.special_days ?? "Special Days"}:');
      for (final day in completeDate.astrologicalDays) {
        buffer.writeln(
          '• ${TranslationService.translateTo(day, MyanmarCalendar.currentLanguage)}',
        );
      }
    }

    return buffer.toString().trim();
  }

  // Helper methods
  // String _getGreeting() {
  //   final hour = DateTime.now().hour;
  //   if (hour < 12) {
  //     return 'Good Morning';
  //   } else if (hour < 17) {
  //     return 'Good Afternoon';
  //   } else {
  //     return 'Good Evening';
  //   }
  // }
}

/// Compact home app bar for smaller screens
class CompactHomeAppBar extends StatelessWidget {
  const CompactHomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      title: Text(AppConstants.appName),
      backgroundColor: theme.colorScheme.primaryContainer,
      foregroundColor: theme.colorScheme.onPrimaryContainer,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => _showSearch(context),
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => GoRouter.of(context).go(RoutePaths.settings),
        ),
      ],
    );
  }

  void _showSearch(BuildContext context) {
    // todo(mixin27): Implement search
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Search functionality coming soon!')),
    );
  }
}

// todo(mixin27): implement search functionality
// Simple search delegate
// class _CalendarSearchDelegate extends SearchDelegate {
//   @override
//   List<Widget> buildActions(BuildContext context) => [
//     IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
//   ];

//   @override
//   Widget buildLeading(BuildContext context) => IconButton(
//     icon: const Icon(Icons.arrow_back),
//     onPressed: () => close(context, null),
//   );

//   @override
//   Widget buildResults(BuildContext context) =>
//       const Center(child: Text('Search results will appear here'));

//   @override
//   Widget buildSuggestions(BuildContext context) =>
//       const Center(child: Text('Search for dates, holidays...'));
// }
