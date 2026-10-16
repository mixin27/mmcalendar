import 'dart:typed_data';

import 'package:flutter/widgets.dart' show BuildContext;

import '../models/calendar_studio_document.dart';
import '../models/calendar_studio_types.dart';
import '../theme/calendar_studio_theme.dart';

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
    this.calendarData,
    this.assets,
    this.exportDelivery,
    this.imagePicker,
    this.imageEditor,
    this.featureName = 'Calendar Studio',
    this.classicImport,
    this.now,
    this.appearance = CalendarStudioAppearance.system,
    this.lightTokens = CalendarStudioTokens.light,
    this.darkTokens = CalendarStudioTokens.dark,
  });
  final CalendarStudioProjectStore projects;
  final CalendarStudioDataProvider? calendarData;
  final CalendarStudioAssetStore? assets;
  final CalendarStudioExportDelivery? exportDelivery;

  /// Optional; defaults to a files-only picker.
  final CalendarStudioImagePicker? imagePicker;

  /// Optional; when null the image inspector offers only fit and opacity.
  final CalendarStudioImageEditor? imageEditor;
  final String featureName;
  final Future<List<CalendarStudioProject>> Function()? classicImport;
  final DateTime Function()? now;
  final CalendarStudioAppearance appearance;
  final CalendarStudioTokens lightTokens;
  final CalendarStudioTokens darkTokens;
}
