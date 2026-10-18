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
  String get add => 'Add';

  @override
  String get addEvent => 'Add event';

  @override
  String get allDay => 'All day';

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
  String get apply => 'Apply';

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
  String get astrology => 'Astrology';

  @override
  String get britishCalendarSystem => 'British calendar system';

  @override
  String get buddhist_era => 'Buddhist Era (BE)';

  @override
  String get calculate => 'Calculate';

  @override
  String get calendar => 'Calendar';

  @override
  String get calendarChooseMonth => 'Choose month';

  @override
  String calendarDaysAgo(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return '$daysString days ago';
  }

  @override
  String calendarDaysFromToday(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return '$daysString days from today';
  }

  @override
  String calendarDaysShort(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return '$daysString d';
  }

  @override
  String calendarEventCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString events',
      one: '1 event',
    );
    return '$_temp0';
  }

  @override
  String get calendarFullDayDetails => 'Full day details';

  @override
  String get calendarFullDayDetailsSubtitle =>
      'Astrology, Buddhist calendar, AI prompt';

  @override
  String calendarInDays(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return 'in $daysString days';
  }

  @override
  String get calendarJumpToMonth => 'Jump to month';

  @override
  String calendarLabelCopied(String label) {
    return '$label copied!';
  }

  @override
  String get calendarLanguage => 'Calendar Language';

  @override
  String calendarMakeYourCalendar(String year) {
    return 'Make your $year calendar';
  }

  @override
  String get calendarNextYear => 'Next year';

  @override
  String get calendarPreviousYear => 'Previous year';

  @override
  String get calendarStudio => 'Calendar Studio';

  @override
  String get calendarToggleDayDetails => 'Show or hide day details';

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
  String get calendarUpcoming => 'Upcoming';

  @override
  String get cancel => 'Cancel';

  @override
  String get categories => 'Categories';

  @override
  String get category => 'Category';

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
  String get clear => 'Clear';

  @override
  String get clearPromoDataDebug => 'Clear Promo Data (Debug)';

  @override
  String get close => 'Close';

  @override
  String get colour => 'Colour';

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
  String get converterAddSub => 'Add/Sub';

  @override
  String get converterConvertedDate => 'Converted date';

  @override
  String get converterDateArithmetic => 'Date arithmetic';

  @override
  String get converterDateDifference => 'Date difference';

  @override
  String converterDaysUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days',
      one: 'day',
    );
    return '$_temp0';
  }

  @override
  String get converterDifference => 'Difference';

  @override
  String get converterEnd => 'End';

  @override
  String get converterEnterMyanmarDate =>
      'Enter a Myanmar year, month and day.';

  @override
  String get converterEnterWholeNumber => 'Enter a whole number above 0.';

  @override
  String get converterFrom => 'From';

  @override
  String converterInDays(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'in $countString days',
      one: 'in 1 day',
    );
    return '$_temp0';
  }

  @override
  String get converterMonthDayRange => 'Month is 0–14 and day is 1–30.';

  @override
  String get converterMonthFooter =>
      'Month: 0 = First Waso, 1–12 = Tagu to Tabaung, 13 = Late Tagu, 14 = Second Waso.';

  @override
  String get converterMoonPhase => 'Moon phase';

  @override
  String get converterMyanmarDate => 'Myanmar date';

  @override
  String get converterMyanmarToWestern => 'Myanmar → Western';

  @override
  String converterNextPhase(String name) {
    return 'Next $name';
  }

  @override
  String get converterResult => 'Result';

  @override
  String get converterStart => 'Start';

  @override
  String get converterStartFromToday => 'Start from today';

  @override
  String get converterSubtract => 'Subtract';

  @override
  String get converterSwapDates => 'Swap dates';

  @override
  String get converterTodayLower => 'today';

  @override
  String converterUnit(String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'days': 'days',
      'weeks': 'weeks',
      'months': 'months',
      'years': 'years',
      'other': '$unit',
    });
    return '$_temp0';
  }

  @override
  String get converterValue => 'Value';

  @override
  String get converterWesternToMyanmar => 'Western → Myanmar';

  @override
  String get copied => 'Copied';

  @override
  String get copy => 'Copy';

  @override
  String get crashReports => 'Crash Reports';

  @override
  String get create => 'Create';

  @override
  String get currentVersion => 'Current Version';

  @override
  String currentVersionWithBuild(Object version, Object build) {
    return 'Current: $version ($build)';
  }

  @override
  String get custom => 'Custom';

  @override
  String get dark => 'Dark';

  @override
  String get date => 'Date';

  @override
  String get day => 'Day';

  @override
  String get day_view => 'Day View';

  @override
  String get dayDetailsAddEvent => 'Add Event';

  @override
  String get dayDetailsAiHoroscopePrompt => 'AI Horoscope Prompt';

  @override
  String get dayDetailsAiHoroscopePromptSubtitle =>
      'Copy a ready-made prompt for this day';

  @override
  String get dayDetailsAiPromptHint =>
      'Paste this into any AI assistant (ChatGPT, Gemini, …) for a reading of the day. Nothing is sent from this app.';

  @override
  String get dayDetailsBuddhistCalendar => 'Buddhist Calendar';

  @override
  String get dayDetailsCopyPrompt => 'Copy Prompt';

  @override
  String get dayDetailsErrorLoadingEvents => 'Error loading events';

  @override
  String dayDetailsFailedToUpdateEvent(String error) {
    return 'Failed to update event: $error';
  }

  @override
  String dayDetailsFortnightDayPercentLit(String day, String percent) {
    return 'Day $day · $percent% lit';
  }

  @override
  String get dayDetailsJumpToDate => 'Jump to Date';

  @override
  String get dayDetailsLoadingEvents => 'Loading events…';

  @override
  String get dayDetailsMarkNotDone => 'Mark not done';

  @override
  String get dayDetailsNextDay => 'Next Day';

  @override
  String get dayDetailsNoEventsAddEvent => 'No events · Add event';

  @override
  String dayDetailsPercentLit(String percent) {
    return '$percent% lit';
  }

  @override
  String get dayDetailsPreviousDay => 'Previous Day';

  @override
  String get dayDetailsPromptCopied => 'Prompt copied to clipboard';

  @override
  String get dayDetailsPyathada => 'Pyathada';

  @override
  String get dayDetailsShareDay => 'Share Day';

  @override
  String get dayDetailsShareFailed => 'Failed to share';

  @override
  String get dayDetailsShareSubject => 'Please check myanmar calendar';

  @override
  String get dayDetailsSpecial => 'Special';

  @override
  String get dayDetailsYatyaza => 'Yatyaza';

  @override
  String get dayDetailsYearType => 'Type';

  @override
  String get days => 'Days';

  @override
  String get defaultCalculationMethod => 'Default calculation method';

  @override
  String get defaultLabel => 'Default';

  @override
  String get delete => 'Delete';

  @override
  String get deleteEvent => 'Delete event';

  @override
  String get deleteEventQuestion => 'Delete event?';

  @override
  String get description => 'Description';

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
  String get edit => 'Edit';

  @override
  String get editEvent => 'Edit event';

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
  String get event => 'Event';

  @override
  String get events => 'Events';

  @override
  String get eventsAddReminder => 'Add reminder';

  @override
  String get eventsAddTagHint => 'Add a tag and press return';

  @override
  String get eventsBuiltInCategoriesFooter =>
      'Built-in categories can’t be changed.';

  @override
  String get eventsCategoryColour => 'Category colour';

  @override
  String get eventsCompleted => 'Completed';

  @override
  String get eventsCouldNotLoadEvent => 'Couldn’t load this event';

  @override
  String get eventsCreateEvent => 'Create Event';

  @override
  String get eventsCustomCategoriesEmptyFooter =>
      'Create categories for the events you keep.';

  @override
  String get eventsCustomCategoriesFooter =>
      'Tap a category to rename, recolour or delete it.';

  @override
  String eventsDayEventsSemantics(String date, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$date, $countString events';
  }

  @override
  String get eventsDeleteCategory => 'Delete Category';

  @override
  String get eventsDeleteCategoryMessage =>
      'Its events are kept; they just stop being linked to this category.';

  @override
  String eventsDeleteCategoryQuestion(String name) {
    return 'Delete “$name”?';
  }

  @override
  String get eventsDeleteEventMessage =>
      'This event will be removed. This can’t be undone.';

  @override
  String get eventsDeleteThisOccurrence => 'Delete this occurrence';

  @override
  String get eventsDeleteThisOccurrenceQuestion => 'Delete this occurrence?';

  @override
  String get eventsEditCategory => 'Edit Category';

  @override
  String get eventsEditEventTitle => 'Edit Event';

  @override
  String eventsEventCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString events',
      one: '1 event',
    );
    return '$_temp0';
  }

  @override
  String get eventsEventCreated => 'Event created';

  @override
  String get eventsEventNotFound => 'Event not found';

  @override
  String get eventsEventUpdated => 'Event updated';

  @override
  String eventsEventWillBeRemoved(String title) {
    return '“$title” will be removed. This can’t be undone.';
  }

  @override
  String get eventsFillRequiredFields => 'Please fill in required fields';

  @override
  String get eventsJumpToToday => 'Jump to today';

  @override
  String get eventsMayHaveBeenDeleted => 'It may have been deleted.';

  @override
  String get eventsNewCategory => 'New Category';

  @override
  String eventsNoEventsOn(String date) {
    return 'No events on $date';
  }

  @override
  String get eventsNoResultsFound => 'No results found';

  @override
  String get eventsOccurrence => 'Occurrence';

  @override
  String get eventsOnlyThisOccurrenceRemoved =>
      'Only this occurrence will be removed.';

  @override
  String get eventsPickAColor => 'Pick a color';

  @override
  String get eventsPickADate => 'Pick a date';

  @override
  String get eventsPickAnotherDay => 'Pick another day or create one.';

  @override
  String get eventsReminderAtStart => 'at start';

  @override
  String eventsReminderDays(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString days',
      one: '$countString day',
    );
    return '$_temp0';
  }

  @override
  String eventsReminderHours(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString h';
  }

  @override
  String eventsReminderMinutes(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString min';
  }

  @override
  String get eventsRemoveReminder => 'Remove reminder';

  @override
  String get eventsReopenEvent => 'Reopen event';

  @override
  String get eventsRepeatsDaily => 'repeats daily';

  @override
  String eventsRepeatsEveryNDays(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'repeats every $countString days';
  }

  @override
  String eventsRepeatsEveryNMonths(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'repeats every $countString months';
  }

  @override
  String eventsRepeatsEveryNWeeks(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'repeats every $countString weeks';
  }

  @override
  String eventsRepeatsEveryNYears(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'repeats every $countString years';
  }

  @override
  String get eventsRepeatsMonthly => 'repeats monthly';

  @override
  String get eventsRepeatsWeekly => 'repeats weekly';

  @override
  String get eventsRepeatsYearly => 'repeats yearly';

  @override
  String get eventsResults => 'Results';

  @override
  String get eventsSaveChanges => 'Save Changes';

  @override
  String get eventsSaving => 'Saving…';

  @override
  String get eventsSearchEvents => 'Search events';

  @override
  String get eventsSearchPromptHint => 'Type title or description';

  @override
  String get eventsTryDifferentKeyword => 'Try a different keyword';

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
  String get goBack => 'Go back';

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
  String get icon => 'Icon';

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
  String get location => 'Location';

  @override
  String get mahabote => 'Mahabote';

  @override
  String get markAsPending => 'Mark as pending';

  @override
  String get markComplete => 'Mark complete';

  @override
  String get matchSystemTheme => 'Match system theme';

  @override
  String get month => 'Month';

  @override
  String get months => 'Months';

  @override
  String get moon => 'Moon';

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
  String get name => 'Name';

  @override
  String get never => 'Never';

  @override
  String get newEvent => 'New Event';

  @override
  String get next_month => 'Next Month';

  @override
  String get nextYear => 'Next Year';

  @override
  String get noChanges => 'no changes';

  @override
  String get none => 'None';

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
  String get previousYear => 'Previous Year';

  @override
  String get priority => 'Priority';

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
  String get refresh => 'Refresh';

  @override
  String get releaseNotes => 'Release Notes';

  @override
  String get reminders => 'Reminders';

  @override
  String get repeat => 'Repeat';

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
  String get sabbath => 'Sabbath';

  @override
  String get sasanaYearType => 'Sasana Year Type';

  @override
  String get sasana_year => 'Sasana Year';

  @override
  String get save => 'Save';

  @override
  String get select => 'Select';

  @override
  String get sendCrashReportsToHelpFixIssues =>
      'Send crash reports to help fix issues';

  @override
  String get settings => 'Settings';

  @override
  String get settingsResetSuccessfully => 'Settings reset successfully';

  @override
  String get share => 'Share';

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
  String get somethingWentWrong => 'Oops! Something went wrong';

  @override
  String get special_days => 'Special Days';

  @override
  String get system => 'System';

  @override
  String get tags => 'Tags';

  @override
  String telegramUserLabel(Object userName) {
    return 'TG: $userName';
  }

  @override
  String get themeMode => 'Theme Mode';

  @override
  String get theme_preset => 'Theme Preset';

  @override
  String get time => 'Time';

  @override
  String get timezoneOffset => 'Timezone Offset';

  @override
  String get timezoneOffsetExample => 'e.g., 6.5 for Myanmar Time (UTC+6:30)';

  @override
  String get title => 'Title';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get tryAgain => 'Try Again';

  @override
  String typeValue(Object value) {
    return 'Type $value';
  }

  @override
  String get unableToOpenUpdatePage => 'Unable to open the update page.';

  @override
  String get unexpectedError => 'Unexpected error occurred';

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
  String get viewsDayViewSubtitle => 'Everything about one day';

  @override
  String get viewsNextWeek => 'Next Week';

  @override
  String get viewsPreviousWeek => 'Previous Week';

  @override
  String get viewsThisWeek => 'This Week';

  @override
  String get viewsThisYear => 'This Year';

  @override
  String get viewsViewFullMonth => 'View Full Month';

  @override
  String get viewsWeekViewSubtitle =>
      'Seven days with Myanmar dates and the moon';

  @override
  String get viewsYearViewSubtitle => 'All 12 months with holiday counts';

  @override
  String get week => 'Week';

  @override
  String get week_view => 'Week View';

  @override
  String get weekday => 'Weekday';

  @override
  String weekNumber(int number) {
    final intl.NumberFormat numberNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String numberString = numberNumberFormat.format(number);

    return 'Week $numberString';
  }

  @override
  String get weeks => 'Weeks';

  @override
  String get widgetSettings => 'Widget Settings';

  @override
  String get year => 'Year';

  @override
  String get year_name => 'Year Name';

  @override
  String get year_view => 'Year View';

  @override
  String get years => 'Years';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get settingsAppLanguageFooter => 'Menus, buttons and messages.';

  @override
  String get settingsCalendarLanguageFooter =>
      'Dates, month and weekday names, lunar days, holidays and moon phases everywhere in the app, including widgets.';

  @override
  String get settingsCalendarGrid => 'Calendar grid';

  @override
  String get settingsGridLayoutTab => 'Layout';

  @override
  String get settingsGridThemeTab => 'Theme';

  @override
  String get settingsGridFitNote =>
      'Every style fits the screen: rows take the height that is left above the day sheet.';

  @override
  String get settingsGridThemeFooter =>
      'A theme colours the month header, weekday row and grid, and works with every layout. The day sheet keeps the app’s colours.';

  @override
  String get settingsGridShowMotif => 'Show motif';

  @override
  String get gridLayoutDetailedTitle => 'Detailed';

  @override
  String get gridLayoutDetailedDescription =>
      'Lunar day, holiday name, moon and events in every day.';

  @override
  String get gridLayoutCleanTitle => 'Clean';

  @override
  String get gridLayoutCleanDescription =>
      'Numbers first; the moon only on moon days.';

  @override
  String get gridLayoutClassicTitle => 'Classic';

  @override
  String get gridLayoutClassicDescription =>
      'The original tiles and coloured dots.';

  @override
  String get gridLayoutDetailedV2Title => 'Detailed v2';

  @override
  String get gridLayoutDetailedV2Description =>
      'Detailed, calmer: no lines, the moon only on moon days.';

  @override
  String get gridLayoutLunarFirstTitle => 'Lunar first';

  @override
  String get gridLayoutLunarFirstDescription =>
      'The lunar day large, the date small in the corner.';

  @override
  String get gridLayoutMinimalTitle => 'Minimal';

  @override
  String get gridLayoutMinimalDescription => 'The date and one status dot.';

  @override
  String get gridLayoutMoonStripTitle => 'Moon strip';

  @override
  String get gridLayoutMoonStripDescription => 'Tonight’s moon in every day.';

  @override
  String get gridLayoutAgendaTitle => 'Agenda';

  @override
  String get gridLayoutAgendaDescription =>
      'Event titles and holidays inside the days.';

  @override
  String get gridLayoutClassicPrintTitle => 'Classic print';

  @override
  String get gridLayoutClassicPrintDescription =>
      'A ruled table like a wall calendar.';

  @override
  String get gridLayoutTilesTitle => 'Tiles';

  @override
  String get gridLayoutTilesDescription =>
      'Every day a card; holidays and Sabbath tinted.';

  @override
  String get gridLayoutMoonlightTitle => 'Moonlight';

  @override
  String get gridLayoutMoonlightDescription =>
      'Days glow brighter toward the full moon.';

  @override
  String get gridLayoutSplitTitle => 'Split';

  @override
  String get gridLayoutSplitDescription =>
      'The date and the lunar day, split diagonally.';

  @override
  String get gridLayoutPosterTitle => 'Poster';

  @override
  String get gridLayoutPosterDescription =>
      'Big, bold numbers you can read from afar.';

  @override
  String get gridLayoutMoonRingTitle => 'Moon ring';

  @override
  String get gridLayoutMoonRingDescription =>
      'A ring around each date fills with moonlight.';

  @override
  String get gridLayoutAstrologyTitle => 'Astrology';

  @override
  String get gridLayoutAstrologyDescription =>
      'Astrological days and holidays as tags.';

  @override
  String get gridThemeAppTitle => 'App colours';

  @override
  String get gridThemeAppDescription => 'The app’s own colours and accent.';

  @override
  String get gridThemePagodaTitle => 'Pagoda';

  @override
  String get gridThemePagodaDescription =>
      'Temple cream, maroon and pagoda gold.';

  @override
  String get gridThemeJadeTitle => 'Jade';

  @override
  String get gridThemeJadeDescription =>
      'Jade green on cool white, with a seal.';

  @override
  String get gridThemeLacquerTitle => 'Lacquer';

  @override
  String get gridThemeLacquerDescription =>
      'Black lacquer, cinnabar and gold leaf.';

  @override
  String get gridThemeThadingyutTitle => 'Thadingyut';

  @override
  String get gridThemeThadingyutDescription =>
      'Lantern paper by day, indigo by night.';

  @override
  String get gridThemeThingyanTitle => 'Thingyan';

  @override
  String get gridThemeThingyanDescription => 'Splash blue and padauk yellow.';

  @override
  String get gridThemeBotanicalTitle => 'Botanical';

  @override
  String get gridThemeBotanicalDescription =>
      'Pressed-leaf greens on herbarium paper.';

  @override
  String get gridThemeMonsoonTitle => 'Monsoon';

  @override
  String get gridThemeMonsoonDescription =>
      'Rain-season slate with a rust accent.';

  @override
  String get gridThemeTidewaterTitle => 'Tidewater';

  @override
  String get gridThemeTidewaterDescription => 'Sea glass and deep teal.';

  @override
  String get gridThemeMorningPourTitle => 'Morning Pour';

  @override
  String get gridThemeMorningPourDescription =>
      'Coffee and cream for early risers.';

  @override
  String get gridThemeDeepFieldTitle => 'Deep Field';

  @override
  String get gridThemeDeepFieldDescription =>
      'Lavender dusk, or deep space at night.';

  @override
  String get gridThemeMoonlightTitle => 'Moonlight';

  @override
  String get gridThemeMoonlightDescription => 'Silver-blue and moon gold.';

  @override
  String get gridThemeNightChartTitle => 'Night Chart';

  @override
  String get gridThemeNightChartDescription => 'Violet ink and antique gold.';

  @override
  String settingsGridDefault(String description) {
    return 'Default · $description';
  }
}
