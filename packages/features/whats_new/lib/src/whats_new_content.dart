import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_localizations/shared_localizations.dart';

/// Text looked up in the app language.
typedef WhatsNewText = String Function(AppLocalizations l10n);

/// One new feature: what it is, and where "Try it" goes.
class WhatsNewItem {
  const WhatsNewItem({
    required this.id,
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    this.action,
    this.route,
  });

  final String id;
  final IconData icon;
  final Color color;
  final WhatsNewText title;
  final WhatsNewText body;

  /// The button label; null for features with nowhere to go.
  final WhatsNewText? action;
  final String? route;
}

/// The features one version added.
class WhatsNewRelease {
  const WhatsNewRelease(this.version, this.items);

  final String version;
  final List<WhatsNewItem> items;
}

/// Every release with something to announce, newest first. Add a release
/// here with its strings in the ARB files when a version ships features.
const whatsNewReleases = <WhatsNewRelease>[
  WhatsNewRelease('2.3.0', [
    WhatsNewItem(
      id: 'holidays',
      icon: Icons.star_rounded,
      color: Color(0xFFE5383B),
      title: _holidaysTitle,
      body: _holidaysBody,
      action: _holidaysAction,
      route: '${RoutePaths.views}/${RoutePaths.holidays}',
    ),
    WhatsNewItem(
      id: 'widgets',
      icon: Icons.widgets_outlined,
      color: Color(0xFF16A3B0),
      title: _widgetsTitle,
      body: _widgetsBody,
      action: _widgetsAction,
      route: '${RoutePaths.settings}/${RoutePaths.widgets}',
    ),
    WhatsNewItem(
      id: 'welcome',
      icon: Icons.waving_hand_outlined,
      color: Color(0xFF2F5BEA),
      title: _welcomeTitle,
      body: _welcomeBody,
    ),
  ]),
  WhatsNewRelease('2.2.3', [
    WhatsNewItem(
      id: 'gridThemes',
      icon: Icons.palette_outlined,
      color: Color(0xFF8E6CEF),
      title: _themesTitle,
      body: _themesBody,
      action: _themesAction,
      route: '${RoutePaths.settings}/${RoutePaths.calendarGrid}',
    ),
    WhatsNewItem(
      id: 'customColors',
      icon: Icons.tune,
      color: Color(0xFF4C5BD4),
      title: _colorsTitle,
      body: _colorsBody,
      action: _colorsAction,
      route:
          '${RoutePaths.settings}/${RoutePaths.themeSettings}/${RoutePaths.customColors}',
    ),
  ]),
  WhatsNewRelease('2.2.1', [
    WhatsNewItem(
      id: 'appIcons',
      icon: Icons.apps_rounded,
      color: Color(0xFFE0457B),
      title: _iconsTitle,
      body: _iconsBody,
      action: _iconsAction,
      route: '${RoutePaths.settings}/${RoutePaths.themeSettings}',
    ),
  ]),
  WhatsNewRelease('2.2.0', [
    WhatsNewItem(
      id: 'studio',
      icon: Icons.edit_calendar_outlined,
      color: Color(0xFFF08A1C),
      title: _studioTitle,
      body: _studioBody,
      action: _studioAction,
      route: RoutePaths.studio,
    ),
  ]),
];

String _holidaysTitle(AppLocalizations l) => l.whatsNewHolidaysTitle;
String _holidaysBody(AppLocalizations l) => l.whatsNewHolidaysBody;
String _holidaysAction(AppLocalizations l) => l.whatsNewHolidaysAction;
String _widgetsTitle(AppLocalizations l) => l.whatsNewWidgetsTitle;
String _widgetsBody(AppLocalizations l) => l.whatsNewWidgetsBody;
String _widgetsAction(AppLocalizations l) => l.whatsNewWidgetsAction;
String _welcomeTitle(AppLocalizations l) => l.whatsNewWelcomeTitle;
String _welcomeBody(AppLocalizations l) => l.whatsNewWelcomeBody;
String _themesTitle(AppLocalizations l) => l.whatsNewThemesTitle;
String _themesBody(AppLocalizations l) => l.whatsNewThemesBody;
String _themesAction(AppLocalizations l) => l.whatsNewThemesAction;
String _colorsTitle(AppLocalizations l) => l.whatsNewColorsTitle;
String _colorsBody(AppLocalizations l) => l.whatsNewColorsBody;
String _colorsAction(AppLocalizations l) => l.whatsNewColorsAction;
String _iconsTitle(AppLocalizations l) => l.whatsNewIconsTitle;
String _iconsBody(AppLocalizations l) => l.whatsNewIconsBody;
String _iconsAction(AppLocalizations l) => l.whatsNewIconsAction;
String _studioTitle(AppLocalizations l) => l.whatsNewStudioTitle;
String _studioBody(AppLocalizations l) => l.whatsNewStudioBody;
String _studioAction(AppLocalizations l) => l.whatsNewStudioAction;
