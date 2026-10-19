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
  String get gridAuspiceGood => 'Good';

  @override
  String get gridAuspiceCareful => 'Careful';

  @override
  String get gridLayoutAlmanacTitle => 'Almanac';

  @override
  String get gridLayoutAlmanacDescription =>
      'Lunar day, moon, holidays and events, with a strip for Sabbath and good or careful days.';

  @override
  String get gridLayoutMonthRegionsTitle => 'Myanmar months';

  @override
  String get gridLayoutMonthRegionsDescription =>
      'Each Myanmar month tinted as a region, named where it begins.';

  @override
  String get gridLayoutFocusWeekTitle => 'Focus week';

  @override
  String get gridLayoutFocusWeekDescription =>
      'A compact month; the selected week opens to show the day\'s details.';

  @override
  String get gridLayoutAuspiceTitle => 'Auspice';

  @override
  String get gridLayoutAuspiceDescription =>
      'Days tinted by Yatyaza, Pyathada and the other astrological days.';

  @override
  String get gridLayoutMoonBandTitle => 'Moon band';

  @override
  String get gridLayoutMoonBandDescription =>
      'The moon as a band under each week, brightest at the full moon.';

  @override
  String get gridLayoutHeroTodayTitle => 'Hero today';

  @override
  String get gridLayoutHeroTodayDescription =>
      'A quiet month with the selected day as a large card under it.';

  @override
  String get gridLayoutWeekRibbonsTitle => 'Week ribbons';

  @override
  String get gridLayoutWeekRibbonsDescription =>
      'Each week as a card, with its events as bars under their days.';

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

  @override
  String get settingsCalendarStudioValue => 'Design and print';

  @override
  String get settingsShowInCalendar => 'Show in calendar';

  @override
  String get settingsDates => 'Dates';

  @override
  String get settingsUseDeviceTimezone => 'Use Device Timezone';

  @override
  String get settingsRefreshHolidayData => 'Refresh holiday data';

  @override
  String get settingsDebugBuildsOnly => 'Debug builds only.';

  @override
  String get settingsCustomColours => 'Custom colours…';

  @override
  String settingsThemePresetDefault(String name) {
    return '$name (default)';
  }

  @override
  String get settingsAppStyle => 'App style';

  @override
  String get settingsAppStyleAutomatic => 'Automatic';

  @override
  String get settingsAppStyleClear => 'Clear';

  @override
  String get settingsAppStyleMaterial => 'Material';

  @override
  String settingsAppStyleFooter(String style) {
    return 'Automatic uses Material on Android and Clear on iPhone, iPad, Mac and web (here: $style). Colours and content stay the same; bars, lists and controls change.';
  }

  @override
  String get settingsAppIcon => 'App Icon';

  @override
  String get settingsChooseAppIcon => 'Choose App Icon';

  @override
  String get settingsChooseAppIconSubtitle =>
      'Select your preferred launcher icon style.';

  @override
  String get settingsAppIconApplying => 'Please wait, applying app icon...';

  @override
  String get settingsAppIconUnsupported =>
      'App icon switching is not supported here.';

  @override
  String get settingsAppIconFailed => 'Failed to switch app icon.';

  @override
  String get settingsAppIconUpdated => 'App icon updated.';

  @override
  String get settingsAppIconCurrent => 'Current icon';

  @override
  String get settingsAppIconTapApply => 'Tap Apply to use this icon';

  @override
  String get settingsAppIconActive => 'Active';

  @override
  String get settingsAppIconCurrentShort => 'Current';

  @override
  String get settingsAppIconStandard => 'Standard icon';

  @override
  String get settingsAppIconAlternate => 'Alternate icon';

  @override
  String get appIconMoon => 'Moon';

  @override
  String get appIconForest => 'Forest';

  @override
  String get appIconMinimalFlat => 'Minimal Flat';

  @override
  String get appIconPremiumDark => 'Premium Dark';

  @override
  String get appIconTraditionalMyanmar => 'Traditional Myanmar Motif';

  @override
  String get languageZawgyi => 'Zawgyi';

  @override
  String get languageMon => 'Mon';

  @override
  String get languageShan => 'Shan';

  @override
  String get languageKaren => 'Karen';

  @override
  String get customColorsTitle => 'Custom colours';

  @override
  String get customColorsAccent => 'Accent';

  @override
  String get customColorsAccentFooter =>
      'Every other colour is made from this one, in light and dark.';

  @override
  String get customColorsMore => 'More colours…';

  @override
  String get customColorsPreview => 'Preview';

  @override
  String get customColorsAdvanced => 'Advanced';

  @override
  String get customColorsAdvancedFooter =>
      'Set any colour by hand. Choosing a new accent clears these.';

  @override
  String get customColorsReset => 'Reset to preset';

  @override
  String customColorsResetMessage(String preset) {
    return 'Your custom colours will be removed and $preset will be used again.';
  }

  @override
  String get customColorsPickTitle => 'Choose a colour';

  @override
  String get customColorPrimary => 'Primary';

  @override
  String get customColorOnPrimary => 'On primary';

  @override
  String get customColorSecondary => 'Secondary';

  @override
  String get customColorOnSecondary => 'On secondary';

  @override
  String get customColorTertiary => 'Tertiary';

  @override
  String get customColorOnTertiary => 'On tertiary';

  @override
  String get customColorError => 'Error';

  @override
  String get customColorOnError => 'On error';

  @override
  String get customColorSurface => 'Surface';

  @override
  String get customColorOnSurface => 'On surface';

  @override
  String get done => 'Done';

  @override
  String get widgetsStyle => 'Style';

  @override
  String get widgetsStyleFooter =>
      'New widgets start with this style. To change one widget, touch and hold it and choose Edit Widget (iPhone) or Reconfigure (Android).';

  @override
  String get widgetStyleApp => 'Follow app';

  @override
  String get widgetStyleAppDescription =>
      'The app\'s colours, light or dark with the system.';

  @override
  String get widgetStylePlain => 'Plain';

  @override
  String get widgetStylePlainDescription =>
      'Black and white, with red for holidays.';

  @override
  String get widgetsShow => 'Show on widgets';

  @override
  String get widgetsCountdown => 'Countdown counts to';

  @override
  String get widgetCountdownFullMoon => 'Next full moon';

  @override
  String get widgetCountdownNewMoon => 'Next new moon';

  @override
  String get widgetCountdownSabbath => 'Next Sabbath';

  @override
  String get widgetCountdownThingyan => 'Thingyan';

  @override
  String get widgetsOnScreen => 'On your home screen';

  @override
  String widgetsInstalled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count widgets',
      one: '1 widget',
      zero: 'None yet',
    );
    return '$_temp0';
  }

  @override
  String get widgetsInstalledTitle => 'Widgets added';

  @override
  String get widgetsRefresh => 'Refresh widgets';

  @override
  String get widgetsRefreshed => 'Widgets refreshed';

  @override
  String get widgetsHowToAdd => 'How to add a widget';

  @override
  String get widgetsHowToAddIos =>
      'Touch and hold an empty spot on the Home Screen, tap Edit, then Add Widget, and search for Myanmar Calendar. On the Lock Screen, touch and hold it and tap Customize.';

  @override
  String get widgetsHowToAddAndroid =>
      'Touch and hold an empty spot on the home screen, tap Widgets, and find Myanmar Calendar. Drag a widget to resize it.';

  @override
  String widgetsLanguageNote(String language) {
    return 'Widgets use the calendar language: $language.';
  }

  @override
  String get widgetsAddToHome => 'Add to home screen';

  @override
  String get widgetsAddToHomeFooter =>
      'Your launcher asks where to put it. You can resize it there.';

  @override
  String get widgetKindToday => 'Today';

  @override
  String get widgetKindMoon => 'Moon';

  @override
  String get widgetKindMonth => 'Month';

  @override
  String get widgetKindWeek => 'Week';

  @override
  String get widgetKindComingUp => 'Coming up';

  @override
  String get widgetKindAgenda => 'Agenda';

  @override
  String get widgetKindCountdown => 'Countdown';

  @override
  String get widgetKindAstrology => 'Astrology day';

  @override
  String get widgetKindYear => 'Myanmar year';

  @override
  String get holidayNameNewYear => 'New Year\'s Day';

  @override
  String get holidayAboutNewYear =>
      'The first day of the Gregorian year, a public holiday in Myanmar since 2018.';

  @override
  String get holidayNameIndependence => 'Independence Day';

  @override
  String get holidayAboutIndependence =>
      'Marks Myanmar\'s independence from British rule on 4 January 1948. Flags go up across the country, and many towns hold fairs and sports.';

  @override
  String get holidayNameUnion => 'Union Day';

  @override
  String get holidayAboutUnion =>
      'Commemorates the Panglong Agreement of 12 February 1947, when leaders of the Bamar, Shan, Kachin and Chin peoples agreed to form a union.';

  @override
  String get holidayNamePeasants => 'Peasants\' Day';

  @override
  String get holidayAboutPeasants =>
      'Honours the farmers who grow the country\'s food. It falls on 2 March.';

  @override
  String get holidayNameResistance => 'Resistance Day';

  @override
  String get holidayAboutResistance =>
      'Recalls the armed uprising against the Japanese occupation that began on 27 March 1945. It is also called Armed Forces Day.';

  @override
  String get holidayNameLabour => 'Labour Day';

  @override
  String get holidayAboutLabour =>
      'International Workers\' Day on 1 May, honouring working people.';

  @override
  String get holidayNameMartyrs => 'Martyrs\' Day';

  @override
  String get holidayAboutMartyrs =>
      'Remembers General Aung San and the cabinet members assassinated on 19 July 1947. Sirens sound at 10:37 am, the time of the attack.';

  @override
  String get holidayNameNationalDay => 'National Day';

  @override
  String get holidayAboutNationalDay =>
      'Commemorates the 1920 university students\' strike against the colonial education law, the start of the national movement. It falls on the 10th day of the waning moon of Tazaungmon.';

  @override
  String get holidayNameNewYearsEve => 'New Year\'s Eve';

  @override
  String get holidayAboutNewYearsEve =>
      'The last day of the Gregorian year, a public holiday since 2018.';

  @override
  String get holidayNamePublicHoliday => 'Public holiday';

  @override
  String get holidayAboutPublicHoliday =>
      'An extra day off announced by the government, often to replace a holiday that fell on a weekend.';

  @override
  String get holidayNameTabaung => 'Full Moon of Tabaung';

  @override
  String get holidayAboutTabaung =>
      'The full moon of Tabaung, the last month of the Myanmar year. Pagoda festivals are held across the country, the best known at Shwedagon.';

  @override
  String get holidayNameBuddhaDay => 'Buddha Day';

  @override
  String get holidayAboutBuddhaDay =>
      'The full moon of Kason marks the Buddha\'s birth, enlightenment and passing. People pour water on the Bodhi trees at pagodas.';

  @override
  String get holidayNameLentStart => 'Start of Buddhist Lent';

  @override
  String get holidayAboutLentStart =>
      'The full moon of Waso begins the three-month Buddhist Lent. Monks stay in their monasteries, and many people keep extra precepts.';

  @override
  String get holidayNameThadingyut => 'Thadingyut';

  @override
  String get holidayAboutThadingyut =>
      'The full moon of Thadingyut ends the three-month Buddhist Lent. Homes and pagodas are lit with candles and lanterns for three nights, and younger people pay respects to parents, teachers and elders.';

  @override
  String get holidayNameTazaungdaing => 'Tazaungdaing';

  @override
  String get holidayAboutTazaungdaing =>
      'The full moon of Tazaungmon closes the robe-offering season. It is a festival of lights, with fire balloons in Taunggyi and overnight contests weaving monks\' robes.';

  @override
  String get holidayNameChristmas => 'Christmas';

  @override
  String get holidayAboutChristmas =>
      'Christians celebrate the birth of Jesus on 25 December.';

  @override
  String get holidayNameDiwali => 'Diwali';

  @override
  String get holidayAboutDiwali =>
      'The Hindu festival of lights, celebrated with oil lamps, sweets and prayers.';

  @override
  String get holidayNameEidAlAdha => 'Eid al-Adha';

  @override
  String get holidayAboutEidAlAdha =>
      'The Muslim festival of sacrifice, at the end of the Hajj pilgrimage. Its date follows the Islamic lunar calendar.';

  @override
  String get holidayNameGoodFriday => 'Good Friday';

  @override
  String get holidayAboutGoodFriday =>
      'Christians remember the crucifixion of Jesus on the Friday before Easter.';

  @override
  String get holidayNameEaster => 'Easter';

  @override
  String get holidayAboutEaster =>
      'Christians celebrate the resurrection of Jesus.';

  @override
  String get holidayNameEidAlFitr => 'Eid al-Fitr';

  @override
  String get holidayAboutEidAlFitr =>
      'The Muslim festival that ends the fasting month of Ramadan. Its date follows the Islamic lunar calendar.';

  @override
  String get holidayNameMahathamaya => 'Mahathamaya Day';

  @override
  String get holidayAboutMahathamaya =>
      'The full moon of Nayon recalls the Buddha teaching the Mahasamaya Sutta to a great gathering of devas.';

  @override
  String get holidayNameGarudhamma => 'Garudhamma Day';

  @override
  String get holidayAboutGarudhamma =>
      'The full moon of Tawthalin recalls the Buddha giving the eight Garudhamma rules to the first nuns.';

  @override
  String get holidayNameMetta => 'Metta Day';

  @override
  String get holidayAboutMetta =>
      'The full moon of Wagaung, a day for practising loving-kindness.';

  @override
  String get holidayNameThingyan => 'Thingyan and Myanmar New Year';

  @override
  String get holidayAboutThingyan =>
      'The water festival that ends the Myanmar year: Akyo, Akya, Akyat and Atat, then New Year\'s Day. People splash water to wash away the old year, and offices stay closed through the festival and the days after New Year.';

  @override
  String get holidayNameKarenNewYear => 'Karen New Year';

  @override
  String get holidayAboutKarenNewYear =>
      'The Karen New Year, on the first day of the month of Pyatho, celebrated with traditional dances and music.';

  @override
  String get holidayNameChineseNewYear => 'Chinese New Year';

  @override
  String get holidayAboutChineseNewYear =>
      'The Lunar New Year, celebrated by Chinese communities with family reunions, lion dances and red envelopes.';

  @override
  String get holidayNameShanNewYear => 'Shan New Year';

  @override
  String get holidayAboutShanNewYear =>
      'The Shan New Year, on the first day of the waxing moon of Nadaw.';

  @override
  String get holidayNameTaungpyone => 'Taungpyone Festival';

  @override
  String get holidayAboutTaungpyone =>
      'The nat festival at Taungpyone near Mandalay, held in Wagaung for the two Taungpyone brother spirits.';

  @override
  String get holidayNameYadanagu => 'Yadanagu Festival';

  @override
  String get holidayAboutYadanagu =>
      'The nat festival at Yadanagu near Amarapura, held in Tawthalin for the mother of the Taungpyone brothers.';

  @override
  String get holidayNameMonNational => 'Mon National Day';

  @override
  String get holidayAboutMonNational =>
      'Falls on the full moon of Tabodwe and recalls the founding of Hanthawaddy (Bago).';

  @override
  String get holidayNameMothers => 'Mother\'s Day';

  @override
  String get holidayAboutMothers => 'A day to thank and honour mothers.';

  @override
  String get holidayNameFathers => 'Father\'s Day';

  @override
  String get holidayAboutFathers => 'A day to thank and honour fathers.';

  @override
  String get holidayNameAuthors => 'Authors\' Day';

  @override
  String get holidayAboutAuthors =>
      'Honours Myanmar writers and poets, with literary talks and book fairs.';

  @override
  String get holidayNameAungSanBirthday => 'General Aung San\'s Birthday';

  @override
  String get holidayAboutAungSanBirthday =>
      'General Aung San, the father of Myanmar\'s independence, was born on 13 February 1915. The day is also Children\'s Day.';

  @override
  String get holidayNameValentines => 'Valentine\'s Day';

  @override
  String get holidayAboutValentines => 'A day for sweethearts, on 14 February.';

  @override
  String get holidayNameAprilFools => 'April Fools\' Day';

  @override
  String get holidayAboutAprilFools => 'A day for practical jokes, on 1 April.';

  @override
  String get holidayNameEarth => 'Earth Day';

  @override
  String get holidayAboutEarth =>
      'A worldwide day for protecting the environment, on 22 April.';

  @override
  String get holidayNameRedCross => 'Red Cross Day';

  @override
  String get holidayAboutRedCross =>
      'World Red Cross Day, on 8 May, the birthday of its founder Henry Dunant.';

  @override
  String get holidayNameUnitedNations => 'United Nations Day';

  @override
  String get holidayAboutUnitedNations =>
      'Marks the founding of the United Nations on 24 October 1945.';

  @override
  String get holidayNameWorldTeachers => 'World Teachers\' Day';

  @override
  String get holidayAboutWorldTeachers =>
      'UNESCO\'s day for teachers, on 5 October.';

  @override
  String get holidayNameHalloween => 'Halloween';

  @override
  String get holidayAboutHalloween =>
      'An evening of costumes and treats, on 31 October.';

  @override
  String get holidaysSearchHint => 'Search holidays';

  @override
  String get holidaysFilterAll => 'All';

  @override
  String get holidaysFilterPublic => 'Public';

  @override
  String get holidaysFilterReligious => 'Religious';

  @override
  String get holidaysFilterCultural => 'Cultural';

  @override
  String get holidaysFilterAnniversary => 'Anniversaries';

  @override
  String get holidaysPublicHoliday => 'Public holiday';

  @override
  String get holidaysObservance => 'Observance';

  @override
  String get holidaysKindNational => 'National';

  @override
  String get holidaysKindReligious => 'Religious';

  @override
  String get holidaysKindCultural => 'Cultural';

  @override
  String get holidaysKindAnniversary => 'Anniversary';

  @override
  String get holidaysNextUp => 'Next holiday';

  @override
  String holidaysDaysOff(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days off',
      one: '1 day off',
    );
    return '$_temp0';
  }

  @override
  String holidaysDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String holidaysDaysShort(String count) {
    return '$count d';
  }

  @override
  String holidaysInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'in $count days',
      one: 'Tomorrow',
      zero: 'Today',
    );
    return '$_temp0';
  }

  @override
  String get holidaysNow => 'Now';

  @override
  String holidaysResults(int count, String year) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count holidays',
      one: '1 holiday',
      zero: 'No holidays',
    );
    return '$_temp0 in $year';
  }

  @override
  String holidaysNoResults(String year, String query) {
    return 'Nothing in $year matches “$query”.';
  }

  @override
  String get holidaysSearchAllYears => 'Search all years';

  @override
  String holidaysYearsRange(String from, String to) {
    return '$from to $to';
  }

  @override
  String get holidaysEarlier => 'Earlier this year';

  @override
  String get holidaysComingUp => 'Coming up';

  @override
  String get holidaysNextYear => 'Next';

  @override
  String get holidaysOtherYears => 'Other years';

  @override
  String get holidaysOpenInCalendar => 'Open in calendar';

  @override
  String holidaysNotThisYear(String year) {
    return 'Not in $year';
  }

  @override
  String get holidaysViewsSubtitle =>
      'Every holiday of the year, with reminders';

  @override
  String holidaysViewsFooter(int count, String year) {
    return '$count public holidays in $year.';
  }

  @override
  String get viewsCalendarGroup => 'Calendar';

  @override
  String get viewsExploreGroup => 'Explore';

  @override
  String get holidayRemindMe => 'Remind me';

  @override
  String get holidayReminderEvening => 'The evening before, at 6 pm';

  @override
  String get holidayReminderMorning => 'On the day, at 8 am';

  @override
  String get holidayReminderBoth => 'The evening before and on the day';

  @override
  String get holidayRemindersTitle => 'Reminders';

  @override
  String get holidayRemindersWhen => 'When';

  @override
  String get holidayRemindersEveningOption => 'The evening before';

  @override
  String get holidayRemindersMorningOption => 'On the morning';

  @override
  String get holidayRemindersBothOption => 'Both';

  @override
  String get holidayRemindersFollow => 'Follow';

  @override
  String get holidayRemindersAllPublic => 'All public holidays';

  @override
  String holidayRemindersAllPublicSubtitle(int count, String year) {
    return '$count in $year';
  }

  @override
  String get holidayRemindersFooter =>
      'Reminders cover the next 60 days and refresh each time you open the app.';

  @override
  String get holidayRemindersIncluded => 'Included in all public holidays';

  @override
  String get holidayRemindersPermissionDenied =>
      'Notifications are off for Myanmar Calendar. Turn them on in your phone\'s Settings to get reminders.';

  @override
  String holidayReminderTomorrow(String holiday) {
    return 'Tomorrow: $holiday';
  }

  @override
  String holidayReminderToday(String holiday) {
    return 'Today: $holiday';
  }

  @override
  String holidayReminderBodyPublic(String dates) {
    return 'Public holiday · $dates';
  }

  @override
  String get whatsNewTitle => 'What\'s new';

  @override
  String whatsNewBadge(String version) {
    return 'New in $version';
  }

  @override
  String whatsNewFromVersion(String version) {
    return 'From $version';
  }

  @override
  String whatsNewPageOf(int page, int count) {
    return '$page of $count';
  }

  @override
  String get whatsNewNext => 'Next';

  @override
  String get whatsNewDone => 'Done';

  @override
  String get whatsNewSeeAll => 'See all updates';

  @override
  String whatsNewThisUpdate(String version) {
    return 'Version $version · this update';
  }

  @override
  String whatsNewVersion(String version) {
    return 'Version $version';
  }

  @override
  String get whatsNewHolidaysTitle => 'Holidays';

  @override
  String get whatsNewHolidaysBody =>
      'Every holiday of the year in one place. Search in Myanmar or English, see what each day marks, and get a reminder the evening before.';

  @override
  String get whatsNewHolidaysAction => 'Explore holidays';

  @override
  String get whatsNewWidgetsTitle => 'New home-screen widgets';

  @override
  String get whatsNewWidgetsBody =>
      'Nine widgets in five styles, from today\'s date to a countdown to Thingyan. Tap any day to open it in the app.';

  @override
  String get whatsNewWidgetsAction => 'Widget settings';

  @override
  String get whatsNewWelcomeTitle => 'A new welcome';

  @override
  String get whatsNewWelcomeBody =>
      'New users get a short tour and a quick setup for language, look, privacy and reminders.';

  @override
  String get whatsNewThemesTitle => 'Calendar themes';

  @override
  String get whatsNewThemesBody =>
      'Twelve themes for the month grid, from Pagoda and Jade to Deep Field, each with light and dark colours.';

  @override
  String get whatsNewThemesAction => 'Choose a theme';

  @override
  String get whatsNewColorsTitle => 'Custom colours';

  @override
  String get whatsNewColorsBody =>
      'Pick one accent colour for the whole app, or fine-tune every colour in Advanced.';

  @override
  String get whatsNewColorsAction => 'Pick colours';

  @override
  String get whatsNewIconsTitle => 'App icons';

  @override
  String get whatsNewIconsBody =>
      'Choose from six app icons, including Moon, Forest and Traditional.';

  @override
  String get whatsNewIconsAction => 'Change icon';

  @override
  String get whatsNewStudioTitle => 'Calendar Studio';

  @override
  String get whatsNewStudioBody =>
      'Design wall, desk and social calendars from presets, then export print-ready PDFs and images.';

  @override
  String get whatsNewStudioAction => 'Open Studio';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get onboardingSetUp => 'Set up the app';

  @override
  String get onboardingNotNow => 'Not now';

  @override
  String get onboardingStart => 'Start';

  @override
  String onboardingStep(int step, int count) {
    return 'Step $step of $count';
  }

  @override
  String get onboardingWelcomeTitle => 'Welcome to Myanmar Calendar';

  @override
  String get onboardingWelcomeBody =>
      'Myanmar and Western dates side by side, for every day of the year.';

  @override
  String get onboardingCalendarsTitle => 'Two calendars in one';

  @override
  String get onboardingCalendarsBody =>
      'Every day shows its Myanmar date, moon phase and Sabbath, with astrology one tap away.';

  @override
  String get onboardingHolidaysTitle => 'Never miss a holiday';

  @override
  String get onboardingHolidaysBody =>
      'Browse and search every holiday, add your own events, and get a reminder the evening before.';

  @override
  String get onboardingYoursTitle => 'Make it yours';

  @override
  String get onboardingYoursBody =>
      'Choose colours and calendar themes, add home-screen widgets, and design printable calendars in Calendar Studio.';

  @override
  String get onboardingLanguagesTitle => 'Choose your languages';

  @override
  String get onboardingAppLanguage => 'App language';

  @override
  String get onboardingCalendarLanguageFooter =>
      'Month names, holidays and moon phases use the calendar language.';

  @override
  String get onboardingLookTitle => 'Pick a look';

  @override
  String get onboardingThemeAutomatic => 'Automatic';

  @override
  String get onboardingThemeLight => 'Light';

  @override
  String get onboardingThemeDark => 'Dark';

  @override
  String get onboardingColour => 'Colour';

  @override
  String get onboardingColourFooter =>
      'More colours and calendar themes are in Settings › Appearance.';

  @override
  String get onboardingPrivacyTitle => 'Your calendar stays on your phone';

  @override
  String get onboardingPrivacyBody =>
      'Events and notes never leave your device. You can help improve the app by sharing anonymous data.';

  @override
  String get onboardingUsageStats => 'Usage statistics';

  @override
  String get onboardingUsageStatsSubtitle =>
      'Which screens are used, never what\'s on them';

  @override
  String get onboardingCrashReports => 'Crash reports';

  @override
  String get onboardingCrashReportsSubtitle => 'Sent only when the app crashes';

  @override
  String get onboardingPrivacyFooter =>
      'Change this any time in Settings › Privacy & Data.';

  @override
  String get onboardingNotificationsTitle => 'Reminders when they matter';

  @override
  String get onboardingEventReminders => 'Event reminders';

  @override
  String get onboardingEventRemindersSubtitle =>
      'At the time you choose for each event';

  @override
  String get onboardingHolidayReminders => 'Holiday reminders';

  @override
  String get onboardingHolidayRemindersSubtitle =>
      'The evening before holidays you follow';

  @override
  String get onboardingAllowNotifications => 'Allow notifications';

  @override
  String get onboardingDoneTitle => 'You\'re all set';

  @override
  String onboardingDoneToday(String date) {
    return 'Today is $date.';
  }

  @override
  String get onboardingWidgetTipTitle => 'Tip: add a widget';

  @override
  String get onboardingWidgetTipBody =>
      'See the Myanmar date on your home screen. Touch and hold an empty spot, then add Myanmar Calendar.';

  @override
  String get viewsMyanmarMonth => 'Myanmar Month';

  @override
  String get viewsMyanmarMonthSubtitle =>
      'The month by waxing and waning fortnight';

  @override
  String get viewsAgenda => 'Agenda';

  @override
  String get viewsAgendaSubtitle =>
      'Holidays, Sabbath, moon days and your events ahead';

  @override
  String get dayDetailsComingUp => 'Coming up';

  @override
  String get dayDetailsNagahleCompass => 'Dragon\'s head';

  @override
  String get dayDetailsNoAstrologicalDays => 'No special astrological days';

  @override
  String get repeatOn => 'On';

  @override
  String get repeatEveryWeek => 'Every week';

  @override
  String repeatEveryWeeks(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Every $countString weeks';
  }

  @override
  String get repeatEnds => 'Ends';

  @override
  String get repeatEndsOnDate => 'On a date';

  @override
  String get repeatEndsAfter => 'After';

  @override
  String repeatTimes(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString times';
  }

  @override
  String repeatUntil(String date) {
    return 'until $date';
  }

  @override
  String get repeatTimePerDay => 'A time for each day';

  @override
  String get repeatTimePerDayNote =>
      'Days with different times are saved as one weekly event per time.';

  @override
  String repeatEventsCreated(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString events created';
  }

  @override
  String get repeatPerDay => 'Per day';

  @override
  String get repeatSpecificDates => 'Specific dates';

  @override
  String get repeatChooseDates => 'Choose dates';

  @override
  String repeatDatesCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString dates';
  }

  @override
  String eventsRepeatsOnDates(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'on $countString dates';
  }

  @override
  String get eventsAddMoreDates => 'Add more dates';
}
