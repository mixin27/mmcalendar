import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_my.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('my'),
  ];

  /// About label
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Localized text for alternativeCalculationMethod.
  ///
  /// In en, this message translates to:
  /// **'Alternative calculation method'**
  String get alternativeCalculationMethod;

  /// Localized text for alwaysUseDarkTheme.
  ///
  /// In en, this message translates to:
  /// **'Always use dark theme'**
  String get alwaysUseDarkTheme;

  /// Localized text for alwaysUseLightTheme.
  ///
  /// In en, this message translates to:
  /// **'Always use light theme'**
  String get alwaysUseLightTheme;

  /// Localized text for analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// Localized text for analyticsDisabledChangeInSettings.
  ///
  /// In en, this message translates to:
  /// **'Analytics disabled. You can change this in Settings.'**
  String get analyticsDisabledChangeInSettings;

  /// Localized text for analyticsDisabledInSettings.
  ///
  /// In en, this message translates to:
  /// **'Analytics disabled. You can enable it in Settings.'**
  String get analyticsDisabledInSettings;

  /// Localized text for analyticsEnabledChangeInSettings.
  ///
  /// In en, this message translates to:
  /// **'Thank you! Analytics enabled. You can change this in Settings.'**
  String get analyticsEnabledChangeInSettings;

  /// Anniversary Days label
  ///
  /// In en, this message translates to:
  /// **'Anniversary Days'**
  String get anniversary_days;

  /// Localized text for appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguage;

  /// Localized text for appUpdates.
  ///
  /// In en, this message translates to:
  /// **'App Updates'**
  String get appUpdates;

  /// Localized text for appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// Appearance label
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// Arithmetic label
  ///
  /// In en, this message translates to:
  /// **'Arithmetic'**
  String get arithmetic;

  /// Astrological Information label
  ///
  /// In en, this message translates to:
  /// **'Astrological Information'**
  String get astrological_information;

  /// Localized text for britishCalendarSystem.
  ///
  /// In en, this message translates to:
  /// **'British calendar system'**
  String get britishCalendarSystem;

  /// Buddhist Era label
  ///
  /// In en, this message translates to:
  /// **'Buddhist Era (BE)'**
  String get buddhist_era;

  /// Calculate label
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get calculate;

  /// Localized text for calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// Localized text for calendarLanguage.
  ///
  /// In en, this message translates to:
  /// **'Calendar Language'**
  String get calendarLanguage;

  /// Localized text for calendarType.
  ///
  /// In en, this message translates to:
  /// **'Calendar Type'**
  String get calendarType;

  /// Localized text for calendarTypeBritish.
  ///
  /// In en, this message translates to:
  /// **'British'**
  String get calendarTypeBritish;

  /// Localized text for calendarTypeGregorian.
  ///
  /// In en, this message translates to:
  /// **'Gregorian'**
  String get calendarTypeGregorian;

  /// Localized text for calendarTypeJulian.
  ///
  /// In en, this message translates to:
  /// **'Julian'**
  String get calendarTypeJulian;

  /// Calendar Configuration label
  ///
  /// In en, this message translates to:
  /// **'Calendar Configuration'**
  String get calendar_configuration;

  /// Localized text for cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Localized text for checkAgain.
  ///
  /// In en, this message translates to:
  /// **'Check Again'**
  String get checkAgain;

  /// Localized text for checkFailed.
  ///
  /// In en, this message translates to:
  /// **'Check failed'**
  String get checkFailed;

  /// Localized text for checkForNewVersionsAndUpdateSettings.
  ///
  /// In en, this message translates to:
  /// **'Check for new versions and update settings'**
  String get checkForNewVersionsAndUpdateSettings;

  /// Localized text for checkForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for Updates'**
  String get checkForUpdates;

  /// Choose Your View label
  ///
  /// In en, this message translates to:
  /// **'Choose Your View'**
  String get choose_your_view;

  /// Localized text for clearPromoDataDebug.
  ///
  /// In en, this message translates to:
  /// **'Clear Promo Data (Debug)'**
  String get clearPromoDataDebug;

  /// Localized text for close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Localized text for comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// Localized text for consentDescription.
  ///
  /// In en, this message translates to:
  /// **'Myanmar Calendar would like to collect analytics and crash reports to help improve your experience.\n\nThis data is never shared with third parties.'**
  String get consentDescription;

  /// Localized text for consentDialogDescription.
  ///
  /// In en, this message translates to:
  /// **'Myanmar Calendar would like to collect analytics and crash reports to help improve your experience. This data is never shared with third parties.\n\nYou can change these settings anytime in Settings > Privacy & Data.'**
  String get consentDialogDescription;

  /// Localized text for consentSettingsHint.
  ///
  /// In en, this message translates to:
  /// **'You can change these settings anytime in Settings > Privacy & Data'**
  String get consentSettingsHint;

  /// Convert label
  ///
  /// In en, this message translates to:
  /// **'Convert'**
  String get convert;

  /// Converter label
  ///
  /// In en, this message translates to:
  /// **'Converter'**
  String get converter;

  /// Localized text for crashReports.
  ///
  /// In en, this message translates to:
  /// **'Crash Reports'**
  String get crashReports;

  /// Localized text for currentVersion.
  ///
  /// In en, this message translates to:
  /// **'Current Version'**
  String get currentVersion;

  /// Localized text for currentVersionWithBuild.
  ///
  /// In en, this message translates to:
  /// **'Current: {version} ({build})'**
  String currentVersionWithBuild(Object version, Object build);

  /// Localized text for dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// Day label
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get day;

  /// Day View label
  ///
  /// In en, this message translates to:
  /// **'Day View'**
  String get day_view;

  /// Localized text for defaultCalculationMethod.
  ///
  /// In en, this message translates to:
  /// **'Default calculation method'**
  String get defaultCalculationMethod;

  /// Name of developer
  ///
  /// In en, this message translates to:
  /// **'Kyaw Zayar Tun'**
  String get developer;

  /// Localized text for disableAll.
  ///
  /// In en, this message translates to:
  /// **'Disable All'**
  String get disableAll;

  /// Localized text for displayAnniversaryDaysIndicators.
  ///
  /// In en, this message translates to:
  /// **'Display anniversary days indicators'**
  String get displayAnniversaryDaysIndicators;

  /// Localized text for displayAppInEnglish.
  ///
  /// In en, this message translates to:
  /// **'Display app in English'**
  String get displayAppInEnglish;

  /// Localized text for displayAppInMyanmar.
  ///
  /// In en, this message translates to:
  /// **'Display app in Myanmar'**
  String get displayAppInMyanmar;

  /// Localized text for displayAstrologicalIndicators.
  ///
  /// In en, this message translates to:
  /// **'Display astrological indicators'**
  String get displayAstrologicalIndicators;

  /// Localized text for displayCalendarIn.
  ///
  /// In en, this message translates to:
  /// **'Display calendar in {language}'**
  String displayCalendarIn(Object language);

  /// Localized text for displayHolidayIndicators.
  ///
  /// In en, this message translates to:
  /// **'Display holiday indicators'**
  String get displayHolidayIndicators;

  /// Localized text for displayMyanmarCalendarDates.
  ///
  /// In en, this message translates to:
  /// **'Display Myanmar calendar dates'**
  String get displayMyanmarCalendarDates;

  /// Localized text for displaySabbathIndicators.
  ///
  /// In en, this message translates to:
  /// **'Display sabbath indicators'**
  String get displaySabbathIndicators;

  /// Localized text for displayWesternCalendarDates.
  ///
  /// In en, this message translates to:
  /// **'Display Western calendar dates'**
  String get displayWesternCalendarDates;

  /// Display Preferences label
  ///
  /// In en, this message translates to:
  /// **'Display Preferences'**
  String get display_preferences;

  /// Localized text for enableAll.
  ///
  /// In en, this message translates to:
  /// **'Enable All'**
  String get enableAll;

  /// Localized text for english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Localized text for errorLoadingSettings.
  ///
  /// In en, this message translates to:
  /// **'Error Loading Settings'**
  String get errorLoadingSettings;

  /// Localized text for errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorTitle;

  /// Localized text for errorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorWithMessage(Object error);

  /// Events label
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// Localized text for failedToFetchHolidayConfig.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch holiday config from server.'**
  String get failedToFetchHolidayConfig;

  /// Localized text for failedToInitializeApp.
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize the app:\n\n{error}'**
  String failedToInitializeApp(Object error);

  /// Localized text for fetchRemoteConfigNowAndCheckAgain.
  ///
  /// In en, this message translates to:
  /// **'Fetch remote config now and check again'**
  String get fetchRemoteConfigNowAndCheckAgain;

  /// Localized text for forceRefreshHolidayConfigDescription.
  ///
  /// In en, this message translates to:
  /// **'Force refresh and apply holiday overrides from Remote Config'**
  String get forceRefreshHolidayConfigDescription;

  /// Localized text for forceRefreshUpdateConfig.
  ///
  /// In en, this message translates to:
  /// **'Force Refresh Update Config'**
  String get forceRefreshUpdateConfig;

  /// Localized text for general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// Localized text for goToHome.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get goToHome;

  /// Go To Today label
  ///
  /// In en, this message translates to:
  /// **'Go To Today'**
  String get go_to_today;

  /// Localized text for gregorianCalendarSystem.
  ///
  /// In en, this message translates to:
  /// **'Gregorian calendar system'**
  String get gregorianCalendarSystem;

  /// Localized text for helpImproveBySharingAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Help improve the app by sharing usage analytics'**
  String get helpImproveBySharingAnalytics;

  /// Localized text for helpUsImprove.
  ///
  /// In en, this message translates to:
  /// **'Help Us Improve'**
  String get helpUsImprove;

  /// Localized text for holidayConfigRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Holiday config refreshed ({status}). Custom: {customCount}, Disabled: {disabledCount}'**
  String holidayConfigRefreshed(
    Object status,
    Object customCount,
    Object disabledCount,
  );

  /// Localized text for holidayConfigRemote.
  ///
  /// In en, this message translates to:
  /// **'Holiday Config (Remote)'**
  String get holidayConfigRemote;

  /// Holidays label
  ///
  /// In en, this message translates to:
  /// **'Holidays'**
  String get holidays;

  /// Home label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Localized text for homeWidgets.
  ///
  /// In en, this message translates to:
  /// **'Home Widgets'**
  String get homeWidgets;

  /// Home Screen Widget label
  ///
  /// In en, this message translates to:
  /// **'Home Screen Widget'**
  String get home_screen_widget;

  /// Localized text for hours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hours;

  /// Localized text for hoursValue.
  ///
  /// In en, this message translates to:
  /// **'{value} hours'**
  String hoursValue(Object value);

  /// Localized text for initializationErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Initialization Error'**
  String get initializationErrorTitle;

  /// Localized text for julianCalendarSystem.
  ///
  /// In en, this message translates to:
  /// **'Julian calendar system'**
  String get julianCalendarSystem;

  /// Language label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Localized text for lastCheckedAt.
  ///
  /// In en, this message translates to:
  /// **'Last checked: {time}'**
  String lastCheckedAt(Object time);

  /// Localized text for later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// Localized text for latestVersionWithBuild.
  ///
  /// In en, this message translates to:
  /// **'Latest: {version} ({build})'**
  String latestVersionWithBuild(Object version, Object build);

  /// Localized text for light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// Localized text for loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Localized text for loadingSettings.
  ///
  /// In en, this message translates to:
  /// **'Loading settings...'**
  String get loadingSettings;

  /// Mahabote label
  ///
  /// In en, this message translates to:
  /// **'Mahabote'**
  String get mahabote;

  /// Localized text for matchSystemTheme.
  ///
  /// In en, this message translates to:
  /// **'Match system theme'**
  String get matchSystemTheme;

  /// Month label
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// Moon Phase label
  ///
  /// In en, this message translates to:
  /// **'Moon Phase'**
  String get moon_phase;

  /// Localized text for myanmar.
  ///
  /// In en, this message translates to:
  /// **'Myanmar'**
  String get myanmar;

  /// Localized text for myanmarCalendar.
  ///
  /// In en, this message translates to:
  /// **'Myanmar Calendar'**
  String get myanmarCalendar;

  /// Myanmar Era label
  ///
  /// In en, this message translates to:
  /// **'Myanmar Era (ME)'**
  String get myanmar_era;

  /// Nagahle label
  ///
  /// In en, this message translates to:
  /// **'Nagahle'**
  String get nagahle;

  /// Nakhat label
  ///
  /// In en, this message translates to:
  /// **'Nakhat'**
  String get nakhat;

  /// Next Month label
  ///
  /// In en, this message translates to:
  /// **'Next Month'**
  String get next_month;

  /// Localized text for noChanges.
  ///
  /// In en, this message translates to:
  /// **'no changes'**
  String get noChanges;

  /// Localized text for openSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get openSourceLicenses;

  /// Localized text for openStore.
  ///
  /// In en, this message translates to:
  /// **'Open Store'**
  String get openStore;

  /// Localized text for others.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get others;

  /// Localized text for pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get pageNotFound;

  /// Localized text for preferShanYear.
  ///
  /// In en, this message translates to:
  /// **'Prefer Shan Year'**
  String get preferShanYear;

  /// Localized text for preferShanYearDescription.
  ///
  /// In en, this message translates to:
  /// **'Display Shan calendar year instead of Myanmar year in Shan language'**
  String get preferShanYearDescription;

  /// Previous Month label
  ///
  /// In en, this message translates to:
  /// **'Previous Month'**
  String get previous_month;

  /// Localized text for privacyAndData.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Data'**
  String get privacyAndData;

  /// Localized text for privacyDataUsageDescription.
  ///
  /// In en, this message translates to:
  /// **'This data is used only for app improvement and is never shared with third parties.'**
  String get privacyDataUsageDescription;

  /// Localized text for privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// Localized text for privacyPolicyContentHint.
  ///
  /// In en, this message translates to:
  /// **'App privacy & policy contents will be here.'**
  String get privacyPolicyContentHint;

  /// Localized text for promoDataClearedRestartApp.
  ///
  /// In en, this message translates to:
  /// **'Promo data cleared! Restart app to see onboarding.'**
  String get promoDataClearedRestartApp;

  /// Localized text for releaseNotes.
  ///
  /// In en, this message translates to:
  /// **'Release Notes'**
  String get releaseNotes;

  /// Localized text for reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// Localized text for resetAllSettings.
  ///
  /// In en, this message translates to:
  /// **'Reset All Settings'**
  String get resetAllSettings;

  /// Localized text for resetOnboardingAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Reset onboarding & announcements'**
  String get resetOnboardingAnnouncements;

  /// Localized text for resetSettingsConfirmation.
  ///
  /// In en, this message translates to:
  /// **'This will reset all settings to their default values. This action cannot be undone.'**
  String get resetSettingsConfirmation;

  /// Localized text for resetSettingsQuestion.
  ///
  /// In en, this message translates to:
  /// **'Reset Settings?'**
  String get resetSettingsQuestion;

  /// Localized text for retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Localized text for sasanaYearType.
  ///
  /// In en, this message translates to:
  /// **'Sasana Year Type'**
  String get sasanaYearType;

  /// Sasana Year label
  ///
  /// In en, this message translates to:
  /// **'Sasana Year'**
  String get sasana_year;

  /// Localized text for save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Localized text for sendCrashReportsToHelpFixIssues.
  ///
  /// In en, this message translates to:
  /// **'Send crash reports to help fix issues'**
  String get sendCrashReportsToHelpFixIssues;

  /// Settings label
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Localized text for settingsResetSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Settings reset successfully'**
  String get settingsResetSuccessfully;

  /// Localized text for showAnniversaryDays.
  ///
  /// In en, this message translates to:
  /// **'Show Anniversary Days'**
  String get showAnniversaryDays;

  /// Localized text for showAstrology.
  ///
  /// In en, this message translates to:
  /// **'Show Astrology'**
  String get showAstrology;

  /// Localized text for showHolidays.
  ///
  /// In en, this message translates to:
  /// **'Show Holidays'**
  String get showHolidays;

  /// Localized text for showMyanmarDates.
  ///
  /// In en, this message translates to:
  /// **'Show Myanmar Dates'**
  String get showMyanmarDates;

  /// Localized text for showSabbath.
  ///
  /// In en, this message translates to:
  /// **'Show Sabbath'**
  String get showSabbath;

  /// Localized text for showWesternDates.
  ///
  /// In en, this message translates to:
  /// **'Show Western Dates'**
  String get showWesternDates;

  /// Special Days label
  ///
  /// In en, this message translates to:
  /// **'Special Days'**
  String get special_days;

  /// Localized text for system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// Localized text for telegramUserLabel.
  ///
  /// In en, this message translates to:
  /// **'TG: {userName}'**
  String telegramUserLabel(Object userName);

  /// Localized text for themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeMode;

  /// Theme Preset label
  ///
  /// In en, this message translates to:
  /// **'Theme Preset'**
  String get theme_preset;

  /// Localized text for timezoneOffset.
  ///
  /// In en, this message translates to:
  /// **'Timezone Offset'**
  String get timezoneOffset;

  /// Localized text for timezoneOffsetExample.
  ///
  /// In en, this message translates to:
  /// **'e.g., 6.5 for Myanmar Time (UTC+6:30)'**
  String get timezoneOffsetExample;

  /// Today label
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Localized text for typeValue.
  ///
  /// In en, this message translates to:
  /// **'Type {value}'**
  String typeValue(Object value);

  /// Localized text for unableToOpenUpdatePage.
  ///
  /// In en, this message translates to:
  /// **'Unable to open the update page.'**
  String get unableToOpenUpdatePage;

  /// Localized text for unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// Localized text for unsupportedPlatform.
  ///
  /// In en, this message translates to:
  /// **'Unsupported platform'**
  String get unsupportedPlatform;

  /// Localized text for upToDate.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get upToDate;

  /// Localized text for update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// Localized text for updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateAvailable;

  /// Localized text for updateCheckDisabled.
  ///
  /// In en, this message translates to:
  /// **'Update check disabled'**
  String get updateCheckDisabled;

  /// Localized text for updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get updateNow;

  /// Localized text for updateRequired.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get updateRequired;

  /// Localized text for updated.
  ///
  /// In en, this message translates to:
  /// **'updated'**
  String get updated;

  /// Localized text for useCurrentRemoteConfigValues.
  ///
  /// In en, this message translates to:
  /// **'Use current remote config values'**
  String get useCurrentRemoteConfigValues;

  /// Localized text for versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(Object version);

  /// Localized text for viewAllLicenses.
  ///
  /// In en, this message translates to:
  /// **'View all licenses'**
  String get viewAllLicenses;

  /// Localized text for viewPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'View privacy & policy'**
  String get viewPrivacyPolicy;

  /// Views label
  ///
  /// In en, this message translates to:
  /// **'Views'**
  String get views;

  /// Week View label
  ///
  /// In en, this message translates to:
  /// **'Week View'**
  String get week_view;

  /// Weekday label
  ///
  /// In en, this message translates to:
  /// **'Weekday'**
  String get weekday;

  /// Localized text for widgetSettings.
  ///
  /// In en, this message translates to:
  /// **'Widget Settings'**
  String get widgetSettings;

  /// Year label
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// Year name label
  ///
  /// In en, this message translates to:
  /// **'Year Name'**
  String get year_name;

  /// Year View label
  ///
  /// In en, this message translates to:
  /// **'Year View'**
  String get year_view;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'my'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'my':
      return AppLocalizationsMy();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
