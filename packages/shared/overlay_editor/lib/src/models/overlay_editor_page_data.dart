import 'package:flutter/widgets.dart';

import 'overlay_editor_item.dart';

class OverlayEditorPageData {
  const OverlayEditorPageData({
    required this.pageKey,
    required this.title,
    required this.preview,
    required this.canvasSize,
    this.subtitle,
    this.items = const <OverlayEditorItem>[],
  });

  final int pageKey;
  final String title;
  final String? subtitle;
  final Widget preview;
  final Size canvasSize;
  final List<OverlayEditorItem> items;
}
