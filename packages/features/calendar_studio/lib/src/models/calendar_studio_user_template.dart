import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import 'calendar_studio_document.dart';
import 'calendar_studio_types.dart';

/// A page design the user saved (or imported) as a template: one page of
/// blocks whose month and year titles are bound, so projects made from it
/// get the right titles on every page.
class CalendarStudioUserTemplate extends Equatable {
  const CalendarStudioUserTemplate({
    required this.id,
    required this.name,
    required this.basePresetId,
    required this.category,
    required this.canvas,
    required this.monthly,
    required this.blocks,
    required this.createdAt,
    required this.updatedAt,
    this.author,
    this.description,
    this.moods = const [],
    this.palette = const [],
    this.preview,
  });

  /// A UUID; galleries and projects refer to it as [templateId].
  final String id;
  final String name;
  final String? author;
  final String? description;

  /// The built-in preset the design started from ("jade-wall"), or the user
  /// template it was saved from.
  final String basePresetId;

  /// Gallery place and size ("Wall · A4 portrait").
  final String category;
  final StudioCanvas canvas;

  /// One page per month; false for single-sheet designs (year at a glance).
  final bool monthly;
  final List<String> moods;

  /// Swatches for the gallery card (paper, primary, accent, ink, holiday).
  final List<int> palette;

  /// The page design. Text blocks may carry a binding
  /// (`CalendarStudioBindings`); image blocks refer to the host's assets.
  final List<CalendarStudioBlock> blocks;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// A PNG of the design, about 600 px wide.
  final Uint8List? preview;

  /// Prefix that tells user templates from built-in ones.
  static const idPrefix = 'user:';

  /// Version of `template.json` this app writes and reads.
  static const formatVersion = 1;

  String get templateId => '$idPrefix$id';

  static bool isUserTemplateId(String templateId) =>
      templateId.startsWith(idPrefix);

  /// Image asset ids the design uses.
  Set<String> get assetIds => {
    for (final block in blocks)
      for (final key in assetKeys)
        if (block.content[key] case final String id) id,
  };

  /// Block content keys that hold asset ids.
  static const assetKeys = ['assetId', 'originalAssetId', 'editBaseAssetId'];

  CalendarStudioUserTemplate copyWith({
    String? id,
    String? name,
    String? author,
    String? description,
    List<String>? moods,
    List<CalendarStudioBlock>? blocks,
    DateTime? createdAt,
    DateTime? updatedAt,
    Uint8List? preview,
  }) => CalendarStudioUserTemplate(
    id: id ?? this.id,
    name: name ?? this.name,
    author: author ?? this.author,
    description: description ?? this.description,
    basePresetId: basePresetId,
    category: category,
    canvas: canvas,
    monthly: monthly,
    moods: moods ?? this.moods,
    palette: palette,
    blocks: blocks ?? this.blocks,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    preview: preview ?? this.preview,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    author,
    description,
    basePresetId,
    category,
    canvas,
    monthly,
    moods,
    palette,
    blocks,
    createdAt,
    updatedAt,
    preview,
  ];
}
