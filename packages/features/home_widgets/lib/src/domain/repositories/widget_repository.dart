import '../entities/widget_config.dart';
import '../entities/widget_data.dart';

abstract class WidgetRepository {
  /// Get current widget data for today
  Future<WidgetData> getWidgetData(DateTime date);

  /// Update widget on home screen
  Future<void> updateWidget(WidgetData data);

  /// Get widget configuration
  Future<WidgetConfig> getWidgetConfig();

  /// Save widget configuration
  Future<void> saveWidgetConfig(WidgetConfig config);

  /// Schedule periodic widget updates
  Future<void> scheduleWidgetUpdates();

  /// Cancel scheduled widget updates
  Future<void> cancelWidgetUpdates();

  /// Force widget refresh
  Future<void> refreshWidget();

  /// Check if widget is currently displayed
  Future<bool> isWidgetActive();

  /// Check if updates are scheduled
  Future<bool> isUpdateScheduled();
}
