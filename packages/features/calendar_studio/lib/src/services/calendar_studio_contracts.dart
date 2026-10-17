import 'dart:typed_data';

import 'package:flutter/widgets.dart' show BuildContext;

import '../models/calendar_studio_document.dart';
import '../models/calendar_studio_types.dart';
import '../theme/calendar_studio_theme.dart';
import 'calendar_studio_template_bundle.dart';

/// Canonical data supplied by the host. Studio only decides whether to show it.
class CalendarStudioDayData {
  const CalendarStudioDayData({
    required this.date,
    required this.gregorianLabel,
    this.myanmarLabel,
    this.moonLabel,
    this.holidayLabel,
    this.astrologyLabel,
    this.events = const [],
    this.moonPhase,
    this.fortnightDay,
    this.isSabbath = false,
    this.isSabbathEve = false,
    this.hasAstrology = false,
  });
  final DateTime date;
  final String gregorianLabel;
  final String? myanmarLabel;
  final String? moonLabel;
  final String? holidayLabel;
  final String? astrologyLabel;
  final List<String> events;
  final int? moonPhase;
  final int? fortnightDay;
  final bool isSabbath;
  final bool isSabbathEve;
  final bool hasAstrology;
}

abstract interface class CalendarStudioDataProvider {
  Future<List<CalendarStudioDayData>> daysFor(
    CalendarStudioSource source, {
    required int month,
  });
}

abstract interface class CalendarStudioProjectStore {
  Future<List<CalendarStudioProject>> list();
  Future<CalendarStudioProject?> load(String id);
  Future<void> save(CalendarStudioProject project);
  Future<void> delete(String id);
}

abstract interface class CalendarStudioAssetStore {
  Future<CalendarStudioAsset> importAsset(CalendarStudioAssetInput input);
  Future<List<int>?> loadBytes(String assetId);
  Future<CalendarStudioAsset?> load(String assetId);
  Future<void> deleteUnusedAssets(Set<String> usedAssetIds);
}

class CalendarStudioAssetInput {
  const CalendarStudioAssetInput({
    required this.name,
    required this.bytes,
    this.mimeType,
    this.width = 0,
    this.height = 0,
  });
  final String name;
  final List<int> bytes;
  final String? mimeType;
  final int width;
  final int height;
}

class CalendarStudioAsset {
  const CalendarStudioAsset({
    required this.id,
    required this.name,
    required this.width,
    required this.height,
    this.localPath,
  });
  final String id;
  final String name;
  final int width;
  final int height;
  final String? localPath;
}

enum CalendarStudioImageSource { gallery, camera, files }

class CalendarStudioPickedImage {
  const CalendarStudioPickedImage({
    required this.name,
    required this.bytes,
    this.mimeType,
  });
  final String name;
  final Uint8List bytes;
  final String? mimeType;
}

/// Lets the host offer platform pickers (gallery, camera) without the Studio
/// package depending on them. Studio downsizes whatever is returned.
abstract interface class CalendarStudioImagePicker {
  /// Sources to offer, in display order. Studio skips the chooser sheet
  /// when only one is available.
  List<CalendarStudioImageSource> get sources;

  /// Returns null when the user cancels. [maxDimension] is a hint for
  /// pickers that can downscale natively.
  Future<CalendarStudioPickedImage?> pick(
    CalendarStudioImageSource source, {
    required int maxDimension,
  });
}

class CalendarStudioEditedImage {
  const CalendarStudioEditedImage({required this.bytes, this.editorState});
  final Uint8List bytes;

  /// Opaque, re-applicable edit history. Studio stores it on the block and
  /// passes it back with the original bytes so edits stay non-destructive.
  final String? editorState;
}

/// Optional rich image editing (crop, filters, adjustments) supplied by the
/// host, e.g. backed by `pro_image_editor`.
abstract interface class CalendarStudioImageEditor {
  /// Opens the editor over [original]. Returns null when the user cancels.
  Future<CalendarStudioEditedImage?> edit(
    BuildContext context, {
    required Uint8List original,
    String? editorState,
    required int maxDimension,
  });
}

/// Removes the background from a photo or logo, on device or via a backend
/// the host controls. Studio never embeds AI keys.
abstract interface class CalendarStudioBackgroundRemover {
  /// Whether removal can run right now (platform, OS version, model download,
  /// feature flags). Studio hides the action when false.
  Future<bool> isAvailable();

  /// Returns a transparent PNG, or null when no subject was found.
  Future<Uint8List?> removeBackground(Uint8List image);
}

enum CalendarStudioTextKind { title, quote, caption }

/// Calendar context for text suggestions. Only canonical, already-visible
/// data is shared; no user events or personal data are included.
class CalendarStudioTextSuggestionRequest {
  const CalendarStudioTextSuggestionRequest({
    required this.kind,
    required this.language,
    required this.year,
    required this.month,
    required this.pageLabel,
    required this.templateName,
    this.currentText = '',
    this.holidays = const [],
    this.sabbathDays = const [],
  });
  final CalendarStudioTextKind kind;
  final CalendarStudioLanguage language;
  final int year;
  final int month;
  final String pageLabel;
  final String templateName;
  final String currentText;

