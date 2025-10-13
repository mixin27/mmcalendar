import '../entities/widget_config.dart';
import '../repositories/widget_repository.dart';

class ConfigureWidget {
  final WidgetRepository repository;

  ConfigureWidget(this.repository);

  Future<WidgetConfig> getConfig() async {
    return await repository.getWidgetConfig();
  }

  Future<void> saveConfig(WidgetConfig config) async {
    await repository.saveWidgetConfig(config);
    // Trigger widget refresh with new config
    await repository.refreshWidget();
  }
}
