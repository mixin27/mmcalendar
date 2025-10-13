import '../repositories/widget_repository.dart';

class GetIsWidgetActive {
  final WidgetRepository repository;

  GetIsWidgetActive(this.repository);

  Future<bool> call() async {
    return await repository.isWidgetActive();
  }
}
