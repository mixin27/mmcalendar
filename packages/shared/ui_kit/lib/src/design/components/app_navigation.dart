import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../app_tokens.dart';

@immutable
class AppNavDestination {
  const AppNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// The bottom tab bar on phones.
///
/// Clear: a translucent, blurred bar with a hairline, accent icon and label
/// for the current tab. Material: the Material 3 navigation bar with its
/// pill indicator.
class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<AppNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    if (!t.isClear) {
      return NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelected,
        destinations: [
          for (final d in destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      );
    }
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: t.bar,
            border: Border(top: BorderSide(color: t.separator, width: .5)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 52,
              child: Row(
                children: [
                  for (final (i, d) in destinations.indexed)
                    Expanded(
                      child: _ClearTab(
                        destination: d,
                        selected: i == selectedIndex,
                        onTap: () => onSelected(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClearTab extends StatelessWidget {
  const _ClearTab({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final AppNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = selected ? t.accent : t.tertiaryLabel;
    return Semantics(
      selected: selected,
      button: true,
      label: destination.label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        highlightShape: BoxShape.rectangle,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? destination.selectedIcon : destination.icon,
              size: 25,
              color: color,
            ),
            const SizedBox(height: 2),
            Text(
              destination.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Side navigation from tablet width.
///
/// Clear: a sidebar list (icons only when narrow) on a raised surface.
/// Material: the Material 3 navigation rail.
class AppNavRail extends StatelessWidget {
  const AppNavRail({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    this.extended = false,
    this.header,
  });

  final List<AppNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool extended;

  /// Logo or app name above the destinations.
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    if (!t.isClear) {
      return NavigationRail(
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelected,
        extended: extended,
        labelType: extended
            ? NavigationRailLabelType.none
            : NavigationRailLabelType.all,
        leading: header,
        destinations: [
          for (final d in destinations)
            NavigationRailDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: Text(d.label),
            ),
        ],
      );
    }
    return Container(
      width: extended ? 232 : 84,
      decoration: BoxDecoration(
        color: t.surfaceRaised,
        border: Border(right: BorderSide(color: t.separator, width: .5)),
      ),
      child: SafeArea(
        right: false,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          children: [
            if (header != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: header,
              ),
            for (final (i, d) in destinations.indexed)
              _SidebarItem(
                destination: d,
                selected: i == selectedIndex,
                extended: extended,
                onTap: () => onSelected(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.destination,
    required this.selected,
    required this.extended,
    required this.onTap,
  });

  final AppNavDestination destination;
  final bool selected;
  final bool extended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = selected ? t.accent : t.label;
    final icon = Icon(
      selected ? destination.selectedIcon : destination.icon,
      color: color,
      size: 22,
    );
    return Semantics(
      selected: selected,
      button: true,
      label: destination.label,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Material(
          color: selected ? t.accentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          child: InkWell(
            borderRadius: BorderRadius.circular(9),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 10,
                vertical: extended ? 9 : 8,
              ),
              child: extended
                  ? Row(
                      children: [
                        icon,
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            destination.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w500,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        icon,
                        const SizedBox(height: 3),
                        Text(
                          destination.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
