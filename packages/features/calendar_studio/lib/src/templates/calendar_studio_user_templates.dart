import 'dart:typed_data';

import '../models/calendar_studio_document.dart';
import '../models/calendar_studio_types.dart';
import '../models/calendar_studio_user_template.dart';
import '../services/calendar_studio_zip.dart';
import 'calendar_studio_bindings.dart';
import 'calendar_studio_templates.dart';

/// Turns a project page into a [CalendarStudioUserTemplate], and a user
/// template into a gallery [CalendarStudioTemplate].
abstract final class CalendarStudioUserTemplates {
  /// [page]'s blocks with the month and year titles it shows marked bound,
  /// for the save sheet to offer as "Updates every month".
  static List<CalendarStudioBlock> detectBindings(CalendarStudioPage page) => [
    for (final block in page.blocks)
      CalendarStudioBindings.markDetected(
        block,
        year: page.year,
        month: page.month,
      ),
  ];

  /// A template of [page] in [project]. [blocks] are the page's blocks after
  /// the user chose which titles stay bound (see [detectBindings]). Without
  /// [keepPhotos], image blocks keep their frame but lose the photo.
  static CalendarStudioUserTemplate capture(
    CalendarStudioProject project,
    CalendarStudioPage page, {
    required String name,
    required List<CalendarStudioBlock> blocks,
    required bool keepPhotos,
    required DateTime now,
    List<String> moods = const [],
    String? author,
    String? description,
    Uint8List? preview,
  }) {
    final base = CalendarStudioTemplates.byIdOrNull(project.templateId);
    return CalendarStudioUserTemplate(
      id: CalendarStudioZip.uuid(),
      name: name.trim(),
      author: _blankToNull(author),
      description: _blankToNull(description),
      basePresetId: project.templateId,
      category: base?.category ?? _category(page.canvas),
      canvas: page.canvas,
      monthly: base?.monthly ?? project.pages.length > 1,
      moods: moods,
      palette: base != null && base.palette.isNotEmpty
          ? base.palette
          : _palette(page),
      blocks: [
        for (final block in blocks)
          keepPhotos ? block : block.copyWith(content: _withoutPhoto(block)),
      ],
      createdAt: now,
      updatedAt: now,
      preview: preview,
    );
  }

  /// The gallery entry for [template]: creating a project from it gives one
  /// page per month (or one sheet) with its bound titles rewritten.
  static CalendarStudioTemplate toTemplate(
    CalendarStudioUserTemplate template,
  ) => CalendarStudioTemplate(
    id: template.templateId,
    name: template.name,
    category: template.category,
    canvas: template.canvas,
    monthly: template.monthly,
    moods: template.moods,
    palette: template.palette,
    user: template,
    create: ({required id, required source, required now}) {
      final pageCount = template.monthly ? source.pageCount : 1;
      return CalendarStudioProject(
        id: id,
        name: '${template.name} ${source.year}',
        templateId: template.templateId,
        source: source,
        createdAt: now,
        updatedAt: now,
        pages: List.generate(pageCount, (index) {
          final absolute = source.month - 1 + index;
          final year = source.year + absolute ~/ 12;
          final month = absolute % 12 + 1;
          return CalendarStudioPage(
            id: 'page-$index',
            label: CalendarStudioBindings.englishMonths[month - 1],
            year: year,
            month: month,
            canvas: template.canvas,
            blocks: [
              for (final block in template.blocks)
                CalendarStudioBindings.apply(
                  block,
                  language: source.language,
                  year: year,
                  month: month,
                ),
            ],
          );
        }),
      );
    },
  );

  static Map<String, Object?> _withoutPhoto(CalendarStudioBlock block) => {
    for (final entry in block.content.entries)
      if (!CalendarStudioUserTemplate.assetKeys.contains(entry.key) &&
          entry.key != 'editorState')
        entry.key: entry.value,
  };

  static String? _blankToNull(String? value) =>
      value == null || value.trim().isEmpty ? null : value.trim();

  static String _category(StudioCanvas canvas) {
    final ratio = canvas.width / canvas.height;
    if ((ratio - 1).abs() < .01) return 'Social · square';
    if (ratio < .6) return 'Story · 9:16';
    return ratio > 1 ? 'Custom · landscape' : 'Custom · portrait';
  }

  /// Paper, then the colours the design uses most visibly.
  static List<int> _palette(CalendarStudioPage page) {
    final colors = <int>[page.canvas.backgroundColor];
    void add(Object? value) {
      if (value is int && !colors.contains(value) && colors.length < 5) {
        colors.add(value);
      }
    }

    for (final block in page.blocks) {
      add(block.style['color']);
      add(block.style['inkColor']);
      add(block.style['holidayColor']);
    }
    return colors;
  }
}
