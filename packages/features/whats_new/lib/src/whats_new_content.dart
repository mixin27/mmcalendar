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
  WhatsNewRelease('2.7.0', [
    WhatsNewItem(
      id: 'longWeekends',
      icon: Icons.beach_access_outlined,
      color: Color(0xFFF08A1C),
      title: _wnLongWeekendsTitle,
      body: _wnLongWeekendsBody,
      action: _wnLongWeekendsAction,
      route:
          '${RoutePaths.views}/${RoutePaths.holidays}/${RoutePaths.longWeekends}',
    ),
    WhatsNewItem(
      id: 'meritDiary',
      icon: Icons.volunteer_activism_outlined,
      color: Color(0xFFC9A227),
      title: _wnMeritTitle,
      body: _wnMeritBody,
      action: _wnMeritAction,
      route: '${RoutePaths.views}/${RoutePaths.merit}',
    ),
    WhatsNewItem(
      id: 'shareEvents',
      icon: Icons.qr_code_2_rounded,
      color: Color(0xFF4C5BD4),
      title: _wnShareEventsTitle,
      body: _wnShareEventsBody,
      action: _wnShareEventsAction,
      route: RoutePaths.events,
    ),
    WhatsNewItem(
      id: 'widgetTicks',
      icon: Icons.task_alt_rounded,
      color: Color(0xFF16A3B0),
      title: _wnWidgetTicksTitle,
      body: _wnWidgetTicksBody,
      action: _wnWidgetTicksAction,
      route: '${RoutePaths.settings}/${RoutePaths.widgets}',
    ),
    WhatsNewItem(
      id: 'watch',
      icon: Icons.watch_outlined,
      color: Color(0xFF2B5598),
      title: _wnWatchTitle,
      body: _wnWatchBody,
    ),
  ]),
  WhatsNewRelease('2.6.0', [
    WhatsNewItem(
      id: 'dailySummary',
      icon: Icons.wb_twilight_rounded,
      color: Color(0xFFF08A1C),
      title: _wnDailyTitle,
      body: _wnDailyBody,
      action: _wnDailyAction,
      route: '${RoutePaths.views}/${RoutePaths.holidays}',
    ),
    WhatsNewItem(
      id: 'myanmarRepeats',
      icon: Icons.event_repeat_outlined,
      color: Color(0xFF2F9E5B),
      title: _wnMyanmarRepeatTitle,
      body: _wnMyanmarRepeatBody,
      action: _wnMyanmarRepeatAction,
      route: '${RoutePaths.events}/${RoutePaths.createEvent}',
    ),
    WhatsNewItem(
      id: 'shareDay',
      icon: Icons.ios_share_rounded,
      color: Color(0xFF4C5BD4),
      title: _wnShareDayTitle,
      body: _wnShareDayBody,
      action: _wnShareDayAction,
      route: RoutePaths.home,
    ),
    WhatsNewItem(
      id: 'typedDates',
      icon: Icons.keyboard_outlined,
      color: Color(0xFF8E6CEF),
      title: _wnTypedDatesTitle,
      body: _wnTypedDatesBody,
    ),
    WhatsNewItem(
      id: 'widgets260',
      icon: Icons.widgets_outlined,
      color: Color(0xFF16A3B0),
      title: _wnWidgetsTitle,
      body: _wnWidgetsBody,
      action: _wnWidgetsAction,
      route: '${RoutePaths.settings}/${RoutePaths.widgets}',
    ),
    WhatsNewItem(
      id: 'icsImport',
      icon: Icons.event_note_outlined,
      color: Color(0xFFE0457B),
      title: _wnIcsImportTitle,
      body: _wnIcsImportBody,
      action: _wnIcsImportAction,
      route:
          '${RoutePaths.settings}/${RoutePaths.privacyAndData}/${RoutePaths.backup}',
    ),
    WhatsNewItem(
      id: 'easyReading',
      icon: Icons.format_size_rounded,
      color: Color(0xFF2B5598),
      title: _wnEasyReadingTitle,
      body: _wnEasyReadingBody,
      action: _wnEasyReadingAction,
      route: '${RoutePaths.settings}/${RoutePaths.displayPreferences}',
    ),
  ]),
  WhatsNewRelease('2.5.0', [
    WhatsNewItem(
      id: 'dayNotes',
      icon: Icons.sticky_note_2_outlined,
      color: Color(0xFFE0A21B),
      title: _wnNotesTitle,
      body: _wnNotesBody,
      action: _wnNotesAction,
      route: '${RoutePaths.views}/${RoutePaths.notes}',
    ),
    WhatsNewItem(
      id: 'search',
      icon: Icons.search_rounded,
      color: Color(0xFF4C5BD4),
      title: _wnSearchTitle,
      body: _wnSearchBody,
      action: _wnSearchAction,
      route: '${RoutePaths.home}/${RoutePaths.search}',
    ),
    WhatsNewItem(
      id: 'sabbathReminders',
      icon: Icons.self_improvement_rounded,
      color: Color(0xFF8E6CEF),
      title: _wnSabbathTitle,
      body: _wnSabbathBody,
      action: _wnSabbathAction,
      route: '${RoutePaths.views}/${RoutePaths.holidays}',
    ),
    WhatsNewItem(
      id: 'goodDays',
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFF2F9E5B),
      title: _wnGoodDaysTitle,
      body: _wnGoodDaysBody,
      action: _wnGoodDaysAction,
      route: '${RoutePaths.views}/${RoutePaths.goodDays}',
    ),
    WhatsNewItem(
      id: 'birthTool',
      icon: Icons.cake_outlined,
      color: Color(0xFFE0457B),
      title: _wnBirthTitle,
      body: _wnBirthBody,
      action: _wnBirthAction,
      route: RoutePaths.converter,
    ),
    WhatsNewItem(
      id: 'backup',
      icon: Icons.cloud_upload_outlined,
      color: Color(0xFF16A3B0),
      title: _wnBackupTitle,
      body: _wnBackupBody,
      action: _wnBackupAction,
      route:
          '${RoutePaths.settings}/${RoutePaths.privacyAndData}/${RoutePaths.backup}',
    ),
  ]),
  WhatsNewRelease('2.4.0', [
    WhatsNewItem(
      id: 'holidayGuide',
      icon: Icons.menu_book_outlined,
      color: Color(0xFFE5383B),
      title: _guideTitle,
      body: _guideBody,
      action: _holidaysAction,
      route: '${RoutePaths.views}/${RoutePaths.holidays}',
    ),
    WhatsNewItem(
      id: 'englishWesternDates',
      icon: Icons.translate,
      color: Color(0xFF2B5598),
      title: _englishDatesTitle,
      body: _englishDatesBody,
      action: _englishDatesAction,
      route: '${RoutePaths.settings}/${RoutePaths.displayPreferences}',
    ),
  ]),
  // Everything since 2.2.3, the biggest first.
  WhatsNewRelease('2.3.0', [
    WhatsNewItem(
      id: 'studio',
      icon: Icons.edit_calendar_outlined,
      color: Color(0xFFF08A1C),
      title: _studioTitle,
      body: _studioBody,
      action: _studioAction,
      route: RoutePaths.studio,
    ),
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
      id: 'timetables',
      icon: Icons.event_repeat_outlined,
      color: Color(0xFF2F9E5B),
      title: _timetablesTitle,
      body: _timetablesBody,
      action: _timetablesAction,
      route: '${RoutePaths.events}/${RoutePaths.createEvent}',
    ),
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
      id: 'customColors',
      icon: Icons.tune,
      color: Color(0xFF4C5BD4),
      title: _colorsTitle,
      body: _colorsBody,
      action: _colorsAction,
      route:
          '${RoutePaths.settings}/${RoutePaths.themeSettings}/${RoutePaths.customColors}',
    ),
    WhatsNewItem(
      id: 'newAppIcons',
      icon: Icons.apps_rounded,
      color: Color(0xFF2B5598),
      title: _newIconsTitle,
      body: _newIconsBody,
      action: _iconsAction,
      route: '${RoutePaths.settings}/${RoutePaths.themeSettings}',
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
];

