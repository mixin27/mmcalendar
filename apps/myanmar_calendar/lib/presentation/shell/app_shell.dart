import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localizations/localizations.dart';
import 'package:mmcalendar/config/di_setup.dart';

import '../../telegram/telegram_service.dart';

class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({Key? key, required this.navigationShell})
    : super(key: key ?? const ValueKey('ScaffoldWithNestedNavigation'));

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final telegramService = getIt<TelegramService>();
    final userName = telegramService.getUserName();
    // final firstName = telegramService.getUserFirstName();

    final size = MediaQuery.sizeOf(context);

    if (size.width < 450) {
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
    return Scaffold(
      appBar: userName != null ? AppBar(title: Text('TG: $userName')) : null,
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
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
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event),
            label: AppLocalizations.of(context)?.events ?? 'Events',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: AppLocalizations.of(context)?.settings ?? 'Settings',
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
  });

  final Widget body;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final String? userName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: userName != null ? AppBar(title: Text('TG: $userName')) : null,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: onDestinationSelected,
            labelType: NavigationRailLabelType.all,
            destinations: <NavigationRailDestination>[
              NavigationRailDestination(
                icon: Icon(Icons.calendar_today_outlined),
                selectedIcon: Icon(Icons.calendar_today),
                label: Text(AppLocalizations.of(context)?.home ?? "Home"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.view_module_outlined),
                selectedIcon: Icon(Icons.view_module),
                label: Text(AppLocalizations.of(context)?.views ?? 'Views'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.sync_alt_outlined),
                selectedIcon: Icon(Icons.sync_alt),
                label: Text(
                  AppLocalizations.of(context)?.converter ?? 'Converter',
                ),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.event_outlined),
                selectedIcon: Icon(Icons.event),
                label: Text(AppLocalizations.of(context)?.events ?? 'Events'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text(
                  AppLocalizations.of(context)?.settings ?? 'Settings',
                ),
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
