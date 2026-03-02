import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:telegram_web/telegram_web.dart';

import '../../config/di_setup.dart';

class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({Key? key, required this.navigationShell})
    : super(key: key ?? const ValueKey('ScaffoldWithNestedNavigation'));

  void _goBranch(int index) {
    getIt<TelegramService>().hapticSelectionChanged();
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final telegramService = getIt<TelegramService>();
    final userName = telegramService.getUserName();

    final size = MediaQuery.sizeOf(context);

    // Standard material breakpoint for NavigationRail vs BottomNavigationBar
    if (size.width < 600) {
      return ScaffoldWithNavigationBar(
        body: navigationShell,
        currentIndex: navigationShell.currentIndex,
        onDestinationSelected: _goBranch,
        userName: userName,
      );
    } else {
      return ScaffoldWithNavigationRail(
        body: navigationShell,
        currentIndex: navigationShell.currentIndex,
        onDestinationSelected: _goBranch,
        userName: userName,
        // Show extended rail on large desktop screens
        extended: size.width >= 1200,
      );
    }
  }
}

class ScaffoldWithNavigationBar extends StatelessWidget {
  const ScaffoldWithNavigationBar({
    super.key,
    required this.body,
    required this.currentIndex,
    required this.onDestinationSelected,
    this.userName,
  });

  final Widget body;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final String? userName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: userName != null
          ? AppBar(
              title: Text(
                l10n?.telegramUserLabel(userName!) ?? 'TG: $userName',
              ),
            )
          : null,
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.calendar_today_outlined),
            selectedIcon: const Icon(Icons.calendar_today),
            label: l10n?.home ?? "Home",
          ),
          NavigationDestination(
            icon: const Icon(Icons.view_module_outlined),
            selectedIcon: const Icon(Icons.view_module),
            label: l10n?.views ?? 'Views',
          ),
          NavigationDestination(
            icon: const Icon(Icons.sync_alt_outlined),
            selectedIcon: const Icon(Icons.sync_alt),
            label: l10n?.converter ?? 'Converter',
          ),
          NavigationDestination(
            icon: const Icon(Icons.event_outlined),
            selectedIcon: const Icon(Icons.event),
            label: l10n?.events ?? 'Events',
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n?.settings ?? 'Settings',
          ),
        ],
        onDestinationSelected: onDestinationSelected,
      ),
    );
  }
}

class ScaffoldWithNavigationRail extends StatelessWidget {
  const ScaffoldWithNavigationRail({
    super.key,
    required this.body,
    required this.currentIndex,
    required this.onDestinationSelected,
    this.userName,
    this.extended = false,
  });

  final Widget body;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final String? userName;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: userName != null
          ? AppBar(
              title: Text(
                l10n?.telegramUserLabel(userName!) ?? 'TG: $userName',
              ),
            )
          : null,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: onDestinationSelected,
            labelType: extended
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            extended: extended,
            // Add leading widget for app icon/logo
            leading: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                        image: AssetImage('assets/images/logo.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (extended) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n?.myanmarCalendar ?? 'Myanmar Calendar',
                      style: Theme.of(context).textTheme.bodyLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // FloatingActionButton(
                  //   elevation: 0,
                  //   onPressed: () {}, // Can be used for a primary action
                  //   child: const Icon(Icons.add),
                  // ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            destinations: <NavigationRailDestination>[
              NavigationRailDestination(
                icon: const Icon(Icons.calendar_today_outlined),
                selectedIcon: const Icon(Icons.calendar_today),
                label: Text(l10n?.home ?? "Home"),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.view_module_outlined),
                selectedIcon: const Icon(Icons.view_module),
                label: Text(l10n?.views ?? 'Views'),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.sync_alt_outlined),
                selectedIcon: const Icon(Icons.sync_alt),
                label: Text(l10n?.converter ?? 'Converter'),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.event_outlined),
                selectedIcon: const Icon(Icons.event),
                label: Text(l10n?.events ?? 'Events'),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                label: Text(l10n?.settings ?? 'Settings'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // This is the main content.
          Expanded(child: body),
        ],
      ),
    );
  }
}
