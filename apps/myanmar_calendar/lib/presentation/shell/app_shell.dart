import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localizations/localizations.dart';

class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: AppLocalizations.of(context)?.home ?? "Home",
          ),
          NavigationDestination(
            icon: Icon(Icons.view_module_outlined),
            selectedIcon: Icon(Icons.view_module),
            label: AppLocalizations.of(context)?.views ?? 'Views',
          ),
          NavigationDestination(
            icon: Icon(Icons.sync_alt_outlined),
            selectedIcon: Icon(Icons.sync_alt),
            label: AppLocalizations.of(context)?.converter ?? 'Converter',
          ),
          // NavigationDestination(
          //   icon: Icon(Icons.event_outlined),
          //   selectedIcon: Icon(Icons.event),
          //   label: 'Events', // ← New tab
          // ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: AppLocalizations.of(context)?.settings ?? 'Settings',
          ),
        ],
      ),
    );
  }
}