  /// Public holiday names on this page's month.
  final List<String> holidays;

  /// Gregorian days of the month that are Sabbath (ဥပုသ်) days.
  final List<int> sabbathDays;
}

abstract interface class CalendarStudioTextSuggester {
  Future<bool> isAvailable();

  /// Returns short candidates the user may tap to apply.
  Future<List<String>> suggest(CalendarStudioTextSuggestionRequest request);
}

/// Optional AI capabilities. Each is shown only when supplied and available.
class CalendarStudioAiConfiguration {
  const CalendarStudioAiConfiguration({
    this.backgroundRemover,
    this.textSuggester,
  });
  final CalendarStudioBackgroundRemover? backgroundRemover;
  final CalendarStudioTextSuggester? textSuggester;
}

abstract interface class CalendarStudioExportDelivery {
  Future<void> deliver(
    CalendarStudioExportArtifact artifact, {
    CalendarStudioExportDestination destination =
        CalendarStudioExportDestination.save,
  });
}

enum CalendarStudioExportDestination { save, share, print }

class CalendarStudioExportArtifact {
  const CalendarStudioExportArtifact({
    required this.name,
    required this.mimeType,
    required this.bytes,
  });
  final String name;
  final String mimeType;
  final List<int> bytes;
}

/// Dependency boundary for a host app. All ports are optional except projects.
class CalendarStudioConfiguration {
  const CalendarStudioConfiguration({
    required this.projects,
    this.templates,
    this.calendarData,
    this.assets,
    this.exportDelivery,
    this.imagePicker,
    this.imageEditor,
    this.ai = const CalendarStudioAiConfiguration(),
    this.pickProjectFile,
    this.pickTemplateFile,
    this.featureName = 'Calendar Studio',
    this.now,
    this.appearance = CalendarStudioAppearance.system,
    this.lightTokens = CalendarStudioTokens.light,
    this.darkTokens = CalendarStudioTokens.dark,
    this.chrome = CalendarStudioChrome.material,
    this.fontFamily = 'Noto Sans Myanmar',
    this.fontFamilyFallback,
  });
  final CalendarStudioProjectStore projects;

  /// Where saved and imported templates live; without it Studio offers no
  /// "Save as template" or "My templates".
  final CalendarStudioTemplateStore? templates;
  final CalendarStudioDataProvider? calendarData;
  final CalendarStudioAssetStore? assets;
  final CalendarStudioExportDelivery? exportDelivery;

  /// Optional; defaults to a files-only picker.
  final CalendarStudioImagePicker? imagePicker;

  /// Optional; when null the image inspector offers only fit and opacity.
  final CalendarStudioImageEditor? imageEditor;

  /// AI features; all off unless the host supplies providers.
  final CalendarStudioAiConfiguration ai;

  /// Optional; returns the bytes of a `.mmcstudio` file the user picked.
  /// Defaults to the system file picker.
  final Future<Uint8List?> Function()? pickProjectFile;

  /// Optional; returns the bytes of a `.mmctemplate` file the user picked.
  /// Defaults to the system file picker.
  final Future<Uint8List?> Function()? pickTemplateFile;
  final String featureName;
  final DateTime Function()? now;
  final CalendarStudioAppearance appearance;
  final CalendarStudioTokens lightTokens;
  final CalendarStudioTokens darkTokens;

  /// Bars, sheets, lists and controls follow the host app's style.
  final CalendarStudioChrome chrome;

  /// Font for Studio's chrome (designs keep their own fonts).
  final String fontFamily;
  final List<String>? fontFamilyFallback;

  /// The same services with the host's current look.
  CalendarStudioConfiguration withLook({
    CalendarStudioAppearance? appearance,
    CalendarStudioTokens? lightTokens,
    CalendarStudioTokens? darkTokens,
    CalendarStudioChrome? chrome,
    String? fontFamily,
    List<String>? fontFamilyFallback,
  }) => CalendarStudioConfiguration(
    projects: projects,
    templates: templates,
    calendarData: calendarData,
    assets: assets,
    exportDelivery: exportDelivery,
    imagePicker: imagePicker,
    imageEditor: imageEditor,
    ai: ai,
    pickProjectFile: pickProjectFile,
    pickTemplateFile: pickTemplateFile,
    featureName: featureName,
    now: now,
    appearance: appearance ?? this.appearance,
    lightTokens: lightTokens ?? this.lightTokens,
    darkTokens: darkTokens ?? this.darkTokens,
    chrome: chrome ?? this.chrome,
    fontFamily: fontFamily ?? this.fontFamily,
    fontFamilyFallback: fontFamilyFallback ?? this.fontFamilyFallback,
  );
}
