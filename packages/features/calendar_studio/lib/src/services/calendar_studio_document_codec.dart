import '../models/calendar_studio_document.dart';
import '../models/calendar_studio_types.dart';

/// Versioned JSON representation used by storage adapters and future migrations.
abstract final class CalendarStudioDocumentCodec {
  static Map<String, Object?> encode(CalendarStudioProject project) => {
    'schemaVersion': project.schemaVersion,
    'id': project.id,
    'name': project.name,
    'templateId': project.templateId,
    'createdAt': project.createdAt.toIso8601String(),
    'updatedAt': project.updatedAt.toIso8601String(),
    'source': _source(project.source),
    'defaultExportPreset': _preset(project.defaultExportPreset),
    if (project.lastExport case final record?)
      'lastExport': {
        'exportedAt': record.exportedAt.toIso8601String(),
        'presetLabel': record.presetLabel,
        'format': record.format.name,
        'pageCount': record.pageCount,
        'fileName': record.fileName,
      },
    'pages': project.pages.map(_page).toList(),
  };

  static Map<String, Object?> _preset(CalendarStudioExportPreset preset) => {
    'id': preset.id,
    'label': preset.label,
    'format': preset.format.name,
    'dpi': preset.dpi,
    'width': preset.width,
    'height': preset.height,
  };

  static CalendarStudioExportRecord? _decodeRecord(Object? value) {
    if (value is! Map) return null;
    try {
      return CalendarStudioExportRecord(
        exportedAt: DateTime.parse(value['exportedAt'] as String),
        presetLabel: value['presetLabel'] as String,
        format: CalendarStudioExportFormat.values.byName(
          value['format'] as String,
        ),
        pageCount: value['pageCount'] as int,
        fileName: value['fileName'] as String,
      );
    } catch (_) {
      return null;
    }
  }

  static CalendarStudioExportPreset _decodePreset(Object? value) {
    if (value is! Map) return CalendarStudioExportPreset.a4Pdf;
    try {
      return CalendarStudioExportPreset(
        id: value['id'] as String,
        label: value['label'] as String,
        format: CalendarStudioExportFormat.values.byName(
          value['format'] as String,
        ),
        dpi: value['dpi'] as int,
        width: value['width'] as int,
        height: value['height'] as int,
      );
    } catch (_) {
      return CalendarStudioExportPreset.a4Pdf;
    }
  }

  static CalendarStudioProject decode(Map<String, dynamic> value) =>
      CalendarStudioProject(
        id: value['id'] as String,
        name: value['name'] as String,
        templateId: value['templateId'] as String,
        schemaVersion: value['schemaVersion'] as int? ?? 1,
        createdAt: DateTime.parse(value['createdAt'] as String),
        updatedAt: DateTime.parse(value['updatedAt'] as String),
        source: _decodeSource(
          Map<String, dynamic>.from(value['source'] as Map),
        ),
        pages: _decodePages(
          value['pages'] as List,
          _decodeSource(Map<String, dynamic>.from(value['source'] as Map)),
        ),
        defaultExportPreset: _decodePreset(value['defaultExportPreset']),
        lastExport: _decodeRecord(value['lastExport']),
      );

