import '../entities/widget_data.dart';
import '../repositories/widget_repository.dart';

class GetWidgetData {
  final WidgetRepository repository;

  GetWidgetData(this.repository);

  Future<WidgetData> call(DateTime date) async {
    return await repository.getWidgetData(date);
  }
}
