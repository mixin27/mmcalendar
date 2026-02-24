import 'package:equatable/equatable.dart';

/// Base class for analytics events
abstract class AnalyticsEvent extends Equatable {
  /// Event name
  final String name;

  /// Event parameters - must be [Map<String, Object>] for Firebase compatibility
  final Map<String, Object> parameters;

  const AnalyticsEvent({required this.name, this.parameters = const {}});

  @override
  List<Object?> get props => [name, parameters];

  /// Convert dynamic map to Firebase-compatible Object map
  Map<String, Object> sanitizeParameters(Map<String, dynamic> params) {
    return params.map((key, value) {
      if (value == null) {
        return MapEntry(key, 'null');
      }
      if (value is String || value is int || value is double || value is bool) {
        return MapEntry(key, value as Object);
      }
      // Convert complex types to string representation
      return MapEntry(key, value.toString());
    });
  }
}

/// Screen view event
class ScreenViewEvent extends AnalyticsEvent {
  final String screenName;
  final String? screenClass;

  const ScreenViewEvent({required this.screenName, this.screenClass})
    : super(name: 'screen_view', parameters: const {});

  @override
  Map<String, Object> get parameters {
    final params = <String, Object>{'screen_name': screenName};
    if (screenClass != null) {
      params['screen_class'] = screenClass!;
    }
    return params;
  }

  @override
  List<Object?> get props => [screenName, screenClass];
}

/// Button click event
class ButtonClickEvent extends AnalyticsEvent {
  final String buttonName;
  final String? buttonLocation;
  final Map<String, Object>? additionalData;

  const ButtonClickEvent({
    required this.buttonName,
    this.buttonLocation,
    this.additionalData,
  }) : super(name: 'button_click', parameters: const {});

  @override
  Map<String, Object> get parameters {
    final params = <String, Object>{'button_name': buttonName};
    if (buttonLocation != null) {
      params['button_location'] = buttonLocation!;
    }
    if (additionalData != null) {
      params.addAll(additionalData!);
    }
    return params;
  }

  @override
  List<Object?> get props => [buttonName, buttonLocation, additionalData];
}

/// Date selection event
class DateSelectionEvent extends AnalyticsEvent {
  final String selectedDate;
  final String calendarType;
  final String? dateFormat;

  const DateSelectionEvent({
    required this.selectedDate,
    required this.calendarType,
    this.dateFormat,
  }) : super(name: 'date_selected', parameters: const {});

  @override
  Map<String, Object> get parameters {
    final params = <String, Object>{
      'selected_date': selectedDate,
      'calendar_type': calendarType,
    };
    if (dateFormat != null) {
      params['date_format'] = dateFormat!;
    }
    return params;
  }

  @override
  List<Object?> get props => [selectedDate, calendarType, dateFormat];
}

/// Settings change event
class SettingsChangeEvent extends AnalyticsEvent {
  final String settingName;
  final Object oldValue;
  final Object newValue;

  const SettingsChangeEvent({
    required this.settingName,
    required this.oldValue,
    required this.newValue,
  }) : super(name: 'settings_changed', parameters: const {});

  @override
  Map<String, Object> get parameters => {
    'setting_name': settingName,
    'old_value': oldValue.toString(),
    'new_value': newValue.toString(),
  };

  @override
  List<Object?> get props => [settingName, oldValue, newValue];
}

/// Theme change event
class ThemeChangeEvent extends AnalyticsEvent {
  final String themeMode;
  final String? themePreset;

  const ThemeChangeEvent({required this.themeMode, this.themePreset})
    : super(name: 'theme_changed', parameters: const {});

  @override
  Map<String, Object> get parameters {
    final params = <String, Object>{'theme_mode': themeMode};
    if (themePreset != null) {
      params['theme_preset'] = themePreset!;
    }
    return params;
  }

  @override
  List<Object?> get props => [themeMode, themePreset];
}

/// Language change event
class LanguageChangeEvent extends AnalyticsEvent {
  final String languageCode;
  final String languageName;

  const LanguageChangeEvent({
    required this.languageCode,
    required this.languageName,
  }) : super(name: 'language_changed', parameters: const {});

  @override
  Map<String, Object> get parameters => {
    'language_code': languageCode,
    'language_name': languageName,
  };

  @override
  List<Object?> get props => [languageCode, languageName];
}

/// Feature toggle event
class FeatureToggleEvent extends AnalyticsEvent {
  final String featureName;
  final bool enabled;

