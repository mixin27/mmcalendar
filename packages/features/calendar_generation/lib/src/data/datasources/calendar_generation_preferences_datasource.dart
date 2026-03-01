import 'dart:convert';

import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/calendar_generation_mode.dart';
import '../../domain/entities/calendar_generation_request.dart';
import '../../domain/entities/calendar_generation_template.dart';
import '../../domain/entities/calendar_export_tuning.dart';
import '../../domain/entities/calendar_image_quality.dart';
import '../../domain/entities/calendar_landscape_decoration_area_side.dart';
import '../../domain/entities/calendar_overlay_element.dart';
import '../../domain/entities/calendar_page_orientation.dart';
import '../../domain/entities/calendar_paper_size.dart';
import '../../domain/entities/calendar_preview_theme.dart';

class CalendarGenerationPreferencesDataSource {
  CalendarGenerationPreferencesDataSource(this._preferences);

  final SharedPreferences _preferences;

  Future<void> saveRequest(CalendarGenerationRequest request) async {
    final payload = _encodeRequest(request, includeDateSelection: true);

    await _preferences.setString(
      StorageKeys.calendarGenerationSettings,
      jsonEncode(payload),
    );
  }

  CalendarGenerationRequest restoreRequest(CalendarGenerationRequest fallback) {
    final raw = _preferences.getString(StorageKeys.calendarGenerationSettings);
    if (raw == null || raw.isEmpty) {
      return fallback;
    }

    try {
      final map = jsonDecode(raw);
      if (map is! Map<String, dynamic>) {
        return fallback;
      }

      return _decodeRequest(
        map,
        fallback: fallback,
        includeDateSelection: true,
      );
    } catch (_) {
      return fallback;
    }
  }

