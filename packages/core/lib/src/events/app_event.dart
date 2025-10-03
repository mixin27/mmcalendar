/// Base class for all application events
abstract class AppEvent {
  final DateTime timestamp;

  AppEvent() : timestamp = DateTime.now();
}
