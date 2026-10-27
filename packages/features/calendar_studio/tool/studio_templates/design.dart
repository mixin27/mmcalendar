import 'page_builder.dart';

/// What a design needs to know while it lays out a page.
class DesignContext {
  DesignContext({required this.template, required this.photo});

  /// Building the reusable `.mmctemplate` page: no month-specific text.
  final bool template;

  /// The next photo slot's asset id; only previews have photos.
  final String? Function() photo;
}

/// One design in the pack: a cover and twelve months for the year project,
/// and one month page for the reusable template.
abstract class StudioTemplateDesign {
  const StudioTemplateDesign();

  /// Stable id, used in file names and the template id.
  String get id;
  String get name;
  String get topic;
  String get description;
  StudioFormat get format;
  StudioPalette get palette;

  /// The closest built-in preset, so Studio's re-theme works.
  String get basePresetId;
  List<String> get moods;

  void cover(PageBuilder page, DesignContext context);

  /// [month] is 1–12. With [DesignContext.template] the page must suit any
  /// month, as the template repeats it.
  void month(PageBuilder page, int month, DesignContext context);

  /// The month whose layout the template uses.
  int get templateMonth => 1;
}
