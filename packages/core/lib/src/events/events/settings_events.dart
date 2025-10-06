import '../app_event.dart';

/// Fired when app language is changed
class LanguageChangedEvent extends AppEvent {
  final String languageCode;

  LanguageChangedEvent(this.languageCode);
}

/// Fired when settings are updated
class SettingsUpdatedEvent extends AppEvent {
  final String key;
  final dynamic value;

  SettingsUpdatedEvent(this.key, this.value);
}