  List<CalendarGenerationTemplate> getTemplates() {
    final raw = _preferences.getString(StorageKeys.calendarGenerationTemplates);
    if (raw == null || raw.isEmpty) {
      return const <CalendarGenerationTemplate>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <CalendarGenerationTemplate>[];
      }

      final templates = <CalendarGenerationTemplate>[];
      for (final item in decoded) {
        if (item is! Map<String, dynamic>) {
          continue;
        }
        final template = _decodeTemplate(item);
        if (template != null) {
          templates.add(template);
        }
      }

      templates.sort(
        (left, right) => right.updatedAt.compareTo(left.updatedAt),
      );
      return templates;
    } catch (_) {
      return const <CalendarGenerationTemplate>[];
    }
  }

  Future<List<CalendarGenerationTemplate>> saveTemplate({
    required String name,
    required CalendarGenerationRequest request,
  }) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      return getTemplates();
    }

    final templates = getTemplates().toList(growable: true);
    final now = DateTime.now();
    final existingIndex = templates.indexWhere(
      (template) => template.name.toLowerCase() == normalizedName.toLowerCase(),
    );

    final template = CalendarGenerationTemplate(
      id: existingIndex >= 0
          ? templates[existingIndex].id
          : _generateTemplateId(normalizedName, now),
      name: normalizedName,
      language: request.language,
      mode: request.mode,
      showHolidays: request.showHolidays,
      showAstrology: request.showAstrology,
      showWesternDates: request.showWesternDates,
      showMyanmarDates: request.showMyanmarDates,
      firstDayOfWeek: request.firstDayOfWeek,
      paperSize: request.paperSize,
      pageOrientation: request.pageOrientation,
      landscapeDecorationAreaSide: request.landscapeDecorationAreaSide,
      imageQuality: request.imageQuality,
      exportTuning: request.exportTuning,
      theme: request.theme,
      updatedAt: now,
    );

    if (existingIndex >= 0) {
      templates[existingIndex] = template;
    } else {
      templates.add(template);
    }

    await _saveTemplates(templates);
    return getTemplates();
  }

  bool hasTemplateName(String name, {String? excludingTemplateId}) {
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) {
      return false;
    }

    for (final template in getTemplates()) {
      if (excludingTemplateId != null && template.id == excludingTemplateId) {
        continue;
      }
      if (template.name.trim().toLowerCase() == normalized) {
        return true;
      }
    }
    return false;
  }

  Future<List<CalendarGenerationTemplate>> deleteTemplate(
    String templateId,
  ) async {
    final templates = getTemplates()
        .where((template) => template.id != templateId)
        .toList(growable: false);
    await _saveTemplates(templates);
    return getTemplates();
  }

  Future<List<CalendarGenerationTemplate>> renameTemplate({
    required String templateId,
    required String name,
  }) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      return getTemplates();
    }

    final templates = getTemplates().toList(growable: true);
    final index = templates.indexWhere((template) => template.id == templateId);
    if (index < 0) {
      return templates;
    }

    final target = templates[index];
    templates[index] = CalendarGenerationTemplate(
      id: target.id,
      name: normalizedName,
      language: target.language,
      mode: target.mode,
      showHolidays: target.showHolidays,
      showAstrology: target.showAstrology,
      showWesternDates: target.showWesternDates,
      showMyanmarDates: target.showMyanmarDates,
      firstDayOfWeek: target.firstDayOfWeek,
      paperSize: target.paperSize,
      pageOrientation: target.pageOrientation,
      landscapeDecorationAreaSide: target.landscapeDecorationAreaSide,
      imageQuality: target.imageQuality,
      exportTuning: target.exportTuning,
      theme: target.theme,
      updatedAt: DateTime.now(),
    );

    await _saveTemplates(templates);
    return getTemplates();
  }

  CalendarGenerationRequest applyTemplate({
    required CalendarGenerationRequest baseRequest,
    required CalendarGenerationTemplate template,
  }) {
    return baseRequest.copyWith(
      language: template.language,
      mode: template.mode,
      showHolidays: template.showHolidays,
      showAstrology: template.showAstrology,
      showWesternDates: template.showWesternDates,
      showMyanmarDates: template.showMyanmarDates,
      firstDayOfWeek: template.firstDayOfWeek,
      paperSize: template.paperSize,
      pageOrientation: template.pageOrientation,
      landscapeDecorationAreaSide: template.landscapeDecorationAreaSide,
      imageQuality: template.imageQuality,
      exportTuning: template.exportTuning,
      theme: template.theme,
    );
  }

  Future<void> _saveTemplates(
    List<CalendarGenerationTemplate> templates,
  ) async {
    final payload = templates
        .map(
          (template) => <String, dynamic>{
            'id': template.id,
            'name': template.name,
            'updatedAt': template.updatedAt.toIso8601String(),
            'config': _encodeTemplateConfig(template),
          },
        )
        .toList(growable: false);

    await _preferences.setString(
      StorageKeys.calendarGenerationTemplates,
      jsonEncode(payload),
    );
  }

  Map<String, dynamic> _encodeTemplateConfig(
    CalendarGenerationTemplate template,
  ) {
    return <String, dynamic>{
      'mode': template.mode.name,
      'language': template.language.code,
      'showHolidays': template.showHolidays,
      'showAstrology': template.showAstrology,
      'showWesternDates': template.showWesternDates,
      'showMyanmarDates': template.showMyanmarDates,
      'firstDayOfWeek': template.firstDayOfWeek,
      'paperSize': template.paperSize.name,
      'pageOrientation': template.pageOrientation.name,
      'landscapeDecorationAreaSide': template.landscapeDecorationAreaSide.name,
      'imageQuality': template.imageQuality.name,
      'exportTuning': _encodeExportTuning(template.exportTuning),
      'theme': _encodeTheme(template.theme),
    };
  }

  Map<String, dynamic> _encodeRequest(
    CalendarGenerationRequest request, {
    required bool includeDateSelection,
  }) {
    return <String, dynamic>{
      'mode': request.mode.name,
      'language': request.language.code,
      if (includeDateSelection) ...{
        'year': request.year,
        'month': request.month,
      },
      'showHolidays': request.showHolidays,
      'showAstrology': request.showAstrology,
      'showWesternDates': request.showWesternDates,
      'showMyanmarDates': request.showMyanmarDates,
      'firstDayOfWeek': request.firstDayOfWeek,
      'paperSize': request.paperSize.name,
      'pageOrientation': request.pageOrientation.name,
      'landscapeDecorationAreaSide': request.landscapeDecorationAreaSide.name,
      'imageQuality': request.imageQuality.name,
      'exportTuning': _encodeExportTuning(request.exportTuning),
      'overlayElementsByMonth': _encodeOverlayElementsByMonth(
        request.overlayElementsByMonth,
      ),
      'theme': _encodeTheme(request.theme),
    };
  }

  Map<String, dynamic> _encodeExportTuning(CalendarExportTuning tuning) {
    return <String, dynamic>{
      'dpi': tuning.dpi,
      'jpegQuality': tuning.jpegQuality,
      'targetSizeKb': tuning.targetSizeKb,
      'enableAdaptiveCompression': tuning.enableAdaptiveCompression,
    };
  }

  Map<String, dynamic> _encodeTheme(CalendarPreviewTheme theme) {
    return <String, dynamic>{
      'backgroundColorValue': theme.backgroundColorValue,
      'foregroundColorValue': theme.foregroundColorValue,
      'accentColorValue': theme.accentColorValue,
      'backgroundImageUrl': theme.backgroundImageUrl,
      'backgroundImageOpacity': theme.backgroundImageOpacity,
      'backgroundImageFit': theme.backgroundImageFit.name,
      'backgroundImageAlignment': theme.backgroundImageAlignment.name,
      'backgroundImageUrlsByMonth': theme.backgroundImageUrlsByMonth.map(
        (key, value) => MapEntry('$key', value),
      ),
    };
  }

  CalendarGenerationTemplate? _decodeTemplate(Map<String, dynamic> map) {
    final id = map['id']?.toString().trim();
    final name = map['name']?.toString().trim();
    final config = map['config'];
    if (id == null || id.isEmpty || name == null || name.isEmpty) {
      return null;
    }
    if (config is! Map<String, dynamic>) {
      return null;
    }

    final fallbackRequest = _defaultTemplateFallbackRequest();
    final parsedRequest = _decodeRequest(
      config,
      fallback: fallbackRequest,
      includeDateSelection: false,
    );

    return CalendarGenerationTemplate(
      id: id,
      name: name,
      language: parsedRequest.language,
      mode: parsedRequest.mode,
      showHolidays: parsedRequest.showHolidays,
      showAstrology: parsedRequest.showAstrology,
      showWesternDates: parsedRequest.showWesternDates,
      showMyanmarDates: parsedRequest.showMyanmarDates,
      firstDayOfWeek: parsedRequest.firstDayOfWeek,
      paperSize: parsedRequest.paperSize,
      pageOrientation: parsedRequest.pageOrientation,
      landscapeDecorationAreaSide: parsedRequest.landscapeDecorationAreaSide,
      imageQuality: parsedRequest.imageQuality,
      exportTuning: parsedRequest.exportTuning,
      theme: parsedRequest.theme,
      updatedAt:
          DateTime.tryParse(map['updatedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  CalendarGenerationRequest _defaultTemplateFallbackRequest() {
    return CalendarGenerationRequest(
      mode: CalendarGenerationMode.month,
      year: DateTime.now().year,
      month: DateTime.now().month,
      language: Language.english,
      calendarConfig: const CalendarConfig(),
      useDeviceTimezone: true,
      showHolidays: true,
      showAstrology: true,
      showWesternDates: true,
      showMyanmarDates: true,
      firstDayOfWeek: 1,
      theme: CalendarPreviewTheme.defaults(),
      paperSize: CalendarPaperSize.a4,
      pageOrientation: CalendarPageOrientation.portrait,
      landscapeDecorationAreaSide: CalendarLandscapeDecorationAreaSide.right,
      imageQuality: CalendarImageQuality.print,
      exportTuning: CalendarExportTuning(
        dpi: CalendarImageQuality.print.defaultDpi,
        jpegQuality: CalendarImageQuality.print.defaultJpegQuality,
        targetSizeKb: CalendarImageQuality.print.defaultTargetSizeKb,
        enableAdaptiveCompression: true,
      ),
    );
  }

  CalendarGenerationRequest _decodeRequest(
    Map<String, dynamic> map, {
    required CalendarGenerationRequest fallback,
    required bool includeDateSelection,
  }) {
    final mode = _parseMode(map['mode']) ?? fallback.mode;
    final language = _parseLanguage(map['language']) ?? fallback.language;
    final year = _parseInt(map['year']) ?? fallback.year;
    final month = _parseInt(map['month']) ?? fallback.month;
    final paperSize = _parsePaperSize(map['paperSize']) ?? fallback.paperSize;
    final orientation =
        _parseOrientation(map['pageOrientation']) ?? fallback.pageOrientation;
    final landscapeDecorationAreaSide =
        _parseLandscapeDecorationAreaSide(map['landscapeDecorationAreaSide']) ??
        fallback.landscapeDecorationAreaSide;
    final quality =
        _parseImageQuality(map['imageQuality']) ?? fallback.imageQuality;
    final exportTuning =
        _parseExportTuning(map['exportTuning']) ?? fallback.exportTuning;
    final overlayElementsByMonth = _parseOverlayElementsByMonth(
      map['overlayElementsByMonth'],
    );
    final theme = _parseTheme(map['theme'], fallback.theme);

    return fallback.copyWith(
      language: language,
      mode: mode,
      year: includeDateSelection ? year : fallback.year,
      month: includeDateSelection ? month : fallback.month,
      showHolidays: _parseBool(map['showHolidays']) ?? fallback.showHolidays,
      showAstrology: _parseBool(map['showAstrology']) ?? fallback.showAstrology,
      showWesternDates:
          _parseBool(map['showWesternDates']) ?? fallback.showWesternDates,
      showMyanmarDates:
          _parseBool(map['showMyanmarDates']) ?? fallback.showMyanmarDates,
      firstDayOfWeek:
          _parseInt(map['firstDayOfWeek']) ?? fallback.firstDayOfWeek,
      paperSize: paperSize,
      pageOrientation: orientation,
      landscapeDecorationAreaSide: landscapeDecorationAreaSide,
      imageQuality: quality,
      exportTuning: exportTuning,
      overlayElementsByMonth: overlayElementsByMonth,
      theme: theme,
    );
  }

  Map<String, dynamic> _encodeOverlayElementsByMonth(
    Map<int, List<CalendarOverlayElement>> source,
  ) {
    return source.map(
      (month, elements) => MapEntry(
        '$month',
        elements
            .map(
              (element) => <String, dynamic>{
                'id': element.id,
                'type': element.type.name,
                'x': element.x,
                'y': element.y,
                'scale': element.scale,
                'rotation': element.rotation,
                'text': element.text,
                'stickerKey': element.stickerKey,
                'imageSource': element.imageSource,
                'colorValue': element.colorValue,
                'fontWeightValue': element.fontWeightValue,
                'italic': element.italic,
                'letterSpacing': element.letterSpacing,
                'backgroundColorValue': element.backgroundColorValue,
                'shadowColorValue': element.shadowColorValue,
                'shadowBlur': element.shadowBlur,
                'shadowOffsetX': element.shadowOffsetX,
                'shadowOffsetY': element.shadowOffsetY,
                'baseSize': element.baseSize,
                'opacity': element.opacity,
                'locked': element.locked,
              },
            )
            .toList(growable: false),
      ),
    );
  }

  Map<int, List<CalendarOverlayElement>> _parseOverlayElementsByMonth(
    Object? raw,
  ) {
    if (raw is! Map<String, dynamic>) {
      return const <int, List<CalendarOverlayElement>>{};
    }

    final parsed = <int, List<CalendarOverlayElement>>{};
    for (final entry in raw.entries) {
      final month = int.tryParse(entry.key);
      final value = entry.value;
      if (month == null || month < 1 || month > 12 || value is! List) {
        continue;
      }

      final elements = <CalendarOverlayElement>[];
      for (final item in value) {
        if (item is! Map<String, dynamic>) {
          continue;
        }
        final element = _parseOverlayElement(item);
        if (element != null) {
          elements.add(element);
        }
      }
      if (elements.isNotEmpty) {
        parsed[month] = elements;
      }
    }
    return parsed;
  }

  CalendarOverlayElement? _parseOverlayElement(Map<String, dynamic> raw) {
    final id = raw['id']?.toString().trim();
    final typeName = raw['type']?.toString();
    final type = _firstWhereOrNull<CalendarOverlayElementType>(
      CalendarOverlayElementType.values,
      (value) => value.name == typeName,
    );
    final x = _parseDouble(raw['x']);
    final y = _parseDouble(raw['y']);
    if (id == null || id.isEmpty || type == null || x == null || y == null) {
      return null;
    }

    return CalendarOverlayElement(
      id: id,
      type: type,
      x: x.clamp(0.0, 1.0),
      y: y.clamp(0.0, 1.0),
      scale: (_parseDouble(raw['scale']) ?? 1.0).clamp(0.2, 8.0),
      rotation: _parseDouble(raw['rotation']) ?? 0.0,
      text: raw['text']?.toString(),
      stickerKey: raw['stickerKey']?.toString(),
      imageSource: raw['imageSource']?.toString(),
      colorValue: _parseInt(raw['colorValue']) ?? 0xFF1F2937,
      fontWeightValue: (_parseInt(raw['fontWeightValue']) ?? 700)
          .clamp(100, 900)
          .toInt(),
      italic: _parseBool(raw['italic']) ?? false,
      letterSpacing: (_parseDouble(raw['letterSpacing']) ?? 0.0)
          .clamp(-2.0, 8.0)
          .toDouble(),
      backgroundColorValue: _parseInt(raw['backgroundColorValue']),
      shadowColorValue: _parseInt(raw['shadowColorValue']),
      shadowBlur: (_parseDouble(raw['shadowBlur']) ?? 0.0)
          .clamp(0.0, 32.0)
          .toDouble(),
      shadowOffsetX: (_parseDouble(raw['shadowOffsetX']) ?? 0.0)
          .clamp(-40.0, 40.0)
          .toDouble(),
      shadowOffsetY: (_parseDouble(raw['shadowOffsetY']) ?? 0.0)
          .clamp(-40.0, 40.0)
          .toDouble(),
      baseSize: (_parseDouble(raw['baseSize']) ?? 28).clamp(8, 360).toDouble(),
      opacity: (_parseDouble(raw['opacity']) ?? 1).clamp(0.0, 1.0).toDouble(),
      locked: _parseBool(raw['locked']) ?? false,
    );
  }

  CalendarPreviewTheme _parseTheme(
    Object? rawTheme,
    CalendarPreviewTheme fallback,
  ) {
    if (rawTheme is! Map<String, dynamic>) {
      return fallback;
    }

    final monthlyImages = <int, String>{};
    final rawMonthly = rawTheme['backgroundImageUrlsByMonth'];
    if (rawMonthly is Map<String, dynamic>) {
      for (final entry in rawMonthly.entries) {
        final month = int.tryParse(entry.key);
        final value = entry.value?.toString();
        if (month != null &&
            month >= 1 &&
            month <= 12 &&
            value != null &&
            value.trim().isNotEmpty) {
          monthlyImages[month] = value.trim();
        }
      }
    }

    return fallback.copyWith(
      backgroundColorValue:
          _parseInt(rawTheme['backgroundColorValue']) ??
          fallback.backgroundColorValue,
      foregroundColorValue:
          _parseInt(rawTheme['foregroundColorValue']) ??
          fallback.foregroundColorValue,
      accentColorValue:
          _parseInt(rawTheme['accentColorValue']) ?? fallback.accentColorValue,
      backgroundImageUrl:
          rawTheme['backgroundImageUrl']?.toString() ??
          fallback.backgroundImageUrl,
      backgroundImageOpacity:
          _parseDouble(rawTheme['backgroundImageOpacity']) ??
          fallback.backgroundImageOpacity,
      backgroundImageFit:
          _parseBackgroundImageFit(rawTheme['backgroundImageFit']) ??
          fallback.backgroundImageFit,
      backgroundImageAlignment:
          _parseBackgroundImageAlignment(
            rawTheme['backgroundImageAlignment'],
          ) ??
          fallback.backgroundImageAlignment,
      backgroundImageUrlsByMonth: monthlyImages,
    );
  }

  String _generateTemplateId(String name, DateTime now) {
    final normalizedName = name.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '_',
    );
    return '${normalizedName}_${now.microsecondsSinceEpoch}';
  }

  CalendarExportTuning? _parseExportTuning(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      return null;
    }
    return CalendarExportTuning(
      dpi: _parseInt(raw['dpi']) ?? CalendarImageQuality.print.defaultDpi,
      jpegQuality:
          _parseInt(raw['jpegQuality']) ??
          CalendarImageQuality.print.defaultJpegQuality,
      targetSizeKb:
          _parseInt(raw['targetSizeKb']) ??
          CalendarImageQuality.print.defaultTargetSizeKb,
      enableAdaptiveCompression:
          _parseBool(raw['enableAdaptiveCompression']) ?? true,
    );
  }

  CalendarGenerationMode? _parseMode(Object? raw) {
    final name = raw?.toString();
    return _firstWhereOrNull<CalendarGenerationMode>(
      CalendarGenerationMode.values,
      (value) => value.name == name,
    );
  }

  Language? _parseLanguage(Object? raw) {
    final code = raw?.toString();
    if (code == null || code.trim().isEmpty) {
      return null;
    }
    return Language.fromCode(code);
  }

  CalendarPaperSize? _parsePaperSize(Object? raw) {
    final name = raw?.toString();
    return _firstWhereOrNull<CalendarPaperSize>(
      CalendarPaperSize.values,
      (value) => value.name == name,
    );
  }

  CalendarPageOrientation? _parseOrientation(Object? raw) {
    final name = raw?.toString();
    return _firstWhereOrNull<CalendarPageOrientation>(
      CalendarPageOrientation.values,
      (value) => value.name == name,
    );
  }

  CalendarImageQuality? _parseImageQuality(Object? raw) {
    final name = raw?.toString();
    return _firstWhereOrNull<CalendarImageQuality>(
      CalendarImageQuality.values,
      (value) => value.name == name,
    );
  }

  CalendarLandscapeDecorationAreaSide? _parseLandscapeDecorationAreaSide(
    Object? raw,
  ) {
    final name = raw?.toString();
    return _firstWhereOrNull<CalendarLandscapeDecorationAreaSide>(
      CalendarLandscapeDecorationAreaSide.values,
      (value) => value.name == name,
    );
  }

  int? _parseInt(Object? raw) {
    if (raw is int) {
      return raw;
    }
    return int.tryParse(raw?.toString() ?? '');
  }

  double? _parseDouble(Object? raw) {
    if (raw is double) {
      return raw;
    }
    if (raw is int) {
      return raw.toDouble();
    }
    return double.tryParse(raw?.toString() ?? '');
  }

  bool? _parseBool(Object? raw) {
    if (raw is bool) {
      return raw;
    }

    final value = raw?.toString().toLowerCase();
    if (value == 'true') {
      return true;
    }
    if (value == 'false') {
      return false;
    }
    return null;
  }

  CalendarBackgroundImageFit? _parseBackgroundImageFit(Object? raw) {
    final name = raw?.toString();
    return _firstWhereOrNull<CalendarBackgroundImageFit>(
      CalendarBackgroundImageFit.values,
      (value) => value.name == name,
    );
  }

  CalendarBackgroundImageAlignment? _parseBackgroundImageAlignment(
    Object? raw,
  ) {
    final name = raw?.toString();
    return _firstWhereOrNull<CalendarBackgroundImageAlignment>(
      CalendarBackgroundImageAlignment.values,
      (value) => value.name == name,
    );
  }

  T? _firstWhereOrNull<T>(Iterable<T> values, bool Function(T) test) {
    for (final value in values) {
      if (test(value)) {
        return value;
      }
    }
    return null;
  }
}
