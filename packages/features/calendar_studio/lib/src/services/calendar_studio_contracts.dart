import '../models/calendar_studio_document.dart';
import '../models/calendar_studio_types.dart';

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
  });
  final DateTime date;
  final String gregorianLabel;
  final String? myanmarLabel;
  final String? moonLabel;
  final String? holidayLabel;
  final String? astrologyLabel;
  final List<String> events;
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
  Future<void> deleteUnusedAssets(Set<String> usedAssetIds);
}

class CalendarStudioAssetInput {
  const CalendarStudioAssetInput({
    required this.name,
    required this.bytes,
    this.mimeType,
  });
  final String name;
  final List<int> bytes;
  final String? mimeType;
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

abstract interface class CalendarStudioExportDelivery {
  Future<void> deliver(CalendarStudioExportArtifact artifact);
}

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
    this.featureName = 'Calendar Studio',
    this.classicImport,
    this.now,
  });
  final CalendarStudioProjectStore projects;
  final CalendarStudioDataProvider? calendarData;
  final CalendarStudioAssetStore? assets;
  final CalendarStudioExportDelivery? exportDelivery;
  final String featureName;
  final Future<List<CalendarStudioProject>> Function()? classicImport;
  final DateTime Function()? now;
}
