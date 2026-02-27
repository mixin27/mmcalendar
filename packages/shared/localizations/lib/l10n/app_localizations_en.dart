// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get about => 'About';

  @override
  String get alternativeCalculationMethod => 'Alternative calculation method';

  @override
  String get alwaysUseDarkTheme => 'Always use dark theme';

  @override
  String get alwaysUseLightTheme => 'Always use light theme';

  @override
  String get analytics => 'Analytics';

  @override
  String get analyticsDisabledChangeInSettings =>
      'Analytics disabled. You can change this in Settings.';

  @override
  String get analyticsDisabledInSettings =>
      'Analytics disabled. You can enable it in Settings.';

  @override
  String get analyticsEnabledChangeInSettings =>
      'Thank you! Analytics enabled. You can change this in Settings.';

  @override
  String get anniversary_days => 'Anniversary Days';

  @override
  String get appLanguage => 'App Language';

  @override
  String get appUpdates => 'App Updates';

  @override
  String get appVersion => 'App Version';

  @override
  String get appearance => 'Appearance';

  @override
  String get arithmetic => 'Arithmetic';

  @override
  String get astrological_information => 'Astrological Information';

  @override
  String get britishCalendarSystem => 'British calendar system';

  @override
  String get buddhist_era => 'Buddhist Era (BE)';

  @override
  String get calculate => 'Calculate';

  @override
  String get calendar => 'Calendar';

  @override
  String get calendarLanguage => 'Calendar Language';

  @override
  String get calendarType => 'Calendar Type';

  @override
  String get calendarTypeBritish => 'British';

  @override
  String get calendarTypeGregorian => 'Gregorian';

  @override
  String get calendarTypeJulian => 'Julian';

  @override
  String get calendar_configuration => 'Calendar Configuration';

  @override
  String get cancel => 'Cancel';

  @override
  String get checkAgain => 'Check Again';

  @override
  String get checkFailed => 'Check failed';

  @override
  String get checkForNewVersionsAndUpdateSettings =>
      'Check for new versions and update settings';

  @override
  String get checkForUpdates => 'Check for Updates';

  @override
  String get choose_your_view => 'Choose Your View';

  @override
  String get clearPromoDataDebug => 'Clear Promo Data (Debug)';

  @override
  String get close => 'Close';

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String get consentDescription =>
      'Myanmar Calendar would like to collect analytics and crash reports to help improve your experience.\n\nThis data is never shared with third parties.';

  @override
  String get consentDialogDescription =>
      'Myanmar Calendar would like to collect analytics and crash reports to help improve your experience. This data is never shared with third parties.\n\nYou can change these settings anytime in Settings > Privacy & Data.';

  @override
  String get consentSettingsHint =>
      'You can change these settings anytime in Settings > Privacy & Data';

  @override
  String get convert => 'Convert';

  @override
  String get converter => 'Converter';

  @override
  String get crashReports => 'Crash Reports';

  @override
  String get currentVersion => 'Current Version';

  @override
  String currentVersionWithBuild(Object version, Object build) {
    return 'Current: $version ($build)';
  }

  @override
  String get dark => 'Dark';

  @override
  String get day => 'Day';

  @override
  String get day_view => 'Day View';

  @override
  String get defaultCalculationMethod => 'Default calculation method';

  @override
  String get developer => 'Kyaw Zayar Tun';

  @override
  String get disableAll => 'Disable All';

  @override
  String get displayAnniversaryDaysIndicators =>
      'Display anniversary days indicators';

  @override
  String get displayAppInEnglish => 'Display app in English';

  @override
  String get displayAppInMyanmar => 'Display app in Myanmar';

  @override
  String get displayAstrologicalIndicators => 'Display astrological indicators';

  @override
  String displayCalendarIn(Object language) {
    return 'Display calendar in $language';
  }

  @override
  String get displayHolidayIndicators => 'Display holiday indicators';

  @override
  String get displayMyanmarCalendarDates => 'Display Myanmar calendar dates';

  @override
  String get displaySabbathIndicators => 'Display sabbath indicators';

  @override
  String get displayWesternCalendarDates => 'Display Western calendar dates';

  @override
  String get display_preferences => 'Display Preferences';

  @override
  String get enableAll => 'Enable All';

  @override
  String get english => 'English';

  @override
  String get errorLoadingSettings => 'Error Loading Settings';

  @override
  String get errorTitle => 'Error';

  @override
  String errorWithMessage(Object error) {
    return 'Error: $error';
  }

  @override
  String get events => 'Events';

  @override
  String get failedToFetchHolidayConfig =>
      'Failed to fetch holiday config from server.';

  @override
  String failedToInitializeApp(Object error) {
    return 'Failed to initialize the app:\n\n$error';
  }

  @override
  String get fetchRemoteConfigNowAndCheckAgain =>
      'Fetch remote config now and check again';

  @override
  String get forceRefreshHolidayConfigDescription =>
      'Force refresh and apply holiday overrides from Remote Config';

  @override
  String get forceRefreshUpdateConfig => 'Force Refresh Update Config';

  @override
  String get general => 'General';

  @override
  String get goToHome => 'Go to Home';

  @override
  String get go_to_today => 'Go To Today';

  @override
  String get gregorianCalendarSystem => 'Gregorian calendar system';

  @override
  String get helpImproveBySharingAnalytics =>
      'Help improve the app by sharing usage analytics';

  @override
  String get helpUsImprove => 'Help Us Improve';

  @override
  String holidayConfigRefreshed(
    Object status,
    Object customCount,
    Object disabledCount,
  ) {
    return 'Holiday config refreshed ($status). Custom: $customCount, Disabled: $disabledCount';
  }

  @override
  String get holidayConfigRemote => 'Holiday Config (Remote)';

  @override
  String get holidays => 'Holidays';

  @override
  String get home => 'Home';

  @override
  String get homeWidgets => 'Home Widgets';

  @override
  String get home_screen_widget => 'Home Screen Widget';

  @override
  String get hours => 'Hours';

  @override
  String hoursValue(Object value) {
    return '$value hours';
  }

  @override
  String get initializationErrorTitle => 'Initialization Error';

  @override
  String get julianCalendarSystem => 'Julian calendar system';

  @override
  String get language => 'Language';

  @override
  String lastCheckedAt(Object time) {
    return 'Last checked: $time';
  }

  @override
  String get later => 'Later';

  @override
  String latestVersionWithBuild(Object version, Object build) {
    return 'Latest: $version ($build)';
  }

  @override
  String get light => 'Light';

  @override
  String get loading => 'Loading...';

  @override
  String get loadingSettings => 'Loading settings...';

  @override
  String get mahabote => 'Mahabote';

  @override
  String get matchSystemTheme => 'Match system theme';

  @override
  String get month => 'Month';

  @override
  String get moon_phase => 'Moon Phase';

  @override
  String get myanmar => 'Myanmar';

  @override
  String get myanmarCalendar => 'Myanmar Calendar';

  @override
  String get myanmar_era => 'Myanmar Era (ME)';

  @override
  String get nagahle => 'Nagahle';

  @override
  String get nakhat => 'Nakhat';

  @override
  String get next_month => 'Next Month';

  @override
  String get noChanges => 'no changes';

  @override
  String get openSourceLicenses => 'Open Source Licenses';

  @override
  String get openStore => 'Open Store';

  @override
  String get others => 'Others';

  @override
  String get pageNotFound => 'Page not found';

  @override
  String get preferShanYear => 'Prefer Shan Year';

  @override
  String get preferShanYearDescription =>
      'Display Shan calendar year instead of Myanmar year in Shan language';

  @override
  String get previous_month => 'Previous Month';

  @override
  String get privacyAndData => 'Privacy & Data';

  @override
  String get privacyDataUsageDescription =>
      'This data is used only for app improvement and is never shared with third parties.';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get privacyPolicyContentHint =>
      'App privacy & policy contents will be here.';

  @override
  String get promoDataClearedRestartApp =>
      'Promo data cleared! Restart app to see onboarding.';

  @override
  String get releaseNotes => 'Release Notes';

  @override
  String get reset => 'Reset';

  @override
  String get resetAllSettings => 'Reset All Settings';

  @override
  String get resetOnboardingAnnouncements => 'Reset onboarding & announcements';

  @override
  String get resetSettingsConfirmation =>
      'This will reset all settings to their default values. This action cannot be undone.';

  @override
  String get resetSettingsQuestion => 'Reset Settings?';

  @override
  String get retry => 'Retry';

  @override
  String get sasanaYearType => 'Sasana Year Type';

  @override
  String get sasana_year => 'Sasana Year';

  @override
  String get save => 'Save';

  @override
  String get sendCrashReportsToHelpFixIssues =>
      'Send crash reports to help fix issues';

  @override
  String get settings => 'Settings';

  @override
  String get settingsResetSuccessfully => 'Settings reset successfully';

  @override
  String get showAnniversaryDays => 'Show Anniversary Days';

  @override
  String get showAstrology => 'Show Astrology';

  @override
  String get showHolidays => 'Show Holidays';

  @override
  String get showMyanmarDates => 'Show Myanmar Dates';

  @override
  String get showSabbath => 'Show Sabbath';

  @override
  String get showWesternDates => 'Show Western Dates';

  @override
  String get special_days => 'Special Days';

  @override
  String get system => 'System';

  @override
  String telegramUserLabel(Object userName) {
    return 'TG: $userName';
  }

  @override
  String get themeMode => 'Theme Mode';

  @override
  String get theme_preset => 'Theme Preset';

  @override
  String get timezoneOffset => 'Timezone Offset';

  @override
  String get timezoneOffsetExample => 'e.g., 6.5 for Myanmar Time (UTC+6:30)';

  @override
  String get today => 'Today';

  @override
  String typeValue(Object value) {
    return 'Type $value';
  }

  @override
  String get unableToOpenUpdatePage => 'Unable to open the update page.';

  @override
  String get unknown => 'Unknown';

  @override
  String get unsupportedPlatform => 'Unsupported platform';

  @override
  String get upToDate => 'Up to date';

  @override
  String get update => 'Update';

  @override
  String get updateAvailable => 'Update available';

  @override
  String get updateCheckDisabled => 'Update check disabled';

  @override
  String get updateNow => 'Update Now';

  @override
  String get updateRequired => 'Update required';

  @override
  String get updated => 'updated';

  @override
  String get useCurrentRemoteConfigValues => 'Use current remote config values';

  @override
  String versionLabel(Object version) {
    return 'Version $version';
  }

  @override
  String get viewAllLicenses => 'View all licenses';

  @override
  String get viewPrivacyPolicy => 'View privacy & policy';

  @override
  String get views => 'Views';

  @override
  String get week_view => 'Week View';

  @override
  String get weekday => 'Weekday';

  @override
  String get widgetSettings => 'Widget Settings';

  @override
  String get year => 'Year';

  @override
  String get year_name => 'Year Name';

  @override
  String get year_view => 'Year View';
}
