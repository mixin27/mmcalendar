/// A standalone calendar creation workspace.
///
/// The host application supplies canonical calendar data, project persistence,
/// assets, and export delivery through [CalendarStudioConfiguration]. The
/// package never calculates or mutates canonical dates itself.
library;

export 'src/models/calendar_studio_document.dart';
export 'src/models/calendar_studio_project_theme.dart';
export 'src/models/calendar_studio_types.dart';
export 'src/models/calendar_studio_user_template.dart';
export 'src/services/calendar_studio_arrange.dart';
export 'src/services/calendar_studio_cache.dart';
export 'src/services/calendar_studio_contracts.dart';
export 'src/services/calendar_studio_controller.dart';
export 'src/services/calendar_studio_document_codec.dart';
export 'src/services/calendar_studio_export_service.dart';
export 'src/services/calendar_studio_image_import.dart';
export 'src/services/calendar_studio_preflight.dart';
export 'src/services/calendar_studio_project_bundle.dart';
export 'src/services/calendar_studio_template_bundle.dart';
export 'src/services/calendar_studio_transform.dart';
export 'src/services/calendar_studio_raster_renderer.dart';
export 'src/services/myanmar_calendar_studio_data_provider.dart';
export 'src/templates/calendar_studio_bindings.dart';
export 'src/templates/calendar_studio_templates.dart';
export 'src/templates/calendar_studio_user_templates.dart';
export 'src/templates/calendar_studio_theme_spec.dart';
export 'src/theme/calendar_studio_font_catalog.dart';
export 'src/theme/calendar_studio_theme.dart';
export 'src/widgets/calendar_studio_decorations.dart';
export 'src/widgets/calendar_studio_scene.dart';
export 'src/presentation/calendar_studio_page.dart';