String _holidaysTitle(AppLocalizations l) => l.whatsNewHolidaysTitle;
String _holidaysBody(AppLocalizations l) => l.whatsNewHolidaysBody;
String _holidaysAction(AppLocalizations l) => l.whatsNewHolidaysAction;
String _widgetsTitle(AppLocalizations l) => l.whatsNewWidgetsTitle;
String _widgetsBody(AppLocalizations l) => l.whatsNewWidgetsBody;
String _widgetsAction(AppLocalizations l) => l.whatsNewWidgetsAction;
String _timetablesTitle(AppLocalizations l) => l.whatsNewTimetablesTitle;
String _timetablesBody(AppLocalizations l) => l.whatsNewTimetablesBody;
String _timetablesAction(AppLocalizations l) => l.whatsNewTimetablesAction;
String _themesTitle(AppLocalizations l) => l.whatsNewThemesTitle;
String _themesBody(AppLocalizations l) => l.whatsNewThemesBody;
String _themesAction(AppLocalizations l) => l.whatsNewThemesAction;
String _colorsTitle(AppLocalizations l) => l.whatsNewColorsTitle;
String _colorsBody(AppLocalizations l) => l.whatsNewColorsBody;
String _colorsAction(AppLocalizations l) => l.whatsNewColorsAction;
String _iconsTitle(AppLocalizations l) => l.whatsNewIconsTitle;
String _iconsBody(AppLocalizations l) => l.whatsNewIconsBody;
String _iconsAction(AppLocalizations l) => l.whatsNewIconsAction;
String _newIconsTitle(AppLocalizations l) => l.whatsNewNewIconsTitle;
String _newIconsBody(AppLocalizations l) => l.whatsNewNewIconsBody;
String _studioTitle(AppLocalizations l) => l.whatsNewStudioTitle;
String _studioBody(AppLocalizations l) => l.whatsNewStudioBody;
String _studioAction(AppLocalizations l) => l.whatsNewStudioAction;
String _guideTitle(AppLocalizations l) => l.whatsNewGuideTitle;
String _guideBody(AppLocalizations l) => l.whatsNewGuideBody;
String _englishDatesTitle(AppLocalizations l) => l.whatsNewEnglishDatesTitle;
String _englishDatesBody(AppLocalizations l) => l.whatsNewEnglishDatesBody;
String _englishDatesAction(AppLocalizations l) => l.whatsNewEnglishDatesAction;
String _wnNotesTitle(AppLocalizations l) => l.whatsNewNotesTitle_250;
String _wnNotesBody(AppLocalizations l) => l.whatsNewNotesBody_250;
String _wnNotesAction(AppLocalizations l) => l.whatsNewNotesAction_250;
String _wnSearchTitle(AppLocalizations l) => l.whatsNewSearchTitle_250;
String _wnSearchBody(AppLocalizations l) => l.whatsNewSearchBody_250;
String _wnSearchAction(AppLocalizations l) => l.whatsNewSearchAction_250;
String _wnSabbathTitle(AppLocalizations l) => l.whatsNewSabbathTitle_250;
String _wnSabbathBody(AppLocalizations l) => l.whatsNewSabbathBody_250;
String _wnSabbathAction(AppLocalizations l) => l.whatsNewSabbathAction_250;
String _wnGoodDaysTitle(AppLocalizations l) => l.whatsNewGoodDaysTitle_250;
String _wnGoodDaysBody(AppLocalizations l) => l.whatsNewGoodDaysBody_250;
String _wnGoodDaysAction(AppLocalizations l) => l.whatsNewGoodDaysAction_250;
String _wnBirthTitle(AppLocalizations l) => l.whatsNewBirthTitle_250;
String _wnBirthBody(AppLocalizations l) => l.whatsNewBirthBody_250;
String _wnBirthAction(AppLocalizations l) => l.whatsNewBirthAction_250;
String _wnBackupTitle(AppLocalizations l) => l.whatsNewBackupTitle_250;
String _wnBackupBody(AppLocalizations l) => l.whatsNewBackupBody_250;
String _wnBackupAction(AppLocalizations l) => l.whatsNewBackupAction_250;
String _wnDailyTitle(AppLocalizations l) => l.whatsNewDailyTitle_260;
String _wnDailyBody(AppLocalizations l) => l.whatsNewDailyBody_260;
String _wnDailyAction(AppLocalizations l) => l.whatsNewDailyAction_260;
String _wnMyanmarRepeatTitle(AppLocalizations l) =>
    l.whatsNewMyanmarRepeatTitle_260;
