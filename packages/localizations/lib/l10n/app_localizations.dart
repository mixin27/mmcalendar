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

  /// Name of developer
  ///
  /// In en, this message translates to:
  /// **'Kyaw Zayar Tun'**
  String get developer;

  /// Home label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Views label
  ///
  /// In en, this message translates to:
  /// **'Views'**
  String get views;

  /// Converter label
  ///
  /// In en, this message translates to:
  /// **'Converter'**
  String get converter;

  /// Events label
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// Settings label
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Next Month label
  ///
  /// In en, this message translates to:
  /// **'Next Month'**
  String get next_month;

  /// Previous Month label
  ///
  /// In en, this message translates to:
  /// **'Previous Month'**
  String get previous_month;

  /// Go To Today label
  ///
  /// In en, this message translates to:
  /// **'Go To Today'**
  String get go_to_today;

  /// Today label
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Choose Your View label
  ///
  /// In en, this message translates to:
  /// **'Choose Your View'**
  String get choose_your_view;

  /// Year View label
  ///
  /// In en, this message translates to:
  /// **'Year View'**
  String get year_view;

  /// Week View label
  ///
  /// In en, this message translates to:
  /// **'Week View'**
  String get week_view;

  /// Day View label
  ///
  /// In en, this message translates to:
  /// **'Day View'**
  String get day_view;

  /// Convert label
  ///
  /// In en, this message translates to:
  /// **'Convert'**
  String get convert;

  /// Calculate label
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get calculate;

  /// Arithmetic label
  ///
  /// In en, this message translates to:
  /// **'Arithmetic'**
  String get arithmetic;

  /// Appearance label
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// Language label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Display Preferences label
  ///
  /// In en, this message translates to:
  /// **'Display Preferences'**
  String get display_preferences;

  /// Calendar Configuration label
  ///
  /// In en, this message translates to:
  /// **'Calendar Configuration'**
  String get calendar_configuration;

  /// Home Screen Widget label
  ///
  /// In en, this message translates to:
  /// **'Home Screen Widget'**
  String get home_screen_widget;

  /// About label
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Theme Preset label
  ///
  /// In en, this message translates to:
  /// **'Theme Preset'**
  String get theme_preset;

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

  /// Mahabote label
  ///
  /// In en, this message translates to:
  /// **'Mahabote'**
  String get mahabote;

  /// Year name label
  ///
  /// In en, this message translates to:
  /// **'Year Name'**
  String get year_name;

  /// Moon Phase label
  ///
  /// In en, this message translates to:
  /// **'Moon Phase'**
  String get moon_phase;

  /// Year label
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// Month label
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// Day label
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get day;

  /// Weekday label
  ///
  /// In en, this message translates to:
  /// **'Weekday'**
  String get weekday;

  /// Astrological Information label
  ///
  /// In en, this message translates to:
  /// **'Astrological Information'**
  String get astrological_information;

  /// Holidays label
  ///
  /// In en, this message translates to:
  /// **'Holidays'**
  String get holidays;

  /// Special Days label
  ///
  /// In en, this message translates to:
  /// **'Special Days'**
  String get special_days;

  /// Buddhist Era label
  ///
  /// In en, this message translates to:
  /// **'Buddhist Era (BE)'**
  String get buddhist_era;

  /// Sasana Year label
  ///
  /// In en, this message translates to:
  /// **'Sasana Year'**
  String get sasana_year;

  /// Myanmar Era label
  ///
  /// In en, this message translates to:
  /// **'Myanmar Era (ME)'**
  String get myanmar_era;
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
