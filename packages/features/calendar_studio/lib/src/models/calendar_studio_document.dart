import 'package:equatable/equatable.dart';

import 'calendar_studio_types.dart';

class CalendarStudioBlock extends Equatable {
  const CalendarStudioBlock({
    required this.id,
    required this.type,
    required this.name,
    required this.bounds,
    this.rotation = 0,
    this.zIndex = 0,
    this.visible = true,
    this.locked = false,
    this.style = const {},
    this.content = const {},
  });
  final String id;
  final CalendarStudioBlockType type;
  final String name;
  final StudioRect bounds;
  final double rotation;
  final int zIndex;
  final bool visible;
  final bool locked;
  final Map<String, Object?> style;
  final Map<String, Object?> content;
  CalendarStudioBlock copyWith({
    String? name,
    StudioRect? bounds,
    double? rotation,
    int? zIndex,
    bool? visible,
    bool? locked,
    Map<String, Object?>? style,
    Map<String, Object?>? content,
  }) => CalendarStudioBlock(
    id: id,
    type: type,
    name: name ?? this.name,
    bounds: bounds ?? this.bounds,
    rotation: rotation ?? this.rotation,
    zIndex: zIndex ?? this.zIndex,
    visible: visible ?? this.visible,
    locked: locked ?? this.locked,
    style: style ?? this.style,
    content: content ?? this.content,
  );
  @override
  List<Object?> get props => [
    id,
    type,
    name,
    bounds,
    rotation,
    zIndex,
    visible,
    locked,
    style,
    content,
  ];
}

class CalendarStudioPage extends Equatable {
  const CalendarStudioPage({
    required this.id,
    required this.label,
    required this.year,
    required this.month,
    required this.canvas,
    this.blocks = const [],
  });
  final String id;
  final String label;
  final int year;
  final int month;
  final StudioCanvas canvas;
  final List<CalendarStudioBlock> blocks;
  CalendarStudioPage copyWith({
    String? label,
    int? year,
    int? month,
    StudioCanvas? canvas,
    List<CalendarStudioBlock>? blocks,
  }) => CalendarStudioPage(
    id: id,
    label: label ?? this.label,
    year: year ?? this.year,
    month: month ?? this.month,
    canvas: canvas ?? this.canvas,
    blocks: blocks ?? this.blocks,
  );
  @override
  List<Object> get props => [id, label, year, month, canvas, blocks];
}

class CalendarStudioProject extends Equatable {
  const CalendarStudioProject({
    required this.id,
    required this.name,
    required this.templateId,
    required this.source,
    required this.pages,
    required this.createdAt,
    required this.updatedAt,
    this.schemaVersion = 2,
    this.defaultExportPreset = CalendarStudioExportPreset.a4Pdf,
  });
  final String id;
  final String name;
  final String templateId;
  final int schemaVersion;
  final CalendarStudioSource source;
  final List<CalendarStudioPage> pages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CalendarStudioExportPreset defaultExportPreset;
  CalendarStudioProject copyWith({
    String? name,
    CalendarStudioSource? source,
    List<CalendarStudioPage>? pages,
    DateTime? updatedAt,
    CalendarStudioExportPreset? defaultExportPreset,
  }) => CalendarStudioProject(
    id: id,
    name: name ?? this.name,
    templateId: templateId,
    source: source ?? this.source,
    pages: pages ?? this.pages,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    schemaVersion: schemaVersion,
    defaultExportPreset: defaultExportPreset ?? this.defaultExportPreset,
  );
  @override
  List<Object> get props => [
    id,
    name,
    templateId,
    schemaVersion,
    source,
    pages,
    createdAt,
    updatedAt,
    defaultExportPreset,
  ];
}