String _wnMyanmarRepeatBody(AppLocalizations l) =>
    l.whatsNewMyanmarRepeatBody_260;
String _wnMyanmarRepeatAction(AppLocalizations l) =>
    l.whatsNewMyanmarRepeatAction_260;
String _wnShareDayTitle(AppLocalizations l) => l.whatsNewShareDayTitle_260;
String _wnShareDayBody(AppLocalizations l) => l.whatsNewShareDayBody_260;
String _wnShareDayAction(AppLocalizations l) => l.whatsNewShareDayAction_260;
String _wnTypedDatesTitle(AppLocalizations l) => l.whatsNewTypedDatesTitle_260;
String _wnTypedDatesBody(AppLocalizations l) => l.whatsNewTypedDatesBody_260;
String _wnWidgetsTitle(AppLocalizations l) => l.whatsNewWidgetsTitle_260;
String _wnWidgetsBody(AppLocalizations l) => l.whatsNewWidgetsBody_260;
String _wnWidgetsAction(AppLocalizations l) => l.whatsNewWidgetsAction_260;
String _wnIcsImportTitle(AppLocalizations l) => l.whatsNewIcsImportTitle_260;
String _wnIcsImportBody(AppLocalizations l) => l.whatsNewIcsImportBody_260;
String _wnIcsImportAction(AppLocalizations l) => l.whatsNewIcsImportAction_260;
String _wnEasyReadingTitle(AppLocalizations l) =>
    l.whatsNewEasyReadingTitle_260;
