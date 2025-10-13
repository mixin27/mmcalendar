import '../repositories/widget_repository.dart';

class UpdateWidget {
  final WidgetRepository repository;

  UpdateWidget(this.repository);

  Future<void> call() async {
    final today = DateTime.now();
    final data = await repository.getWidgetData(today);
    await repository.updateWidget(data);
  }
}
