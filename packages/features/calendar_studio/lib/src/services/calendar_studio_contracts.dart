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
  final String featureName;
  final Future<List<CalendarStudioProject>> Function()? classicImport;
  final DateTime Function()? now;
  final CalendarStudioAppearance appearance;
  final CalendarStudioTokens lightTokens;
  final CalendarStudioTokens darkTokens;
}
