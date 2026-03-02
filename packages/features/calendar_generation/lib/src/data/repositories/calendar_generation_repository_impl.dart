import '../../domain/entities/calendar_generation_request.dart';
import '../../domain/entities/calendar_page_model.dart';
import '../../domain/repositories/calendar_generation_repository.dart';
import '../../rendering/page_model_builder.dart';

class CalendarGenerationRepositoryImpl implements CalendarGenerationRepository {
  CalendarGenerationRepositoryImpl(this._pageModelBuilder);

  final CalendarPageModelBuilder _pageModelBuilder;

  @override
  List<CalendarPageModel> buildPreviewPages(CalendarGenerationRequest request) {
    return _pageModelBuilder.build(request);
  }
}