  static Map<String, Object?> _source(CalendarStudioSource source) => {
    'year': source.year,
    'month': source.month,
    'period': source.period.name,
    'language': source.language.name,
    'weekStartsMonday': source.weekStartsMonday,
    'timeZoneLabel': source.timeZoneLabel,
    'showMyanmarDate': source.showMyanmarDate,
    'showMoonPhases': source.showMoonPhases,
    'showHolidays': source.showHolidays,
    'showAstrology': source.showAstrology,
    'showEvents': source.showEvents,
  };
  static CalendarStudioSource _decodeSource(Map<String, dynamic> value) =>
      CalendarStudioSource(
        year: value['year'] as int,
        month: value['month'] as int? ?? 1,
        period: CalendarStudioPeriod.values.byName(
          value['period'] as String? ?? 'year',
        ),
        language: CalendarStudioLanguage.values.byName(
          value['language'] as String? ?? 'both',
        ),
        weekStartsMonday: value['weekStartsMonday'] as bool? ?? false,
        timeZoneLabel:
            value['timeZoneLabel'] as String? ?? 'Myanmar Time (UTC+6:30)',
        showMyanmarDate: value['showMyanmarDate'] as bool? ?? true,
        showMoonPhases: value['showMoonPhases'] as bool? ?? true,
        showHolidays: value['showHolidays'] as bool? ?? true,
        showAstrology: value['showAstrology'] as bool? ?? true,
        showEvents: value['showEvents'] as bool? ?? true,
      );
  static Map<String, Object?> _page(CalendarStudioPage page) => {
    'id': page.id,
    'label': page.label,
    'year': page.year,
    'month': page.month,
    'canvas': {
      'width': page.canvas.width,
      'height': page.canvas.height,
      'safeInset': page.canvas.safeInset,
      'bleed': page.canvas.bleed,
      'backgroundColor': page.canvas.backgroundColor,
    },
    'blocks': page.blocks.map(_block).toList(),
  };
  static List<CalendarStudioPage> _decodePages(
    List<dynamic> values,
    CalendarStudioSource source,
  ) => List.generate(
    values.length,
    (index) => _decodePage(
      Map<String, dynamic>.from(values[index] as Map),
      fallbackYear: source.year + ((source.month - 1 + index) ~/ 12),
      fallbackMonth: ((source.month - 1 + index) % 12) + 1,
    ),
  );

  static CalendarStudioPage _decodePage(
    Map<String, dynamic> value, {
    required int fallbackYear,
    required int fallbackMonth,
  }) {
    final canvas = Map<String, dynamic>.from(value['canvas'] as Map);
    return CalendarStudioPage(
      id: value['id'] as String,
      label: value['label'] as String,
      year: value['year'] as int? ?? fallbackYear,
      month: value['month'] as int? ?? fallbackMonth,
      canvas: StudioCanvas(
        width: (canvas['width'] as num).toDouble(),
        height: (canvas['height'] as num).toDouble(),
        safeInset: (canvas['safeInset'] as num?)?.toDouble() ?? .04,
        bleed: (canvas['bleed'] as num?)?.toDouble() ?? 0,
        backgroundColor: canvas['backgroundColor'] as int? ?? 0xFFFFFFFF,
      ),
      blocks: (value['blocks'] as List)
          .map((item) => _decodeBlock(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }

  static Map<String, Object?> _block(CalendarStudioBlock block) => {
    'id': block.id,
    'type': block.type.name,
    'name': block.name,
    'bounds': {
      'left': block.bounds.left,
      'top': block.bounds.top,
      'width': block.bounds.width,
      'height': block.bounds.height,
    },
    'rotation': block.rotation,
    'zIndex': block.zIndex,
    'visible': block.visible,
    'locked': block.locked,
    'style': block.style,
    'content': block.content,
  };
  static CalendarStudioBlock _decodeBlock(Map<String, dynamic> value) {
    final bounds = Map<String, dynamic>.from(value['bounds'] as Map);
    return CalendarStudioBlock(
      id: value['id'] as String,
      type: CalendarStudioBlockType.values.byName(value['type'] as String),
      name: value['name'] as String,
      bounds: StudioRect(
        left: (bounds['left'] as num).toDouble(),
        top: (bounds['top'] as num).toDouble(),
        width: (bounds['width'] as num).toDouble(),
        height: (bounds['height'] as num).toDouble(),
      ),
      rotation: (value['rotation'] as num?)?.toDouble() ?? 0,
      zIndex: value['zIndex'] as int? ?? 0,
      visible: value['visible'] as bool? ?? true,
      locked: value['locked'] as bool? ?? false,
      style: Map<String, Object?>.from(value['style'] as Map? ?? const {}),
      content: Map<String, Object?>.from(value['content'] as Map? ?? const {}),
    );
  }
}
