import '../app_event.dart';

/// Fired when app language is changed
class LanguageChangedEvent extends AppEvent {
  final String languageCode;

  LanguageChangedEvent(this.languageCode);
}

/// Fired when calendar language is changed
class CalendarLanguageChangedEvent extends AppEvent {
  final String calendarLanguage;

  CalendarLanguageChangedEvent(this.calendarLanguage);
}

/// Fired when settings are updated
class SettingsUpdatedEvent extends AppEvent {
  final String key;
  final dynamic value;

  SettingsUpdatedEvent(this.key, this.value);
}
