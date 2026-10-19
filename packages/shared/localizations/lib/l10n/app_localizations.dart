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

  /// Localized text for add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Localized text for addEvent.
  ///
  /// In en, this message translates to:
  /// **'Add event'**
  String get addEvent;

  /// Localized text for allDay.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get allDay;

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

  /// Localized text for apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

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

  /// Localized text for astrology.
  ///
  /// In en, this message translates to:
  /// **'Astrology'**
  String get astrology;

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

  /// Localized text for calendarChooseMonth.
  ///
  /// In en, this message translates to:
  /// **'Choose month'**
  String get calendarChooseMonth;

  /// Localized text for calendarDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String calendarDaysAgo(int days);

  /// Localized text for calendarDaysFromToday.
  ///
  /// In en, this message translates to:
  /// **'{days} days from today'**
  String calendarDaysFromToday(int days);

  /// Compact day count in the Upcoming list
  ///
  /// In en, this message translates to:
  /// **'{days} d'**
  String calendarDaysShort(int days);

  /// Localized text for calendarEventCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 event} other{{count} events}}'**
  String calendarEventCount(int count);

  /// Localized text for calendarFullDayDetails.
  ///
  /// In en, this message translates to:
  /// **'Full day details'**
  String get calendarFullDayDetails;

  /// Localized text for calendarFullDayDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Astrology, Buddhist calendar, AI prompt'**
  String get calendarFullDayDetailsSubtitle;

  /// Localized text for calendarInDays.
  ///
  /// In en, this message translates to:
  /// **'in {days} days'**
  String calendarInDays(int days);

  /// Localized text for calendarJumpToMonth.
  ///
  /// In en, this message translates to:
  /// **'Jump to month'**
  String get calendarJumpToMonth;

  /// Localized text for calendarLabelCopied.
  ///
  /// In en, this message translates to:
  /// **'{label} copied!'**
  String calendarLabelCopied(String label);

  /// Localized text for calendarLanguage.
  ///
  /// In en, this message translates to:
  /// **'Calendar Language'**
  String get calendarLanguage;

  /// Localized text for calendarMakeYourCalendar.
  ///
  /// In en, this message translates to:
  /// **'Make your {year} calendar'**
  String calendarMakeYourCalendar(String year);

  /// Localized text for calendarNextYear.
  ///
  /// In en, this message translates to:
  /// **'Next year'**
  String get calendarNextYear;

  /// Localized text for calendarPreviousYear.
  ///
  /// In en, this message translates to:
  /// **'Previous year'**
  String get calendarPreviousYear;

  /// Localized text for calendarStudio.
  ///
  /// In en, this message translates to:
  /// **'Calendar Studio'**
  String get calendarStudio;

  /// Localized text for calendarToggleDayDetails.
  ///
  /// In en, this message translates to:
  /// **'Show or hide day details'**
  String get calendarToggleDayDetails;

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

  /// Localized text for calendarUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get calendarUpcoming;

  /// Localized text for cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Localized text for categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// Localized text for category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

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

  /// Localized text for clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

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

  /// Localized text for colour.
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get colour;

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

  /// Localized text for converterAddSub.
  ///
  /// In en, this message translates to:
  /// **'Add/Sub'**
  String get converterAddSub;

  /// Localized text for converterConvertedDate.
  ///
  /// In en, this message translates to:
  /// **'Converted date'**
  String get converterConvertedDate;

  /// Localized text for converterDateArithmetic.
  ///
  /// In en, this message translates to:
  /// **'Date arithmetic'**
  String get converterDateArithmetic;

  /// Localized text for converterDateDifference.
  ///
  /// In en, this message translates to:
  /// **'Date difference'**
  String get converterDateDifference;

  /// Localized text for converterDaysUnit.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{day} other{days}}'**
  String converterDaysUnit(int count);

  /// Localized text for converterDifference.
  ///
  /// In en, this message translates to:
  /// **'Difference'**
  String get converterDifference;

  /// Localized text for converterEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get converterEnd;

  /// Localized text for converterEnterMyanmarDate.
  ///
  /// In en, this message translates to:
  /// **'Enter a Myanmar year, month and day.'**
  String get converterEnterMyanmarDate;

  /// Localized text for converterEnterWholeNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number above 0.'**
  String get converterEnterWholeNumber;

  /// Localized text for converterFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get converterFrom;

  /// Localized text for converterInDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{in 1 day} other{in {count} days}}'**
  String converterInDays(int count);

  /// Localized text for converterMonthDayRange.
  ///
  /// In en, this message translates to:
  /// **'Month is 0–14 and day is 1–30.'**
  String get converterMonthDayRange;

  /// Localized text for converterMonthFooter.
  ///
  /// In en, this message translates to:
  /// **'Month: 0 = First Waso, 1–12 = Tagu to Tabaung, 13 = Late Tagu, 14 = Second Waso.'**
  String get converterMonthFooter;

  /// Localized text for converterMoonPhase.
  ///
  /// In en, this message translates to:
  /// **'Moon phase'**
  String get converterMoonPhase;

  /// Localized text for converterMyanmarDate.
  ///
  /// In en, this message translates to:
  /// **'Myanmar date'**
  String get converterMyanmarDate;

  /// Localized text for converterMyanmarToWestern.
  ///
  /// In en, this message translates to:
  /// **'Myanmar → Western'**
  String get converterMyanmarToWestern;

  /// Localized text for converterNextPhase.
  ///
  /// In en, this message translates to:
  /// **'Next {name}'**
  String converterNextPhase(String name);

  /// Localized text for converterResult.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get converterResult;

  /// Localized text for converterStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get converterStart;

  /// Localized text for converterStartFromToday.
  ///
  /// In en, this message translates to:
  /// **'Start from today'**
  String get converterStartFromToday;

  /// Localized text for converterSubtract.
  ///
  /// In en, this message translates to:
  /// **'Subtract'**
  String get converterSubtract;

  /// Localized text for converterSwapDates.
  ///
  /// In en, this message translates to:
  /// **'Swap dates'**
  String get converterSwapDates;

  /// Localized text for converterTodayLower.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get converterTodayLower;

  /// Localized text for converterUnit.
  ///
  /// In en, this message translates to:
  /// **'{unit, select, days{days} weeks{weeks} months{months} years{years} other{{unit}}}'**
  String converterUnit(String unit);

  /// Localized text for converterValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get converterValue;

  /// Localized text for converterWesternToMyanmar.
  ///
  /// In en, this message translates to:
  /// **'Western → Myanmar'**
  String get converterWesternToMyanmar;

  /// Localized text for copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// Localized text for copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// Localized text for crashReports.
  ///
  /// In en, this message translates to:
  /// **'Crash Reports'**
  String get crashReports;

  /// Localized text for create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

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

  /// Localized text for custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// Localized text for dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// Localized text for date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

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

  /// Localized text for dayDetailsAddEvent.
  ///
  /// In en, this message translates to:
  /// **'Add Event'**
  String get dayDetailsAddEvent;

  /// Localized text for dayDetailsAiHoroscopePrompt.
  ///
  /// In en, this message translates to:
  /// **'AI Horoscope Prompt'**
  String get dayDetailsAiHoroscopePrompt;

  /// Localized text for dayDetailsAiHoroscopePromptSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Copy a ready-made prompt for this day'**
  String get dayDetailsAiHoroscopePromptSubtitle;

  /// Localized text for dayDetailsAiPromptHint.
  ///
  /// In en, this message translates to:
  /// **'Paste this into any AI assistant (ChatGPT, Gemini, …) for a reading of the day. Nothing is sent from this app.'**
  String get dayDetailsAiPromptHint;

  /// Localized text for dayDetailsBuddhistCalendar.
  ///
  /// In en, this message translates to:
  /// **'Buddhist Calendar'**
  String get dayDetailsBuddhistCalendar;

  /// Localized text for dayDetailsCopyPrompt.
  ///
  /// In en, this message translates to:
  /// **'Copy Prompt'**
  String get dayDetailsCopyPrompt;

  /// Localized text for dayDetailsErrorLoadingEvents.
  ///
  /// In en, this message translates to:
  /// **'Error loading events'**
  String get dayDetailsErrorLoadingEvents;

  /// Localized text for dayDetailsFailedToUpdateEvent.
  ///
  /// In en, this message translates to:
  /// **'Failed to update event: {error}'**
  String dayDetailsFailedToUpdateEvent(String error);

  /// Localized text for dayDetailsFortnightDayPercentLit.
  ///
  /// In en, this message translates to:
  /// **'Day {day} · {percent}% lit'**
  String dayDetailsFortnightDayPercentLit(String day, String percent);

  /// Localized text for dayDetailsJumpToDate.
  ///
  /// In en, this message translates to:
  /// **'Jump to Date'**
  String get dayDetailsJumpToDate;

  /// Localized text for dayDetailsLoadingEvents.
  ///
  /// In en, this message translates to:
  /// **'Loading events…'**
  String get dayDetailsLoadingEvents;

  /// Localized text for dayDetailsMarkNotDone.
  ///
  /// In en, this message translates to:
  /// **'Mark not done'**
  String get dayDetailsMarkNotDone;

  /// Localized text for dayDetailsNextDay.
  ///
  /// In en, this message translates to:
  /// **'Next Day'**
  String get dayDetailsNextDay;

  /// Localized text for dayDetailsNoEventsAddEvent.
  ///
  /// In en, this message translates to:
  /// **'No events · Add event'**
  String get dayDetailsNoEventsAddEvent;

  /// Moon illumination
  ///
  /// In en, this message translates to:
  /// **'{percent}% lit'**
  String dayDetailsPercentLit(String percent);

  /// Localized text for dayDetailsPreviousDay.
  ///
  /// In en, this message translates to:
  /// **'Previous Day'**
  String get dayDetailsPreviousDay;

  /// Localized text for dayDetailsPromptCopied.
  ///
  /// In en, this message translates to:
  /// **'Prompt copied to clipboard'**
  String get dayDetailsPromptCopied;

  /// Localized text for dayDetailsPyathada.
  ///
  /// In en, this message translates to:
  /// **'Pyathada'**
  String get dayDetailsPyathada;

  /// Localized text for dayDetailsShareDay.
  ///
  /// In en, this message translates to:
  /// **'Share Day'**
  String get dayDetailsShareDay;

  /// Localized text for dayDetailsShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to share'**
  String get dayDetailsShareFailed;

  /// Localized text for dayDetailsShareSubject.
  ///
  /// In en, this message translates to:
  /// **'Please check myanmar calendar'**
  String get dayDetailsShareSubject;

  /// Localized text for dayDetailsSpecial.
  ///
  /// In en, this message translates to:
  /// **'Special'**
  String get dayDetailsSpecial;

  /// Localized text for dayDetailsYatyaza.
  ///
  /// In en, this message translates to:
  /// **'Yatyaza'**
  String get dayDetailsYatyaza;

  /// Myanmar year type (common, little/big watat)
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get dayDetailsYearType;

  /// Localized text for days.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get days;

  /// Localized text for defaultCalculationMethod.
  ///
  /// In en, this message translates to:
  /// **'Default calculation method'**
  String get defaultCalculationMethod;

  /// Localized text for defaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultLabel;

  /// Localized text for delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Localized text for deleteEvent.
  ///
  /// In en, this message translates to:
  /// **'Delete event'**
  String get deleteEvent;

  /// Localized text for deleteEventQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete event?'**
  String get deleteEventQuestion;

  /// Localized text for description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

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

  /// Localized text for edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Localized text for editEvent.
  ///
  /// In en, this message translates to:
  /// **'Edit event'**
  String get editEvent;

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

  /// Localized text for event.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get event;

  /// Events label
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// Localized text for eventsAddReminder.
  ///
  /// In en, this message translates to:
  /// **'Add reminder'**
  String get eventsAddReminder;

  /// Localized text for eventsAddTagHint.
  ///
  /// In en, this message translates to:
  /// **'Add a tag and press return'**
  String get eventsAddTagHint;

  /// Localized text for eventsBuiltInCategoriesFooter.
  ///
  /// In en, this message translates to:
  /// **'Built-in categories can’t be changed.'**
  String get eventsBuiltInCategoriesFooter;

  /// Localized text for eventsCategoryColour.
  ///
  /// In en, this message translates to:
  /// **'Category colour'**
  String get eventsCategoryColour;

  /// Localized text for eventsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get eventsCompleted;

  /// Localized text for eventsCouldNotLoadEvent.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load this event'**
  String get eventsCouldNotLoadEvent;

  /// Localized text for eventsCreateEvent.
  ///
  /// In en, this message translates to:
  /// **'Create Event'**
  String get eventsCreateEvent;

  /// Localized text for eventsCustomCategoriesEmptyFooter.
  ///
  /// In en, this message translates to:
  /// **'Create categories for the events you keep.'**
  String get eventsCustomCategoriesEmptyFooter;

  /// Localized text for eventsCustomCategoriesFooter.
  ///
  /// In en, this message translates to:
  /// **'Tap a category to rename, recolour or delete it.'**
  String get eventsCustomCategoriesFooter;

  /// Screen-reader label for a day in the events day strip.
  ///
  /// In en, this message translates to:
  /// **'{date}, {count} events'**
  String eventsDayEventsSemantics(String date, int count);

  /// Localized text for eventsDeleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get eventsDeleteCategory;

  /// Localized text for eventsDeleteCategoryMessage.
  ///
  /// In en, this message translates to:
  /// **'Its events are kept; they just stop being linked to this category.'**
  String get eventsDeleteCategoryMessage;

  /// Localized text for eventsDeleteCategoryQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”?'**
  String eventsDeleteCategoryQuestion(String name);

  /// Localized text for eventsDeleteEventMessage.
  ///
  /// In en, this message translates to:
  /// **'This event will be removed. This can’t be undone.'**
  String get eventsDeleteEventMessage;

  /// Localized text for eventsDeleteThisOccurrence.
  ///
  /// In en, this message translates to:
  /// **'Delete this occurrence'**
  String get eventsDeleteThisOccurrence;

  /// Localized text for eventsDeleteThisOccurrenceQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete this occurrence?'**
  String get eventsDeleteThisOccurrenceQuestion;

  /// Localized text for eventsEditCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get eventsEditCategory;

  /// Title of the event form when editing.
  ///
  /// In en, this message translates to:
  /// **'Edit Event'**
  String get eventsEditEventTitle;

  /// Localized text for eventsEventCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 event} other{{count} events}}'**
  String eventsEventCount(int count);

  /// Localized text for eventsEventCreated.
  ///
  /// In en, this message translates to:
  /// **'Event created'**
  String get eventsEventCreated;

  /// Localized text for eventsEventNotFound.
  ///
  /// In en, this message translates to:
  /// **'Event not found'**
  String get eventsEventNotFound;

  /// Localized text for eventsEventUpdated.
  ///
  /// In en, this message translates to:
  /// **'Event updated'**
  String get eventsEventUpdated;

  /// Localized text for eventsEventWillBeRemoved.
  ///
  /// In en, this message translates to:
  /// **'“{title}” will be removed. This can’t be undone.'**
  String eventsEventWillBeRemoved(String title);

  /// Localized text for eventsFillRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in required fields'**
  String get eventsFillRequiredFields;

  /// Localized text for eventsJumpToToday.
  ///
  /// In en, this message translates to:
  /// **'Jump to today'**
  String get eventsJumpToToday;

  /// Localized text for eventsMayHaveBeenDeleted.
  ///
  /// In en, this message translates to:
  /// **'It may have been deleted.'**
  String get eventsMayHaveBeenDeleted;

  /// Localized text for eventsNewCategory.
  ///
  /// In en, this message translates to:
  /// **'New Category'**
  String get eventsNewCategory;

  /// Localized text for eventsNoEventsOn.
  ///
  /// In en, this message translates to:
  /// **'No events on {date}'**
  String eventsNoEventsOn(String date);

  /// Localized text for eventsNoResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get eventsNoResultsFound;

  /// Localized text for eventsOccurrence.
  ///
  /// In en, this message translates to:
  /// **'Occurrence'**
  String get eventsOccurrence;

  /// Localized text for eventsOnlyThisOccurrenceRemoved.
  ///
  /// In en, this message translates to:
  /// **'Only this occurrence will be removed.'**
  String get eventsOnlyThisOccurrenceRemoved;

  /// Localized text for eventsPickAColor.
  ///
  /// In en, this message translates to:
  /// **'Pick a color'**
  String get eventsPickAColor;

  /// Localized text for eventsPickADate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get eventsPickADate;

  /// Localized text for eventsPickAnotherDay.
  ///
  /// In en, this message translates to:
  /// **'Pick another day or create one.'**
  String get eventsPickAnotherDay;

  /// Localized text for eventsReminderAtStart.
  ///
  /// In en, this message translates to:
  /// **'at start'**
  String get eventsReminderAtStart;

  /// Localized text for eventsReminderDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} day} other{{count} days}}'**
  String eventsReminderDays(int count);

  /// Localized text for eventsReminderHours.
  ///
  /// In en, this message translates to:
  /// **'{count} h'**
  String eventsReminderHours(int count);

  /// Localized text for eventsReminderMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String eventsReminderMinutes(int count);

  /// Localized text for eventsRemoveReminder.
  ///
  /// In en, this message translates to:
  /// **'Remove reminder'**
  String get eventsRemoveReminder;

  /// Localized text for eventsReopenEvent.
  ///
  /// In en, this message translates to:
  /// **'Reopen event'**
  String get eventsReopenEvent;

  /// Localized text for eventsRepeatsDaily.
  ///
  /// In en, this message translates to:
  /// **'repeats daily'**
  String get eventsRepeatsDaily;

  /// Localized text for eventsRepeatsEveryNDays.
  ///
  /// In en, this message translates to:
  /// **'repeats every {count} days'**
  String eventsRepeatsEveryNDays(int count);

  /// Localized text for eventsRepeatsEveryNMonths.
  ///
  /// In en, this message translates to:
  /// **'repeats every {count} months'**
  String eventsRepeatsEveryNMonths(int count);

  /// Localized text for eventsRepeatsEveryNWeeks.
  ///
  /// In en, this message translates to:
  /// **'repeats every {count} weeks'**
  String eventsRepeatsEveryNWeeks(int count);

  /// Localized text for eventsRepeatsEveryNYears.
  ///
  /// In en, this message translates to:
  /// **'repeats every {count} years'**
  String eventsRepeatsEveryNYears(int count);

  /// Localized text for eventsRepeatsMonthly.
  ///
  /// In en, this message translates to:
  /// **'repeats monthly'**
  String get eventsRepeatsMonthly;

  /// Localized text for eventsRepeatsWeekly.
  ///
  /// In en, this message translates to:
  /// **'repeats weekly'**
  String get eventsRepeatsWeekly;

  /// Localized text for eventsRepeatsYearly.
  ///
  /// In en, this message translates to:
  /// **'repeats yearly'**
  String get eventsRepeatsYearly;

  /// Localized text for eventsResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get eventsResults;

  /// Localized text for eventsSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get eventsSaveChanges;

  /// Localized text for eventsSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get eventsSaving;

  /// Localized text for eventsSearchEvents.
  ///
  /// In en, this message translates to:
  /// **'Search events'**
  String get eventsSearchEvents;

  /// Localized text for eventsSearchPromptHint.
  ///
  /// In en, this message translates to:
  /// **'Type title or description'**
  String get eventsSearchPromptHint;

  /// Localized text for eventsTryDifferentKeyword.
  ///
  /// In en, this message translates to:
  /// **'Try a different keyword'**
  String get eventsTryDifferentKeyword;

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

  /// Localized text for goBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get goBack;

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

  /// Localized text for icon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get icon;

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

  /// Localized text for location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// Mahabote label
  ///
  /// In en, this message translates to:
  /// **'Mahabote'**
  String get mahabote;

  /// Localized text for markAsPending.
  ///
  /// In en, this message translates to:
  /// **'Mark as pending'**
  String get markAsPending;

  /// Localized text for markComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark complete'**
  String get markComplete;

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

  /// Localized text for months.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get months;

  /// Localized text for moon.
  ///
  /// In en, this message translates to:
  /// **'Moon'**
  String get moon;

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

  /// Localized text for name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Localized text for never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get never;

  /// Localized text for newEvent.
  ///
  /// In en, this message translates to:
  /// **'New Event'**
  String get newEvent;

  /// Next Month label
  ///
  /// In en, this message translates to:
  /// **'Next Month'**
  String get next_month;

  /// Localized text for nextYear.
  ///
  /// In en, this message translates to:
  /// **'Next Year'**
  String get nextYear;

  /// Localized text for noChanges.
  ///
  /// In en, this message translates to:
  /// **'no changes'**
  String get noChanges;

  /// Localized text for none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

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

  /// Localized text for previousYear.
  ///
  /// In en, this message translates to:
  /// **'Previous Year'**
  String get previousYear;

  /// Localized text for priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

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

  /// Localized text for refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Localized text for releaseNotes.
  ///
  /// In en, this message translates to:
  /// **'Release Notes'**
  String get releaseNotes;

  /// Localized text for reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// Localized text for repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

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

  /// Localized text for sabbath.
  ///
  /// In en, this message translates to:
  /// **'Sabbath'**
  String get sabbath;

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

  /// Localized text for select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

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

  /// Localized text for share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

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

  /// Localized text for somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Oops! Something went wrong'**
  String get somethingWentWrong;

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

  /// Localized text for tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

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

  /// Localized text for time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

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

  /// Localized text for title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// Today label
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Localized text for tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// Localized text for tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

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

  /// Localized text for unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error occurred'**
  String get unexpectedError;

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

  /// Localized text for viewsDayViewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Everything about one day'**
  String get viewsDayViewSubtitle;

  /// Localized text for viewsNextWeek.
  ///
  /// In en, this message translates to:
  /// **'Next Week'**
  String get viewsNextWeek;

  /// Localized text for viewsPreviousWeek.
  ///
  /// In en, this message translates to:
  /// **'Previous Week'**
  String get viewsPreviousWeek;

  /// Localized text for viewsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get viewsThisWeek;

  /// Localized text for viewsThisYear.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get viewsThisYear;

  /// Localized text for viewsViewFullMonth.
  ///
  /// In en, this message translates to:
  /// **'View Full Month'**
  String get viewsViewFullMonth;

  /// Localized text for viewsWeekViewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Seven days with Myanmar dates and the moon'**
  String get viewsWeekViewSubtitle;

  /// Localized text for viewsYearViewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'All 12 months with holiday counts'**
  String get viewsYearViewSubtitle;

  /// Localized text for week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get week;

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

  /// Localized text for weekNumber.
  ///
  /// In en, this message translates to:
  /// **'Week {number}'**
  String weekNumber(int number);

  /// Localized text for weeks.
  ///
  /// In en, this message translates to:
  /// **'Weeks'**
  String get weeks;

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

  /// Localized text for years.
  ///
  /// In en, this message translates to:
  /// **'Years'**
  String get years;

  /// Localized text for yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// Footer under the app language choices on the Language page.
  ///
  /// In en, this message translates to:
  /// **'Menus, buttons and messages.'**
  String get settingsAppLanguageFooter;

  /// Footer under the calendar language choices on the Language page.
  ///
  /// In en, this message translates to:
  /// **'Dates, month and weekday names, lunar days, holidays and moon phases everywhere in the app, including widgets.'**
  String get settingsCalendarLanguageFooter;

  /// Settings row and page title for the calendar grid layout and theme.
  ///
  /// In en, this message translates to:
  /// **'Calendar grid'**
  String get settingsCalendarGrid;

  /// Segment for choosing the grid layout.
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get settingsGridLayoutTab;

  /// Segment for choosing the grid theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsGridThemeTab;

  /// Note under the grid layout choices.
  ///
  /// In en, this message translates to:
  /// **'Every style fits the screen: rows take the height that is left above the day sheet.'**
  String get settingsGridFitNote;

  /// Footer under the grid theme choices.
  ///
  /// In en, this message translates to:
  /// **'A theme colours the month header, weekday row and grid, and works with every layout. The day sheet keeps the app’s colours.'**
  String get settingsGridThemeFooter;

  /// Switch for the small drawing in the header corner of a grid theme.
  ///
  /// In en, this message translates to:
  /// **'Show motif'**
  String get settingsGridShowMotif;

  /// Name of the Almanac calendar grid layout.
  ///
  /// In en, this message translates to:
  /// **'Almanac'**
  String get gridLayoutAlmanacTitle;

  /// One-line description of the Almanac calendar grid layout.
  ///
  /// In en, this message translates to:
  /// **'Lunar day, moon, holidays and events, with a strip for Sabbath and good or careful days.'**
  String get gridLayoutAlmanacDescription;

  /// Name of the Detailed calendar grid layout.
  ///
  /// In en, this message translates to:
  /// **'Detailed'**
  String get gridLayoutDetailedTitle;

  /// One-line description of the Detailed calendar grid layout.
  ///
  /// In en, this message translates to:
  /// **'Lunar day, holiday name, moon and events in every day.'**
  String get gridLayoutDetailedDescription;

  /// Name of the Clean calendar grid layout.
  ///
  /// In en, this message translates to:
  /// **'Clean'**
  String get gridLayoutCleanTitle;

  /// One-line description of the Clean calendar grid layout.
  ///
  /// In en, this message translates to:
  /// **'Numbers first; the moon only on moon days.'**
  String get gridLayoutCleanDescription;

  /// Name of the Classic calendar grid layout.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get gridLayoutClassicTitle;

  /// One-line description of the Classic calendar grid layout.
  ///
  /// In en, this message translates to:
  /// **'The original tiles and coloured dots.'**
  String get gridLayoutClassicDescription;

  /// Name of the Detailed v2 calendar grid layout.
  ///
  /// In en, this message translates to:
  /// **'Detailed v2'**
  String get gridLayoutDetailedV2Title;

  /// One-line description of the Detailed v2 calendar grid layout.
  ///
  /// In en, this message translates to:
  /// **'Detailed, calmer: no lines, the moon only on moon days.'**
  String get gridLayoutDetailedV2Description;

  /// Name of the Lunar first calendar grid layout.
  ///
  /// In en, this message translates to:
  /// **'Lunar first'**
  String get gridLayoutLunarFirstTitle;

  /// One-line description of the Lunar first calendar grid layout.
  ///
  /// In en, this message translates to:
  /// **'The lunar day large, the date small in the corner.'**
  String get gridLayoutLunarFirstDescription;

  /// Name of the Minimal calendar grid layout.
  ///
  /// In en, this message translates to:
  /// **'Minimal'**
  String get gridLayoutMinimalTitle;

  /// One-line description of the Minimal calendar grid layout.
  ///
  /// In en, this message translates to:
  /// **'The date and one status dot.'**
  String get gridLayoutMinimalDescription;

  /// Name of the Moon strip calendar grid layout.
  ///
  /// In en, this message translates to:
  /// **'Moon strip'**
  String get gridLayoutMoonStripTitle;

  /// One-line description of the Moon strip calendar grid layout.
  ///
  /// In en, this message translates to:
  /// **'Tonight’s moon in every day.'**
  String get gridLayoutMoonStripDescription;

  /// Name of the Agenda calendar grid layout.
  ///
  /// In en, this message translates to:
  /// **'Agenda'**
  String get gridLayoutAgendaTitle;

  /// One-line description of the Agenda calendar grid layout.
  ///
  /// In en, this message translates to:
  /// **'Event titles and holidays inside the days.'**
  String get gridLayoutAgendaDescription;

  /// Name of the Classic print calendar grid layout.
  ///
  /// In en, this message translates to:
  /// **'Classic print'**
  String get gridLayoutClassicPrintTitle;

  /// One-line description of the Classic print calendar grid layout.
  ///
  /// In en, this message translates to:
  /// **'A ruled table like a wall calendar.'**
  String get gridLayoutClassicPrintDescription;

  /// Name of the Tiles calendar grid layout.
  ///
  /// In en, this message translates to:
  /// **'Tiles'**
  String get gridLayoutTilesTitle;

  /// One-line description of the Tiles calendar grid layout.
  ///
  /// In en, this message translates to:
  /// **'Every day a card; holidays and Sabbath tinted.'**
  String get gridLayoutTilesDescription;

  /// Name of the Moonlight calendar grid layout.
  ///
  /// In en, this message translates to:
  /// **'Moonlight'**
  String get gridLayoutMoonlightTitle;

  /// One-line description of the Moonlight calendar grid layout.
  ///
  /// In en, this message translates to:
  /// **'Days glow brighter toward the full moon.'**
  String get gridLayoutMoonlightDescription;

  /// Name of the Split calendar grid layout.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get gridLayoutSplitTitle;

  /// One-line description of the Split calendar grid layout.
  ///
  /// In en, this message translates to:
  /// **'The date and the lunar day, split diagonally.'**
  String get gridLayoutSplitDescription;

  /// Name of the Poster calendar grid layout.
  ///
  /// In en, this message translates to:
  /// **'Poster'**
  String get gridLayoutPosterTitle;

  /// One-line description of the Poster calendar grid layout.
  ///
  /// In en, this message translates to:
  /// **'Big, bold numbers you can read from afar.'**
  String get gridLayoutPosterDescription;

  /// Name of the Moon ring calendar grid layout.
  ///
  /// In en, this message translates to:
  /// **'Moon ring'**
  String get gridLayoutMoonRingTitle;

  /// One-line description of the Moon ring calendar grid layout.
  ///
  /// In en, this message translates to:
  /// **'A ring around each date fills with moonlight.'**
  String get gridLayoutMoonRingDescription;

  /// Name of the Astrology calendar grid layout.
  ///
  /// In en, this message translates to:
  /// **'Astrology'**
  String get gridLayoutAstrologyTitle;

  /// One-line description of the Astrology calendar grid layout.
  ///
  /// In en, this message translates to:
  /// **'Astrological days and holidays as tags.'**
  String get gridLayoutAstrologyDescription;

  /// Name of the App colours calendar grid theme.
  ///
  /// In en, this message translates to:
  /// **'App colours'**
  String get gridThemeAppTitle;

  /// One-line description of the App colours calendar grid theme.
  ///
  /// In en, this message translates to:
  /// **'The app’s own colours and accent.'**
  String get gridThemeAppDescription;

  /// Name of the Pagoda calendar grid theme.
  ///
  /// In en, this message translates to:
  /// **'Pagoda'**
  String get gridThemePagodaTitle;

  /// One-line description of the Pagoda calendar grid theme.
  ///
  /// In en, this message translates to:
  /// **'Temple cream, maroon and pagoda gold.'**
  String get gridThemePagodaDescription;

  /// Name of the Jade calendar grid theme.
  ///
  /// In en, this message translates to:
  /// **'Jade'**
  String get gridThemeJadeTitle;

  /// One-line description of the Jade calendar grid theme.
  ///
  /// In en, this message translates to:
  /// **'Jade green on cool white, with a seal.'**
  String get gridThemeJadeDescription;

  /// Name of the Lacquer calendar grid theme.
  ///
  /// In en, this message translates to:
  /// **'Lacquer'**
  String get gridThemeLacquerTitle;

  /// One-line description of the Lacquer calendar grid theme.
  ///
  /// In en, this message translates to:
  /// **'Black lacquer, cinnabar and gold leaf.'**
  String get gridThemeLacquerDescription;

  /// Name of the Thadingyut calendar grid theme.
  ///
  /// In en, this message translates to:
  /// **'Thadingyut'**
  String get gridThemeThadingyutTitle;

  /// One-line description of the Thadingyut calendar grid theme.
  ///
  /// In en, this message translates to:
  /// **'Lantern paper by day, indigo by night.'**
  String get gridThemeThadingyutDescription;

  /// Name of the Thingyan calendar grid theme.
  ///
  /// In en, this message translates to:
  /// **'Thingyan'**
  String get gridThemeThingyanTitle;

  /// One-line description of the Thingyan calendar grid theme.
  ///
  /// In en, this message translates to:
  /// **'Splash blue and padauk yellow.'**
  String get gridThemeThingyanDescription;

  /// Name of the Botanical calendar grid theme.
  ///
  /// In en, this message translates to:
  /// **'Botanical'**
  String get gridThemeBotanicalTitle;

  /// One-line description of the Botanical calendar grid theme.
  ///
  /// In en, this message translates to:
  /// **'Pressed-leaf greens on herbarium paper.'**
  String get gridThemeBotanicalDescription;

  /// Name of the Monsoon calendar grid theme.
  ///
  /// In en, this message translates to:
  /// **'Monsoon'**
  String get gridThemeMonsoonTitle;

  /// One-line description of the Monsoon calendar grid theme.
  ///
  /// In en, this message translates to:
  /// **'Rain-season slate with a rust accent.'**
  String get gridThemeMonsoonDescription;

  /// Name of the Tidewater calendar grid theme.
  ///
  /// In en, this message translates to:
  /// **'Tidewater'**
  String get gridThemeTidewaterTitle;

  /// One-line description of the Tidewater calendar grid theme.
  ///
  /// In en, this message translates to:
  /// **'Sea glass and deep teal.'**
  String get gridThemeTidewaterDescription;

  /// Name of the Morning Pour calendar grid theme.
  ///
  /// In en, this message translates to:
  /// **'Morning Pour'**
  String get gridThemeMorningPourTitle;

  /// One-line description of the Morning Pour calendar grid theme.
  ///
  /// In en, this message translates to:
  /// **'Coffee and cream for early risers.'**
  String get gridThemeMorningPourDescription;

  /// Name of the Deep Field calendar grid theme.
  ///
  /// In en, this message translates to:
  /// **'Deep Field'**
  String get gridThemeDeepFieldTitle;

  /// One-line description of the Deep Field calendar grid theme.
  ///
  /// In en, this message translates to:
  /// **'Lavender dusk, or deep space at night.'**
  String get gridThemeDeepFieldDescription;

  /// Name of the Moonlight calendar grid theme.
  ///
  /// In en, this message translates to:
  /// **'Moonlight'**
  String get gridThemeMoonlightTitle;

  /// One-line description of the Moonlight calendar grid theme.
  ///
  /// In en, this message translates to:
  /// **'Silver-blue and moon gold.'**
  String get gridThemeMoonlightDescription;

  /// Name of the Night Chart calendar grid theme.
  ///
  /// In en, this message translates to:
  /// **'Night Chart'**
  String get gridThemeNightChartTitle;

  /// One-line description of the Night Chart calendar grid theme.
  ///
  /// In en, this message translates to:
  /// **'Violet ink and antique gold.'**
  String get gridThemeNightChartDescription;

  /// A choice marked as the default, followed by its description.
  ///
  /// In en, this message translates to:
  /// **'Default · {description}'**
  String settingsGridDefault(String description);

  /// Value shown next to the Calendar Studio row on the Settings home page.
  ///
  /// In en, this message translates to:
  /// **'Design and print'**
  String get settingsCalendarStudioValue;

  /// Group label on Display Preferences for what the calendar shows.
  ///
  /// In en, this message translates to:
  /// **'Show in calendar'**
  String get settingsShowInCalendar;

  /// Group label on Display Preferences for which dates the calendar shows.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get settingsDates;

  /// Toggle on Calendar Configuration to follow the device time zone.
  ///
  /// In en, this message translates to:
  /// **'Use Device Timezone'**
  String get settingsUseDeviceTimezone;

  /// Row on Calendar Configuration that refreshes holiday data from the server.
  ///
  /// In en, this message translates to:
  /// **'Refresh holiday data'**
  String get settingsRefreshHolidayData;

  /// Footer under the debug-only group on the About page.
  ///
  /// In en, this message translates to:
  /// **'Debug builds only.'**
  String get settingsDebugBuildsOnly;

  /// Row on Appearance that opens the custom colour editor.
  ///
  /// In en, this message translates to:
  /// **'Custom colours…'**
  String get settingsCustomColours;

  /// Theme preset name marked as the default preset.
  ///
  /// In en, this message translates to:
  /// **'{name} (default)'**
  String settingsThemePresetDefault(String name);

  /// Group label on Appearance for the Automatic / Clear / Material choice.
  ///
  /// In en, this message translates to:
  /// **'App style'**
  String get settingsAppStyle;

  /// App style that picks Clear or Material by platform.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get settingsAppStyleAutomatic;

  /// Name of the Clear app style (iOS-like).
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get settingsAppStyleClear;

  /// Name of the Material app style (Android-like).
  ///
  /// In en, this message translates to:
  /// **'Material'**
  String get settingsAppStyleMaterial;

  /// Footer under the App style choice; style is the style Automatic resolves to here.
  ///
  /// In en, this message translates to:
  /// **'Automatic uses Material on Android and Clear on iPhone, iPad, Mac and web (here: {style}). Colours and content stay the same; bars, lists and controls change.'**
  String settingsAppStyleFooter(String style);

  /// Row on Appearance that opens the app icon chooser.
  ///
  /// In en, this message translates to:
  /// **'App Icon'**
  String get settingsAppIcon;

  /// Title of the app icon chooser sheet.
  ///
  /// In en, this message translates to:
  /// **'Choose App Icon'**
  String get settingsChooseAppIcon;

  /// Subtitle of the app icon chooser sheet.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred launcher icon style.'**
  String get settingsChooseAppIconSubtitle;

  /// Shown when the user opens the icon chooser while an icon change is in progress.
  ///
  /// In en, this message translates to:
  /// **'Please wait, applying app icon...'**
  String get settingsAppIconApplying;

  /// Shown when the platform cannot change the app icon.
  ///
  /// In en, this message translates to:
  /// **'App icon switching is not supported here.'**
  String get settingsAppIconUnsupported;

  /// Shown when changing the app icon failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to switch app icon.'**
  String get settingsAppIconFailed;

  /// Shown after the app icon changed.
  ///
  /// In en, this message translates to:
  /// **'App icon updated.'**
  String get settingsAppIconUpdated;

  /// Preview card note when the selected icon is the one in use.
  ///
  /// In en, this message translates to:
  /// **'Current icon'**
  String get settingsAppIconCurrent;

  /// Preview card note when the selected icon is not yet in use.
  ///
  /// In en, this message translates to:
  /// **'Tap Apply to use this icon'**
  String get settingsAppIconTapApply;

  /// Badge on the preview card for the icon in use.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get settingsAppIconActive;

  /// Caption under the icon in use in the icon grid.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get settingsAppIconCurrentShort;

  /// Caption under the default icon in the icon grid.
  ///
  /// In en, this message translates to:
  /// **'Standard icon'**
  String get settingsAppIconStandard;

  /// Caption under an alternate icon in the icon grid.
  ///
  /// In en, this message translates to:
  /// **'Alternate icon'**
  String get settingsAppIconAlternate;

  /// Name of the Moon app icon.
  ///
  /// In en, this message translates to:
  /// **'Moon'**
  String get appIconMoon;

  /// Name of the Forest app icon.
  ///
  /// In en, this message translates to:
  /// **'Forest'**
  String get appIconForest;

  /// Name of the Minimal Flat app icon.
  ///
  /// In en, this message translates to:
  /// **'Minimal Flat'**
  String get appIconMinimalFlat;

  /// Name of the Premium Dark app icon.
  ///
  /// In en, this message translates to:
  /// **'Premium Dark'**
  String get appIconPremiumDark;

  /// Name of the Traditional Myanmar Motif app icon.
  ///
  /// In en, this message translates to:
  /// **'Traditional Myanmar Motif'**
  String get appIconTraditionalMyanmar;

  /// Name of the Zawgyi calendar language option.
  ///
  /// In en, this message translates to:
  /// **'Zawgyi'**
  String get languageZawgyi;

  /// Name of the Mon calendar language option.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get languageMon;

  /// Name of the Shan calendar language option.
  ///
  /// In en, this message translates to:
  /// **'Shan'**
  String get languageShan;

  /// Name of the Karen calendar language option.
  ///
  /// In en, this message translates to:
  /// **'Karen'**
  String get languageKaren;

  /// Title of the custom colours page.
  ///
  /// In en, this message translates to:
  /// **'Custom colours'**
  String get customColorsTitle;

  /// Group label for choosing the accent colour.
  ///
  /// In en, this message translates to:
  /// **'Accent'**
  String get customColorsAccent;

  /// Footer under the accent colours.
  ///
  /// In en, this message translates to:
  /// **'Every other colour is made from this one, in light and dark.'**
  String get customColorsAccentFooter;

  /// Opens a picker for any accent colour.
  ///
  /// In en, this message translates to:
  /// **'More colours…'**
  String get customColorsMore;

  /// Group label above the light and dark previews.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get customColorsPreview;

  /// Expands the list of every colour slot.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get customColorsAdvanced;

  /// Footer under the advanced colour slots.
  ///
  /// In en, this message translates to:
  /// **'Set any colour by hand. Choosing a new accent clears these.'**
  String get customColorsAdvancedFooter;

  /// Button that removes custom colours and returns to a preset.
  ///
  /// In en, this message translates to:
  /// **'Reset to preset'**
  String get customColorsReset;

  /// Confirmation message before resetting custom colours.
  ///
  /// In en, this message translates to:
  /// **'Your custom colours will be removed and {preset} will be used again.'**
  String customColorsResetMessage(String preset);

  /// Title of the colour picker sheet.
  ///
  /// In en, this message translates to:
  /// **'Choose a colour'**
  String get customColorsPickTitle;

  /// Colour slot name.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get customColorPrimary;

  /// Colour slot name: text on the primary colour.
  ///
  /// In en, this message translates to:
  /// **'On primary'**
  String get customColorOnPrimary;

  /// Colour slot name.
  ///
  /// In en, this message translates to:
  /// **'Secondary'**
  String get customColorSecondary;

  /// Colour slot name: text on the secondary colour.
  ///
  /// In en, this message translates to:
  /// **'On secondary'**
  String get customColorOnSecondary;

  /// Colour slot name.
  ///
  /// In en, this message translates to:
  /// **'Tertiary'**
  String get customColorTertiary;

  /// Colour slot name: text on the tertiary colour.
  ///
  /// In en, this message translates to:
  /// **'On tertiary'**
  String get customColorOnTertiary;

  /// Colour slot name.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get customColorError;

  /// Colour slot name: text on the error colour.
  ///
  /// In en, this message translates to:
  /// **'On error'**
  String get customColorOnError;

  /// Colour slot name.
  ///
  /// In en, this message translates to:
  /// **'Surface'**
  String get customColorSurface;

  /// Colour slot name: text on the surface colour.
  ///
  /// In en, this message translates to:
  /// **'On surface'**
  String get customColorOnSurface;

  /// Confirms a sheet or picker.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Group label for the widgets' default style.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get widgetsStyle;

  /// Footer under the widget styles.
  ///
  /// In en, this message translates to:
  /// **'New widgets start with this style. To change one widget, touch and hold it and choose Edit Widget (iPhone) or Reconfigure (Android).'**
  String get widgetsStyleFooter;

  /// Widget style that uses the app's colours.
  ///
  /// In en, this message translates to:
  /// **'Follow app'**
  String get widgetStyleApp;

  /// Description of the Follow app widget style.
  ///
  /// In en, this message translates to:
  /// **'The app\'s colours, light or dark with the system.'**
  String get widgetStyleAppDescription;

  /// Black-and-white widget style.
  ///
  /// In en, this message translates to:
  /// **'Plain'**
  String get widgetStylePlain;

  /// Description of the Plain widget style.
  ///
  /// In en, this message translates to:
  /// **'Black and white, with red for holidays.'**
  String get widgetStylePlainDescription;

  /// Group label for what widgets show.
  ///
  /// In en, this message translates to:
  /// **'Show on widgets'**
  String get widgetsShow;

  /// Group label for the Countdown widget's default target.
  ///
  /// In en, this message translates to:
  /// **'Countdown counts to'**
  String get widgetsCountdown;

  /// Countdown target.
  ///
  /// In en, this message translates to:
  /// **'Next full moon'**
  String get widgetCountdownFullMoon;

  /// Countdown target.
  ///
  /// In en, this message translates to:
  /// **'Next new moon'**
  String get widgetCountdownNewMoon;

  /// Countdown target.
  ///
  /// In en, this message translates to:
  /// **'Next Sabbath'**
  String get widgetCountdownSabbath;

  /// Countdown target.
  ///
  /// In en, this message translates to:
  /// **'Thingyan'**
  String get widgetCountdownThingyan;

  /// Group label for installed widgets.
  ///
  /// In en, this message translates to:
  /// **'On your home screen'**
  String get widgetsOnScreen;

  /// How many widgets are on the home screen.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{None yet} =1{1 widget} other{{count} widgets}}'**
  String widgetsInstalled(int count);

  /// Row title for the installed widget count.
  ///
  /// In en, this message translates to:
  /// **'Widgets added'**
  String get widgetsInstalledTitle;

  /// Button that rewrites widget data.
  ///
  /// In en, this message translates to:
  /// **'Refresh widgets'**
  String get widgetsRefresh;

  /// Toast after refreshing widgets.
  ///
  /// In en, this message translates to:
  /// **'Widgets refreshed'**
  String get widgetsRefreshed;

  /// Group label for instructions.
  ///
  /// In en, this message translates to:
  /// **'How to add a widget'**
  String get widgetsHowToAdd;

  /// iPhone instructions.
  ///
  /// In en, this message translates to:
  /// **'Touch and hold an empty spot on the Home Screen, tap Edit, then Add Widget, and search for Myanmar Calendar. On the Lock Screen, touch and hold it and tap Customize.'**
  String get widgetsHowToAddIos;

  /// Android instructions.
  ///
  /// In en, this message translates to:
  /// **'Touch and hold an empty spot on the home screen, tap Widgets, and find Myanmar Calendar. Drag a widget to resize it.'**
  String get widgetsHowToAddAndroid;

  /// Footer explaining the widget language.
  ///
  /// In en, this message translates to:
  /// **'Widgets use the calendar language: {language}.'**
  String widgetsLanguageNote(String language);

  /// Settings › Widgets: add to home screen.
  ///
  /// In en, this message translates to:
  /// **'Add to home screen'**
  String get widgetsAddToHome;

  /// Settings › Widgets: add to home screen.
  ///
  /// In en, this message translates to:
  /// **'Your launcher asks where to put it. You can resize it there.'**
  String get widgetsAddToHomeFooter;

  /// A home screen widget's name.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get widgetKindToday;

  /// A home screen widget's name.
  ///
  /// In en, this message translates to:
  /// **'Moon'**
  String get widgetKindMoon;

  /// A home screen widget's name.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get widgetKindMonth;

  /// A home screen widget's name.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get widgetKindWeek;

  /// A home screen widget's name.
  ///
  /// In en, this message translates to:
  /// **'Coming up'**
  String get widgetKindComingUp;

  /// A home screen widget's name.
  ///
  /// In en, this message translates to:
  /// **'Agenda'**
  String get widgetKindAgenda;

  /// A home screen widget's name.
  ///
  /// In en, this message translates to:
  /// **'Countdown'**
  String get widgetKindCountdown;

  /// A home screen widget's name.
  ///
  /// In en, this message translates to:
  /// **'Astrology day'**
  String get widgetKindAstrology;

  /// A home screen widget's name.
  ///
  /// In en, this message translates to:
  /// **'Myanmar year'**
  String get widgetKindYear;

  /// A holiday name.
  ///
  /// In en, this message translates to:
  /// **'New Year\'s Day'**
  String get holidayNameNewYear;

  /// What a holiday marks, two or three sentences.
  ///
  /// In en, this message translates to:
  /// **'The first day of the Gregorian year, a public holiday in Myanmar since 2018.'**
  String get holidayAboutNewYear;

  /// A holiday name.
  ///
  /// In en, this message translates to:
  /// **'Independence Day'**
  String get holidayNameIndependence;

  /// What a holiday marks, two or three sentences.
  ///
  /// In en, this message translates to:
  /// **'Marks Myanmar\'s independence from British rule on 4 January 1948. Flags go up across the country, and many towns hold fairs and sports.'**
  String get holidayAboutIndependence;

  /// A holiday name.
  ///
  /// In en, this message translates to:
  /// **'Union Day'**
  String get holidayNameUnion;

  /// What a holiday marks, two or three sentences.
  ///
  /// In en, this message translates to:
  /// **'Commemorates the Panglong Agreement of 12 February 1947, when leaders of the Bamar, Shan, Kachin and Chin peoples agreed to form a union.'**
  String get holidayAboutUnion;

  /// A holiday name.
  ///
  /// In en, this message translates to:
  /// **'Peasants\' Day'**
  String get holidayNamePeasants;

  /// What a holiday marks, two or three sentences.
  ///
  /// In en, this message translates to:
  /// **'Honours the farmers who grow the country\'s food. It falls on 2 March.'**
  String get holidayAboutPeasants;

  /// A holiday name.
  ///
  /// In en, this message translates to:
  /// **'Resistance Day'**
  String get holidayNameResistance;

  /// What a holiday marks, two or three sentences.
  ///
  /// In en, this message translates to:
  /// **'Recalls the armed uprising against the Japanese occupation that began on 27 March 1945. It is also called Armed Forces Day.'**
  String get holidayAboutResistance;

  /// A holiday name.
  ///
  /// In en, this message translates to:
  /// **'Labour Day'**
  String get holidayNameLabour;

  /// What a holiday marks, two or three sentences.
  ///
  /// In en, this message translates to:
  /// **'International Workers\' Day on 1 May, honouring working people.'**
  String get holidayAboutLabour;

  /// A holiday name.
  ///
  /// In en, this message translates to:
  /// **'Martyrs\' Day'**
  String get holidayNameMartyrs;

  /// What a holiday marks, two or three sentences.
  ///
  /// In en, this message translates to:
  /// **'Remembers General Aung San and the cabinet members assassinated on 19 July 1947. Sirens sound at 10:37 am, the time of the attack.'**
  String get holidayAboutMartyrs;

  /// A holiday name.
  ///
  /// In en, this message translates to:
  /// **'National Day'**
  String get holidayNameNationalDay;

  /// What a holiday marks, two or three sentences.
  ///
  /// In en, this message translates to:
  /// **'Commemorates the 1920 university students\' strike against the colonial education law, the start of the national movement. It falls on the 10th day of the waning moon of Tazaungmon.'**
  String get holidayAboutNationalDay;

  /// A holiday name.
  ///
  /// In en, this message translates to:
  /// **'New Year\'s Eve'**
  String get holidayNameNewYearsEve;

  /// What a holiday marks, two or three sentences.
  ///
  /// In en, this message translates to:
  /// **'The last day of the Gregorian year, a public holiday since 2018.'**
  String get holidayAboutNewYearsEve;

  /// A holiday name.
  ///
  /// In en, this message translates to:
  /// **'Public holiday'**
  String get holidayNamePublicHoliday;

  /// What a holiday marks, two or three sentences.
  ///
  /// In en, this message translates to:
  /// **'An extra day off announced by the government, often to replace a holiday that fell on a weekend.'**
  String get holidayAboutPublicHoliday;

  /// A holiday name.
  ///
  /// In en, this message translates to:
  /// **'Full Moon of Tabaung'**
  String get holidayNameTabaung;

  /// What a holiday marks, two or three sentences.
  ///
  /// In en, this message translates to:
  /// **'The full moon of Tabaung, the last month of the Myanmar year. Pagoda festivals are held across the country, the best known at Shwedagon.'**
  String get holidayAboutTabaung;

  /// A holiday name.
  ///
  /// In en, this message translates to:
  /// **'Buddha Day'**
  String get holidayNameBuddhaDay;

  /// What a holiday marks, two or three sentences.
  ///
  /// In en, this message translates to:
  /// **'The full moon of Kason marks the Buddha\'s birth, enlightenment and passing. People pour water on the Bodhi trees at pagodas.'**
  String get holidayAboutBuddhaDay;

  /// A holiday name.
  ///
  /// In en, this message translates to:
  /// **'Start of Buddhist Lent'**
  String get holidayNameLentStart;

  /// What a holiday marks, two or three sentences.
  ///
  /// In en, this message translates to:
  /// **'The full moon of Waso begins the three-month Buddhist Lent. Monks stay in their monasteries, and many people keep extra precepts.'**
  String get holidayAboutLentStart;

  /// A holiday name.
  ///
  /// In en, this message translates to:
  /// **'Thadingyut'**
  String get holidayNameThadingyut;

  /// What a holiday marks, two or three sentences.
  ///
  /// In en, this message translates to:
  /// **'The full moon of Thadingyut ends the three-month Buddhist Lent. Homes and pagodas are lit with candles and lanterns for three nights, and younger people pay respects to parents, teachers and elders.'**
  String get holidayAboutThadingyut;

  /// A holiday name.
  ///
  /// In en, this message translates to:
  /// **'Tazaungdaing'**
  String get holidayNameTazaungdaing;

  /// What a holiday marks, two or three sentences.
  ///
  /// In en, this message translates to:
  /// **'The full moon of Tazaungmon closes the robe-offering season. It is a festival of lights, with fire balloons in Taunggyi and overnight contests weaving monks\' robes.'**
  String get holidayAboutTazaungdaing;

  /// A holiday name.
  ///
  /// In en, this message translates to:
  /// **'Christmas'**
  String get holidayNameChristmas;

  /// What a holiday marks, two or three sentences.
  ///
  /// In en, this message translates to:
  /// **'Christians celebrate the birth of Jesus on 25 December.'**
  String get holidayAboutChristmas;

  /// A holiday name.
  ///
  /// In en, this message translates to:
  /// **'Diwali'**
  String get holidayNameDiwali;

  /// What a holiday marks, two or three sentences.
  ///
  /// In en, this message translates to:
  /// **'The Hindu festival of lights, celebrated with oil lamps, sweets and prayers.'**
  String get holidayAboutDiwali;

  /// A holiday name.
  ///
  /// In en, this message translates to:
  /// **'Eid al-Adha'**
  String get holidayNameEidAlAdha;

  /// What a holiday marks, two or three sentences.
  ///
  /// In en, this message translates to:
  /// **'The Muslim festival of sacrifice, at the end of the Hajj pilgrimage. Its date follows the Islamic lunar calendar.'**
  String get holidayAboutEidAlAdha;

  /// A holiday name.
  ///
  /// In en, this message translates to:
  /// **'Good Friday'**
  String get holidayNameGoodFriday;

  /// What a holiday marks, two or three sentences.
  ///
  /// In en, this message translates to:
  /// **'Christians remember the crucifixion of Jesus on the Friday before Easter.'**
  String get holidayAboutGoodFriday;

  /// A holiday name.
  ///
  /// In en, this message translates to:
  /// **'Easter'**
  String get holidayNameEaster;

  /// What a holiday marks, two or three sentences.
  ///
  /// In en, this message translates to:
  /// **'Christians celebrate the resurrection of Jesus.'**
  String get holidayAboutEaster;

  /// A holiday name.
  ///
  /// In en, this message translates to:
  /// **'Eid al-Fitr'**
  String get holidayNameEidAlFitr;

  /// What a holiday marks, two or three sentences.
  ///
  /// In en, this message translates to:
  /// **'The Muslim festival that ends the fasting month of Ramadan. Its date follows the Islamic lunar calendar.'**
  String get holidayAboutEidAlFitr;

  /// A holiday name.
  ///
  /// In en, this message translates to:
  /// **'Mahathamaya Day'**
  String get holidayNameMahathamaya;

  /// What a holiday marks, two or three sentences.
  ///
  /// In en, this message translates to:
  /// **'The full moon of Nayon recalls the Buddha teaching the Mahasamaya Sutta to a great gathering of devas.'**
  String get holidayAboutMahathamaya;

  /// A holiday name.
  ///
  /// In en, this message translates to:
  /// **'Garudhamma Day'**
  String get holidayNameGarudhamma;

  /// What a holiday marks, two or three sentences.
  ///
  /// In en, this message translates to:
  /// **'The full moon of Tawthalin recalls the Buddha giving the eight Garudhamma rules to the first nuns.'**
  String get holidayAboutGarudhamma;

  /// A holiday name.
  ///
  /// In en, this message translates to:
  /// **'Metta Day'**
  String get holidayNameMetta;

  /// What a holiday marks, two or three sentences.
  ///
  /// In en, this message translates to:
  /// **'The full moon of Wagaung, a day for practising loving-kindness.'**
  String get holidayAboutMetta;

  /// A holiday name.
  ///
  /// In en, this message translates to:
  /// **'Thingyan and Myanmar New Year'**
  String get holidayNameThingyan;

  /// What a holiday marks, two or three sentences.
  ///
  /// In en, this message translates to:
  /// **'The water festival that ends the Myanmar year: Akyo, Akya, Akyat and Atat, then New Year\'s Day. People splash water to wash away the old year, and offices stay closed through the festival and the days after New Year.'**
  String get holidayAboutThingyan;

  /// A holiday name.
  ///
  /// In en, this message translates to:
  /// **'Karen New Year'**
  String get holidayNameKarenNewYear;

  /// What a holiday marks, two or three sentences.
  ///
  /// In en, this message translates to:
  /// **'The Karen New Year, on the first day of the month of Pyatho, celebrated with traditional dances and music.'**
  String get holidayAboutKarenNewYear;

  /// A holiday name.
  ///
  /// In en, this message translates to:
  /// **'Chinese New Year'**
  String get holidayNameChineseNewYear;

  /// What a holiday marks, two or three sentences.
  ///
  /// In en, this message translates to:
  /// **'The Lunar New Year, celebrated by Chinese communities with family reunions, lion dances and red envelopes.'**
  String get holidayAboutChineseNewYear;

  /// A holiday name.
  ///
  /// In en, this message translates to:
  /// **'Shan New Year'**
  String get holidayNameShanNewYear;

  /// What a holiday marks, two or three sentences.
  ///
  /// In en, this message translates to:
  /// **'The Shan New Year, on the first day of the waxing moon of Nadaw.'**
  String get holidayAboutShanNewYear;

  /// A holiday name.
  ///
  /// In en, this message translates to:
  /// **'Taungpyone Festival'**
  String get holidayNameTaungpyone;

  /// What a holiday marks, two or three sentences.
  ///
  /// In en, this message translates to:
  /// **'The nat festival at Taungpyone near Mandalay, held in Wagaung for the two Taungpyone brother spirits.'**
  String get holidayAboutTaungpyone;

  /// A holiday name.
  ///
  /// In en, this message translates to:
  /// **'Yadanagu Festival'**
  String get holidayNameYadanagu;

  /// What a holiday marks, two or three sentences.
  ///
  /// In en, this message translates to:
  /// **'The nat festival at Yadanagu near Amarapura, held in Tawthalin for the mother of the Taungpyone brothers.'**
  String get holidayAboutYadanagu;

  /// A holiday name.
  ///
  /// In en, this message translates to:
  /// **'Mon National Day'**
  String get holidayNameMonNational;

  /// What a holiday marks, two or three sentences.
  ///
  /// In en, this message translates to:
  /// **'Falls on the full moon of Tabodwe and recalls the founding of Hanthawaddy (Bago).'**
  String get holidayAboutMonNational;

  /// A holiday name.
  ///
  /// In en, this message translates to:
  /// **'Mother\'s Day'**
  String get holidayNameMothers;

  /// What a holiday marks, two or three sentences.
  ///
  /// In en, this message translates to:
  /// **'A day to thank and honour mothers.'**
  String get holidayAboutMothers;

  /// A holiday name.
  ///
  /// In en, this message translates to:
  /// **'Father\'s Day'**
  String get holidayNameFathers;

  /// What a holiday marks, two or three sentences.
  ///
  /// In en, this message translates to:
  /// **'A day to thank and honour fathers.'**
  String get holidayAboutFathers;

  /// A holiday name.
  ///
  /// In en, this message translates to:
  /// **'Authors\' Day'**
  String get holidayNameAuthors;

  /// What a holiday marks, two or three sentences.
  ///
  /// In en, this message translates to:
  /// **'Honours Myanmar writers and poets, with literary talks and book fairs.'**
  String get holidayAboutAuthors;

  /// A holiday name.
  ///
  /// In en, this message translates to:
  /// **'General Aung San\'s Birthday'**
  String get holidayNameAungSanBirthday;

  /// What a holiday marks, two or three sentences.
  ///
  /// In en, this message translates to:
  /// **'General Aung San, the father of Myanmar\'s independence, was born on 13 February 1915. The day is also Children\'s Day.'**
  String get holidayAboutAungSanBirthday;

  /// A holiday name.
  ///
  /// In en, this message translates to:
  /// **'Valentine\'s Day'**
  String get holidayNameValentines;

  /// What a holiday marks, two or three sentences.
  ///
  /// In en, this message translates to:
  /// **'A day for sweethearts, on 14 February.'**
  String get holidayAboutValentines;

  /// A holiday name.
  ///
  /// In en, this message translates to:
  /// **'April Fools\' Day'**
  String get holidayNameAprilFools;

  /// What a holiday marks, two or three sentences.
  ///
  /// In en, this message translates to:
  /// **'A day for practical jokes, on 1 April.'**
  String get holidayAboutAprilFools;

  /// A holiday name.
  ///
  /// In en, this message translates to:
  /// **'Earth Day'**
  String get holidayNameEarth;

  /// What a holiday marks, two or three sentences.
  ///
  /// In en, this message translates to:
  /// **'A worldwide day for protecting the environment, on 22 April.'**
  String get holidayAboutEarth;

  /// A holiday name.
  ///
  /// In en, this message translates to:
  /// **'Red Cross Day'**
  String get holidayNameRedCross;

  /// What a holiday marks, two or three sentences.
  ///
  /// In en, this message translates to:
  /// **'World Red Cross Day, on 8 May, the birthday of its founder Henry Dunant.'**
  String get holidayAboutRedCross;

  /// A holiday name.
  ///
  /// In en, this message translates to:
  /// **'United Nations Day'**
  String get holidayNameUnitedNations;

  /// What a holiday marks, two or three sentences.
  ///
  /// In en, this message translates to:
  /// **'Marks the founding of the United Nations on 24 October 1945.'**
  String get holidayAboutUnitedNations;

  /// A holiday name.
  ///
  /// In en, this message translates to:
  /// **'World Teachers\' Day'**
  String get holidayNameWorldTeachers;

  /// What a holiday marks, two or three sentences.
  ///
  /// In en, this message translates to:
  /// **'UNESCO\'s day for teachers, on 5 October.'**
  String get holidayAboutWorldTeachers;

  /// A holiday name.
  ///
  /// In en, this message translates to:
  /// **'Halloween'**
  String get holidayNameHalloween;

  /// What a holiday marks, two or three sentences.
  ///
  /// In en, this message translates to:
  /// **'An evening of costumes and treats, on 31 October.'**
  String get holidayAboutHalloween;

  /// Search field on the Holidays page.
  ///
  /// In en, this message translates to:
  /// **'Search holidays'**
  String get holidaysSearchHint;

  /// Holidays filter chip.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get holidaysFilterAll;

  /// Holidays filter chip: days offices close.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get holidaysFilterPublic;

  /// Holidays filter chip.
  ///
  /// In en, this message translates to:
  /// **'Religious'**
  String get holidaysFilterReligious;

  /// Holidays filter chip.
  ///
  /// In en, this message translates to:
  /// **'Cultural'**
  String get holidaysFilterCultural;

  /// Holidays filter chip.
  ///
  /// In en, this message translates to:
  /// **'Anniversaries'**
  String get holidaysFilterAnniversary;

  /// A day offices close.
  ///
  /// In en, this message translates to:
  /// **'Public holiday'**
  String get holidaysPublicHoliday;

  /// A holiday that is not a day off.
  ///
  /// In en, this message translates to:
  /// **'Observance'**
  String get holidaysObservance;

  /// Holiday kind.
  ///
  /// In en, this message translates to:
  /// **'National'**
  String get holidaysKindNational;

  /// Holiday kind.
  ///
  /// In en, this message translates to:
  /// **'Religious'**
  String get holidaysKindReligious;

  /// Holiday kind.
  ///
  /// In en, this message translates to:
  /// **'Cultural'**
  String get holidaysKindCultural;

  /// Holiday kind.
  ///
  /// In en, this message translates to:
  /// **'Anniversary'**
  String get holidaysKindAnniversary;

  /// Label above the next holiday card.
  ///
  /// In en, this message translates to:
  /// **'Next holiday'**
  String get holidaysNextUp;

  /// How many days a holiday lasts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day off} other{{count} days off}}'**
  String holidaysDaysOff(int count);

  /// Length of a holiday.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String holidaysDayCount(int count);

  /// Days until a holiday, in a narrow column.
  ///
  /// In en, this message translates to:
  /// **'{count} d'**
  String holidaysDaysShort(String count);

  /// When a holiday starts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Today} =1{Tomorrow} other{in {count} days}}'**
  String holidaysInDays(int count);

  /// A holiday that is happening today.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get holidaysNow;

  /// Search result count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No holidays} =1{1 holiday} other{{count} holidays}} in {year}'**
  String holidaysResults(int count, String year);

  /// Empty search.
  ///
  /// In en, this message translates to:
  /// **'Nothing in {year} matches “{query}”.'**
  String holidaysNoResults(String year, String query);

  /// Row that widens the search.
  ///
  /// In en, this message translates to:
  /// **'Search all years'**
  String get holidaysSearchAllYears;

  /// Year range searched.
  ///
  /// In en, this message translates to:
  /// **'{from} to {to}'**
  String holidaysYearsRange(String from, String to);

  /// Search results already past.
  ///
  /// In en, this message translates to:
  /// **'Earlier this year'**
  String get holidaysEarlier;

  /// Search results still ahead.
  ///
  /// In en, this message translates to:
  /// **'Coming up'**
  String get holidaysComingUp;

  /// The next time a holiday comes round, in search.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get holidaysNextYear;

  /// Holiday detail group label.
  ///
  /// In en, this message translates to:
  /// **'Other years'**
  String get holidaysOtherYears;

  /// Holiday detail button.
  ///
  /// In en, this message translates to:
  /// **'Open in calendar'**
  String get holidaysOpenInCalendar;

  /// A holiday that does not fall in the chosen year.
  ///
  /// In en, this message translates to:
  /// **'Not in {year}'**
  String holidaysNotThisYear(String year);

  /// Views row subtitle.
  ///
  /// In en, this message translates to:
  /// **'Every holiday of the year, with reminders'**
  String get holidaysViewsSubtitle;

  /// Views group footer.
  ///
  /// In en, this message translates to:
  /// **'{count} public holidays in {year}.'**
  String holidaysViewsFooter(int count, String year);

  /// Views group label.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get viewsCalendarGroup;

  /// Views group label.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get viewsExploreGroup;

  /// Holiday reminder switch.
  ///
  /// In en, this message translates to:
  /// **'Remind me'**
  String get holidayRemindMe;

  /// When a holiday reminder comes.
  ///
  /// In en, this message translates to:
  /// **'The evening before, at 6 pm'**
  String get holidayReminderEvening;

  /// When a holiday reminder comes.
  ///
  /// In en, this message translates to:
  /// **'On the day, at 8 am'**
  String get holidayReminderMorning;

  /// When a holiday reminder comes.
  ///
  /// In en, this message translates to:
  /// **'The evening before and on the day'**
  String get holidayReminderBoth;

  /// Holiday reminders sheet title.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get holidayRemindersTitle;

  /// Reminder sheet group label.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get holidayRemindersWhen;

  /// Reminder time option.
  ///
  /// In en, this message translates to:
  /// **'The evening before'**
  String get holidayRemindersEveningOption;

  /// Reminder time option.
  ///
  /// In en, this message translates to:
  /// **'On the morning'**
  String get holidayRemindersMorningOption;

  /// Reminder time option.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get holidayRemindersBothOption;

  /// Reminder sheet group label.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get holidayRemindersFollow;

  /// Follow every public holiday.
  ///
  /// In en, this message translates to:
  /// **'All public holidays'**
  String get holidayRemindersAllPublic;

  /// How many public holidays.
  ///
  /// In en, this message translates to:
  /// **'{count} in {year}'**
  String holidayRemindersAllPublicSubtitle(int count, String year);

  /// Reminder sheet footer.
  ///
  /// In en, this message translates to:
  /// **'Reminders cover the next 60 days and refresh each time you open the app.'**
  String get holidayRemindersFooter;

  /// A holiday covered by following all public holidays.
  ///
  /// In en, this message translates to:
  /// **'Included in all public holidays'**
  String get holidayRemindersIncluded;

  /// Shown when notification permission is refused.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off for Myanmar Calendar. Turn them on in your phone\'s Settings to get reminders.'**
  String get holidayRemindersPermissionDenied;

  /// Holiday notification title the evening before.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow: {holiday}'**
  String holidayReminderTomorrow(String holiday);

  /// Holiday notification title on the day.
  ///
  /// In en, this message translates to:
  /// **'Today: {holiday}'**
  String holidayReminderToday(String holiday);

  /// Holiday notification body.
  ///
  /// In en, this message translates to:
  /// **'Public holiday · {dates}'**
  String holidayReminderBodyPublic(String dates);

  /// What's new sheet and page title.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get whatsNewTitle;

  /// Badge on the What's new sheet.
  ///
  /// In en, this message translates to:
  /// **'New in {version}'**
  String whatsNewBadge(String version);

  /// Badge for a feature from an earlier version.
  ///
  /// In en, this message translates to:
  /// **'From {version}'**
  String whatsNewFromVersion(String version);

  /// Page position in the sheet.
  ///
  /// In en, this message translates to:
  /// **'{page} of {count}'**
  String whatsNewPageOf(int page, int count);

  /// Next feature.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get whatsNewNext;

  /// Close the sheet.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get whatsNewDone;

  /// Opens the history page.
  ///
  /// In en, this message translates to:
  /// **'See all updates'**
  String get whatsNewSeeAll;

  /// History group label for the current version.
  ///
  /// In en, this message translates to:
  /// **'Version {version} · this update'**
  String whatsNewThisUpdate(String version);

  /// History group label.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String whatsNewVersion(String version);

  /// Feature title.
  ///
  /// In en, this message translates to:
  /// **'Holidays'**
  String get whatsNewHolidaysTitle;

  /// Feature description.
  ///
  /// In en, this message translates to:
  /// **'Every holiday of the year in one place. Search in Myanmar or English, see what each day marks, and get a reminder the evening before.'**
  String get whatsNewHolidaysBody;

  /// Feature button.
  ///
  /// In en, this message translates to:
  /// **'Explore holidays'**
  String get whatsNewHolidaysAction;

  /// Feature title.
  ///
  /// In en, this message translates to:
  /// **'New home-screen widgets'**
  String get whatsNewWidgetsTitle;

  /// Feature description.
  ///
  /// In en, this message translates to:
  /// **'Nine widgets in five styles, from today\'s date to a countdown to Thingyan. Tap any day to open it in the app.'**
  String get whatsNewWidgetsBody;

  /// Feature button.
  ///
  /// In en, this message translates to:
  /// **'Widget settings'**
  String get whatsNewWidgetsAction;

  /// Feature title.
  ///
  /// In en, this message translates to:
  /// **'A new welcome'**
  String get whatsNewWelcomeTitle;

  /// Feature description.
  ///
  /// In en, this message translates to:
  /// **'New users get a short tour and a quick setup for language, look, privacy and reminders.'**
  String get whatsNewWelcomeBody;

  /// Feature title.
  ///
  /// In en, this message translates to:
  /// **'Calendar themes'**
  String get whatsNewThemesTitle;

  /// Feature description.
  ///
  /// In en, this message translates to:
  /// **'Twelve themes for the month grid, from Pagoda and Jade to Deep Field, each with light and dark colours.'**
  String get whatsNewThemesBody;

  /// Feature button.
  ///
  /// In en, this message translates to:
  /// **'Choose a theme'**
  String get whatsNewThemesAction;

  /// Feature title.
  ///
  /// In en, this message translates to:
  /// **'Custom colours'**
  String get whatsNewColorsTitle;

  /// Feature description.
  ///
  /// In en, this message translates to:
  /// **'Pick one accent colour for the whole app, or fine-tune every colour in Advanced.'**
  String get whatsNewColorsBody;

  /// Feature button.
  ///
  /// In en, this message translates to:
  /// **'Pick colours'**
  String get whatsNewColorsAction;

  /// Feature title.
  ///
  /// In en, this message translates to:
  /// **'App icons'**
  String get whatsNewIconsTitle;

  /// Feature description.
  ///
  /// In en, this message translates to:
  /// **'Choose from six app icons, including Moon, Forest and Traditional.'**
  String get whatsNewIconsBody;

  /// Feature button.
  ///
  /// In en, this message translates to:
  /// **'Change icon'**
  String get whatsNewIconsAction;

  /// Feature title.
  ///
  /// In en, this message translates to:
  /// **'Calendar Studio'**
  String get whatsNewStudioTitle;

  /// Feature description.
  ///
  /// In en, this message translates to:
  /// **'Design wall, desk and social calendars from presets, then export print-ready PDFs and images.'**
  String get whatsNewStudioBody;

  /// Feature button.
  ///
  /// In en, this message translates to:
  /// **'Open Studio'**
  String get whatsNewStudioAction;

  /// Skip the tour.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// Next onboarding page.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// Last tour page button.
  ///
  /// In en, this message translates to:
  /// **'Set up the app'**
  String get onboardingSetUp;

  /// Skip a setup step.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get onboardingNotNow;

  /// Finish onboarding.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get onboardingStart;

  /// Setup progress.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {count}'**
  String onboardingStep(int step, int count);

  /// Tour page 1.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Myanmar Calendar'**
  String get onboardingWelcomeTitle;

  /// Tour page 1.
  ///
  /// In en, this message translates to:
  /// **'Myanmar and Western dates side by side, for every day of the year.'**
  String get onboardingWelcomeBody;

  /// Tour page 2.
  ///
  /// In en, this message translates to:
  /// **'Two calendars in one'**
  String get onboardingCalendarsTitle;

  /// Tour page 2.
  ///
  /// In en, this message translates to:
  /// **'Every day shows its Myanmar date, moon phase and Sabbath, with astrology one tap away.'**
  String get onboardingCalendarsBody;

  /// Tour page 3.
  ///
  /// In en, this message translates to:
  /// **'Never miss a holiday'**
  String get onboardingHolidaysTitle;

  /// Tour page 3.
  ///
  /// In en, this message translates to:
  /// **'Browse and search every holiday, add your own events, and get a reminder the evening before.'**
  String get onboardingHolidaysBody;

  /// Tour page 4.
  ///
  /// In en, this message translates to:
  /// **'Make it yours'**
  String get onboardingYoursTitle;

  /// Tour page 4.
  ///
  /// In en, this message translates to:
  /// **'Choose colours and calendar themes, add home-screen widgets, and design printable calendars in Calendar Studio.'**
  String get onboardingYoursBody;

  /// Setup step 1.
  ///
  /// In en, this message translates to:
  /// **'Choose your languages'**
  String get onboardingLanguagesTitle;

  /// Setup group label.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get onboardingAppLanguage;

  /// Setup group footer.
  ///
  /// In en, this message translates to:
  /// **'Month names, holidays and moon phases use the calendar language.'**
  String get onboardingCalendarLanguageFooter;

  /// Setup step 2.
  ///
  /// In en, this message translates to:
  /// **'Pick a look'**
  String get onboardingLookTitle;

  /// Theme follows the system.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get onboardingThemeAutomatic;

  /// Light theme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get onboardingThemeLight;

  /// Dark theme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get onboardingThemeDark;

  /// Setup group label.
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get onboardingColour;

  /// Setup group footer.
  ///
  /// In en, this message translates to:
  /// **'More colours and calendar themes are in Settings › Appearance.'**
  String get onboardingColourFooter;

  /// Setup step 3.
  ///
  /// In en, this message translates to:
  /// **'Your calendar stays on your phone'**
  String get onboardingPrivacyTitle;

  /// Setup step 3.
  ///
  /// In en, this message translates to:
  /// **'Events and notes never leave your device. You can help improve the app by sharing anonymous data.'**
  String get onboardingPrivacyBody;

  /// Analytics switch.
  ///
  /// In en, this message translates to:
  /// **'Usage statistics'**
  String get onboardingUsageStats;

  /// Analytics switch subtitle.
  ///
  /// In en, this message translates to:
  /// **'Which screens are used, never what\'s on them'**
  String get onboardingUsageStatsSubtitle;

  /// Crash report switch.
  ///
  /// In en, this message translates to:
  /// **'Crash reports'**
  String get onboardingCrashReports;

  /// Crash report switch subtitle.
  ///
  /// In en, this message translates to:
  /// **'Sent only when the app crashes'**
  String get onboardingCrashReportsSubtitle;

  /// Setup group footer.
  ///
  /// In en, this message translates to:
  /// **'Change this any time in Settings › Privacy & Data.'**
  String get onboardingPrivacyFooter;

  /// Setup step 4.
  ///
  /// In en, this message translates to:
  /// **'Reminders when they matter'**
  String get onboardingNotificationsTitle;

  /// Notification kind.
  ///
  /// In en, this message translates to:
  /// **'Event reminders'**
  String get onboardingEventReminders;

  /// Notification kind.
  ///
  /// In en, this message translates to:
  /// **'At the time you choose for each event'**
  String get onboardingEventRemindersSubtitle;

  /// Notification kind.
  ///
  /// In en, this message translates to:
  /// **'Holiday reminders'**
  String get onboardingHolidayReminders;

  /// Notification kind.
  ///
  /// In en, this message translates to:
  /// **'The evening before holidays you follow'**
  String get onboardingHolidayRemindersSubtitle;

  /// Ask for notification permission.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get onboardingAllowNotifications;

  /// Last onboarding page.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set'**
  String get onboardingDoneTitle;

  /// Last onboarding page.
  ///
  /// In en, this message translates to:
  /// **'Today is {date}.'**
  String onboardingDoneToday(String date);

  /// Last onboarding page tip.
  ///
  /// In en, this message translates to:
  /// **'Tip: add a widget'**
  String get onboardingWidgetTipTitle;

  /// Last onboarding page tip.
  ///
  /// In en, this message translates to:
  /// **'See the Myanmar date on your home screen. Touch and hold an empty spot, then add Myanmar Calendar.'**
  String get onboardingWidgetTipBody;

  /// Views row: a Myanmar month by fortnight
  ///
  /// In en, this message translates to:
  /// **'Myanmar Month'**
  String get viewsMyanmarMonth;

  /// Views row subtitle for the Myanmar month view
  ///
  /// In en, this message translates to:
  /// **'The month by waxing and waning fortnight'**
  String get viewsMyanmarMonthSubtitle;

  /// Views row: upcoming days with something on them
  ///
  /// In en, this message translates to:
  /// **'Agenda'**
  String get viewsAgenda;

  /// Views row subtitle for the agenda
  ///
  /// In en, this message translates to:
  /// **'Holidays, Sabbath, moon days and your events ahead'**
  String get viewsAgendaSubtitle;

  /// Day details: next full moon, new moon and Sabbath
  ///
  /// In en, this message translates to:
  /// **'Coming up'**
  String get dayDetailsComingUp;

  /// Day details: the Nagahle compass section
  ///
  /// In en, this message translates to:
  /// **'Dragon\'s head'**
  String get dayDetailsNagahleCompass;

  /// Day details: the astrology section when no Sabbath, Yatyaza, Pyathada or named astrological day falls on the day
  ///
  /// In en, this message translates to:
  /// **'No special astrological days'**
  String get dayDetailsNoAstrologicalDays;
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