String _wnEasyReadingBody(AppLocalizations l) => l.whatsNewEasyReadingBody_260;
String _wnEasyReadingAction(AppLocalizations l) =>
    l.whatsNewEasyReadingAction_260;
String _wnLongWeekendsTitle(AppLocalizations l) =>
    l.whatsNewLongWeekendsTitle_270;
String _wnLongWeekendsBody(AppLocalizations l) =>
    l.whatsNewLongWeekendsBody_270;
String _wnLongWeekendsAction(AppLocalizations l) =>
    l.whatsNewLongWeekendsAction_270;
String _wnMeritTitle(AppLocalizations l) => l.whatsNewMeritTitle_270;
String _wnMeritBody(AppLocalizations l) => l.whatsNewMeritBody_270;
String _wnMeritAction(AppLocalizations l) => l.whatsNewMeritAction_270;
String _wnShareEventsTitle(AppLocalizations l) =>
    l.whatsNewShareEventsTitle_270;
String _wnShareEventsBody(AppLocalizations l) => l.whatsNewShareEventsBody_270;
String _wnShareEventsAction(AppLocalizations l) =>
    l.whatsNewShareEventsAction_270;
String _wnWidgetTicksTitle(AppLocalizations l) =>
    l.whatsNewWidgetTicksTitle_270;
String _wnWidgetTicksBody(AppLocalizations l) => l.whatsNewWidgetTicksBody_270;
String _wnWidgetTicksAction(AppLocalizations l) =>
    l.whatsNewWidgetTicksAction_270;
String _wnWatchTitle(AppLocalizations l) => l.whatsNewWatchTitle_270;
String _wnWatchBody(AppLocalizations l) => l.whatsNewWatchBody_270;