  const FeatureToggleEvent({required this.featureName, required this.enabled})
    : super(name: 'feature_toggled', parameters: const {});

  @override
  Map<String, Object> get parameters => {
    'feature_name': featureName,
    'enabled': enabled ? "true" : "false",
  };

  @override
  List<Object?> get props => [featureName, enabled];
}

/// Share event
class ShareEvent extends AnalyticsEvent {
  final String contentType;
  final String platform;
  final Map<String, Object>? metadata;

  const ShareEvent({
    required this.contentType,
    required this.platform,
    this.metadata,
  }) : super(name: 'content_shared', parameters: const {});

  @override
  Map<String, Object> get parameters {
    final params = <String, Object>{
      'content_type': contentType,
      'platform': platform,
    };
    if (metadata != null) {
      params.addAll(metadata!);
    }
    return params;
  }

  @override
  List<Object?> get props => [contentType, platform, metadata];
}

/// Error/Exception event
class ExceptionEvent extends AnalyticsEvent {
  final String exceptionName;
  final String description;
  final String? stackTrace;

  const ExceptionEvent({
    required this.exceptionName,
    required this.description,
    this.stackTrace,
  }) : super(name: 'exception_occurred', parameters: const {});

  @override
  Map<String, Object> get parameters {
    final params = <String, Object>{
      'exception_name': exceptionName,
      'description': description,
    };
    if (stackTrace != null) {
      params['stack_trace'] = stackTrace!;
    }
    return params;
  }

  @override
  List<Object?> get props => [exceptionName, description, stackTrace];
}

/// Widget interaction event
class WidgetInteractionEvent extends AnalyticsEvent {
  final String widgetName;
  final String actionType;
  final Map<String, Object>? metadata;

  const WidgetInteractionEvent({
    required this.widgetName,
    required this.actionType,
    this.metadata,
  }) : super(name: 'widget_interaction', parameters: const {});

  @override
  Map<String, Object> get parameters {
    final params = <String, Object>{
      'widget_name': widgetName,
      'action_type': actionType,
    };
    if (metadata != null) {
      params.addAll(metadata!);
    }
    return params;
  }

  @override
  List<Object?> get props => [widgetName, actionType, metadata];
}

/// Background task metrics event
class BackgroundMetricsEvent extends AnalyticsEvent {
  final int successCount;
  final String lastUpdate;
  final int lastDurationMs;
  final String healthStatus;

  const BackgroundMetricsEvent({
    required this.successCount,
    required this.lastUpdate,
    required this.lastDurationMs,
    required this.healthStatus,
  }) : super(name: 'background_metrics', parameters: const {});

  @override
  Map<String, Object> get parameters => {
    'success_count': successCount,
    'last_update': lastUpdate,
    'last_duration_ms': lastDurationMs,
    'health_status': healthStatus,
  };

  @override
  List<Object?> get props => [
    successCount,
    lastUpdate,
    lastDurationMs,
    healthStatus,
  ];
}

/// Background error metrics event
class BackgroundErrorMetricsEvent extends AnalyticsEvent {
  final int errorCount;
  final String lastError;
  final String lastErrorTime;

  const BackgroundErrorMetricsEvent({
    required this.errorCount,
    required this.lastError,
    required this.lastErrorTime,
  }) : super(name: 'background_errors', parameters: const {});

  @override
  Map<String, Object> get parameters => {
    'error_count': errorCount,
    'last_error': lastError,
    'last_error_time': lastErrorTime,
  };

  @override
  List<Object?> get props => [errorCount, lastError, lastErrorTime];
}

/// App started event with background health
class AppStartedEvent extends AnalyticsEvent {
  final String backgroundHealth;
  final int backgroundSuccessCount;
  final int backgroundErrorCount;
  final String? lastUpdate;

  const AppStartedEvent({
    required this.backgroundHealth,
    required this.backgroundSuccessCount,
    required this.backgroundErrorCount,
    this.lastUpdate,
  }) : super(name: 'app_started', parameters: const {});

  @override
  Map<String, Object> get parameters {
    final params = <String, Object>{
      'background_health': backgroundHealth,
      'background_success_count': backgroundSuccessCount,
      'background_error_count': backgroundErrorCount,
    };
    if (lastUpdate != null) {
      params['last_background_update'] = lastUpdate!;
    }
    return params;
  }

  @override
  List<Object?> get props => [
    backgroundHealth,
    backgroundSuccessCount,
    backgroundErrorCount,
    lastUpdate,
  ];
}
