import '../../domain/entities/widget_config.dart';
import '../../domain/entities/widget_data.dart';
import '../../domain/repositories/widget_repository.dart';
import '../datasources/widget_local_datasource.dart';

class WidgetRepositoryImpl implements WidgetRepository {
  final WidgetLocalDataSource localDataSource;

  WidgetRepositoryImpl(this.localDataSource);

  @override
  Future<WidgetData> getWidgetData(DateTime date) async {
    // Get current config to determine language
    final config = await localDataSource.getWidgetConfig();
    return await localDataSource.generateWidgetDataWithLanguage(
      date,
      config.language,
    );
  }

  @override
  Future<void> updateWidget(WidgetData data) async {
    final config = await localDataSource.getWidgetConfig();
    await localDataSource.updateWidgetWithConfig(data, config);
  }

  @override
  Future<WidgetConfig> getWidgetConfig() async {
    return await localDataSource.getWidgetConfig();
  }

  @override
  Future<void> saveWidgetConfig(WidgetConfig config) async {
    await localDataSource.saveWidgetConfig(config);
  }

  @override
  Future<void> scheduleWidgetUpdates() async {
    final config = await localDataSource.getWidgetConfig();
    await localDataSource.warmupTimeline(config);
    await localDataSource.scheduleUpdates();
    await localDataSource.markUpdatesScheduled(true);
  }

  @override
  Future<void> cancelWidgetUpdates() async {
    await localDataSource.cancelUpdates();
    await localDataSource.markUpdatesScheduled(false);
  }

  @override
  Future<void> refreshWidget() async {
    final config = await getWidgetConfig();
    await localDataSource.warmupTimeline(config);
    final widgetData = await localDataSource.generateWidgetDataWithLanguage(
      DateTime.now(),
      config.language,
    );
    await localDataSource.updateWidgetWithConfig(widgetData, config);
  }

  @override
  Future<bool> isWidgetActive() async {
    return await localDataSource.isWidgetActive();
  }

  @override
  Future<bool> isUpdateScheduled() async {
    return await localDataSource.isUpdateScheduled();
  }
}
