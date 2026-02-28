import 'package:get_it/get_it.dart';
import 'package:shared_core/shared_core.dart';

import '../data/repositories/calendar_generation_repository_impl.dart';
import '../domain/repositories/calendar_generation_repository.dart';
import '../domain/usecases/build_calendar_previews.dart';
import '../presentation/bloc/calendar_generation_bloc.dart';
import '../rendering/export/background_image_loader.dart';
import '../rendering/export/calendar_export_service.dart';
import '../rendering/image/calendar_image_renderer.dart';
import '../rendering/pdf/calendar_pdf_renderer.dart';
import '../rendering/page_model_builder.dart';

final getIt = GetIt.instance;

Future<void> initCalendarGenerationDependencies() async {
  if (!getIt.isRegistered<CalendarPageModelBuilder>()) {
    getIt.registerLazySingleton<CalendarPageModelBuilder>(
      CalendarPageModelBuilder.new,
    );
  }

  if (!getIt.isRegistered<CalendarGenerationRepository>()) {
    getIt.registerLazySingleton<CalendarGenerationRepository>(
      () => CalendarGenerationRepositoryImpl(getIt<CalendarPageModelBuilder>()),
    );
  }

  if (!getIt.isRegistered<BuildCalendarPreviews>()) {
    getIt.registerLazySingleton<BuildCalendarPreviews>(
      () => BuildCalendarPreviews(getIt<CalendarGenerationRepository>()),
    );
  }

  if (!getIt.isRegistered<BackgroundImageLoader>()) {
    getIt.registerLazySingleton<BackgroundImageLoader>(
      BackgroundImageLoader.new,
    );
  }

  if (!getIt.isRegistered<CalendarPdfRenderer>()) {
    getIt.registerLazySingleton<CalendarPdfRenderer>(
      () => CalendarPdfRenderer(getIt<BackgroundImageLoader>()),
    );
  }

  if (!getIt.isRegistered<CalendarImageRenderer>()) {
    getIt.registerLazySingleton<CalendarImageRenderer>(
      () => CalendarImageRenderer(getIt<BackgroundImageLoader>()),
    );
  }

  if (!getIt.isRegistered<CalendarExportService>()) {
    getIt.registerLazySingleton<CalendarExportService>(
      () => CalendarExportService(
        pdfRenderer: getIt<CalendarPdfRenderer>(),
        imageRenderer: getIt<CalendarImageRenderer>(),
      ),
    );
  }

  getIt.registerFactory<CalendarGenerationBloc>(
    () => CalendarGenerationBloc(
      buildCalendarPreviews: getIt<BuildCalendarPreviews>(),
      calendarDisplayConfigPort: getIt<CalendarDisplayConfigPort>(),
      analyticsPort: getIt<AnalyticsPort>(),
    ),
  );
}
