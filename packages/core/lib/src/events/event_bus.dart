import 'dart:async';
import 'package:event_bus/event_bus.dart' as eb;

import 'app_event.dart';

/// Application-wide event bus for loose coupling between features
class AppEventBus {
  static final eb.EventBus _eventBus = eb.EventBus();

  /// Listen to events of type [T]
  static Stream<T> on<T extends AppEvent>() {
    return _eventBus.on<T>();
  }

  /// Fire an event to all listeners
  static void fire(AppEvent event) {
    _eventBus.fire(event);
  }

  /// Destroy the event bus (for testing)
  static void destroy() {
    _eventBus.destroy();
  }
}
