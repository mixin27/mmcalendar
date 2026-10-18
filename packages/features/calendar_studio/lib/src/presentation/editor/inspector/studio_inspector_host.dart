import 'package:flutter/widgets.dart';

import '../../../models/calendar_studio_document.dart';
import '../../../models/calendar_studio_project_theme.dart';
import '../../../services/calendar_studio_controller.dart';

/// What the inspector panels need from the editor: the controller, the
/// project theme and colours, and the editor actions that open sheets or
/// call host services.
class StudioInspectorHost {
  const StudioInspectorHost({
    required this.controller,
    required this.theme,
    required this.recentColors,
    required this.rememberColor,
    required this.designSize,
    required this.replaceImage,
    required this.revertImage,
    required this.editOnPage,
    this.editImage,
    this.removeBackground,
    this.suggestText,
    this.textFieldRevision = 0,
    this.applyToAllPages,
  });

  final CalendarStudioController controller;
  final CalendarStudioProjectTheme theme;

  /// Colours picked recently in this session, newest first.
  final List<int> recentColors;
  final ValueChanged<int> rememberColor;

  /// The page in design pixels, for the layout fields.
  final Size designSize;

  final ValueChanged<CalendarStudioBlock> replaceImage;
  final ValueChanged<CalendarStudioBlock> revertImage;
  final ValueChanged<CalendarStudioBlock>? editImage;
  final ValueChanged<CalendarStudioBlock>? removeBackground;
  final ValueChanged<CalendarStudioBlock>? suggestText;

  /// Bumped when text changes from outside the field (a suggestion), so the
  /// field shows it.
  final int textFieldRevision;

  /// Starts typing into a text block on the page.
  final ValueChanged<CalendarStudioBlock> editOnPage;

  /// Copies a block's style (and layout when asked) to every page; null on
  /// single-page projects.
  final void Function(CalendarStudioBlock block, {bool layout})?
  applyToAllPages;

  void update(CalendarStudioBlock block) => controller.updateBlock(block);

  void setStyle(CalendarStudioBlock block, String key, Object? value) =>
      update(block.copyWith(style: {...block.style, key: value}));

  void setContent(CalendarStudioBlock block, String key, Object? value) =>
      update(block.copyWith(content: {...block.content, key: value}));

  /// Colours this page already uses that aren't theme colours.
  List<int> pageColors(CalendarStudioPage page) {
    final themeColors = {
      for (final role in CalendarStudioProjectTheme.roles) theme.color(role),
    };
    final seen = <int>{};
    for (final block in page.blocks) {
      for (final MapEntry(:key, :value) in block.style.entries) {
        if (value is int &&
            CalendarStudioRetheme.isColorKey(key) &&
            !themeColors.contains(value)) {
          seen.add(value);
        }
      }
    }
    return seen.take(8).toList();
  }
}
