class AppConstants {
  // App Information
  static const String appName = 'Myanmar Calendar';
  static const String appVersion = '2.0.0';
  static const String appBuildNumber = '200';

  // Spacing and sizing
  static const double paddingXSmall = 4.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  // Database
  static const String databaseName = 'myanmar_calendar.db';
  static const int databaseVersion = 1;

  // Date Formats
  static const String dateFormatFull = 'EEEE, MMMM d, yyyy';
  static const String dateFormatShort = 'MMM d, yyyy';
  static const String dateFormatNumeric = 'dd/MM/yyyy';

  // Calendar
  static const int calendarMonthsToPreload = 1;
  static const int calendarMaxYearRange = 100;

  // UI
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;
  static const double defaultElevation = 2.0;

  // Animation
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 400);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Cache
  static const int maxCacheSize = 100;
  static const Duration cacheExpiration = Duration(hours: 24);
}
