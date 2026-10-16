import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';
import 'package:telegram_web/telegram_web.dart';

import '../../config/di_setup.dart';

/// The five tabs: a bottom bar on phones, a side rail from 600 px.
///
/// The bar and rail follow the app style (Clear or Material). The Telegram
/// user is shown in Settings, not in an extra bar above every tab.
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({Key? key, required this.navigationShell})
    : super(key: key ?? const ValueKey('ScaffoldWithNestedNavigation'));

  static const double _railBreakpoint = 600;
  static const double _extendedRailBreakpoint = 1200;

  void _goBranch(int index) {
    getIt<TelegramService>().hapticSelectionChanged();
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  List<AppNavDestination> _destinations(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      AppNavDestination(
        icon: Icons.calendar_today_outlined,
        selectedIcon: Icons.calendar_today,
        label: l10n?.home ?? 'Home',
      ),
      AppNavDestination(
        icon: Icons.grid_view_outlined,
        selectedIcon: Icons.grid_view_rounded,
        label: l10n?.views ?? 'Views',
      ),
      AppNavDestination(
        icon: Icons.swap_horiz_rounded,
        selectedIcon: Icons.swap_horiz_rounded,
        label: l10n?.converter ?? 'Converter',
      ),
      AppNavDestination(
        icon: Icons.event_outlined,
        selectedIcon: Icons.event,
        label: l10n?.events ?? 'Events',
      ),
      AppNavDestination(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: l10n?.settings ?? 'Settings',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final destinations = _destinations(context);

    if (width < _railBreakpoint) {
      return Scaffold(
        body: navigationShell,
        bottomNavigationBar: AppNavBar(
          destinations: destinations,
          selectedIndex: navigationShell.currentIndex,
          onSelected: _goBranch,
        ),
      );
    }

    final extended = width >= _extendedRailBreakpoint;
    return Scaffold(
      body: Row(
        children: [
          AppNavRail(
            destinations: destinations,
            selectedIndex: navigationShell.currentIndex,
            onSelected: _goBranch,
            extended: extended,
            header: _RailHeader(extended: extended),
          ),
          if (!context.isClearStyle)
            const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

class _RailHeader extends StatelessWidget {
  const _RailHeader({required this.extended});
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final logo = ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.asset(
        'assets/images/logo.png',
        width: 40,
        height: 40,
        fit: BoxFit.cover,
      ),
    );
    if (!extended) {
      return Padding(padding: const EdgeInsets.only(top: 8), child: logo);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: Row(
        children: [
          logo,
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLocalizations.of(context)?.myanmarCalendar ??
                  'Myanmar Calendar',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
