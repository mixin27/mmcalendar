import '../repositories/widget_repository.dart';

class ScheduleUpdates {
  final WidgetRepository repository;

  ScheduleUpdates(this.repository);

  Future<void> call() async {
    await repository.scheduleWidgetUpdates();
  }
}
