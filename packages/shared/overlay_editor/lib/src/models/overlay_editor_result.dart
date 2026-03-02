import 'overlay_editor_item.dart';

class OverlayEditorResult {
  const OverlayEditorResult({
    required this.itemsByPageKey,
    required this.pageIndex,
  });

  final Map<int, List<OverlayEditorItem>> itemsByPageKey;
  final int pageIndex;
}
