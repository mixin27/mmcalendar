import 'package:flutter/material.dart';

import '../../domain/entities/calendar_overlay_element.dart';

class CalendarGenerationEditorToolbar extends StatelessWidget {
  const CalendarGenerationEditorToolbar({
    required this.month,
    required this.previewZoom,
    required this.selectedElement,
    required this.onResetZoom,
    required this.onZoomOut,
    required this.onZoomIn,
    required this.onAddText,
    required this.onAddEmoji,
    required this.onAddSticker,
    required this.onAddImage,
    required this.onOpenLayers,
    required this.onBringToFront,
    required this.onSendToBack,
    required this.onToggleLock,
    required this.onDelete,
    super.key,
  });

  final int month;
  final double previewZoom;
  final CalendarOverlayElement? selectedElement;
  final VoidCallback onResetZoom;
  final VoidCallback onZoomOut;
  final VoidCallback onZoomIn;
  final VoidCallback onAddText;
  final VoidCallback onAddEmoji;
  final VoidCallback onAddSticker;
  final VoidCallback onAddImage;
  final VoidCallback onOpenLayers;
  final VoidCallback? onBringToFront;
  final VoidCallback? onSendToBack;
  final VoidCallback? onToggleLock;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final selectedLabel = selectedElement == null
        ? 'No element selected'
        : 'Selected: ${selectedElement!.type.name}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Editor • Month $month',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(selectedLabel, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _EditorToolButton(
                      icon: Icons.zoom_out_map,
                      label: '${(previewZoom * 100).round()}%',
                      onTap: onResetZoom,
                    ),
                    _EditorToolButton(
                      icon: Icons.zoom_out,
                      label: 'Zoom -',
                      onTap: onZoomOut,
                    ),
                    _EditorToolButton(
                      icon: Icons.zoom_in,
                      label: 'Zoom +',
                      onTap: onZoomIn,
                    ),
                    _EditorToolButton(
                      icon: Icons.text_fields,
                      label: 'Text',
                      onTap: onAddText,
                    ),
                    _EditorToolButton(
                      icon: Icons.emoji_emotions_outlined,
                      label: 'Emoji',
                      onTap: onAddEmoji,
                    ),
                    _EditorToolButton(
                      icon: Icons.auto_awesome_outlined,
                      label: 'Sticker',
                      onTap: onAddSticker,
                    ),
                    _EditorToolButton(
                      icon: Icons.image_outlined,
                      label: 'Image',
                      onTap: onAddImage,
                    ),
                    _EditorToolButton(
                      icon: Icons.layers_outlined,
                      label: 'Layers',
                      onTap: onOpenLayers,
                    ),
                    _EditorToolButton(
                      icon: Icons.vertical_align_top,
                      label: 'Front',
                      onTap: onBringToFront,
                    ),
                    _EditorToolButton(
                      icon: Icons.vertical_align_bottom,
                      label: 'Back',
                      onTap: onSendToBack,
                    ),
                    _EditorToolButton(
                      icon: selectedElement?.locked == true
                          ? Icons.lock_open_outlined
                          : Icons.lock_outline,
                      label: selectedElement?.locked == true
                          ? 'Unlock'
                          : 'Lock',
                      onTap: onToggleLock,
                    ),
                    _EditorToolButton(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      onTap: onDelete,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorToolButton extends StatelessWidget {
  const _EditorToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }
}
