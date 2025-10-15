import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';
import 'package:go_router/go_router.dart';
import 'package:localizations/localizations.dart';

class CalendarAppBar extends StatelessWidget {
  final Language language;

  const CalendarAppBar({super.key, this.language = Language.myanmar});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  Text(
                    AppConstants.appName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  Text(
                    _getTodayMyanmarString(),
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
                backgroundColor: context.colorScheme.secondaryContainer,
                foregroundColor: context.colorScheme.onTertiaryContainer,
              ),
              icon: const Icon(Icons.settings_outlined, size: 22),
              onPressed: () => GoRouter.of(context).go(RoutePaths.settings),
              tooltip: AppLocalizations.of(context)?.settings ?? 'Settings',
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

  String _getTodayMyanmarString() {
    final now = DateTime.now();
    final myanmarDate = MyanmarCalendar.fromWestern(
      now.year,
      now.month,
      now.day,
    );
    return myanmarDate.formatMyanmar(null, language);

    // final s = TranslationService.translate('Sasana Year');
    // final sv = TranslationService.translate(myanmarDate.sasanaYear.toString());
    // final formatted = "$s $sv, ${myanmarDate.formatMyanmar()}";

    // return formatted;
  }

  // todo(mixin27): implement search functionality
  // void _showSearch(BuildContext context) {
  //   showSearch(context: context, delegate: _CalendarSearchDelegate());
  // }

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
