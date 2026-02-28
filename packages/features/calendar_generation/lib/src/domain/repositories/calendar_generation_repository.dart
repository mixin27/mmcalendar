import '../entities/calendar_generation_request.dart';
import '../entities/calendar_page_model.dart';

abstract class CalendarGenerationRepository {
  List<CalendarPageModel> buildPreviewPages(CalendarGenerationRequest request);
}
