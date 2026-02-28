import '../entities/calendar_generation_request.dart';
import '../entities/calendar_page_model.dart';
import '../repositories/calendar_generation_repository.dart';

class BuildCalendarPreviews {
  const BuildCalendarPreviews(this.repository);

  final CalendarGenerationRepository repository;

  List<CalendarPageModel> call(CalendarGenerationRequest request) {
    return repository.buildPreviewPages(request);
  }
}
