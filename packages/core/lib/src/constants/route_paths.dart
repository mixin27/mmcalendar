class RoutePaths {
  // Main Routes
  static const String splash = '/splash';
  static const String home = '/home';
  static const String views = '/views';
  static const String events = '/events';
  static const String converter = '/converter';
  static const String settings = '/settings';
  static const String consent = '/consent';

  // Calendar Routes
  static const String dayDetails = 'day-details';

  // Views Routes
  static const String yearView = 'year';
  static const String weekView = 'week';
  static const String dayView = 'day';

  // Events sub-routes - NEW
  static const String createEvent = 'create';
  static const String editEvent = ':id';
  static const String eventDetail = ':id/detail';
  static const String eventCategories = 'categories';

  // Settings Routes
  static const String widgets = 'widgets';
  static const String privacyPolicy = 'privacy-policy';
  static const String languageSettings = 'language';
  static const String themeSettings = 'theme';
  static const String calendarConfig = 'calendar-config';
  static const String displayPreferences = 'display-preferences';
  static const String about = 'about';
}
